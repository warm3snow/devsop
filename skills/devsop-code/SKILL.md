---
name: devsop-code
description: Implements the design-stage task list with TDD discipline — failing test first, minimal code, verified steps, progress ledger. Use after devsop-design; consumes docs/plans/<plan-dir>/tasks.md.
---

# devsop-code

Implement the task list from `devsop-design`, task by task, with a test-first gate per task and a written progress record that survives context loss.

Core discipline: the design already did the thinking; execute it exactly and prove each step.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it and start from the test. Exceptions (ask the user): throwaway prototypes, generated code, configuration-only changes.

## Setup

1. Resolve the task list: `docs/plans/<plan-dir>/tasks.md` from the `devsop-design` handoff. Fast path: when the handoff is `plan.md` only (small change with obvious implementation), derive the minimal task list from the scenarios and the confirmed assumptions, record it in the ledger, and proceed. Otherwise, if `tasks.md` does not exist, run `devsop-design` first — do not implement from a chat summary.
2. Read the plan artifacts once: stories, NFRs, scenarios, and the `## Interface contracts` in `tasks.md`. The spec (`plan.md`) is the binding authority; conflicts in tasks.md resolve against it. For UI tasks, also read the prototype pages listed in the handoff as the visual reference.
3. Create the ledger at `docs/plans/<plan-dir>/progress.md` (append if it exists — resume, don't redo: tasks marked complete have their commits in git; trust the ledger over memory). Format:

```markdown
# Progress — <plan dir>
## Task N: <name> — <status>
- <one line per step outcome, e.g. "RED: test_foo failed with not defined", "GREEN: 3 passed">
- Ruling: <decision> — <why> (record every deviation from tasks.md)
```

4. Follow the project's own branching rules. Never commit unless the project or the user asks.

## Task loop

For each task, in order:

1. **RED** — write the failing test named in the task's Tests block, with the exact assertion values from `plan.md` scenarios and the interface contracts in `tasks.md`. Run it; watch it fail, and check the failure is the right one (missing function, not syntax error).
2. **GREEN** — implement the minimal code to pass, honoring the task's exact files and signatures. Run the test; watch it pass. Do not add unrequested behavior.
3. **Verify** — run the task's verification steps. Every verification in tasks.md gets run and its output actually read; no "should pass".
4. **REFACTOR** — clean up while staying green, if needed.
5. **Ledger** — record step outcomes and any ruling, mark the task complete.

Keep going without pausing between tasks. Only stop for: an irreversible or destructive operation, a security-sensitive action, a conflict the spec does not resolve, or a task so broken every path forward is a guess. Stop there and ask the user; record the pause in the ledger.

**When reality diverges:** if the plan is wrong (stale line numbers, a signature that doesn't fit the actual code), make the smallest correct change, record a `Ruling:` line in the ledger, and continue. If the divergence changes an interface or a story, escalate back to `devsop-design` instead of improvising.

**Language style:** follow the project's rules under `rules/` of the devsop library and the project's own conventions. When the devsop library is installed, its language style guides are the default; the project's established patterns win where they conflict.

## Completion gate

After the last task:

1. Run the project's full relevant test suite, fresh. Read the output; count failures. Fix what fails, then re-run.
2. Re-read every scenario in `plan.md` (including NFR scenarios); for each, point to the passing test that proves it. Any scenario without proof is unfinished work.
3. Update the ledger with the final suite result and criterion checklist.
4. Report: tasks completed, rulings made, test evidence, and any criteria that need manual testing (they go to `devsop-test`).

Handoff: invoke `devsop-test` to execute the plan's manual/integration scenarios, or report completion if the user wants to stop here.

## Red flags

| Thought | Reality |
|---|---|
| "Skip the test just this once" | That is the exception path: ask, don't rationalize. |
| "Tests pass, next task" | Passing what? Fresh run, read output, count failures — or the claim is unsupported. |
| "I'll fix that unrelated bug too" | Out of scope; note it in the ledger and leave it. |
| "The task says implement X, no test mentioned" | The task block always names tests; if genuinely absent, write the test from the scenario and record a Ruling. |
| "I remember where I was" | Read the ledger. Memory does not survive compaction. |
