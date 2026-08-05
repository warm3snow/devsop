# 09. Commit

> **Purpose**: Commit the code + push to remote + create an MR.
> **Prerequisites** (see the team TAPD SKILL.md / team environment management Skill / `SKILL.md` red line 4): ① AI has proactively asked about TAPD ② the environment dedicated to this task has been released ③ the TAPD status has been advanced to "Developing" (when part of the team flow).
> **No metadata that git / TAPD systems can query is recorded throughout** — commit ID / push time / MR link / amend count / CR status can all be queried in GitLab / `git log` / the TAPD system; this file does **not** repeat them.
> **3 phases across the whole flow**: Phase 0 front-end wrap-up (0.0-0.2) → Phase 1 prepare commit content (§1 steps 1-2, after which **boundary point A** locks in) → Phase 2 execute commit + push to trigger CR (§1 steps 3-5, only once) → Phase 3 optional amend (§1 step 6, only changes code, repeatable until the MR merges, **boundary point B** final lock).

---

## 0. Prerequisites

### 0.0 When entering commit, you MUST first ask about TAPD (AI must execute)

> **When entering this stage, the AI must proactively ask the user whether there is a TAPD requirement ticket** — do not just look at the Meta field and assume yes / no. **If not, guide the user to create one** (not just "ask once" and jump to the next step).

Ask script (**default recommended path A**):
> "Does this task already have a TAPD requirement ticket?
> 1. **Yes** → please provide the TAPD ticket number (or take it directly if the `00-overview.md` Meta `Issue / TAPD` field is already filled)
> 2. **No** → it is recommended to create one:
>    - **Path A (recommended)**: authorize me to create it with the team TAPD skill — fill in the **detailed** solution design from `02-plan.md` (not the summary) + the self-test reports from `04-ut.md` / `06-it.md` (full test results), and advance the status to **Developing** (solution reviewed → scheduled → developing; mandatory before commit); **CR is automatically triggered by the MR submission after push**, not completed at creation time
>    - **Path B**: you create it on the TAPD side yourself; I will provide a detailed field template + status-advancement steps
>    - **Path C** (**must record the reason in the key decision log**): non-team project / TAPD not needed this time"

| Situation | Jump To |
|------|------|
| User has a TAPD ticket number (path 1) | "0.2 TAPD Status Advancement" |
| User chooses path A | AI calls the team TAPD Skill `stories_create`, filling in the **detailed** solution design (full text of `02-plan.md §1 + §4 + §5`) + self-test reports (`04-ut.md` §1-§3 + full `06-it.md` results) → advance to **Developing** (first 3 steps: solution being designed → solution reviewed → scheduled → developing) → backfill Meta after creation → jump to "0.2 TAPD Status Advancement" (the last 4 steps: developing→CR→QA handoff/pending release are triggered automatically by push + subsequent flow, **not** completed at creation time) |
| User chooses path B | AI outputs the **detailed** field template + status-advancement steps to the user; after the user creates and advances, provide the ID → jump to "0.2 TAPD Status Advancement" |
| User chooses path C | Record the reason in the `00-overview.md` key decision log → **skip the entire "0.2 TAPD Status Advancement" section**, go to §1 execution order |
| User says "handle it later" | **Pause commit**, prompt the user to finish it first, then come back |

> ❌ **Forbidden**: skipping the ask and going straight to the Meta field; or after asking, not guiding creation and silently passing as "no ID provided".

| # | Action | Entry | Result Recording |
|---|------|------|---------|
| 1 | **Ask about TAPD** | AI asks proactively | See the "0.0" section outcome (4 situations) |
| 2 | Release the environment dedicated to this task | Team environment management Skill | Fill in the "0.1 Environment Release" table below |
| 3 | Advance TAPD status to "Developing" | Team TAPD Skill | Fill in the first 3 rows of the "0.2 TAPD Status Advancement" table below (the remaining 4 steps are automatically / manually advanced by the system after push) |

### 0.1 Environment Release

| Item | Value |
|----|----|
| Environment name / ID |  |
| Release command | `<Environment management CLI> release -e <env>` |
| Release time | YYYY-MM-DD HH:MM:SS |
| Result | ⬜ Success / ❌ Failure (original text + whether the user agreed to commit with the issue) / N/A (no environment created) + reason |

### 0.2 TAPD Status Advancement (must advance to "Developing" before commit; CR is auto-triggered by the MR after push; confirm it has reached CR before task wrap-up)

