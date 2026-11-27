---
name: devsop-design
description: Converts plan artifacts (stories, NFRs, scenarios) into architecture impact analysis, interface changes, displayable UI prototypes, and an ordered task list with frontend-first sequencing. Use after devsop-plan, before devsop-code.
---

# devsop-design

Take the plan's stories and scenarios and produce: the architecture impact analysis, the exact interface changes, displayable UI prototypes (when the plan touches an interface), and a task list an implementer can execute without re-deriving decisions. Frontend tasks come first in the list so downstream work can start against settled interfaces.

Core discipline: a task is the smallest unit with its own test cycle; every step lets the implementer write exactly one reasonable thing.

## Input

Read `docs/plans/<plan-dir>/plan.md` (or the path from the `devsop-plan` handoff). If it does not exist, run the `devsop-plan` stage first or gather the equivalent with the user; never invent stories.

## Step 1: Recon the architecture

Map the change onto the current system before writing anything:

1. Identify every component the stories touch: services, modules, data stores, frontends, external integrations. Trace actual call paths in code — do not decide impact from file names alone.
2. For each touched component, classify impact: **none / read-only / modified / new**. Record evidence (file paths, call sites, schema files) for each classification.
3. Cross-check the plan's NFR section against the current system: performance headroom, security posture, migrations, compatibility with existing callers.

## Step 2: Define interface changes

For every interface that changes — API endpoints, function signatures, events, database schema, protobuf/GraphQL contracts, CLI flags, UI routes:

- **Before / after**: current shape (with file and line references) and the new shape.
- **Contract**: exact signature, types, error cases, status codes. Translate each scenario's business-observable `Then` into the technical contract — status codes, field names, error shapes are decided here, not in the plan. Never invent values the plan does not imply.
- **Compatibility**: who consumes this interface today, and what breaks or needs migration. If a change is breaking, the task list must include the migration or versioning step.
- Do not change interfaces the plan does not require, even if it would be convenient.

Record the full contracts in `tasks.md` under a `## Interface contracts` section — it is the single technical source `devsop-code` asserts against.

## Step 3: Prototype UI changes

When the plan includes interface-facing stories, produce displayable prototypes in `docs/plans/<plan-dir>/prototype/` — static HTML that opens directly in a browser, no build step. Work in two levels:

1. **Low-fidelity wireframe first** — layout and flow only (boxes, labels, navigation states). Show it to the user and confirm the structure before styling.
2. **High-fidelity on confirmation** — styled pages. For a 0→1 project, apply the platform, style direction, and reference material recorded in `plan.md`. For a 1→n project, extract the existing style from the repo's frontend (its CSS, component library, design tokens) and reuse it; highlight what changed against the current pages.

Change points come from the plan's UI ground and scenarios — each UI scenario maps to a page or component state the prototype must show. Keep prototypes disposable: they are communication artifacts, not production code; `devsop-code` implements for real.

## Step 4: Build the task list

Write `docs/plans/<plan-dir>/tasks.md`:

**Header:** Goal (one sentence from the plan), affected architecture components, interface-change summary, spec links (`plan.md`). Follow the header with a `## Interface contracts` section carrying the full Step 2 contracts, then the task blocks.

**Ordering rule:** frontend tasks precede backend tasks when the plan involves both a frontend and an API/UI contract. Reasons to note explicitly: frontend can start against the agreed contract while backend implements it, and mock/stub needs become explicit early. Exceptions (e.g., backend migration must exist before any UI consumes it) are stated as such, not silently reordered.

**Task structure:**

````markdown
### Task N: [Component]

**Story/NFR:** [story or NFR IDs this task implements]
**Files:**
- Create: `exact/path`
- Modify: `exact/path:line-range`
**Interface:** consumes [exact names from earlier tasks] / produces [exact signatures later tasks rely on]
**Prototype:** [UI tasks only — `prototype/<page>.html` as the visual reference; do not copy its code]
**Tests:** which scenario IDs (S1.1, …) prove this task; new tests to write, with the exact technical assertion values from the `## Interface contracts` section
**Steps:**
1. [One action with a checkable result — write failing test / implement X / run Y / wire Z]
2. [Verification step: command + expected output]
````

A task carries: exact files, exact names/signatures, which scenarios prove it, and one-action steps. Lines that decide nothing ("handle edge cases", "add appropriate validation") are gaps — split or specify them.

## Self-review

Before handoff, check against the plan with fresh eyes:

1. **Coverage:** every story, NFR, and scenario maps to at least one task and one test. List gaps and fix them.
2. **Type consistency:** names/signatures used in later tasks match what earlier tasks define.
3. **Ordering:** frontend-first rule applied; dependencies stated where order is forced.
4. **Proportion:** the task list decides things; it does not transcribe code. Test steps carry names and assertions, not test bodies; code steps carry signatures, not implementations.

## Handoff

Report the artifact paths (`tasks.md`, `prototype/` when produced), task count, and the interface-change summary. Confirm with the user, then invoke `devsop-code` to implement task by task. Escalate back to `devsop-plan` if recon reveals the stories cannot be built as written.

## Red flags

| Thought | Reality |
|---|---|
| "I'll refactor this module while I'm at it" | Out of scope. The plan defines the change; unrelated refactoring needs its own request. |
| "Impact analysis from names is close enough" | Trace the call path. Wrong impact assessment produces wrong task order. |
| "The implementer will figure out the signature" | They cannot know what you decided. Exact signatures go in the Interface block. |
| "I'll skip the wireframe and style directly" | Structure mistakes are cheap in a wireframe and expensive after styling. Confirm layout first. |
| "Frontend ordering doesn't matter here" | It is a stated rule of this stage; follow it or state why an exception applies. |
