---
name: devsop.init
description: DEVSOP initialization
---

# devsop.init

**Purpose**: One-click scaffold or upgrade the `.docs/` skeleton + `AGENTS.md` (the source-of-truth entry) for a project, laying the "tracks" for the 9-phase DEVSOP. The script is idempotent — a brand-new project gets a full initialization; an older project with an existing skeleton automatically gets missing pieces filled in + contractual files refreshed to the latest version.

---

## Standard `.docs/` Layout

> `.docs/` is the long-term technical documentation area, `.docs/plans/` is the task artifact area; the two are strictly separated.
> **No global `plan.md` task overview is generated at the top level** — when multiple people develop in parallel, everyone editing the same file inevitably causes merge conflicts; instead, "task autonomy" is adopted: each task's overview + progress is written in `plans/<task-dir>/00-overview.md`.
> Only one fixed file, `review.md`, remains at the top level; other files such as the glossary / ADR / risk register / project conventions are added under `.docs/` as needed, and placeholders are no longer forced.

```
.docs/
├── review.md                     # AI Code Review standards
├── architecture.md               # System architecture, modules, flows, concurrency model
├── relationship.md               # Upstream/downstream / integrators / failure propagation
├── coding-style.md               # Coding style (line length/complexity/naming/security)
├── code-review.md                # Code review standards (submitter/Reviewer checklist)
├── glossary.md                   # Business glossary (project-private terms/abbreviations/easily-confused comparisons)
├── failures.md                   # Pitfall records (context/root cause/workaround/permanent fix)
├── logging.md                    # Logging standards (level/format/masking/trace)
├── apis/                         # External APIs (organized by module)
│   ├── index.md                  # API master index
│   ├── _template.md              # API doc template
│   ├── api-standards.md          # API design standards (protocol/path/response/version)
│   └── <module>/<Action>.md      # Per-module APIs
├── sqls/                         # Persistence structure (DB schema / migration)
│   ├── README.md
│   └── database.md               # Database standards (table design/index/transaction/migration)
├── unittest/                     # Unit test standards (environment / generation / run-debug)
│   └── unittest.md
├── integration_test/             # Integration test standards (environment / test cases / run-debug)
│   └── integration_test.md
├── devops/                       # Environment setup + test env deployment + release standards
│   ├── env.md
│   ├── test-env-deploy.md
│   ├── deployment.md             # Deployment & run standards (environment matrix/artifacts/config/release)
│   └── development.md            # Local development environment standards (dependencies/one-command run/IDE/FAQ)
└── plans/                        # Task artifact area (one independent directory per task, no interference)
    └── _template/                # 10-file task template
        ├── 00-overview.md        #   —— this task's "mini plan.md", the single source of truth
        ├── 01-clarify.md
        ├── 02-plan.md
        ├── 03-implement.md
        ├── 04-ut.md
        ├── 05-deploy.md
        ├── 06-it.md
        ├── 07-docs.md
        ├── 08-review.md
        └── 09-commit.md
```

### Task discovery convention (replacing the old global `plan.md`)

| Need | Action |
|------|------|
| View all historical / in-flight tasks | `ls .docs/plans/` or `find .docs/plans -maxdepth 2 -name 00-overview.md` |
| Find the task corresponding to the current branch | `git branch --show-current`, then match against the Meta `Branch` field in each `00-overview.md` |
| View a task's progress | Read only that task's `00-overview.md` (Progress + current step) |
| Cross-task statistics / reports | Aggregate the Meta blocks of `00-overview.md` with ad-hoc scripts as needed, **without writing back** to any shared file |

**Core principle**: `00-overview.md` is the single source of truth for this task, maintained only by this task's branch; the overviews of different tasks are independent of each other and never conflict.

### Anti-patterns strictly forbidden

- Placing `.docs/apis/`, `.docs/sqls/`, `.docs/unittest/`, `.docs/integration_test/`, `.docs/devops/`, `.docs/architecture.md` directly at the top level → must be moved under `.docs/`, keeping the physical directory names following the project's existing conventions.
- **Strictly forbidden** to re-introduce a global `plan.md` task overview at the `.docs/` top level — multi-person collaboration inevitably conflicts; any "view all tasks" need is satisfied by listing `.docs/plans/` + reading each `00-overview.md`. If a leftover `.docs/plan.md` is found, simply delete it.
- Introducing placeholder files such as `README.md` / `conventions.md` / `glossary.md` / `risks.md` / `adr/` / `PROFILES.md` outside the skeleton — add them on demand when actually needed; do not pre-generate empty files that pollute the directory.

