# Herdr Lab

A seven-agent coding cockpit for coordinating Claude, Codex and Gemini CLI workers in one repository.

`cockpit.sh` creates a Herdr workspace, prepares per-repository coordination files, starts the configured agents and gives each agent its role prompt. The workflow and role prompts live alongside the launcher.

## Requirements

- [Herdr](https://github.com/lystiger/Hermes-lab) installed and its server running
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
