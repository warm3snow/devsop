# [YYYY-MM-DD] <Task Title>

<!--
═══════════════════════════════════════════════════════════════════════════
⚠️ TEMPLATE ONLY — When AI copies this _template/ to plans/<task>/, it MUST be simplified
═══════════════════════════════════════════════════════════════════════════
This file contains two HTML comment blocks (Progress rules / time-tracking rules, ~30 lines),
both of which are **SOP rules**, shared across tasks and do not change with the task. When copying, it is **forbidden** to carry them over as-is.

**Copy SOP (AI must execute)**:
  1. After `cp -r .harness/plans/_template .harness/plans/YYYY-MM-DD_<title>`
  2. Open the new `plans/<task>/00-overview.md`
  3. Find all comment blocks marked by `<!-- TEMPLATE-ONLY-DO-NOT-COPY: -->`
  4. Delete each block entirely (including the marker line), and replace it with the single-line pointer below (replace N times if it appears N times):

     <!-- For this file's structure / field definitions / Progress / time-tracking SOP rules,
          see .harness/plans/_template/00-overview.md; this task file is simplified and does not repeat them.
          Rule changes only modify _template/; this task file is refreshed later by init_harness.sh
          and does not affect old tasks. -->

  5. The header "⚠️ TEMPLATE ONLY" block is **also deleted entirely** (exists only in _template/)

**Why simplify**:
  - Task-file noise: ~30 lines of rules are repeated in every task; 10 tasks = 10 copies
  - Version drift: only _template/ is synced via init_harness.sh when rules change; old task copies are not synced
  - Single source of truth: SOP rules are maintained only in _template/; AI only looks at _template/ when checking rules
═══════════════════════════════════════════════════════════════════════════
-->

> **This file is the single source of truth for this task**: task meta-information, progress, current step, and key decisions all live here.
> When resuming a session, first read this file to locate the current step, then load the corresponding stage file as needed.
>
> ⚠️ This project does **not** maintain a global `.harness/plan.md` — to view across tasks, list the `.harness/plans/` directory.
> ⚠️ The `Branch` field in Meta is the only basis for locating a task when resuming context; it **must** exactly match the output of `git branch --show-current`.

---

## Meta

| Item | Value |
|----|----|
| Branch | `feature/xxx` |
| Issue / TAPD | `--story=xxx` / `#123` |
| Summary | One-sentence description |
| Status | 🟡 Pending / 🔵 In progress / ✅ Done / ❌ Cancelled |
| Created | YYYY-MM-DD |
| Owner |  |
| Due date | YYYY-MM-DD |
| Development mode | Independent development / Collaborative development (design.md-driven) |
| Test environment | (For collaborative development, fill in the environment name specified in design.md) |
| Estimated code change lines | (Fill in at Plan stage; excludes tests / docs) |
| Small-requirement mode | ⬜ No / ✅ Yes (check when `estimated code change lines ≤ 10`) |

---

## Progress

<!-- TEMPLATE-ONLY-DO-NOT-COPY: ↓↓↓ Progress rules, delete this whole block and replace with the single-line pointer when copying to a task file ↓↓↓ -->
<!--
Progress update rules (AI must read):
1. When a step is completed, **replace in place** `- [ ] N. <step>` with `- [x] N. <step> (<result summary>)`
2. Do not insert new lines or duplicate numbering; each number 01-09 has exactly one line
3. Result summary examples: `(15/15 passed)`, `(coverage 92%)`, `(deployed to dev-env)`
4. Also update the "Current Step" section below
5. ⚠️ Checking off 09. Commit and changing the Meta「Status」to ✅ **must** be done **before** the git commit;
   after the git commit it is **forbidden** to modify this file again — if code fixes are needed, use `git commit --amend` (**only change code, do not touch md**),
   no md meta-information additions are allowed (one MR one commit iron rule, **strictly forbidden** to add a second commit)
-->
<!-- TEMPLATE-ONLY-DO-NOT-COPY: ↑↑↑ -->

- [ ] 01. Clarify    → [01-clarify.md](./01-clarify.md)
- [ ] 02. Plan       → [02-plan.md](./02-plan.md)
- [ ] 03. Implement  → [03-implement.md](./03-implement.md)
- [ ] 04. UT         → [04-ut.md](./04-ut.md)
- [ ] 05. Deploy     → [05-deploy.md](./05-deploy.md)
- [ ] 06. IT         → [06-it.md](./06-it.md)
- [ ] 07. Docs       → [07-docs.md](./07-docs.md)
- [ ] 08. Review     → [08-review.md](./08-review.md)
- [ ] 09. Commit     → [09-commit.md](./09-commit.md)

---

## Current Step

> When resuming a session, read the stage file pointed to here first.

- **Step**: ⏳ 01. Clarify
- **File**: [01-clarify.md](./01-clarify.md)
- **Last updated**: YYYY-MM-DD HH:MM:SS

---

## Time Tracking

