#!/usr/bin/env bash
# 7-agent coding cockpit launcher for herdr.
# Spec: ~/Projects/agents/7-agent-coding-workflow.md
#
# Usage: cockpit.sh [REPO_DIR] [--no-bootstrap] [--init-only]
#   REPO_DIR        repository to work on (default: current directory)
#   --no-bootstrap  start agents without sending the bootstrap prompt
#   --init-only     only create .agent/ coordination files, launch nothing
#
# Verified against: herdr 0.8.2, Claude Code 2.1.296, codex-cli 0.162.1, agy 1.3.3
set -euo pipefail

HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
ROLES="$HERE/roles"
REPO="$PWD"; BOOTSTRAP=1; INIT_ONLY=0
for a in "$@"; do
  case "$a" in
    --no-bootstrap) BOOTSTRAP=0 ;;
    --init-only) INIT_ONLY=1 ;;
    -h|--help) sed -n 2,10p "$0"; exit 0 ;;
    *) REPO="$(cd "$a" && pwd)" ;;
  esac
done
NAME="$(basename "$REPO")"

# ---- Models (edit here when versions change) --------------------------------
OPUS_ARGS=(--model opus --effort medium)
SONNET_ARGS=(--model sonnet --effort medium)
HAIKU_ARGS=(--model haiku --effort medium)
CODEX_ARGS=(-m gpt-6.1-sol -c 'model_reasoning_effort="low"' -c 'service_tier="fast"' -s read-only -a on-request)
AGY_ARGS=(--model gemini-3.8-flash-high --effort high --mode accept-edits --add-dir "$ROLES")
CLAUDE_COMMON=(--permission-mode acceptEdits --settings "$HERE/claude-settings.json" --add-dir "$HERE")