---

## Execution Flow

### Pre-flight checks

```
1. Check whether .docs/ exists at the repo root
   - Does not exist → continue with fresh initialization
   - Exists → run the upgrade check (the script is idempotent and will auto-fill missing pieces + refresh contractual files)
   - Exists but layout does not match → continue; the script handles it per the rules
```

> **Key design**: `init_docs.sh` is idempotent. Whether it's a brand-new project or an old project with an existing skeleton, **a single run completes the upgrade** — missing skeleton files are filled, contractual files are refreshed, and AGENTS.md is smartly merged. There is no need to distinguish between "initialize" and "upgrade" commands.
>
> **Trim HTML comments when copying the template**: when the DEVSOP starts, after the AI creates a task directory with `cp -r .docs/plans/_template .docs/plans/YYYY-MM-DD_<title>`, it **must** delete the entire HTML comment blocks marked with `<!-- TEMPLATE-ONLY-DO-NOT-COPY: -->` in `plans/<task>/00-overview.md`, replacing them with a single-line pointer to `_template/`. DEVSOP rules (Progress / time records) are maintained only in `_template/`; **it is forbidden** to repeat ~30 lines of rules in every task file. See `AGENTS.md` Section 2, DEVSOP "DEVSOP startup prerequisites: branch and task determination" step 3.

### Environment detection (optional enhancement)

> Before initialization, environment detection may be run to understand the target project's characteristics for differentiated handling.

1. **Project type detection**: detect whether it is a library project in priority order Go → Rust → Java (no `package main` / `[[bin]]` / main class).
2. **Framework identification**: detect the core framework (Go: go-zero✓/gin△/kratos△ etc.), recording `$FRAMEWORK`. If `$FRAMEWORK` matches `references/framework-<name>.md`, the main Agent automatically loads the corresponding sections of that file as extra requirements when dispatching the relevant sub-agents (coding-style / api-standards / unittest / development) (see "Attached resources / references").
3. **Maintainer inference**: use `git shortlog -sne --since="6 months ago" HEAD` to get the top committer of the last six months.
4. **AI entry four-state scan**: detect the state of `AGENTS.md` / `CODEBUDDY.md` / `CLAUDE.md` (missing / regular file / correct symlink / wrong symlink).

**Library project differentiated handling**: when `project.type == library` is detected:
- Skip creating `api-standards.md` / `database.md` / `deployment.md` (a library project has no standalone API/DB/deployment).
- Inject the library project context (`references/library-context.md`), focusing on API surface / backward compatibility / semver etc.
- If already present, run in update mode and trim to a library-appropriate version.

### Step 0 capability detection (API / DB, required before initialization)

> Purpose: projects without API / without DB should not have the `.docs/apis/`, `.docs/sqls/` skeleton initialized, nor should the corresponding sub-agents be dispatched. Complete the detection **before** running `init_docs.sh`.

1. The main Agent reads `$SKILL_DIR/references/special-agent-detect.md` and dispatches an **Explore sub-agent (read-only detection)** using it as the complete prompt.
2. The sub-agent returns `HAS_API=true|false` / `HAS_DB=true|false` + an evidence summary in the fixed format.
3. The main Agent passes the two boolean values as flags to `init_docs.sh` (see below); in "batch 2" it uses the same two values to decide whether to dispatch Agent C (apis) / Agent D (sqls):
   - `HAS_API=false` → **do not start** Agent C; the summary report directly marks `skipped(no external API)`
   - `HAS_DB=false`  → **do not start** Agent D; the summary report directly marks `skipped(no database)`
