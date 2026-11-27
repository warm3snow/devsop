---
name: devsop-test
description: Executes the verification scenarios in devsop-plan's plan.md against the implemented code and reports a pass/fail matrix per scenario. Use after devsop-code or whenever verification against the plan is needed.
---

# devsop-test

Run the plan's scenarios against the implemented code and report evidence: which scenarios are proven, which failed, and what was not tested.

Core discipline: evidence before claims, always. A scenario counts as passed only when its expected result was observed in this session's output.

## The Iron Law

```
NO PASS CLAIMS WITHOUT FRESH OBSERVED OUTPUT
```

"Should pass", "the suite is green", "the dev said it works" — none of these are evidence. Run the scenario, read the output, compare against the expected result.

## Input

`docs/plans/<plan-dir>/plan.md` from the `devsop-plan` handoff (path may come from `devsop-code`'s completion report). If it does not exist, ask the user for the scenarios to verify; never grade against invented criteria.

## Scope

Default scope: the scenarios tagged for this stage — **integration** and **manual**, plus re-running **unit** scenarios if `devsop-code` did not report them green in its completion gate. The user can narrow ("only story US-3") or widen ("everything including regression") the scope; a narrowing is recorded in the report.

## Execution

For each scenario, in dependency order:

1. **Automated scenarios (unit / integration):** run the exact command with the scenario's Given preconditions set up. Redirect long output to a file and read the tail; read every result. Compare the observed output against the scenario's Then — exact values, not vibes.
2. **Manual scenarios:** do not fake them. For each, either (a) drive the interface yourself if the environment allows (browser tools, HTTP requests against a local instance), or (b) produce a step-by-step checklist with exact expected results and mark it `NEEDS-HUMAN`. A manual scenario left unexecuted is reported as not tested, never as passed.
3. **Environment missing?** (no local DB, no dev instance, external service unreachable) Mark affected scenarios `BLOCKED` with the reason. Blocked is not failed and not passed.

When a scenario fails, capture: the command, the observed output, the expected output, and the first suspicious change. A failure caused by a bug goes back to `devsop-code` for a fix; a failure caused by a wrong scenario (spec bug) goes back to `devsop-plan`. Do not "fix" a failing scenario by weakening its assertion.

## Report

Write the report **only when it carries evidence the suite cannot reproduce**: manual or integration scenarios, NFR measurements, failures, or blocked cases. When every scenario is a green unit case already evidenced in `devsop-code`'s completion gate, skip the file and report the suite reference in chat — a report that restates a green suite is derivative.

When written, append to `docs/plans/<plan-dir>/test-report.md` (create if absent), one row per scenario:

```markdown
# Test Report — <plan dir> — <date>
| Story | Scenario | Result | Evidence |
|---|---|---|---|
| US-1 | S1.1 Item disappears after delete | PASS | cmd output: 204, list count 2 |
| US-2 | S2.1 Empty body rejected | FAIL | got 500; observed: <snippet> |
| US-3 | S3.1 Approval email received | NEEDS-HUMAN | checklist in report |
| NFR-1 | List loads under 2s | PASS | p95 1.4s over 100 runs |
```

NFR scenarios use their `NFR-<id>` in the Story column. Then a summary: counts (pass / fail / blocked / needs-human), failure root causes (code bug vs spec bug vs environment), and the recommended next action per failure. In chat, report the matrix and the top failures — do not paste full logs.

## Gate

- All automated scenarios pass and no scenario is unproven → the plan is verified; suggest `devsop-ship` if the user wants to deploy.
- Any FAIL → return to `devsop-code` (bug) or `devsop-plan` (spec bug) with the evidence attached.
- NEEDS-HUMAN scenarios remain → hand the checklist to the user and state that the plan is not fully verified until they confirm.

## Red flags

| Thought | Reality |
|---|---|
| "Unit suite passed, so the plan is met" | Unit green proves scenarios ran, not outcomes. Check scenario by scenario. |
| "That manual scenario is obvious, mark it pass" | Obvious is a claim, not evidence. Execute it or mark NEEDS-HUMAN. |
| "The failure is flaky, rerun until green" | Flaky is a finding. Report it with both outputs. |
| "Environment is down, assume it would pass" | BLOCKED, with the reason. Assumption is not evidence. |
