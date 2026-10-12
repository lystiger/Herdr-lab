# 7-Agent Coding Workflow

> **Scope:** This document defines the **workflow layer only** for the coding cockpit.
>
> It does **not** yet integrate Paperclip, LysStack, Hermes, vector memory, long-term telemetry, or autonomous task scheduling. Those can be attached after this workflow is stable.

---

## 1. Goal

Build a 7-agent coding cockpit that can work on one repository with:

- clear ownership
- minimal duplicated work
- controlled write access
- checkpoint-based review
- predictable context rollover
- recoverable sessions
- one human-readable control plane

The system should optimize for **quality and sustained throughput**, not maximum simultaneous code generation.

---

## 2. Agent Topology

### Tab 1 — Control Plane

#### Agent 1 — Opus Medium
**Role:** Orchestrator / architect / decision maker

Responsibilities:

- understand the user request
- decompose work into tasks
- assign tasks to workers
- define file ownership and scope
- resolve conflicting approaches
- review worker summaries
- maintain the task board
- decide when Codex review is worth spending quota on
- produce final synthesis for the human

Default behavior:

- mostly read-only
- should not become the primary implementation agent
- should avoid duplicating work already assigned
- should remain easy for the human to read

**UI requirement:** Opus must run in its own full tab, not a small pane.

---

### Tab 2 — Worker Plane

#### Agent 2 — Sonnet Medium
**Role:** Primary implementation engineer

Best used for:

- main feature implementation
- refactors
- integration work
- backend/frontend changes
- non-trivial bug fixes

Write access: **Yes**

---

#### Agent 3 — Haiku Medium #1
**Role:** Test / debugging engineer

Best used for:

- reproducing failures
- writing tests
- running test suites
- investigating stack traces
- validating fixes
- small targeted patches

Write access: **Yes, but targeted**

---

#### Agent 4 — Haiku Medium #2
**Role:** Repository scout / maintenance engineer

Best used for:

- codebase exploration
- dependency tracing
- finding relevant files
- documentation
- small cleanup tasks
- simple boilerplate
- low-risk fixes

Write access: **Yes, but targeted**

---

#### Agent 5 — Codex GPT-6.1 Sol Low Fast
**Role:** Independent reviewer

Best used for:

- checkpoint review
- regression detection
- security review
- suspicious edge cases
- architecture critique
- diff review

Write access: **Read-only by default**

Codex is a scarce resource in this workflow.

Do **not** review every tiny change.

Preferred pattern:

```text
implementation batch
        ↓
tests
        ↓
Codex review
        ↓
fix findings
        ↓
one verification review if necessary
```

Avoid:

```text
change → Codex → change → Codex → change → Codex
```

---

#### Agent 6 — Agy 3.8 High #1
**Role:** Parallel implementation / alternate solution engineer

Best used for:

- independent implementation
- alternative designs
- boilerplate-heavy work
- isolated features
- experimentation

Write access: **Yes**

---

#### Agent 7 — Agy 3.8 High #2
**Role:** Research / second worker / independent validation

Best used for:

- parallel investigation
- alternative implementation
- documentation research
- isolated subtask execution
- second-opinion debugging

Write access: **Yes**

---

## 3. Repository Coordination Files

Create the following directory in each active repository:

```text
.agent/
├── BOARD.md
├── DECISIONS.md
├── handoffs/
│   ├── opus.md
│   ├── sonnet.md
│   ├── haiku-1.md
│   ├── haiku-2.md
│   ├── codex.md
│   ├── agy-1.md
│   └── agy-2.md
└── locks/
```

These files are operational state, not product documentation.

---

## 4. BOARD.md

`BOARD.md` is the single source of truth for active assignments.

Suggested structure:

```markdown
# Agent Board

| Agent | Task | Status | File Scope | Last Update |
|---|---|---|---|---|
| Opus | Coordinate auth refactor | ACTIVE | read-only | 14:30 |
| Sonnet | Refactor auth service | WORKING | backend/auth/** | 14:28 |
| Haiku-1 | Add regression tests | WORKING | tests/auth/** | 14:25 |
| Haiku-2 | Trace migration dependencies | DONE | read-only | 14:15 |
| Codex | Waiting for checkpoint | IDLE | read-only | 14:10 |
| Agy-1 | Frontend auth integration | WORKING | frontend/src/auth/** | 14:27 |
| Agy-2 | Alternative API analysis | RESEARCH | read-only | 14:20 |
```

Statuses:

- `IDLE`
- `ASSIGNED`
- `WORKING`
- `BLOCKED`
- `REVIEW`
- `DONE`

No agent should begin a new task without checking the board first.

---

## 5. File Ownership

The largest risk in a multi-agent coding cockpit is multiple agents editing the same files without coordination.

Before implementation, Opus should assign:

```text
task
→ agent
→ file/directory scope
→ expected output
```

Example:

```text
Sonnet:
  backend/auth/**

Haiku-1:
  tests/auth/**

Agy-1:
  frontend/src/auth/**

Codex:
  read-only review
```

If two agents must touch the same file:

1. one becomes the owner
2. the other produces recommendations or a patch proposal
3. only the owner applies the final change

The `locks/` directory may later be automated, but the initial workflow can use the board as the coordination mechanism.

---

## 6. DECISIONS.md

Important architectural decisions should survive agent context resets.

Suggested format:

```markdown
## 2026-10-11 — Authentication boundary

**Decision:** Keep token refresh inside backend/auth/session.py.

**Reason:**
- avoids duplicated frontend refresh logic
- keeps credentials server-side
- existing tests already target this layer

**Rejected alternative:**
Move refresh handling entirely to the frontend.

**Affected tasks:**
Sonnet auth refactor, Agy-1 frontend integration.
```

Only meaningful decisions belong here.

Do not log every implementation detail.

---

## 7. Context Rollover Protocol

Every long-running agent should reset before context degradation becomes significant.

### Threshold

Target rollover at approximately **70% context usage**.

Do not wait until the context is almost full.

### Before `/clear`

The agent must update its handoff file.

Template:

```markdown
# Session Handoff

## Goal
What this agent is currently trying to accomplish.

## Completed
- ...
- ...

## Current State
Branch:
Files changed:
Tests run:
Processes running:

## Important Findings
- ...
- ...

## Decisions
- decision → reason

## Remaining Work
1. ...
2. ...
3. ...

## Known Issues / Risks
- ...

## Next Recommended Action
...

## Important Commands
```bash
...
```

## Relevant Files
- path/to/file
- path/to/other/file
```

Then:

```text
update handoff
→ update BOARD.md
→ inspect git status
→ summarize uncommitted work
→ /clear
→ reload role instructions
→ read BOARD.md
→ read DECISIONS.md if relevant
→ read own handoff
→ continue
```

The handoff file is the durable memory.

Do not rely on the model remembering the previous session after `/clear`.

---

## 8. New Session Bootstrap

Every fresh agent session should follow:

```text
1. Read assigned role.
2. Read .agent/BOARD.md.
3. Read own handoff file.
4. Read .agent/DECISIONS.md if relevant.
5. Inspect git status.
6. Verify assigned scope.
7. Continue only the assigned task.
```

If the board and handoff disagree, stop and ask Opus to resolve the conflict.

---

## 9. Task Assignment Protocol

Opus should assign work in a compact format:

```markdown
## Task: AUTH-03

Agent: Sonnet
Goal: Refactor token refresh path.

Scope:
- backend/auth/**
- backend/services/session.py

Do not touch:
- frontend/**
- database migrations

Acceptance criteria:
- existing tests pass
- refresh path has one source of truth
- no credential logging
- add/update tests if behavior changes

Return:
- summary
- files changed
- tests run
- blockers
```

Workers should not reinterpret the task into a larger project unless requested.

---

## 10. Worker Completion Protocol

When a worker finishes a task, it should return:

```markdown
## Completion Report

Task:
Status: DONE / BLOCKED / REVIEW REQUIRED

Changed:
- ...

Tests:
- command → result

Important decisions:
- ...

Risks:
- ...

Recommended next step:
- ...
```

Then update:

- `BOARD.md`
- own handoff

Opus decides whether the result goes directly to integration or requires Codex review.

---

## 11. Codex Review Policy

Because Codex usage can become the limiting resource, trigger it deliberately.

Use Codex when:

- a meaningful implementation batch is complete
- a risky refactor was made
- authentication/security logic changed
- migrations changed
- concurrency changed
- a bug survived multiple attempts
- final pre-merge review is valuable

Skip Codex when:

- only formatting changed
- documentation changed
- trivial boilerplate changed
- a worker has not finished the implementation batch
- tests are still obviously failing for known reasons

Review request should include:

```text
goal
+
diff
+
relevant tests
+
known concerns
```

not the entire project history.

---

## 12. Permissions Policy

The cockpit should avoid constant approval prompts for normal repository work, but agents should not receive unrestricted machine authority.

### Allowed without repeated confirmation

Within the active repository:

- read files
- edit assigned files
- create source/test files
- run linters
- run unit/integration tests
- run development builds
- inspect git status/diff/log
- use normal package-manager commands required by the project when non-destructive

### Require human confirmation

Agents must not autonomously perform:

- `sudo` system changes
- destructive operations outside the repository
- deleting unrelated user files
- modifying credentials
- rotating secrets
- production deployments
- destructive cloud actions
- destructive database migrations
- `git push --force`
- rewriting shared branch history
- deleting remote branches
- changing billing/resources
- changing OS boot configuration

The goal is **low-friction development**, not unlimited machine control.

---

## 13. Git Discipline

Agents share one working tree unless explicitly configured otherwise.