> **This section covers all 7 statuses of the full TAPD chain** (including branches). **The first 3 steps must be advanced before commit** — write into this table + required fields (**detailed** solution design / detailed self-test report, not just the summary). **The last 4 steps** are triggered by push + subsequent flow — **not written into this table** (this file is frozen after `git add`), **the TAPD system is the only source**; before task wrap-up, query the real status with the team TAPD Skill and confirm it has reached **CR** (not "pending release" — "pending release" is a downstream status after CR passes, triggered by the test flow, outside this task's DEVSOP scope).

| Step | Start Status | Target Status | Trigger | Result | Time |
|------|---------|---------|------|------|------|
| 1 | Solution being designed | Solution reviewed | Auto at creation | ⬜ Success / ❌ Failure |  |
| 2 | Solution reviewed | Scheduled | Manual | ⬜ Success / ❌ Failure |  |
| 3 | Scheduled | Developing | Planned start ≤ today auto / manual | ⬜ Success / ❌ Failure |  |
| 4 | Developing | CR | Auto after MR submission | — Queryable in system — |  |
| 5a | CR | QA handoff | CR passed + self-test only = No | — Queryable in system — |  |
| 5b | CR | Pending release | CR passed + **self-test only = Yes** (skip QA handoff) | — Queryable in system — |  |
| 6 | QA handoff | Pending release | Testing completed + gray release verification | — Queryable in system — |  |

> Only when **all of the first 3 rows** are `⬜ Success` may you proceed to §1 "1. Execution Order" step 1; any `❌ Failure` → fix the field and retry.
> **The last 4 rows** (including branch 5b) are advanced automatically / manually by the TAPD system during commit + push + subsequent flow, and are **not** written back to this table — this file is frozen after `git add` in §1 step 3 (boundary point A). **Before task wrap-up**, query the real status with the team TAPD Skill and confirm it has reached **CR** (developing → CR is auto-triggered by the MR after push; "QA handoff / pending release" after CR are triggered by the test flow, outside this task's DEVSOP scope).
> For the complete check fields (including the "detailed solution design" / "self-test report" field mapping), see the team TAPD SKILL.md.

---

## 1. Execution Order

> **Two boundary points (iron rules)**:
> - **Boundary point A — content lock**: after both steps 1+2 (write commit message + update `00-overview.md`) are **done**, it is **forbidden** to change `00-overview.md` and `09-commit.md` again — the commit content is final.
> - **Boundary point B — MR lock**: after the MR merges (or the user explicitly declares task wrap-up), **no more changes are allowed**.
> - **The only exception**: between boundary points A and B, if "code fixes" are needed (step 6), use amend — **only change the code itself**, **do not** change `00-overview.md` / `09-commit.md` / any plans deliverables; amend can repeat, **there is always only one commit**.

| # | Action | Result |
|---|------|------|
| 1 | Write commit message | Lands in the "2. Actual Commit This Time" section |
| 2 | **Update `00-overview.md`** | Time-tracking row 09 **end time** (= the moment "all prep is written") + duration; append to key decision log `Commit: <subject>` + `TAPD: <ID> @ Developing` (the real status before commit, **do not** pre-fill CR — CR is auto-triggered by the MR after push, **not** backfilled later) + key change points; Meta status ✅; check off Progress 09 (**do not** write the commit ID) — completing steps 1+2 = **boundary point A** |
| 3 | One-time `git add` | Code + `plans/<task>/*.md` (including the just-updated 00-overview.md and 09-commit.md) + `.harness/docs/**` increments (**forbidden** to add only code) |
| 4 | `git commit` (**first time only**) | Use the message from the "2. Actual Commit This Time" section |
| 5 | `git push` + create MR | After pushing to remote and creating the MR, the **TAPD system automatically** does "Developing → CR"; if CI passes and no fixes are needed, proceed to **boundary point B** |
| 6 | **(Optional, repeatable) code fixes** | CI failure / review comments / follow-up fixes: change code → amend (§2) → force-push; **only change code, do not touch md files**; repeatable until the MR merges |

> One MR one commit (any fix goes through step 6 amend, **forbidden** to add a second commit); after amend, push with `--force-with-lease` (**forbidden** bare `--force`). See `SKILL.md` red line 4.

---

## 2. Amend Process (step 6 = code fix, repeatable)

> **Amend only changes the code itself** — `00-overview.md` / `09-commit.md` / any plans deliverables are **frozen to the end** and are not rewritten via amend. git / TAPD systems are already the only source for this information (MR link / commit hash / CR status can all be queried in GitLab / `git log` / the TAPD system).

```bash
git add -A                              # add only the changed code
git commit --amend --no-edit           # reuse the original commit message
git push --force-with-lease            # ✅ must use; forbidden bare --force
```

> **Repeatable** — as long as boundary point B (MR merged) has not been reached, every fix goes through the same amend process, **no limit on count**, but **there is always only one commit**, and **only code changes, no md changes**.
> **Immediately after the MR merges (or the user explicitly declares task wrap-up), enter "boundary point B — MR lock"** — no more amending; any further changes require a new task / new MR.

---

## 3. Actual Commit This Time (must fill in before commit)

```
<type>(<scope>): <subject>

<body>

--<kind>=<id>      # default --story=<id>; for bug fixes change to --bug=<id>
```

> ✅ Finalizing this section triggers **boundary point A** — **forbidden** to touch this section again (including via amend).

---

## Completion Criteria

> **This checklist only contains items checkable "before boundary point A"** — this file is committed together with `00-overview.md` via `git add` in §1 step 3; **this file is frozen once add happens**. Actions after boundary point A (add / commit / push / amend / CI / merge) are **not checked off in this file** — report them verbally to the user during execution; query GitLab / `git log` / the TAPD system when needed.

- [ ] "0.0 Ask about TAPD" completed: user gave an ID / AI created it on behalf / user created it manually / skipped (one of 4)
- [ ] "0.1 Environment Release" table filled in (success / failure original text / skip reason)
- [ ] "0.2 TAPD Status Advancement" all 3 rows `⬜ Success` (advanced to "Developing"); or non-team / skipped, with the reason recorded in the key decision log
- [ ] "3. Actual Commit This Time" commit message finalized
- [ ] **`00-overview.md` fully updated** (**boundary point A** triggered — row 09 end time + duration + key decision log commit info; **no** commit ID; Meta ✅; Progress 09 checked)

> **After boundary point A** (execution actions, not written back to this file, verbally confirmed with the user): one-time `git add` → `git commit` (first, only once) → `git push` to create the MR (**TAPD system automatically** "Developing → CR") → (repeatable) CI failure / review comments → change code → amend + force-push (**only change code, do not touch md**) → MR merges → query the TAPD real status before task wrap-up to confirm CR → trigger **boundary point B**, report to the user.
