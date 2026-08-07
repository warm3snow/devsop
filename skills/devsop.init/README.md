# devsop.init · Usage guide

> **In one sentence**: lays down a `.docs/` DEVSOP skeleton + an `AGENTS.md` AI entry point (the single source of truth shared by all AI coding agents) for any code project in one go, turning the 9-stage process of "requirement → clarify → plan → implement → unit test → deploy → integration test → docs → review → commit" into an artifact structure that an AI Agent can continuously drive forward.

---

## 1. What problem does this skill solve

| Pain point | devsop.init's response |
|------------|---------------------|
| AI collaboration has to re-align project conventions every time; the process is unstable | Generate `AGENTS.md` at the repository root as the **single source of truth entry point** shared by all AI coding agents, with all conventions / DEVSOP / red lines written out explicitly |
| Multi-person parallel development; global task overview files conflict | **No longer generate** a global `plan.md`; each task carries its own `00-overview.md` as the single source of truth |
| Requirements get done with no docs left behind, and everything has to be re-explained next time | Each of the 9 stages has a fixed artifact file (`0N-<step>.md`); the task leaves a trail as soon as it ends |
| Unit/integration test conventions scattered everywhere | `.docs/unittest/` + `.docs/integration_test/` standard three-part format (environment / test cases / run & debug) |

---

## 2. How to trigger

Any of the following prompts will make the AI automatically invoke this skill:

- "Initialize `.docs/`"
- "Set up DEVSOP / project scaffolding"
- "bootstrap specs"
- "Lay down an AGENTS.md for the current repo"

You can also run the scripts directly by hand (see §4).

---

## 3. What you get after initialization

After running, these artifacts appear in the repo (existing files are not overwritten; `AGENTS.md` is the exception — only section two of the DEVSOP is refreshed while the other sections are preserved):

```
<repo_root>/
├── AGENTS.md                    # AI collaboration single source of truth entry (four sections: quick index / DEVSOP / development conventions / forbidden red lines)
├── CODEBUDDY.md                 # optional: symlink → AGENTS.md (only with --with-agent-links, for CodeBuddy)
├── CLAUDE.md                    # optional: symlink → AGENTS.md (only with --with-agent-links, for Claude Code)
├── .codebuddy/
│   └── skills/clarify/          # dialogue protocol skill supporting Stage 01 (auto-installed)
├── scripts/                     # copies of Git Hook scripts (pre-commit / pre-push / commit-msg)
│   ├── pre_commit_check.sh
│   ├── pre_push_check.sh
│   └── commit_msg_check.sh
└── .docs/
    ├── review.md                # AI Code Review conventions
    ├── architecture.md
    ├── relationship.md
    ├── coding-style.md
    ├── code-review.md
    ├── glossary.md
    ├── failures.md
    ├── logging.md
    ├── apis/{index.md, _template.md, api-standards.md, <module>/<Action>.md}
    ├── sqls/{README.md, database.md}
    ├── unittest/unittest.md
    ├── integration_test/integration_test.md
    ├── devops/{env.md, test-env-deploy.md, deployment.md, development.md}
    └── plans/
        └── _template/           # 10-file task template (00-overview + 01-clarify ... 09-commit)
```

**Task discovery conventions** (replacing the old global `plan.md`):

| To find out | How |
|-------------|-----|
| All tasks | `ls .docs/plans/` |
| The task corresponding to the current branch | `git branch --show-current`, then match against the `branch` field in each `00-overview.md` Meta |
| A single task's progress | Read only `.docs/plans/<task>/00-overview.md` |

---

## 4. Usage

### 4.1 Initializing a brand-new project

```bash
# Enter the repository root
cd /path/to/your/repo

# Run the script directly (or let the AI trigger it automatically)
bash /path/to/skills/devsop.init/scripts/init_docs.sh

# Optional flags: projects without APIs / DBs skip the corresponding skeleton directories (default true, backward compatible)
bash /path/to/skills/devsop.init/scripts/init_docs.sh . --has-api=false --has-db=false
```