<!-- TEMPLATE-ONLY-DO-NOT-COPY: ↓↓↓ Time-tracking rules, delete this whole block and replace with the single-line pointer when copying to a task file ↓↓↓ -->
<!--
Time-tracking update rules (AI must read, equally mandatory as Progress):
1. **Start time**: immediately after the user agrees in the "start confirmation" step and **before** the AI starts executing that step, write the current local time into the "start time" cell of the corresponding step (format: `YYYY-MM-DD HH:MM:SS`, **accurate to the second**).
2. **End time**: immediately after the step's deliverable is in place and **before** sending the "end confirmation" to the user, write the current local time into the "end time" cell of the corresponding step (same format, accurate to the second).
3. **Duration**: fill in a human-readable duration at completion (e.g. `45s`, `2m30s`, `35m12s`, `1h20m08s`, `2d3h`); durations under 1 minute must keep seconds, over 1 hour may omit seconds.
4. **Timezone and capture command**: use the local timezone, unified format `YYYY-MM-DD HH:MM:SS`, **forbidden** to omit seconds or omit the date. Recommended capture command:
   - macOS / Linux: `date "+%Y-%m-%d %H:%M:%S"`
5. **Skipped steps** (only the following two scenarios; ordinary steps are never allowed to be skipped):
   - Clarify pre-provided by user: fill the start / end time with the same timestamp, and write "Skipped: user-provided" in the remarks column
   - Collaborative development (design.md-driven) skipping Clarify / Plan: fill the start / end time with the same timestamp, and write "Skipped: design.md-driven" in the remarks column
   - The duration of skipped steps is always `0s`
6. **Redo / rollback**: if a step is sent back for rework, **do not clear** the existing time; instead append `Redone N times (latest YYYY-MM-DD HH:MM:SS)` in the remarks column; the end time is based on the most recent completion.
7. ⚠️ **Strictly forbidden to backfill fabricated times**: all times must be read with the `date` command at the moment the event occurs and then written; for steps whose recording was missed, write "Missed" in the remarks column and keep it blank, do not guess timestamps afterwards (even if only a few minutes off).
8. This table, consistent with Progress, is the only source for task-level time auditing; when doing cross-task statistics, directly aggregate each task's table.
9. **Small-requirement mode batches** (when Meta `Small-requirement mode` = ✅): 03-04 run combined / 07-09 run combined; fill the start/end time of the corresponding rows per batch — each row in the batch writes the **same** start time (the moment the batch starts) and the **same** end time (the moment the batch ends), and the duration is also the same value (the actual duration of the whole batch); write "Small-requirement mode batch: 03-04" or "Small-requirement mode batch: 07-09" in the remarks column for later aggregation to identify batches.
   - Example: row 03's start/end = `10:00:00` / `10:08:30`, remark `Small-requirement mode batch: 03-04`; row 04's start/end = `10:00:00` / `10:08:30`, remark `Small-requirement mode batch: 03-04`; 07/08/09 likewise (using the second batch's start/end times)
   - 05 Deploy and 06 IT are still recorded in standard mode and are **not** included in batches
   - Misestimate (actual changes > 10 lines) → AI changes the Meta `Small-requirement mode` back to ⬜ when reporting the 03-04 results, **time records do not need to be backfilled** — times recorded per batch already reflect the real work window; the cross-task statistics aggregation algorithm only needs to recognize the "Small-requirement mode batch" prefix in the remarks to correctly merge.
-->
<!-- TEMPLATE-ONLY-DO-NOT-COPY: ↑↑↑ -->

| # | Step | Start Time | End Time | Duration | Remarks |
|---|------|---------|---------|------|------|
| 01 | Clarify    |  |  |  |  |
| 02 | Plan       |  |  |  |  |
| 03 | Implement  |  |  |  |  |
| 04 | UT         |  |  |  |  |
| 05 | Deploy     |  |  |  |  |
| 06 | IT         |  |  |  |  |
| 07 | Docs       |  |  |  |  |
| 08 | Review     |  |  |  |  |
| 09 | Commit     |  |  |  |  |

---

## Key Decision Log

> **Key context shared across stages**. Only record decisions that affect later steps, to avoid having to page through historical stage files when resuming.
> Filling suggestions: final choice of interface naming, DataType field design, compatibility constraints, conventions with other modules, skipped steps and reasons, etc.

-

---

## Risk Overview

> Task-level risk register. High-severity risks can be archived separately under `.harness/docs/` as needed, to avoid merge conflicts caused by sharing files across tasks.

| # | Risk | Severity | Mitigation |
|---|------|-------|------|
|  |  |  |  |

---

## File Index

| File | Deliverable |
|------|------|
| [00-overview.md](./00-overview.md) | Task overview (this file) |
| [01-clarify.md](./01-clarify.md) | Requirements clarification: background, goals, scope, open questions |
| [02-plan.md](./02-plan.md) | Solution design: changed files, call chain, data model, IT cases |
| [03-implement.md](./03-implement.md) | Implementation: key details, deviations from Plan, check results |
| [04-ut.md](./04-ut.md) | Unit tests: cases, coverage, uncovered lines |
| [05-deploy.md](./05-deploy.md) | Deployment: environment, results, rollback plan |
| [06-it.md](./06-it.md) | Integration tests: req_id, results, failure analysis |
| [07-docs.md](./07-docs.md) | Documentation update checklist |
| [08-review.md](./08-review.md) | Code Review: issues and fixes |
| [09-commit.md](./09-commit.md) | Commit message and amend process |