Rules:

- inspect `git status` before editing
- do not overwrite another agent's uncommitted work
- do not use destructive reset commands to solve conflicts
- do not amend another agent's commit without instruction
- do not force-push
- use small logical commits when Opus asks for commits
- report all uncommitted changes at handoff

Later, the harness may introduce worktrees or isolated branches per worker.

---

## 14. Human Interaction Model

The human primarily interacts with **Opus**.

Normal flow:

```text
Human
  ↓
Opus
  ↓
Task decomposition
  ↓
Workers
  ↓
Completion reports
  ↓
Tests
  ↓
Codex checkpoint when justified
  ↓
Opus synthesis
  ↓
Human
```

The human may directly inspect or intervene in any worker pane when necessary.

The system must never make Opus a bottleneck for simple status visibility; `BOARD.md` should always expose current activity.

---

## 15. Suggested Herdr Layout

### Tab 1

```text
┌──────────────────────────────────────────────┐
│                  OPUS MEDIUM                 │
│                                              │
│               CONTROL PLANE                  │
│                                              │
└──────────────────────────────────────────────┘
```

### Tab 2

```text
┌──────────────────┬──────────────────┬──────────────────┐
│ SONNET MEDIUM    │ HAIKU MEDIUM #1 │ HAIKU MEDIUM #2 │
├──────────────────┼──────────────────┼──────────────────┤
│ CODEX 6.1 LOW    │ AGY 3.8 HIGH #1 │ AGY 3.8 HIGH #2 │
│ FAST             │                  │                  │
└──────────────────┴──────────────────┴──────────────────┘
```

Exact pane geometry may be adjusted for terminal size.

---

## 16. Startup Requirement

The eventual launcher should be able to start the full cockpit with one command.

Conceptually:

```text
herdr
  ↓
create control tab
  ↓
launch Opus Medium
  ↓
create worker tab
  ↓
launch Sonnet Medium
  ↓
launch Haiku Medium #1
  ↓
launch Haiku Medium #2
  ↓
launch Codex 6.1 Sol Low Fast
  ↓
launch Agy 3.8 High #1
  ↓
launch Agy 3.8 High #2
```

Do not hard-code CLI flags until they are verified against the installed versions of Claude, Codex, Agy, and Herdr.

---

## 17. Failure Handling

If an agent crashes:

```text
restart agent
→ read role
→ read BOARD
→ read handoff
→ inspect git status
→ resume
```

If two agents conflict:

```text
stop both edits
→ Opus inspects diff
→ select file owner
→ preserve useful work
→ update BOARD
→ continue
```

If tests fail:

```text
implementation agent investigates first
→ Haiku-1 reproduces/isolates if useful
→ Codex only after a coherent implementation exists
```

---

## 18. Definition of Done for This Workflow

This workflow layer is considered stable when:

- [ ] all 7 agents launch reliably
- [ ] Opus runs in a separate tab
- [ ] six worker panes are created consistently
- [ ] every agent has a fixed role
- [ ] BOARD.md is used for task ownership
- [ ] handoff files survive context resets
- [ ] `/clear` rollover works around 70% context
- [ ] agents resume correctly from handoff
- [ ] overlapping edits are rare and recoverable
- [ ] Codex is used at checkpoints rather than continuously
- [ ] normal coding does not require constant permission prompts
- [ ] dangerous host-level actions still require human approval
- [ ] one real repository completes a multi-agent task successfully

---

# Phase Boundary

## Phase 1 — Workflow
**This document.**

Provides:

- agent roles
- task routing
- state handoff
- review policy
- permissions model
- cockpit topology
- basic coordination

## Phase 2 — Harness / Orchestration
Integrate **LysStack** around the workflow.

Potential responsibilities:

- launcher/runtime abstraction
- agent lifecycle management
- structured event logging
- prompt injection
- shared task state
- automatic context monitoring
- session handoff automation
- tool routing
- model/provider abstraction
- telemetry
- retry/recovery logic

## Phase 3 — Paperclip Integration
Use Paperclip only after its responsibilities are clearly mapped against LysStack.

Potential integration points:

- task/project orchestration
- agent assignment
- persistent work state
- workflow visualization
- human approval gates
- scheduling
- task dependencies

Avoid duplicating capabilities already owned by LysStack.

## Phase 4 — Memory / Hermes / Elysia
Attach longer-lived intelligence after execution is stable.

Potential responsibilities:

- retrieve prior decisions
- project memory
- engineering preferences
- reusable lessons
- historical failure patterns
- cross-session context
- future Elysia orchestration

---

# Design Principle

Do not make the system more autonomous faster than it becomes observable.

The progression should be:

```text
reliable workflow
      ↓
observable workflow
      ↓
automated orchestration
      ↓
persistent memory
      ↓
greater autonomy
```

A seven-agent cockpit with reliable coordination is more useful than twenty agents with unclear ownership.