4. If detection fails / is not run, the flags default to `true` (conservative, consistent with the old version's behavior).

### Initialization steps (brand-new project)

1. Run the initialization script:
   ```bash
   bash <skill_dir>/scripts/init_docs.sh <repo_root> --has-api=<true|false> --has-db=<true|false>
   ```
   Both flags default to `true` (backward compatible); when `false`, the script skips copying the skeleton `.docs/apis/` / `.docs/sqls/` (this only affects gap-filling and does **not delete** the target project's existing files).
   For an equivalent manual operation:
   ```bash
   cp -r <skill_dir>/assets/docs-skeleton/. .docs/
   cp -r <skill_dir>/assets/plans-template   .docs/plans/_template
   # HAS_API=false → do not copy apis/; HAS_DB=false → do not copy sqls/
   ```
   (`<skill_dir>` = the directory where this Skill resides.)
2. The script additionally handles repo-root entry points, Git Hooks, Lint configuration, and companion skills:
   - Generate `AGENTS.md` from `assets/agents.md.tmpl` (**the single source-of-truth entry**), containing four chapters (I. Quick Index / II. DEVSOP / III. Development Guidelines / IV. Forbidden Red Lines).
     - **If `AGENTS.md` already exists**: divide and conquer by chapter — only forcibly refresh the "II. DEVSOP" chapter (the core DEVSOP contract), keep "I. Quick Index", "III. Development Guidelines", "IV. Forbidden Red Lines" unchanged and undeleted (project-custom content); only update when chapter 2 differs (Git-managed, no backup needed).
  - Create symlinks from `CODEBUDDY.md` → `AGENTS.md` (for CodeBuddy compatibility).
  - Create symlinks from `CLAUDE.md` → `AGENTS.md` (for Claude Code compatibility).
    - **If it is already a symlink**: rebuild it directly; **if it is a regular file**: delete it then rebuild as a symlink (recoverable via Git).
   - Install Git Hooks: idempotently install symlinks for the three hooks pre-commit / pre-push / commit-msg into `.git/hooks/` via `scripts/setup_hooks.sh`.
   - Inject Lint config: for Go projects (`go.mod` present), automatically copy `assets/.golangci.yml` to the repo root (skip if it already exists).
   - Install the `clarify` skill into the target repo's `.codebuddy/skills/clarify/` (skip if it already exists).
   - `.docs/` skeleton files are **not overwritten if they already exist** (protecting content the user has filled in).
   - All files under `plans/_template/` use the "overwrite directly if different" strategy, ensuring new tasks after a skill upgrade get the latest template structure; already-created concrete task directories (`plans/<task>/`) are never touched.
   - **Special case**: `.docs/devops/test-env-deploy.md` uses the "divide and conquer by chapter" strategy (same as `AGENTS.md`) — with `## Project Customization` as the boundary, only the skill-managed area above (environment tool readiness check + team environment management Skill operating instructions) is forcibly refreshed, while the project-customized area below (component inventory, common environments, special sync rules) is kept unchanged and undeleted; update only when the skill-managed area differs.
3. Initialization wrap-up — sub-agents are dispatched in two batches (**must use `subagent_type: general-purpose`**; read-only types such as `Explore`/`Plan` are not allowed). Dependency: Agents C–M all need to read the **optimized** AGENTS.md to correctly align with the index and the progressive-disclosure structure, so they must be started in parallel only after Agents A and B complete. When all are done, report a summary to the user:

   **Batch 1 (serial, no dependency prerequisites)**

   **Agent A: optimize AGENTS.md**

   Role: CODEBUDDY.md/AGENTS.md optimization expert. Full prompt in `$SKILL_DIR/references/special-agent-agents.md`: optimize AGENTS.md into an AI entry file following the progressive-disclosure principle (hard cap of ≤300 lines, ≤200 is the excellence target, details sink into `.docs/` or `.codebuddy/rules/`; "II. DEVSOP" is the skill-managed contract chapter, read-only, restored verbatim from the template if drifted), writing directly back to AGENTS.md (Git is the safety net, no backup needed).

   **Agent B: rewrite ARCHITECTURE.md**

   Role: architecture documentation generation expert. Full prompt in `$SKILL_DIR/references/special-agent-architecture.md`: generate `.docs/architecture.md` based on code facts following the 13-section template (at least 1 Mermaid diagram, data-flow tracing, technology choices including Why), overwrite directly if present, use `<!-- TODO(devsop.init) -->` placeholders for uncertain fields.

   > **Dispatch constraint**: start Agent A first, and only after it writes back the optimized AGENTS.md, start Agent B (B does not need to read A's output to generate the architecture doc, but is scheduled after it to keep the order clear). **Only after both complete** does batch 2 begin.

   **Batch 2 (parallel, depends on AGENTS.md being finalized)**

   **Agent C: enrich apis/** (**dispatch prerequisite**: Step 0 detection `HAS_API=false` → do not start this Agent; the summary report marks `skipped(no external API)`)

   Role: external API documentation expert. Corresponding instructions: `$SKILL_DIR/references/special-agent-apis.md`.

   Goal: based on the real interfaces in the code, flesh out `.docs/apis/` into an API documentation set from the caller's perspective (`index.md` master index + one `<module>/<Action>.md` per API + `api-standards.md` protocol standards).

   Relevance determination (prerequisite):
   - No evidence of any external API (no proto/thrift/OpenAPI, no HTTP-RPC framework dependency, no route registration, a pure library with no exported interfaces) → determine it is a **no-API project**, **delete** the entire `.docs/apis/` directory, then output `skipped(no external API)`.
   - With evidence → create/update mode: generate per-API docs following `apis/_template.md` and write back a 1:1 index into `index.md`.

   **Agent D: enrich sqls/** (**dispatch prerequisite**: Step 0 detection `HAS_DB=false` → do not start this Agent; the summary report marks `skipped(no database)`)

   Role: persistence structure documentation expert. Corresponding instructions: `$SKILL_DIR/references/special-agent-sqls.md`.

   Goal: based on the real DB schema / migration / ORM model, flesh out `.docs/sqls/` into a specification doc covering table design / index / transaction / migration (focus on `sqls/database.md`).

   Relevance determination (prerequisite):
   - No evidence of any persistence (no DB driver dependency, no migration, no schema, a pure in-memory / pure-computation library) → determine it is a **no-database project**, **delete** the entire `.docs/sqls/` directory, then output `skipped(no database)`.
   - With evidence → create/update mode: extract table structures + state machines and fill `database.md`.

   **Agent E: enrich devops/**

   Role: operations documentation expert. Corresponding instructions: `$SKILL_DIR/references/special-agent-devops.md`.

   Goal: based on the real build/deployment/environment config, flesh out `.docs/devops/` into an actionable operations documentation set (`env.md` / `deployment.md` / `development.md` / `test-env-deploy.md`).

   Task: scan `Makefile` / `Dockerfile` / CI config / config files to extract commands and environment facts; for `test-env-deploy.md`, refresh only the skill-managed area via the divide-and-conquer-by-chapter approach, preserving the user content under "## Project Customization"; verify commands by actually running them locally where possible.

   **Agent F: enrich integration_test/**

   Role: integration test standards expert. Corresponding instructions: `$SKILL_DIR/references/special-agent-integration-test.md`.

   Goal: flesh out `.docs/integration_test/integration_test.md` into an integration test standard covering real chains at the API/E2E level (environment & dependencies / test case design / run-debug), aligned with `relationship.md` and `devops/test-env-deploy.md`.

   Constraints: must not test the same layer as unittest (UT is function-level with Mocks, IT is real chains); dependencies come from relationship.md, environment from devops, referenced with `@` without copying.

   **Agent G: enrich failures.md**

   Role: pitfall records expert. Corresponding instructions: `$SKILL_DIR/references/special-agent-failures.md`.

   Goal: extract evidence-backed pitfall records from AI Memory (`.codebuddy/memory/`, `.claude/`, etc.) and Git Log (fix/revert-type commits), filling `.docs/failures.md` (each entry includes date / context / root cause / temporary workaround / permanent fix). If there is no evidence, keep the template structure and note "No historical pitfall records yet".

   Constraints: no fabrication; silently skip when Git Log / Memory are missing; mark inferred items with `source: git log`.

   **Agent H: enrich glossary.md**

   Role: business glossary expert. Corresponding instructions: `$SKILL_DIR/references/special-agent-glossary.md`.

   Goal: scan code package / struct names, config keys, and team docs, strictly filtering with the three questions "project-private, not publicly known, would be misunderstood without explanation", then fill `.docs/glossary.md` (project-private terms / abbreviations / easily-confused comparisons). Prefer fewer but precise entries; do not pad with publicly known terms.

   **Agent I: enrich unittest/**

   Role: unit test standards expert. Corresponding instructions: `$SKILL_DIR/references/special-agent-unittest.md`.

   Goal: flesh out `.docs/unittest/unittest.md` into an actionable Go unit test standard (three phases: environment setup / generation standard / run-debug).

   Prerequisite determination:
   - Update `unittest/unittest.md` directly based on the project's actual situation (`*_test.go` files / `go.mod` test dependencies / CI config)
   - If the project has no Go code (no `*.go` / no `go.mod`) → output `skipped(no Go code)`

   Constraints: must not test the same layer as IT (UT is fully Mocked + function-level); commands / environment come from real config, no fabrication; if the repo has `.codebuddy/rules/unittest_*.md`, unittest.md changes to excerpts + links, noting the authoritative source.

   **Agent J: enrich relationship.md**

   Role: upstream/downstream / integration relationship expert. Corresponding instructions: `$SKILL_DIR/references/special-agent-relationship.md`.

   Goal: flesh out `.docs/relationship.md` into an actionable upstream/downstream / integration relationship doc (upstream callers / downstream dependencies / call-relationship descriptions / topology diagram / failure propagation matrix).

   Prerequisite determination:
   - Directly analyze the code based on the project's actual situation (`go.mod` dependencies / imported clients / route registration / configured addresses / message produce-consume) and fill `relationship.md`

   Constraints: callers / dependencies / failure handling come from real code and config, no fabrication; the degradation plan in the failure propagation matrix must correspond to real fallback code; only touch `relationship.md`.

   **Agent K: enrich coding-style.md**

   Role: coding style expert. Corresponding instructions: `$SKILL_DIR/references/special-agent-coding-style.md`.

   Goal: trim `.docs/coding-style.md` from a multilingual generic template and make it the coding standard for the project's actual language and toolchain (trim language sections / fill in formatting and lint tools / align thresholds with lint config).

   Prerequisite determination:
   - No code files at all (pure documentation repo) → output `skipped(no code)`
   - Matches `$FRAMEWORK` (e.g. go-zero) → merge the extra requirements from the coding-style section of `references/framework-<name>.md`

   Constraints: tool names / thresholds / commands must come from evidence in real config files (`.golangci.yml` / `.prettierrc` / pre-commit hook), no fabrication; only touch `coding-style.md`.

   **Agent L: enrich code-review.md**

   Role: code review process expert. Corresponding instructions: `$SKILL_DIR/references/special-agent-code-review.md`.

   Goal: replace the placeholders and generic conventions in `.docs/code-review.md` with the project's real values (main branch name / real build·lint·ut commands / coverage thresholds / commit message validation rules), and draw a clear boundary with the top-level `.docs/review.md` (review.md = AI review checklist; code-review.md = team manual review process).

   Constraints: commands / thresholds / branch names come from real evidence (Makefile / CI config / commit-msg hook), no fabrication; only touch `code-review.md`, do not copy review.md's AI checklist.

   **Agent M: enrich logging.md**

   Role: logging standards expert. Corresponding instructions: `$SKILL_DIR/references/special-agent-logging.md`.

   Goal: turn `.docs/logging.md` into the standard for the project's real logging system (log library / level mapping / trace field names / masking rules / collection method all come from code evidence).

   Relevance determination (prerequisite):
   - No evidence of any logging output (a pure library project that only returns errors, no log library dependency, no log calls found by grep) → determine it is a **no-logging project**, **delete** `logging.md`, output `skipped(no logging)`, and note in the summary report that the corresponding index line in AGENTS.md must be removed
   - With evidence → fill based on the actual log library and fields

   Constraints: log library / field names / levels must come from code evidence, no fabrication; align the masking clauses with `coding-style.md` §10 by reference, without copying; only touch `logging.md`.

   > **Batch 2 runs in parallel (C–M)**: after both Agents A and B complete, the following eleven Agents are all started **in parallel** (C APIs, D data, E operations, F integration tests, G pitfall records, H glossary, I unit tests, J upstream/downstream relationships, K coding style, L review process, M logging standards). They all read the batch-1 finalized AGENTS.md to align with the index and the progressive-disclosure structure — this is the dependency on A/B; be sure to run A, B first and then C–M. Agents C/D first do the relevance determination — delete `apis/` if no API, delete `sqls/` if no DB; Agent I first does the no-Go-code determination; Agent J directly fills relationship.md based on code evidence; Agent M first does the no-logging determination. Each Agent only touches the file it owns; they never overlap.

   After all complete, the summary report:
   - Agent A: AGENTS.md line count before/after optimization + description of sunk content
   - Agent B: ARCHITECTURE.md fill status + TODO list
   - Agent C: number of API docs in apis/ + whether the directory was deleted due to no API
   - Agent D: sqls/ doc status + whether the directory was deleted due to no DB
   - Agent E: fill status of each devops/ file
   - Agent F: integration_test.md fill status
   - Agent G: number of pitfall records in failures.md + whether left empty due to no evidence
   - Agent H: number of glossary.md entries + whether left empty due to no private terms
   - Agent I: unittest.md fill status + whether skipped due to no Go code
   - Agent J: relationship.md fill status
   - Agent K: coding-style.md trimmed languages + toolchain fill status / whether framework-specific content was injected
   - Agent L: code-review.md fill status (main branch / commands / thresholds)
   - Agent M: logging.md fill status + whether the file was deleted due to no logging
   - List of remaining TODO items (parts the user needs to handle manually later)
- Do not pre-generate placeholders such as `README.md` / `conventions.md` / `glossary.md` / `risks.md` / `adr/` — add them on demand when actually needed.
- Existing `.codebuddy/rules/<topic>_*.md` files (e.g. `unittest_rule.md`) serve as the authoritative source for docs; docs change to excerpts + links to avoid dual tracking.

---

## Attached Resources

### `scripts/`
- `scripts/init_docs.sh [repo_root]` — the core initialization/upgrade script (idempotent). For **all files** under `plans/_template/` it uses the "overwrite directly if different" strategy (only refreshes `_template/` itself; already-created concrete task directories are not touched); for `AGENTS.md` and `.docs/devops/test-env-deploy.md` it uses the "divide and conquer by chapter" strategy — with `## II. DEVSOP` / `## Project Customization` as the boundaries respectively, only refreshing the skill-managed areas and keeping the project-customized areas untouched. The project is managed by Git; no `.bk.*` backup files are generated by any write operation.

### `references/`
- `references/docs-generation.md` — the `.docs/` generation methodology; loaded when guiding the user to fill in docs content after initialization.
- `references/special-agent-detect.md` — dedicated instructions for the Step 0 capability-detection sub-agent (Explore, read-only): API / DB detection methods + the fixed return format `HAS_API=` / `HAS_DB=`.
- `references/special-agent-architecture.md` — dedicated instructions for Agent B (ARCHITECTURE.md).
- `references/special-agent-agents.md` — dedicated instructions for Agent A (AGENTS.md).
- `references/special-agent-apis.md` — dedicated supplementary instructions for Agent C (apis/), including the no-API directory-deletion determination.
- `references/special-agent-sqls.md` — dedicated supplementary instructions for Agent D (sqls/), including the no-database directory-deletion determination.
- `references/special-agent-devops.md` — dedicated supplementary instructions for Agent E (devops/).
- `references/special-agent-integration-test.md` — dedicated supplementary instructions for Agent F (integration_test/).
- `references/special-agent-failures.md` — dedicated supplementary instructions for Agent G (failures.md); extracts pitfall records from Memory + Git Log.
- `references/special-agent-glossary.md` — dedicated supplementary instructions for Agent H (glossary.md); strictly filters terms with the three questions "project-private / not publicly known".
- `references/special-agent-unittest.md` — dedicated supplementary instructions for Agent I (unittest/), including the no-Go-code skip determination.
- `references/special-agent-relationship.md` — dedicated supplementary instructions for Agent J (relationship.md).
- `references/special-agent-coding-style.md` — dedicated supplementary instructions for Agent K (coding-style.md), including language trimming + toolchain fill-in + framework-specific injection.
- `references/special-agent-code-review.md` — dedicated supplementary instructions for Agent L (code-review.md), including main branch / commands / thresholds fill-in + the boundary with the top-level review.md.
- `references/special-agent-logging.md` — dedicated supplementary instructions for Agent M (logging.md), including log library detection + no-logging-project deletion determination.
- `references/merge-agent-prompt.md` — instructions for the normalize-and-merge sub-agent; when multiple scattered AI entry regular files are detected at the repo root (`CODEBUDDY.md` / `CLAUDE.md` not symlinks), the main Agent reads this file and dispatches the merge sub-agent to consolidate them into a single `AGENTS.md` (template taken from `assets/agents.md.tmpl`, read-only).
- `references/framework-gozero.md` — go-zero framework-specific instructions; when environment detection finds `$FRAMEWORK = go-zero`, the main Agent automatically loads it by matching `references/framework-<name>.md` and injects the extra requirements of the corresponding sections into the relevant sub-agents (coding-style / api-standards / unittest / development). To extend to a new framework, just add `references/framework-<name>.md`; no need to change SKILL.md.

### `assets/` — copied into the target repo for use, not read into context
- `assets/docs-skeleton/` — the `.docs/` skeleton (`review.md` + 20 template files at the `.docs/` top level + `plans/`).
- `assets/plans-template/` — the 10-file task template.
- `assets/agents.md.tmpl` — the template for the repo-root `AGENTS.md` (four chapters: Quick Index / DEVSOP / Development Guidelines / Forbidden Red Lines). AGENTS.md is the single source of truth; CODEBUDDY.md / CLAUDE.md are both symlinks.
- `assets/README.md.tmpl` — the project README template. **Not auto-generated** (red line 3 forbids pre-generating README.md); copied manually by the user to the target repo root as needed, filling in the `{{...}}` placeholders.
- `assets/ARCHITECTURE.md.tmpl` — the project architecture doc template (used by Agent B as the 13-section skeleton reference when generating `.docs/architecture.md`; not copied directly to the target root).
- `assets/clarify-skill/` — the `clarify` skill template used in Stage 01.
- `assets/.golangci.yml` — the Go project lint config template (auto-copied to the repo root during initialization).

---

## Validation Mechanism

After initialization, it is recommended to run the following validations (either executed automatically by `init_docs.sh` or checked manually):

| # | Validation | Check content | Threshold |
|---|--------|---------|------|
| V1 | Line count & existence | `wc -l AGENTS.md` >300 lines→WARN; README/ARCHITECTURE missing→BLOCK | ≤300 |
| V2 | Symlink correctness | CODEBUDDY.md / CLAUDE.md must be correct symlinks pointing to AGENTS.md | all correct |
| V3 | AGENTS.md chapter completeness | diff chapters against the template; missing→WARN | chapters complete |
| V4 | TODO count gate | `TODO(devsop.init)` total >30→WARN, >60→BLOCK | ≤30 |
| V5 | docs back-references + dead links | .docs/*.md must be referenced by the AGENTS.md Index; .docs links in AGENTS.md must exist | no dead links |
| V6 | Library project file consistency | a library project must not create deployment/database/api-standards | consistent |
| V7 | .gitignore conflicts | AGENTS.md / .docs/ must not be ignored | no conflicts |
| V8 | Empty directory cleanup | a no-external-API project must not leave `.docs/apis/`; a no-database project must not leave `.docs/sqls/` | deleted |

---

## Red Lines

1. **Strictly forbidden** to place DEVSOP documents (`architecture.md` / `relationship.md` / `apis/` / `sqls/` / `unittest/` / `integration_test/` / `devops/` etc.) outside `.docs/` — all docs must live under the `.docs/` directory.
2. **Strictly forbidden** to re-introduce a global `plan.md` task overview at the `.docs/` top level — multi-person collaboration inevitably conflicts; all task-overview capability sinks into each `plans/<task-dir>/00-overview.md`.
3. **Strictly forbidden** to pre-generate placeholder files such as `README.md` / `conventions.md` / `glossary.md` / `risks.md` / `adr/` / `PROFILES.md` / `contracts/` / `internals/` / `operability/` just to look "complete" — create them on demand to avoid polluting the directory and drifting from the project's actual structure.
4. **Step 9 Commit standard** — must follow in order: "**① when entering commit, the AI must first ask whether there is an issue/task ticket** (do not assume it exists / does not exist; if it does not exist, guide the user to create it — the default recommendation is for the AI to create it on their behalf via the team issue-tracker skill; if not this team / skipping, record the reason in the Key Decision Log) → ② 0. Environment release** (execute the environment release command via the team environment management Skill, recording the result in the "environment release execution record" table) → ③ advance the ticket status to "In Development"** (see `09-commit.md` section 0.2: advance the status from the current node to "In Development"; **CR is triggered automatically by the MR submission after push, not completed in this step**) → ④ write all the md files (including the commit message in `09-commit.md` section 2) → ⑤ **update `00-overview.md`** (row 09 **end time** = the moment "all prep is done" + duration + append commit info to the Key Decision Log) → ⑥ `git add` code + plans artifacts (including the just-updated 00-overview.md) + docs increments in one shot → ⑦ `git commit` (footer **defaults to `--story=<id>`**, bug fixes use `--bug=<id>`; **exactly once**) → ⑧ `git push` creates the MR, triggering the ticket status In Development → CR"; **strictly forbidden** to proceed without asking about the issue/task ticket after entering commit (not asking, or asking without guiding creation, both count as violations); **strictly forbidden** to bypass the team environment management Skill and directly invoke test tools, directly execute environment release commands, or release the environment through any workaround; **strictly forbidden** to bypass the team issue-tracker skill and call the tracker's API/MCP directly; **strictly forbidden** to declare the task finished without the full chain ultimately landing on CR (CR can only be triggered after push and is not a commit prerequisite, but it must be confirmed reached before the task is wrapped up); **strictly forbidden** to update `00-overview.md` after `git commit` (that would create a second commit and break the one-MR-one-commit rule) — must **first** update `00-overview.md` (row 09 end time in the time records + commit info in the Key Decision Log) **then** add + commit. **Two boundary points (iron rule)**: **boundary point A — content lock**: after steps ④+⑤ (writing the commit message + updating 00-overview.md) are both complete, **forbidden** to change `00-overview.md` and the "2. This Actual Commit" section of `09-commit.md`; **boundary point B — MR lock**: after the MR is merged (or the user explicitly declares the task finished), **forbidden** to make any further changes; **the only exception** is between boundary points A and B, when there is a code fix (CI failure / review comments), go through `--amend` — **only change the code itself**, do **not** change `00-overview.md` / `09-commit.md` / any plans artifacts; it can be repeated any number of times, always keeping a single commit; once boundary point B is reached, everything is frozen and no more amends are allowed. **`--amend` is allowed** (one-MR-one-commit principle): ① minor adjustments before the first commit (including before push) can be rewritten directly with `git commit --amend`; ② after push, CI failures / review comments / follow-up fixes **may only** be accumulated onto the original commit via `git commit --amend` (repeatable), and a second commit is **strictly forbidden** (a "metadata-padding" commit like `chore(specs): post-commit notes` is not allowed); ③ after amending, push must use `git push --force-with-lease` (**bare `--force` is forbidden**); ④ no longer record the MR link / amend count / merge time / CR status via the "3. Push Record" table in `09-commit.md` or any md artifacts — all of these are queryable in GitLab / `git log` / the issue-tracker system, so do **not** duplicate them. **Throughout, do not record metadata queryable in the git / issue-tracker systems** — `00-overview.md` / `09-commit.md` / Key Decision Log all leave out commit ID / push time / amend count / MR link / CR status; **row 09 end time = the moment "all prep is done"** (**first** write it into `00-overview.md`, **then** run `git add` + `git commit` + `git push`). See the "0. Prerequisites", "1. Execution order", and "2. amend flow" sections of `assets/plans-template/09-commit.md`.
5. **Strictly forbidden** to violate the TDD red-green loop — the Step 2 Plan artifact `02-plan.md` **must** include a `§6 UT test case design` section (object under test / test files / inputs / expectations / Mock boundaries), landed before Step 3 Implement; Step 3 Implement must, per the Plan §6 cases, first write the tests and see them fail (red), then write the minimal implementation to make them pass (green); the Step 4 UT artifact `04-ut.md` test case list **must** be aligned one-by-one with `02-plan.md §6` (including a "Plan §6 number" column). **Forbidden** to use the reverse flow of "write implementation first, then add tests"; **forbidden** to have UT and IT test the same layer of logic (UT is fully Mocked + function-level; IT is real chains + API/E2E level).
6. **Strictly forbidden** to miss, or later backfill/fabricate, the start / end times in the "time records" table of `00-overview.md` — the start time must be written the moment the user confirms the start; the end time must be written before the end confirmation is sent to the user; for steps whose time was missed, write "missed" in the remarks column and leave it blank, **forbidden** to guess timestamps afterwards. This table is the only source for task-level time auditing.
7. **Strictly forbidden** for the AI to proactively read / reference md artifacts under other `.docs/plans/<other-task-dir>/` while working on the current task (including `00-overview.md`, `01-clarify.md` … `09-commit.md`, `.docs/design.md`, etc.). Tasks are physically isolated from each other and each is an independent source of truth; cross-task references would contaminate the current task's design judgment. **The only exception**: when the user **explicitly** says "refer to task X", the specified task directory may be read, and the referenced content **stays only in the conversation context**, never written back automatically to the current task. See the "Task isolation principle (mandatory)" section in Section 2, DEVSOP of `agents.md.tmpl`.
8. **Small-requirement mode** (when the 02 Plan estimates `estimated code change lines ≤ 10`, set the Meta `Small-requirement mode` of `00-overview.md` to ✅): the start/end confirmations for 03-04 (Implement+UT) and 07-09 (Docs+Review+Commit) may be **merged into a single one** (the AI states "I am going to do X-Y-Z" in one go, starts running, and reports once when done), but **strictly forbidden** to — ① miss the md artifacts / `00-overview.md` time records / Progress checkboxes of these 6 steps; ② include 05 Deploy / 06 IT in the automatic batch (environment-sensitive + real-chain verification, must be explicitly confirmed); ③ fail to correct the Meta status after underestimating (if the actual change exceeds 10 lines, the `Small-requirement mode` should be changed back to ⬜ when reporting the 03-04 conclusion). See the "task size branching" section in Section 2, DEVSOP of `agents.md.tmpl`.