Script key points:
- `.docs/` skeleton files are **not overwritten if they already exist** (protects user-filled content).
- `--has-api=false` / `--has-db=false` only affect gap-filling copies (skipping `.docs/apis/` / `.docs/sqls/`); they **do not delete** existing files; flag values are usually determined by the AI via detection per `references/special-agent-detect.md`.
- **All files** under `plans/_template/` follow the "overwrite directly if different" strategy, ensuring newly created tasks get the latest template structure after a skill upgrade; already-created task directories (`plans/<task>/`) are never touched.
- `AGENTS.md` already exists → **divide and conquer by section**: only force-refresh the "2. DEVSOP" section (the core DEVSOP contract), keeping "1. Quick index", "3. Development conventions", and "4. Forbidden red lines" unchanged and undeleted; update only when section two actually differs (Git-managed, no backup needed).
- `AGENTS.md` is the single generic AI entry; `CODEBUDDY.md` / `CLAUDE.md` symlinks are created only with `--with-agent-links` (existing symlinks rebuilt directly; real files deleted then rebuilt, recoverable via Git).
- `.docs/devops/test-env-deploy.md` is divided by section: the skill-managed region is force-refreshed, the `## Project-specific` section is preserved.
- Go projects (where `go.mod` exists) automatically copy `.golangci.yml` to the repo root (skipped if it already exists).
- Install Git Hooks idempotently via `setup_hooks.sh`: first copy the 3 hook scripts to the target repo's `scripts/` (skipped if they exist), then create symlinks under `.git/hooks/` pointing to `../../scripts/<script>` (pre-commit / pre-push / commit-msg).
- Also installs the `clarify` skill into `<repo>/.codebuddy/skills/clarify/`.

### 4.2 Content that must be manually filled in after initialization

In order of importance:

1. `.docs/architecture.md`, `.docs/relationship.md`
2. `.docs/apis/<module>/<Action>.md` + `apis/index.md`
3. `.docs/sqls/` (DB schema / migration)
4. **`.docs/unittest/unittest.md`** (three-part: environment / generation / run & debug)
5. **`.docs/integration_test/integration_test.md`** (three-part: environment & dependencies / test case design / run & debug)
6. `.docs/devops/env.md` + `.docs/devops/test-env-deploy.md`
7. The "3. Development conventions" and "4. Forbidden red lines" sections of `AGENTS.md`

> For projects that already have `.codebuddy/rules/<topic>_*.md` (e.g. `unittest_rule.md`), docs should be **excerpted + linked** to avoid dual tracks.

---

## 5. Overview of the 9-stage task DEVSOP

Every new requirement starts with `cp -r .docs/plans/_template .docs/plans/YYYY-MM-DD_<short-title>`, then progresses per the table below:

| # | Stage | Artifact | Key actions |
|---|-------|----------|-------------|
| 1 | Clarify | `01-clarify.md` | Invoke the `clarify` skill; the AI switches to a PM perspective and clarifies background/goals/open questions |
| 2 | Plan | `02-plan.md` | Changed files, call chain, **§6 UT test case design (TDD-first, mandatory)**, IT test case design, risk assessment |
| 3 | Implement | `03-implement.md` | Key implementation details, differences from the Plan; **follow the Plan §6 red-green loop: first write UT per §6 and watch it fail red → write the minimal implementation to turn it green → refactor while keeping UT green** |
| 4 | UT | `04-ut.md` | Test cases **aligned one-by-one with Plan §6** (including the Plan §6 numbering column), unit test commands, coverage, uncovered lines; rules per `unittest/unittest.md` |
| 5 | Deploy | `05-deploy.md` | Deployment results (collaborative mode: hot-update to the environment specified in Meta's "test environment") |
| 6 | IT | `06-it.md` | Integration test results, key req_id; **must also be executed in collaborative mode** (test cases covering this component's responsibilities; cross-component / end-to-end cases are covered separately by the upper-level orchestrator); rules per `integration_test/integration_test.md` |
| 7 | Docs | `07-docs.md` | Incrementally write back to `.docs/` |
| 8 | Review | `08-review.md` | Code Review results |
| 9 | Commit | `09-commit.md` | **Mandatory order**: ① ask about the issue/task ticket (guide creation if none) → ② release the environment (execute the environment release command via the team environment-management Skill, record the result in the "0.1 environment release" table) → ③ advance the ticket status to "in development" (for team process; **CR is triggered automatically by the MR submission after push, not completed in this step**) → ④ write all md files (including the `09-commit.md` §3 commit message) → ⑤ update `00-overview.md` (boundary point A) → ⑥ one-shot `git add` → ⑦ `git commit` (ticket-reference footer **default `--story=<id>`**, use `--bug=<id>` for bug fixes; GitHub-style `#<id>` also accepted) → ⑧ `git push` triggers the ticket status "in development → CR" → ⑨ (repeatable until the MR is merged) accumulate fixes via amend**; **one MR one commit** — any fix must go through `git commit --amend`, **adding a second commit is strictly forbidden**; after amending, push must use `git push --force-with-lease` (**bare `--force` forbidden**); **calling environment release commands directly, bypassing the team environment-management Skill, is forbidden**; **calling the issue tracker's API/MCP directly, bypassing the team issue-tracker skill, is forbidden**; **the ticket must have landed in CR before task wrap-up (for team process) is forbidden to skip**; **committing before the environment is released is forbidden** |

**Single source of truth**: after each stage completes, only two places are updated — this stage's `0N-<step>.md` + this task's `00-overview.md` (Progress checkboxes + current-stage pointer + time log). Never write cross-task shared files.

**Stage time logging**: `00-overview.md` has a built-in "time log" table recording start time / end time / duration / remark per line for the 9 stages.
- Start time: written after the user agrees in the "start confirmation" step and **before** the AI starts executing (to the second)
- End time: written after the stage artifact lands and **before** the user is prompted with the "end confirmation"
- "Skipped" is allowed only in these two scenarios: ① Clarify pre-supplied by the user; ② collaborative development (design.md-driven) skips Clarify / Plan. Start/end get the same timestamp, duration `0s`, and the remark column states the skip reason
- **Small-requirement mode batch time logging**: when Meta's `small-requirement mode` = ✅, 03-04 / 07-09 each share the same start/end/duration across the batch, with the remark column reading "small-requirement mode batch: 03-04" or "small-requirement mode batch: 07-09"; 05/06 are still logged in standard mode. No backfill is needed on underestimation — batch-recorded times already reflect the real work window, and cross-task aggregation relies on the remark prefix
- **Backfilling fabricated times afterwards is forbidden** — stages that were not logged stay blank with "missed" in the remark

**Collaborative development mode** (when the upper-level orchestrator generates `.docs/design.md`):
- Clarify & Plan are derived from design.md in one go into `01-clarify.md` / `02-plan.md`; **design.md is deleted immediately after derivation** (to avoid dual sources); the test environment name settles into the `00-overview.md` Meta as the single source of truth for subsequent stages
- Skip Step 1 / Step 2, start from Step 3 Implement
- The Deploy stage uses fast-update hot-code reload instead (uses Meta's "test environment", no new environment created)
- The IT stage runs **normally** (not skipped), covering test cases for this component's responsibilities; cross-component / end-to-end cases are covered separately by the upper-level orchestrator
- After Review completes, the upper-level orchestrator does the unified merge; no merge operations from Commit are performed in this repo

**Small-requirement mode** (02 Plan estimates `estimated code change lines ≤ 10` → set Meta's `small-requirement mode` to ✅):

| Stage | Mode | Note |
|-------|------|------|
| 01-02 Clarify / Plan | **Confirm** | Decision points, must explicitly confirm |
| 03-04 Implement / UT | **Automatic** | Start/end merged into a single prompt; artifacts + time logs not exempt |
| 05 Deploy | **Confirm** | Environment-sensitive, must explicitly confirm |
| 06 IT | **Confirm** | Real-link verification, must explicitly confirm |
| 07-09 Docs / Review / Commit | **Automatic** | Start/end merged into a single prompt; environment release still per `09-commit.md` section 0 |

> If the actual change exceeds 10 lines (underestimated), flip `small-requirement mode` back to ⬜ when reporting the 03-04 conclusion, and run in standard mode from 05 onward.

---

## 6. FAQ

**Q: I already have `AGENTS.md`; will running again lose content?**
A: No. The script divides by section — it only force-refreshes section two, "DEVSOP" (the core contract); the project-specific content you filled into sections one/three/four (quick index extra lines, development conventions, forbidden red lines) is preserved as-is. The project is Git-managed; use `git restore` if you need to recover old content; no `.bk.*` backup files are generated.

**Q: Can I generate only `.docs/` without touching `AGENTS.md`?**
A: The script is a single unit. If you only want the skeleton, manually `cp -r assets/docs-skeleton/. .docs/` + `cp -r assets/plans-template .docs/plans/_template`.

**Q: Must every task go through all 9 steps?**
A: Not mandatory. But the `00-overview.md` Progress must honestly reflect actual progress (skipped stages annotated with reasons) to enable context recovery.

**Q: Can DEVSOP be done on the `master`/`main` branch?**
A: No. `AGENTS.md` has the red line hard-coded: all DEVSOP steps must be on a `feature/<task>` branch.

**Q: Can I add `apis/` / `sqls/` / `architecture.md` at the top level of `.docs/`?**
A: No. These must go under `.docs/`. See the "red lines" section of SKILL.md.

**Q: After committing, I found a line missing in a plans artifact / need to fix a typo — what do I do?**
A: If it's a **code** problem → directly `git commit --amend` to accumulate into the original commit, then `git push --force-with-lease` (**one MR can only have one commit**). If it's **missing md content** → do NOT go back to edit the md! `00-overview.md` / `09-commit.md` are frozen after `git add` (boundary point A) — any post-commit md edit breaks the one-MR-one-commit principle; the **only exception** is that amending code changes also does not write md. The MR link / commit hash / CR status can be looked up in GitLab / `git log` / the issue-tracker system; do not duplicate them into md. See the "2. amend process" section of `09-commit.md`.

**Q: After amending, use `git push --force` or `--force-with-lease`?**
A: **Must** use `--force-with-lease` (refuses to overwrite new remote commits, safer than bare `--force`). Using bare `--force` triggers SKILL.md red line 4.

**Q: How do I choose the `kind` field in the commit message footer?**
A: **Default `--story=<id>`** — use `--story` whenever it is not a clear bug fix (`fix` type); bug fixes use `--bug=<id>`; otherwise use `task` / `test` / `other` as needed. `--kind` must be unique within one commit. The commit-msg hook enforces the footer's presence by default; a missing footer will BLOCK the commit.

**Q: Will a non-conforming commit message be blocked by the hook?**
A: Yes. `commit_msg_check.sh` enforces two rules by default: ① the subject conforms to Conventional Commits (`<type>(<scope>): <subject>`, with `type` being one of `feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|other`); ② the body contains an issue-tracker ticket reference footer `--<kind>=<id>` (GitHub-style `#<id>` also accepted; override the pattern with `TICKET_FOOTER_PATTERN`). In a transition period, you can set `DISABLE_CONV_COMMITS=1` / `DISABLE_TICKET_FOOTER=1` to skip temporarily (not recommended long-term).

**Q: What if no issue-tracker ticket is filled in at the commit stage?**
A: The AI will **proactively ask** you "do you want an issue/task ticket created based on this requirement in the team-designated tracker" (default recommendation: yes). If yes, the AI invokes the team issue-tracker skill to create it based on the `02-plan.md` solution design + the `04-ut.md` / `06-it.md` test results, and advances it to "in development" (mandatory before commit); **CR is triggered automatically by the MR submission after push** (not completed before commit). If no, record the reason in the `00-overview.md` key-decision memo and skip section 0.2. **Before task wrap-up**, confirm the whole chain has landed in CR.

**Q: Do projects outside this team also need the issue-tracker handoff?**
A: No. The team issue-tracker skill applies to this team's designated tracker (e.g. GitHub Issues). For projects outside this team, write "this task skips ticket tracking: <reason>" in the `00-overview.md` key-decision memo and skip the whole section 0.2; at commit time you can set `DISABLE_TICKET_FOOTER=1` to temporarily bypass the footer check.

---

## 7. Directory quick tour

```
skills/devsop.init/
├── SKILL.md                     # entry point for the AI to read (contains trigger words, process, red lines)
├── README.md                    # this file, a human-readable usage guide
├── scripts/
│   ├── init_docs.sh          # new project initialization / existing project upgrade (idempotent)
│   ├── setup_hooks.sh           # Git Hooks installation (idempotent, copies scripts + creates symlinks)
│   ├── pre_commit_check.sh      # pre-commit hook
│   ├── pre_push_check.sh        # pre-push hook
│   └── commit_msg_check.sh      # commit-msg hook (validates Conventional Commits + issue-tracker ticket footer)
├── references/                  # sub-agent instructions + methodology (read-only)
│   ├── docs-generation.md       # `.docs/` generation methodology (loaded when guiding post-init filling)
│   ├── merge-agent-prompt.md    # normalization merge sub-agent instructions
│   ├── library-context.md       # library project supplementary instructions
│   ├── framework-gozero.md      # go-zero framework specialization instructions
│   └── special-agent-*.md       # dedicated instructions for 13 sub-agents (A–M)
└── assets/                      # copied into the target repo for use; AI does not load into context
    ├── docs-skeleton/        # `.docs/` skeleton (review.md + 20 doc files at the top level + plans/)
    ├── plans-template/          # 10-file task template
    ├── agents.md.tmpl           # AGENTS.md template (four sections; tool-specific entry symlinks optional)
    ├── ARCHITECTURE.md.tmpl     # project architecture doc template (13 sections)
    ├── README.md.tmpl           # project README template (manually copied on demand, not auto-generated)
    ├── clarify-skill/           # clarify skill template supporting Stage 01
    └── .golangci.yml            # Go project lint config template (auto-copied to the repo root when go.mod exists)
```

---

## 8. Companion skills

| skill | Purpose |
|-------|---------|
| `clarify` (auto-installed to the target repo's `.codebuddy/skills/clarify/`) | The dialogue protocol for the Step 1 Clarify stage; the AI switches to a PM perspective for Discovery + Challenge |
| `devsop.eval` (standalone skill) | A read-only audit of the `.docs/` system — six pillars, 28 items of Eval (PASS / PARTIAL / FAIL) + anti-pattern detection, with the report written to `.docs/devsop_report.md`. `devsop.init` and `devsop.eval` are a pair: init lays the skeleton → eval runs the baseline → periodic `devsop.eval --diff-from=...` tracks improvement |

---

## 9. Red-line quick reference

1. ❌ Placing DEVSOP documents (`apis/` / `sqls/` / `unittest/` / `integration_test/` / `architecture.md` etc.) outside `.docs/` → all docs must live under `.docs/`.
2. ❌ Reintroducing a global `.docs/plan.md` → all overview capability sinks to `plans/<task>/00-overview.md`.
3. ❌ Pre-generating `README.md` / `conventions.md` / `glossary.md` / `risks.md` / `adr/` placeholders → create on demand.
4. ❌ Calling environment release commands directly, bypassing the team environment-management Skill; ❌ skipping the "0.1 environment release" section before commit (must execute the environment release command via the team environment-management Skill and fill the result into the "0.1 environment release" table); ❌ calling the issue tracker's API/MCP directly, bypassing the team issue-tracker skill; ❌ the ticket not landing in CR before task wrap-up (mandatory for team process; CR is triggered automatically by the MR submission after push, not a precondition of commit); ❌ a second commit appearing in the same MR — the one-MR-one-commit principle, any fix (including push metadata, follow-up fixes, repeatable until the MR is merged) must `git commit --amend` into the original commit; ❌ using bare `git push --force` after amending (must use `--force-with-lease`).
5. ❌ Violating the TDD red-green loop → `02-plan.md` must contain `§6 UT test case design`, Implement must write tests first per Plan §6 and watch them fail red, `04-ut.md` must be aligned one-by-one with Plan §6; "write the implementation first, then add tests" is forbidden, and UT and IT re-testing the same layer of logic is forbidden.
6. ❌ Missing / backfilled-fabricated start / end times in the `00-overview.md` "time log" table → the start time must be written the moment the user confirms starting; the end time must be written before the end confirmation is prompted; stages with missed logs keep the remark column blank and write "missed".
7. ❌ The AI proactively reading/referencing md artifacts under other `.docs/plans/<task>/` → tasks are physically isolated and are each other's independent sources of truth; they may only be read when the user **explicitly** says "reference task X", and referenced content must not be automatically written back into the current task. See "task isolation principle (mandatory)" in section 2, DEVSOP of `AGENTS.md`.

---

## 10. Feedback and extension

- Template needs project-specific customization: directly modify `assets/agents.md.tmpl` and `assets/plans-template/`; it takes effect the next time `init_docs.sh` runs.
- Adding a new DEVSOP stage: edit the stage table in `assets/agents.md.tmpl` + add `0N-<step>.md` in `assets/plans-template/`, and sync the entry in `assets/docs-skeleton/plans/_template/`.
- Scoring rules update in sync: see `skills/devsop.eval/`.
