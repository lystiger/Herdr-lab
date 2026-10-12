# Cockpit Protocol (all agents)

You are one of 7 agents sharing ONE git working tree. Full spec:
~/Projects/Herdr-lab/7-agent-coding-workflow.md

Coordination state lives in `.agent/` at the repo root:
- `.agent/BOARD.md` — single source of truth for assignments. Check it before starting anything.
- `.agent/DECISIONS.md` — durable architectural decisions (only meaningful ones).
- `.agent/handoffs/<you>.md` — your durable memory across /clear.

## Bootstrap (every fresh session, and after /clear)
1. Read your role (this prompt / your role file).
2. Read `.agent/BOARD.md`.
3. Read your own handoff file.
4. Read `.agent/DECISIONS.md` if relevant.
5. Run `git status`.
6. Verify your assigned file scope.
7. Continue ONLY your assigned task. If none, report IDLE and wait.
If the board and your handoff disagree, stop and ask Opus to resolve it.

## Rules
- Only edit files inside your assigned scope. If you need a change elsewhere, propose a patch to the owner / Opus instead of applying it.
- Never overwrite another agent's uncommitted work. No `git reset --hard`, `git checkout -- .`, `git stash` of others' work, force-push, or history rewrites.
- Do not reinterpret a task into a larger project.
- Update your own row in BOARD.md when your status changes (IDLE/ASSIGNED/WORKING/BLOCKED/REVIEW/DONE).
- Require human confirmation for: sudo, anything destructive outside the repo, credentials/secrets, production deploys, destructive DB migrations, force-push, deleting remote branches, billing/cloud changes.

## Completion report (when a task finishes)
```
## Completion Report
Task:
Status: DONE / BLOCKED / REVIEW REQUIRED
Changed:
Tests: command → result
Important decisions:
Risks:
Recommended next step:
```
Then update BOARD.md and your handoff.

## Context rollover
At ~70% context: update your handoff (template in `.agent/handoffs/_TEMPLATE.md`) → update BOARD.md → `git status` and summarize uncommitted work in the handoff → tell the human you are ready for /clear. After /clear, run the Bootstrap.
