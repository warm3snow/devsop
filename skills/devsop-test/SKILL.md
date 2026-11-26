---
name: devsop-test
description: Executes the plan's test cases (from devsop-plan's test-cases.md) against the implemented code and reports a pass/fail matrix per acceptance criterion. Use after devsop-code or whenever verification against acceptance criteria is needed.
---

# devsop-test

Run the plan's test cases against the implemented code and report evidence: which acceptance criteria are proven, which failed, and what was not tested.

Core discipline: evidence before claims, always. A test case counts as passed only when its expected result was observed in this session's output.

## The Iron Law

```
NO PASS CLAIMS WITHOUT FRESH OBSERVED OUTPUT
```

"Should pass", "the suite is green", "the dev said it works" — none of these are evidence. Run the case, read the output, compare against the expected result.

## Input

`docs/plans/<plan-dir>/test-cases.md` and `user-stories.md` from the `devsop-plan` handoff (paths may come from `devsop-code`'s completion report). If they do not exist, ask the user for the criteria to verify; never grade against invented criteria.

## Scope

Default scope: the test cases tagged for this stage — **integration** and **manual** cases, plus re-running **unit** cases if `devsop-code` did not report them green in its completion gate. The user can narrow ("only story US-3") or widen ("everything including regression") the scope; a narrowing is recorded in the report.

## Execution

For each test case, in dependency order:

1. **Automated cases (unit / integration):** run the exact command with the case's preconditions set up. Redirect long output to a file and read the tail; read every result. Compare the observed output against the case's expected result — exact values, not vibes.
2. **Manual cases:** do not fake them. For each, either (a) drive the interface yourself if the environment allows (browser tools, HTTP requests against a local instance), or (b) produce a step-by-step checklist with exact expected results and mark it `NEEDS-HUMAN`. A manual case left unexecuted is reported as not tested, never as passed.
3. **Environment missing?** (no local DB, no dev instance, external service unreachable) Mark affected cases `BLOCKED` with the reason. Blocked is not failed and not passed.

When a case fails, capture: the command, the observed output, the expected output, and the first suspicious change. A failure caused by a bug goes back to `devsop-code` for a fix; a failure caused by a wrong test case (spec bug) goes back to `devsop-plan`. Do not "fix" a failing case by weakening its assertion.

## Report

Append to `docs/plans/<plan-dir>/test-report.md` (create if absent), one row per criterion:

```markdown
# Test Report — <plan dir> — <date>
| Story | Criterion | Case | Result | Evidence |
|---|---|---|---|---|
| US-1 | Returns 204 on delete | TC-1.2 | PASS | cmd output: 204, log line ... |
| US-2 | Rejects empty body with 400 | TC-2.1 | FAIL | got 500; observed: <snippet> |
| US-3 | Approval email received | TC-3.1 | NEEDS-HUMAN | checklist in report |
```

Then a summary: counts (pass / fail / blocked / needs-human), failure root causes (code bug vs spec bug vs environment), and the recommended next action per failure. In chat, report the matrix and the top failures — do not paste full logs.

## Gate

- All automated cases pass and no criterion is unproven → the plan is verified; suggest `devsop-ship` if the user wants to deploy.
- Any FAIL → return to `devsop-code` (bug) or `devsop-plan` (spec bug) with the evidence attached.
- NEEDS-HUMAN cases remain → hand the checklist to the user and state that the plan is not fully verified until they confirm.

## Red flags

| Thought | Reality |
|---|---|
| "Unit suite passed, so criteria are met" | Unit green proves cases ran, not criteria. Check case by case. |
| "That manual case is obvious, mark it pass" | Obvious is a claim, not evidence. Execute it or mark NEEDS-HUMAN. |
| "The failure is flaky, rerun until green" | Flaky is a finding. Report it with both outputs. |
| "Environment is down, assume it would pass" | BLOCKED, with the reason. Assumption is not evidence. |
