# Herdr Lab

A seven-agent coding cockpit for coordinating Claude, Codex and Gemini CLI workers in one repository.

`cockpit.sh` creates a Herdr workspace, prepares per-repository coordination files, starts the configured agents and gives each agent its role prompt. The workflow and role prompts live alongside the launcher.

## Requirements

- `herdr` CLI installed and its server running
- Claude Code, Codex CLI and Agy CLI installed and authenticated
- Bash, Python 3, and Git

## Start a cockpit

From the repository you want the agents to work on:

```bash
/path/to/Herdr-lab/cockpit.sh
```

Or pass a repository path explicitly:

```bash
/path/to/Herdr-lab/cockpit.sh /path/to/project
```

Use `--init-only` to create the `.agent/` coordination files without starting agents, or `--no-bootstrap` to start agents without sending their initial prompts.

The `.agent/` directory and `roles/.built/` are generated at runtime and are excluded from Git.

## Six job panes

A lighter setup with no roles, board or protocol: one orchestrator and six job panes.

```bash
/path/to/Herdr-lab/six.sh [REPO_DIR]
```

- Tab `control` runs Opus as the orchestrator. Tell it what to build.
- Tab `jobs` has six panes. The orchestrator splits your request into jobs and hands each one to `claude`, `codex` or `agy` with `assign`.
- Each job gets its own worktree, `~/six-worktrees/<repo>/jobN`, on branch `six/N-<slug>`. When an agent finishes, it ends with `DONE:` or `STUCK:`.
- Merging the branches is up to you.

By hand:

```bash
assign N claude|codex|agy "job"   # start an agent on a job in pane N
assign status                     # one line per pane
assign free N                     # stop pane N's agent; its branch is kept
```

- Claude runs in `auto` permission mode.
- Codex runs in its `workspace-write` sandbox, which keeps `.git` read-only, so the orchestrator commits Codex's work.
- Agy runs in `accept-edits` mode.
- New worktrees are trusted automatically, because you created them.
