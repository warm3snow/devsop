---
name: devsop-flow
description: Orchestrates the full devsop pipeline — plan, design, code, test, ship (with optional init) — as one flow, or picks the right single stage for the request. Use when the user asks to run a feature through the whole devsop workflow or is unsure which stage to start.
---

# devsop-flow

Route a request through the devsop stages, or run them end to end. Each stage is a standalone skill; this skill decides where to start and hands off between stages, keeping the artifacts as the contract.

## Stage map

| Stage | Skill | Consumes | Produces | Optional |
|---|---|---|---|---|
| init | `devsop-init` | repo (with or without code) | AGENTS.md + project docs | yes |
| plan | `devsop-plan` | user request | plan.md: stories (FR), NFRs, scenarios | no |
| design | `devsop-design` | plan.md | impact analysis, interface changes, UI prototypes, task list | no |
| code | `devsop-code` | task list | implemented code + green unit tests | no |
| test | `devsop-test` | plan.md scenarios | pass/fail matrix per scenario (report on demand) | no |
| ship | `devsop-ship` | test report | deployment to dev env (human-confirmed) | yes |

## Choosing the entry stage

- **No code yet (greenfield):** invoke `devsop-init` in interactive mode first — its "Greenfield repositories (no code yet)" section is the authority for the question flow and scaffolding. Then start at plan.
- **Existing repo, not AI-friendly yet:** offer `devsop-init` (it is a separate, independent step); start at plan regardless.
- **Request is a feature/change request:** start at plan. For a trivially clear request, the plan stage itself uses its fast path — flow does not skip it, because scenarios are what later stages verify against.
- **Request is a bug fix:** still plan (fast path), design (recon is quick), code, test. The pipeline is the same; artifact size shrinks.
- **User names a stage ("just design it", "run the tests"):** enter at that stage; check its input artifacts exist and generate the missing prerequisites by invoking the earlier stage first if the user agrees.
- **User says "run the whole flow" / "from idea to dev env":** start at init (if applicable), then plan → design → code → test → ship, handing off between skills.

## Handoff contract

Every handoff passes artifact paths, not summaries. When invoking the next stage skill, state: the plan directory, the files produced so far, and any open rulings. Each stage skill re-reads its inputs from disk — that is what makes stages independently runnable and resumable. Canonical artifact paths: `plan.md` (plan) → `tasks.md` with its `## Interface contracts` section, plus `prototype/` for UI changes (design) → `progress.md` (code) → `test-report.md` (test; written only for evidence the suite cannot reproduce) → `ship.md` (ship, optional).

## Greenfield init

For a repository with no code, invoke `devsop-init` in interactive mode; follow `../devsop-init/SKILL.md` → "Greenfield repositories (no code yet)" for the question flow, confirmation gate, and scaffolding. This skill only routes: stop after init if the user asked only to initialize; otherwise continue to plan.

## Flow behavior

- **Announce transitions:** one line per stage boundary — "Plan complete (3 stories, 9 scenarios) → moving to design."
- **No silent scope changes:** if a stage's recon or execution invalidates an upstream artifact (design reveals a story can't be built as written), escalate to the user with the evidence instead of patching upstream silently.
- **Wireframe gate:** for UI changes, `devsop-design` pauses mid-stage for wireframe confirmation; the flow waits for the user's confirmation before continuing.
- **Ship is never automatic:** reaching the end of code/test does not deploy. `devsop-ship` has its own confirmation gate; the flow ends at the verified state unless the user says ship.
- **Interruptible:** each stage leaves artifacts on disk. A flow interrupted at any point resumes by reading the latest artifacts and continuing from the incomplete stage.
- **Artifacts scale with the change:** the minimum disk footprint is `plan.md` plus the code ledger; `tasks.md` is derived in-code on the fast path, `test-report.md` is written only for evidence the suite cannot reproduce, and `prototype/` / `ship.md` exist only when UI / deployment are in scope. Never generate artifacts for stages the change does not touch.

## Red flags

| Thought | Reality |
|---|---|
| "Small request, skip plan and code directly" | Plan's fast path exists for this — use it, don't bypass it. Scenarios drive verification. |
| "I'll keep the plan in my head between stages" | Artifacts are the contract. Head-only handoffs break resumability. |
| "Tests passed, deploying now" | Ship has its own gate. Never deploy without its explicit confirmation. |
| "The repo is empty, I'll scaffold something sensible" | Greenfield init is interactive. Ask what to build first. |
