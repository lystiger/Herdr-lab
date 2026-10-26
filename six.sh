#!/usr/bin/env bash
# Six job panes and an orchestrator in one herdr workspace.
#
# Usage: six.sh [REPO_DIR]
#   Tab "control": Opus, the orchestrator. Tab "jobs": six empty panes, 3x2.
#   Opus splits your request into jobs and hands each one to an agent in a pane
#   with `assign`; every job gets its own git worktree and branch.
#
# Verified against: herdr 0.8.2
set -euo pipefail

HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
. "$HERE/six-lib.sh"
REPO="$(cd "${1:-$PWD}" && git rev-parse --show-toplevel)"
NAME="$(basename "$REPO")"
STATE="$REPO/.six"

command -v herdr >/dev/null || { echo "herdr not found" >&2; exit 1; }
herdr workspace list >/dev/null 2>&1 || { echo "herdr server not running — start herdr first" >&2; exit 1; }
if herdr agent get "$NAME-orch" >/dev/null 2>&1; then
  echo "a six workspace for $NAME is already running" >&2; exit 1
fi

mkdir -p "$STATE"
ex="$(git -C "$REPO" rev-parse --path-format=absolute --git-path info/exclude)"
grep -qxF '.six/' "$ex" 2>/dev/null || echo '.six/' >> "$ex"

j() { python3 -c "import json,sys;d=json.load(sys.stdin)['result'];print($1)"; }
ws_json="$(herdr workspace create --cwd "$REPO" --label "$NAME six" --no-focus)"
WS="$(echo "$ws_json" | j "d['workspace']['workspace_id']")"
CTRL_TAB="$(echo "$ws_json" | j "d['tab']['tab_id']")"
P_ORCH="$(echo "$ws_json" | j "d['root_pane']['pane_id']")"
herdr tab rename "$CTRL_TAB" control >/dev/null

jobs_json="$(herdr tab create --workspace "$WS" --cwd "$REPO" --label jobs --no-focus)"
split() { herdr pane split --pane "$1" --direction "$2" --ratio "$3" --cwd "$REPO" --no-focus | j "d['pane']['pane_id']"; }
P1="$(echo "$jobs_json" | j "d['root_pane']['pane_id']")"
P4="$(split "$P1" down 0.5)"
P2="$(split "$P1" right 0.333)"
P3="$(split "$P2" right 0.5)"
P5="$(split "$P4" right 0.333)"
P6="$(split "$P5" right 0.5)"
printf '%s\n' "$P1" "$P2" "$P3" "$P4" "$P5" "$P6" > "$STATE/panes"  # line N is pane N
n=0; for p in "$P1" "$P2" "$P3" "$P4" "$P5" "$P6"; do n=$((n + 1)); herdr pane rename "$p" "$n · free" >/dev/null; done
rm -f "$STATE"/job*.meta
sleep 1  # let shells reach their prompt

start_agent "$NAME-orch" claude "$P_ORCH" \
  --model opus --dangerously-skip-permissions --add-dir "$HERE" \
  --append-system-prompt-file "$HERE/orchestrator.md"

herdr workspace focus "$WS" >/dev/null
herdr tab focus "$CTRL_TAB" >/dev/null
echo "✓ $NAME six up: tell Opus what to build in tab 'control'; jobs run in tab 'jobs'."
