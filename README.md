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

A lighter setup, with no board or protocol: one orchestrator, six job panes, and the LysStack/Hermes roles.

```bash
/path/to/Herdr-lab/six.sh [REPO_DIR]
```

- Tab `control` runs Opus as the orchestrator. Tell it what to build.
- Tab `jobs` has six panes. The orchestrator gives each job an agent (`claude`, `codex` or `agy`) and a role from `six-roles/`.
- The roles are builder, hardener, verifier, security, production, researcher and designer.
- Each feature runs builder, then hardener, then verifier. Each job runs in its own worktree, `~/six-worktrees/<repo>/jobN`, on branch `six/N-<slug>`.
- Merging the branches is up to you.

By hand:

```bash
assign N claude|codex|agy ROLE "job" [BASE]   # start a job in pane N; BASE is the branch to start from
assign status                                 # one line per pane
assign free N                                 # stop pane N's agent; its branch is kept
```

Every agent runs with its permission checks off: Codex with `--dangerously-bypass-approvals-and-sandbox`, Claude and agy with `--dangerously-skip-permissions`. They can run any command as you, so read each branch before you merge it. New worktrees are trusted automatically.
