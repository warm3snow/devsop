---
name: devsop-design
description: Converts plan artifacts (user stories, acceptance criteria) into architecture impact analysis, interface changes, and an ordered task list with frontend-first sequencing. Use after devsop-plan, before devsop-code.
---

# devsop-design

Take the plan's stories and acceptance criteria and produce three things: the architecture impact analysis, the exact interface changes, and a task list an implementer can execute without re-deriving decisions. Frontend tasks come first in the list so downstream work can start against settled interfaces.

Core discipline: a task is the smallest unit with its own test cycle; every step lets the implementer write exactly one reasonable thing.

## Input

Read `docs/plans/<plan-dir>/user-stories.md` and `test-cases.md` (or the paths from the `devsop-plan` handoff). If they do not exist, run the `devsop-plan` stage first or gather the equivalent with the user; never invent stories.

## Step 1: Recon the architecture

Map the change onto the current system before writing anything:

1. Identify every component the stories touch: services, modules, data stores, frontends, external integrations. Trace actual call paths in code — do not decide impact from file names alone.
2. For each touched component, classify impact: **none / read-only / modified / new**. Record evidence (file paths, call sites, schema files) for each classification.
3. List non-functional concerns the plan implies: performance, security, migrations, compatibility with existing callers.

## Step 2: Define interface changes

For every interface that changes — API endpoints, function signatures, events, database schema, protobuf/GraphQL contracts, CLI flags, UI routes:

- **Before / after**: current shape (with file and line references) and the new shape.
- **Contract**: exact signature, types, error cases, status codes. Copy exact values from the plan's acceptance criteria; never invent them.
- **Compatibility**: who consumes this interface today, and what breaks or needs migration. If a change is breaking, the task list must include the migration or versioning step.
- Do not change interfaces the plan does not require, even if it would be convenient.

## Step 3: Build the task list

Write `docs/plans/<plan-dir>/tasks.md`:

**Header:** Goal (one sentence from the plan), affected architecture components, interface-change summary, spec links (story/test-case files).

**Ordering rule:** frontend tasks precede backend tasks when the plan involves both a frontend and an API/UI contract. Reasons to note explicitly: frontend can start against the agreed contract while backend implements it, and mock/stub needs become explicit early. Exceptions (e.g., backend migration must exist before any UI consumes it) are stated as such, not silently reordered.

**Task structure:**

````markdown
### Task N: [Component]

**Story:** [story IDs this task implements]
**Files:**
- Create: `exact/path`
- Modify: `exact/path:line-range`
**Interface:** consumes [exact names from earlier tasks] / produces [exact signatures later tasks rely on]
**Tests:** which test-case IDs prove this task; new tests to write, with the exact assertion values from `test-cases.md`
**Steps:**
1. [One action with a checkable result — write failing test / implement X / run Y / wire Z]
2. [Verification step: command + expected output]
````

A task carries: exact files, exact names/signatures, which tests prove it, and one-action steps. Lines that decide nothing ("handle edge cases", "add appropriate validation") are gaps — split or specify them.

## Self-review

Before handoff, check against the plan with fresh eyes:

1. **Coverage:** every story and acceptance criterion maps to at least one task and one test. List gaps and fix them.
2. **Type consistency:** names/signatures used in later tasks match what earlier tasks define.
3. **Ordering:** frontend-first rule applied; dependencies stated where order is forced.
4. **Proportion:** the task list decides things; it does not transcribe code. Test steps carry names and assertions, not test bodies; code steps carry signatures, not implementations.

## Handoff

Report the artifact paths, task count, and the interface-change summary. Confirm with the user, then invoke `devsop-code` to implement task by task. Escalate back to `devsop-plan` if recon reveals the stories cannot be built as written.

## Red flags

| Thought | Reality |
|---|---|
| "I'll refactor this module while I'm at it" | Out of scope. The plan defines the change; unrelated refactoring needs its own request. |
| "Impact analysis from names is close enough" | Trace the call path. Wrong impact assessment produces wrong task order. |
| "The implementer will figure out the signature" | They cannot know what you decided. Exact signatures go in the Interface block. |
| "Frontend ordering doesn't matter here" | It is a stated rule of this stage; follow it or state why an exception applies. |