# ---- 1. Coordination files ---------------------------------------------------
init_agent_dir() {
  local d="$REPO/.agent"
  mkdir -p "$d/handoffs" "$d/locks"
  [ -f "$d/BOARD.md" ]     || cp "$HERE/templates/BOARD.md" "$d/BOARD.md"
  [ -f "$d/DECISIONS.md" ] || cp "$HERE/templates/DECISIONS.md" "$d/DECISIONS.md"
  cp -n "$HERE/templates/handoffs/_TEMPLATE.md" "$d/handoffs/_TEMPLATE.md" 2>/dev/null || true
  for a in opus sonnet haiku-1 haiku-2 codex agy-1 agy-2; do
    [ -f "$d/handoffs/$a.md" ] || printf '# Session Handoff — %s\n\n(no session yet)\n' "$a" > "$d/handoffs/$a.md"
  done
  # Keep operational state out of git without touching the tracked .gitignore.
  local ex; ex="$(git -C "$REPO" rev-parse --git-path info/exclude 2>/dev/null || true)"
  if [ -n "$ex" ]; then
    case "$ex" in /*) ;; *) ex="$REPO/$ex" ;; esac
    grep -qxF '.agent/' "$ex" 2>/dev/null || echo '.agent/' >> "$ex"
  fi
}
init_agent_dir
echo "✓ $REPO/.agent ready"
[ "$INIT_ONLY" = 1 ] && exit 0

# ---- 2. Herdr layout --------------------------------------------------------
command -v herdr >/dev/null || { echo "herdr not found" >&2; exit 1; }
herdr workspace list >/dev/null 2>&1 || { echo "herdr server not running — start herdr first" >&2; exit 1; }
j() { python3 -c "import json,sys;d=json.load(sys.stdin)['result'];print($1)"; }

ws_json="$(herdr workspace create --cwd "$REPO" --label "$NAME cockpit" --no-focus)"
WS="$(echo "$ws_json" | j "d['workspace']['workspace_id']")"
CTRL_TAB="$(echo "$ws_json" | j "d['tab']['tab_id']")"
P_OPUS="$(echo "$ws_json" | j "d['root_pane']['pane_id']")"
herdr tab rename "$CTRL_TAB" control >/dev/null

wt_json="$(herdr tab create --workspace "$WS" --cwd "$REPO" --label workers --no-focus)"
P_SONNET="$(echo "$wt_json" | j "d['root_pane']['pane_id']")"
split() { herdr pane split --pane "$1" --direction "$2" --ratio "$3" --cwd "$REPO" --no-focus | j "d['pane']['pane_id']"; }
P_CODEX="$(split "$P_SONNET" down 0.5)"
P_HAIKU1="$(split "$P_SONNET" right 0.333)"
P_HAIKU2="$(split "$P_HAIKU1" right 0.5)"
P_AGY1="$(split "$P_CODEX" right 0.333)"
P_AGY2="$(split "$P_AGY1" right 0.5)"
echo "✓ workspace $WS: tab control [$P_OPUS], tab workers [$P_SONNET $P_HAIKU1 $P_HAIKU2 / $P_CODEX $P_AGY1 $P_AGY2]"
sleep 1  # let shells reach their prompt

# ---- 3. Agents --------------------------------------------------------------
# herdr can't shell-encode multi-line args, so pass the role as a file.
role_file() { mkdir -p "$ROLES/.built"; cat "$ROLES/_common.md" "$ROLES/$1.md" > "$ROLES/.built/$1.md"; echo "$ROLES/.built/$1.md"; }
start_claude() { # name pane model-args...
  local n="$1" p="$2"; shift 2
  herdr agent start "$n" --kind claude --pane "$p" --timeout 60000 -- \
    "$@" "${CLAUDE_COMMON[@]}" --append-system-prompt-file "$(role_file "$n")" >/dev/null
}
pids=()
start_claude opus    "$P_OPUS"   "${OPUS_ARGS[@]}"   & pids+=($!)
start_claude sonnet  "$P_SONNET" "${SONNET_ARGS[@]}" & pids+=($!)
start_claude haiku-1 "$P_HAIKU1" "${HAIKU_ARGS[@]}"  & pids+=($!)
start_claude haiku-2 "$P_HAIKU2" "${HAIKU_ARGS[@]}"  & pids+=($!)
herdr agent start codex --kind codex --pane "$P_CODEX" --timeout 60000 -- "${CODEX_ARGS[@]}" >/dev/null & pids+=($!)
herdr agent start agy-1 --kind agy --pane "$P_AGY1" --timeout 60000 -- "${AGY_ARGS[@]}" >/dev/null & pids+=($!)
herdr agent start agy-2 --kind agy --pane "$P_AGY2" --timeout 60000 -- "${AGY_ARGS[@]}" >/dev/null & pids+=($!)
fail=0; for p in "${pids[@]}"; do wait "$p" || fail=1; done
[ "$fail" = 1 ] && echo "! some agents did not report ready (blocked on a trust/login prompt?) — check panes" >&2
herdr agent list

# ---- 4. Bootstrap -----------------------------------------------------------
if [ "$BOOTSTRAP" = 1 ]; then
  wait_msg=" Then report your status in one line and wait for an assignment from Opus."
  for n in opus sonnet haiku-1 haiku-2 agy-1 agy-2; do
    [ "$n" = opus ] && extra="" || extra="$wait_msg"
    case "$n" in  # Claude agents already carry their role in the system prompt.
      agy-*) msg="You are '$n' in the 7-agent cockpit. Read your role $ROLES/$n.md and the protocol $ROLES/_common.md, then run the Bootstrap steps.$extra" ;;
      *)     msg="You are '$n' in the 7-agent cockpit. Your role and protocol are in your system prompt. Run the Bootstrap steps.$extra" ;;
    esac
    herdr agent prompt "$n" "$msg" >/dev/null 2>&1 || echo "! could not prompt $n" >&2
  done
  # Codex is quota-limited: only load its role, don't make it read the repo.
  herdr agent prompt codex "Read $ROLES/_common.md and $ROLES/codex.md. That is your role. Reply only 'codex ready' and wait for a review request." >/dev/null 2>&1 \
    || echo "! could not prompt codex" >&2
fi

herdr workspace focus "$WS" >/dev/null
herdr tab focus "$CTRL_TAB" >/dev/null
echo "✓ cockpit up — talk to Opus in tab 'control'. Board: $REPO/.agent/BOARD.md"
