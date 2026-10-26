# Shared by six.sh and assign: start an agent in a pane and get a prompt into it.

# start_agent NAME KIND PANE [AGENT_ARG...]: returns once the agent is idle.
start_agent() {
  local name="$1" kind="$2" pane="$3"; shift 3
  herdr agent start "$name" --kind "$kind" --pane "$pane" --timeout 60000 -- "$@" >/dev/null 2>&1 || true
  # A new worktree is a folder the agent has not seen; the user made it, so trust it.
  # Claude lists "No, exit" first, agy lists "Yes, I trust this folder" first.
  local screen; screen="$(herdr pane read "$pane" --source recent-unwrapped --lines 40 2>/dev/null || true)"
  if grep -qE '[❯>] +Yes, I trust this folder' <<<"$screen"; then
    herdr pane send-keys "$pane" enter >/dev/null
  elif grep -q 'trust this folder' <<<"$screen"; then
    herdr pane send-keys "$pane" down enter >/dev/null
  fi
  herdr agent wait "$name" --until idle --timeout 60000 >/dev/null
}

# prompt_agent NAME PANE TEXT: submits TEXT and checks the agent starts working, once more if not.
prompt_agent() {
  local name="$1" pane="$2" text="$3" try
  for try in 1 2; do
    herdr pane send-keys "$pane" esc >/dev/null  # close a startup tip or update notice
    sleep 1
    herdr agent prompt "$name" "$text" --wait --until working --timeout 15000 >/dev/null 2>&1 && return 0
    sleep 2
  done
  return 1
}
