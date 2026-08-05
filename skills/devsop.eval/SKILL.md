---
name: devsop.eval
description: "Evaluates how well a project implements the team R&D DEVSOP standard per DEVSOP v1.0. Scans project structure, docs, CI, testing, and process evidence, then generates a structured scoring report (six pillars, 28 Eval items, PASS/PARTIAL/FAIL, anti-pattern detection, improvement suggestions, upgrade roadmap), finally writing to .harness/devsop_report.md."
disable-model-invocation: true
---

# devsop.eval

**Eval Schema version**: `2.0` (28 Eval items, stable ID namespace. Adapted to the `.harness/` artifact system of the new devsop.init (specs-devsop). New Eval items append new IDs; the version number increments. `--diff-from` comparison must check version consistency.)

## User Input

```text
$ARGUMENTS
```

## Overview

Per the "big principles + six chapters" of the team R&D DEVSOP v1.0, perform a read-only audit of the current project, quantify how well the project implements the DEVSOP, generate actionable improvement suggestions, and finally **write the report to `.harness/devsop_report.md`** (this is the standard location for the regulations library in the DEVSOP §1.2 project directory structure; it is checked into the repo for team review).

Supports three run modes:
1. **Report only** (default): run the evaluation and write `.harness/devsop_report.md`
2. **Report + JSON** (`--json`): after running the evaluation and writing the report, additionally generate structured JSON to a temp directory
3. **JSON only** (`--json-only`): skip evaluation, directly convert the existing `.harness/devsop_report.md` to JSON

> **This Skill is self-contained**: the DEVSOP evaluation criteria are embedded in the "Evaluation Dimensions" section below; no external DEVSOP document is needed. As the team's DEVSOP version evolves, update this SKILL.md and `references/devsop-scoring-criteria.md` together.

---

## Path Variable Definitions (prevent mis-writes)

| Variable | Meaning | How it is resolved | Usage |
|----------|---------|--------------------|-------|
| `$SKILL_DIR` | this Skill's install dir (may be `~/.codebuddy/skills/devsop.eval` user-level, or `<repo>/.codebuddy/skills/devsop.eval` project-level) | the directory containing this SKILL.md | **read-only**: read references/ and scripts/ |
| `$REPO_ROOT` | current project repo root | `git rev-parse --show-toplevel`, falling back to cwd on failure | **read/write**: scan evidence + write `.harness/devsop_report.md` |

Hard constraints:
- The output file `.harness/devsop_report.md` **must** be written to `$REPO_ROOT`; writing to `$SKILL_DIR` / `$HOME` / `~/.codebuddy/` is forbidden
- Scoring/scanning commands (`ls` / `grep` / `git log`) **must** run under `$REPO_ROOT`
- Reading templates/scripts must use `$SKILL_DIR/...`; hardcoding `.codebuddy/skills/devsop.eval/...` is forbidden (it only exists for project-level installs)
- The main agent resolves the paths in the following two steps at Skill startup:

```bash
# Step A: resolve REPO_ROOT (the current project repo)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# Step B: resolve SKILL_DIR (Skill install dir, prefer user-level)
if [ -d "$HOME/.codebuddy/skills/devsop.eval/references" ]; then
  SKILL_DIR="$HOME/.codebuddy/skills/devsop.eval"
elif [ -d "$REPO_ROOT/.codebuddy/skills/devsop.eval/references" ]; then
  SKILL_DIR="$REPO_ROOT/.codebuddy/skills/devsop.eval"
else
  echo "⚠️ cannot locate the devsop.eval skill directory" >&2
fi
```

> ⚠️ All subsequent `$SKILL_DIR` references (reading references/, scripts/) must use the absolute path resolved above; relative paths are forbidden.

---

## When to Use This Skill

- After the project has its DEVSOP directory structure set up via `devsop.init`, run a baseline evaluation
- Monthly routine DEVSOP freshness Review (DEVSOP §3.4 memory + organization mechanisms)
- After introducing new dev processes or tooling changes, verify DEVSOP gate requirements are still met
- Cross-project benchmarking: compare DEVSOP maturity of multiple projects with unified scoring
- Need to convert an existing report to JSON for frontend/task-system consumption (`--json-only`)

---

## Evaluation Dimensions (self-contained · six pillars · total 100)

Directly mapped to the DEVSOP v1.0 chapters; each pillar is scored by its weight and gate strength in the DEVSOP:

| Pillar | Full score | Corresponding DEVSOP chapter | Core question |
|--------|-----------|---------------------------|---------------|
| **A. Project AI-friendliness** | 25 | §1 (friendliness prerequisites + directory structure + symlinks to abstract tool differences) | Can AI/newcomers get the project running and understand its structure within 30 minutes? |

> **Layout alignment note**: this Schema is adapted to the **new specs-devsop (`devsop.init`)** `.harness/` hidden-directory artifact system. Core layout conventions:
> - The regulations library lives under `.harness/docs/` (`architecture.md` / `relationship.md` / `coding-style.md` / `code-review.md` / `glossary.md` / `failures.md` / `logging.md` / `unittest/unittest.md` / `integration_test/integration_test.md` / `apis/` / `sqls/` / `devops/`);
> - The top level keeps only `.harness/review.md` and `.harness/plans/`; a global `plan.md` task overview is **strictly forbidden** (task overviews sink into each `plans/<task>/00-overview.md`).
> - If the project still has a legacy non-hidden `harness/` directory or old doc names (`dependency-map.md` / top-level `testing.md`), prompt migration via the "legacy harness residue" anti-pattern; do not double-deduct.
| **B. Dev mode / role collaboration** | 15 | §2 (overall flow + SOLO/P-G-E architecture) | Is there a clear R&D process definition with per-phase deliverables? |
| **C. Quality checks & feedback mechanisms** | 25 | §3 (quality gates + prohibitions + feedback mechanisms) | Do key checkpoints have gates that can block bad code from merging? |
| **D. Design & change management** | 15 | §4 (sized by scope + design before coding + TDD) | Do large/medium/small changes have matching design processes and doc artifacts? |
| **E. Shared knowledge base** | 5 | §5 (internal accumulation + external resources) | Is there reusable knowledge accumulated across teams/projects? |
| **F. Measurement mechanisms** | 15 | §6 (DEVSOP maturity + AI operating metrics) | Does the project have a self-measurement and continuous-improvement loop? |

> Total 100; the score-to-level mapping is in "Maturity Levels" below.

Each pillar is split into 3-7 independent Eval items; each item is given ✅ PASS / ⚠️ PARTIAL / ❌ FAIL, and evidence must be file paths, command output, or doc excerpts. The complete judgment logic for all 28 Eval items is in `references/devsop-scoring-criteria.md`.

---

## Evaluation Flow (5 steps)

### Step 0: Detect the project language stack and project type

**Detect the language stack** (decides which files to scan):

| Signal file | Language | Toolchain to watch |
|-------------|----------|--------------------|
| `go.mod` / `*.go` | Go | `.golangci.yml`, `*_test.go`, `Makefile`, `go vet` |
| `package.json` / `tsconfig.json` | JS/TS | `.eslintrc*`, `*.test.*` / `*.spec.*`, `vitest`/`jest` |
| `pyproject.toml` / `requirements.txt` | Python | `ruff`/`pylint`, `pytest`, `tox.ini` |
| `Cargo.toml` | Rust | `clippy`, `#[test]` |
| `pom.xml` / `build.gradle` | Java | `checkstyle`, `*Test.java` |

For mixed language stacks, scan each toolchain separately.

**Detect the project type** (decides which Eval items may be exempted):

| Signal | Project type | Judgment logic |
|--------|--------------|----------------|
| Has `cmd/` or `main.go`/`main.py` + HTTP handler/router code | **service** | default type, no exemptions |
| Has `go.mod` but no `main.go`/`cmd/`, only exports packages | **library** | exempt A6 (one-command start), C7 (E2E tests, replaced by checking examples/benchmarks) |
| Has `main.go` but no HTTP handlers; has cobra/flag or other CLI frameworks | **cli** | exempt A6 (replaced by checking `make build`), C7 (replaced by integration test scripts) |
| Has multiple `go.mod` / or a root `packages/` with per-subdirectory entry points | **monorepo** | no exemption, but the sub-agent should note "recommend evaluating each sub-module separately" |

**Exemption handling rules**:
- Exempted Eval items are marked `N/A`, with the reason noted in the report (e.g. "library project does not need one-command start")
- The full score of that Eval is deducted from the total base (e.g. library exempts A6+C7 → total base becomes 94; calculate the percentage against 94, then map to a level)
- The percentage thresholds in the level mapping table do not change (e.g. L3 = 60-79%); only the base is adjusted

**Project type detection script**: `$SKILL_DIR/scripts/detect_project_type.sh`

```bash
cd "$REPO_ROOT" && bash "$SKILL_DIR/scripts/detect_project_type.sh"
# Output: PROJECT_TYPE=service / library / cli / monorepo
```

### Step 1: Collect raw evidence (three-layer Grader priority)

1. **Code Grader** (deterministic): file existence, command output, config completeness. **Use first.**
2. **Model Grader** (subjective): doc quality, regulation depth, constraint clarity.
3. **Manual marking** (high cost): only when the first two cannot judge; mark the item "evaluation confidence: low".

### Step 2: Run the 28 Capability Eval items one by one

Score the six pillars item by item. Record for each:

- **Conclusion**: ✅ PASS / ⚠️ PARTIAL / ❌ FAIL
- **Evidence**: concrete file path / command output / doc excerpt (≤3 lines)
- **Grader**: code / model / manual

**28-item Eval index** (detailed criteria in `references/devsop-scoring-criteria.md`):

#### A. Project AI-friendliness (25 points)

| ID | Evaluation item | Full score | Grader |
|----|-----------------|------------|--------|
| A1 | `AGENTS.md` exists and ≤300 lines + four-chapter completeness (§1 quick index / §2 DEVSOP / §3 dev guidelines / §4 forbidden red lines) | 3 | code+model |
| A2 | `README.md` contains project background/quick start/deployment requirements | 5 | model |
| A3 | `.harness/docs/architecture.md` contains architecture diagram/module boundaries/tech debt (the new specs-devsop has moved the architecture doc into `.harness/docs/`; a root-level `ARCHITECTURE.md` is no longer a scoring target; if the project still has the legacy root file, prompt it via the migration anti-pattern) | 5 | model |
| A4 | `.harness/docs/` regulations library covers the new core docs: `architecture.md`, `relationship.md` (replacing the old `dependency-map.md`), `coding-style.md`, `code-review.md`, `glossary.md`, `failures.md`, `logging.md`, `unittest/unittest.md` (replacing the old `testing.md`), `integration_test/integration_test.md`; plus subdirectory docs `apis/index.md`, `sqls/README.md`, `devops/deployment.md`, `devops/development.md`, `devops/env.md`, `devops/test-env-deploy.md` (on demand; projects without APIs/DB may omit, see pillar A scoring standard §equivalent recognition). **Judgment emphasizes "content substance" rather than mere file existence** (placeholder templates count as missing, see pillar A scoring standard §placeholder recognition) | 5 | code |
| A5 | Detect which AI-tool symlinks the project already has (CODEBUDDY.md / CLAUDE.md → AGENTS.md); at least 1 exists and is not gitignored; **the project is not required to add symlinks for unused AI tools** | 2 | code |
| A6 | `make dev` or an equivalent one-command start command exists and runs | 3 | code |
| A7 | Env config template (`.env.example` or equivalent) exists; new developers need not guess config | 2 | code |

#### B. Dev mode / role collaboration (15 points)

| ID | Evaluation item | Full score | Grader |
|----|-----------------|------------|--------|
| B1 | The `AGENTS.md` "§2 DEVSOP" chapter clearly defines the 9-step R&D flow (Clarify→Plan→Implement→UT→Deploy→IT→Docs→Review→Commit) | 5 | model |
| B2 | Role responsibilities (product/test/R&D) are documented or described in `AGENTS.md` | 4 | model |
| B3 | Phase deliverables have clear ownership locations (`.harness/plans/<task>/` task dirs + `_template/` template); tasks/requirements/defects must be registered in the team-designated issue tracker (default example: GitHub Issues) and used consistently | 4 | code+model |
| B4 | Branch naming + Commit Message conventions are documented (Conventional Commits or equivalent), with ticket references formatted per the team's tracker convention (e.g., `--story=<id>` / `--bug=<id>`, GitHub-style `#<id>`) | 2 | code+model |

#### C. Quality checks & feedback mechanisms (25 points)

| ID | Evaluation item | Full score | Grader |
|----|-----------------|------------|--------|
| C1 | Commit / Push convention memorization: `AGENTS.md` and rule files under `.codebuddy/rules/` explicitly define commit conventions (message format / pre-commit checks / ticket references) and push conventions (pre-push checks / MR flow / force-push constraints). **Note**: this Skill runs on a server; `.git/hooks/` is not distributed with code, so Git Hooks are not evidence | 5 | code+model |
| C2 | CI pipeline with full unit tests + coverage gate (either of two counts as having CI: ① repo contains a CI config such as `Jenkinsfile`/`jenkins/`/`.github/workflows/`/`.gitlab-ci.yml`; ② `README.md` or `.harness/docs/devops/development.md` explicitly writes the CI platform/pipeline URL). Any CI platform counts as primary PASS evidence | 5 | code |
| C3 | Prohibited-item protection: sensitive files, artifacts, unformatted code, unreviewed AI code (reflected in `.gitignore` / Hooks / `.harness/docs/code-review.md`) | 4 | code+model |
| C4 | Branch protection: conventions such as no direct pushes to main, PR must be reviewed, PR line-count constraints, documented | 3 | model |
| C5 | Feedback mechanism (failures.md / pitfall records continuously updated, non-empty doc) | 3 | code+model |
| C6 | Security scanning / dependency vulnerability detection (Go projects: mainly check whether `gosec` is enabled in `.golangci.yml`'s `linters.enable`; or `trivy`/`snyk`/`govulncheck`/`Renovate` or Jenkins pipeline security checks) | 2 | code |
| C7 | E2E / integration tests exist (independent directory + non-empty files + corresponding step in CI) | 3 | code |

#### D. Design & change management (15 points)

> **Unified system**: the new devsop.init uses the 10-file DEVSOP system under `.harness/plans/<task>/`; all changes are managed through task artifacts under the plans directory.

| ID | Evaluation item | Full score | Grader |
|----|-----------------|------------|--------|
| D1 | Task directories exist with substantive content (≥1 task directory under `.harness/plans/` with the full 10 files) | 4 | code |
| D2 | `00-overview.md` maintenance activity (a task overview has git updates in the last 90 days) | 4 | code+model |
| D3 | Small-change TDD/regression testing requirements documented + template completeness (`_template/` has the 10 files + TDD explicitly in `.harness/docs/unittest/unittest.md` or `AGENTS.md`; the legacy `.harness/docs/testing.md` counts as pending migration, prompted via the migration anti-pattern) | 4 | code+model |
| D4 | Change-classification standard documented: clearly defines how large/medium/small changes are judged (person-day thresholds, impact scope) and the corresponding process for each | 3 | model |

#### E. Shared knowledge base (5 points)

| ID | Evaluation item | Full score | Grader |
|----|-----------------|------------|--------|
| E1 | The project has a Skills accumulation directory (`.codebuddy/skills/`) with ≥3 SKILL.md files | 2 | code |
| E2 | Knowledge accumulation completeness (any of the following counts as PASS: ① ≥10 docs under `.harness/docs/`; ② README/AGENTS.md links to external team wikis/Confluence/knowledge bases; ③ ≥3 created task dirs under `.harness/plans/`) | 3 | code+model |

#### F. Measurement mechanisms (15 points)

| ID | Evaluation item | Full score | Grader |
|----|-----------------|------------|--------|
| F1 | `.harness/devsop_report.md` exists with improvement tracking records (F1a report exists + not the first time, 2 points / F1b improvement actions recorded, 3 points) | 5 | code+model |
| F2 | AI session/memory/failure-case retention (any of the following counts as PASS): ① the current project's CodeBuddy memory store (`~/.codebuddy/projects/<project path slug>/memory/`, user-level) has ≥3 memory files; ② `logs/ai-sessions/`, `.codebuddy/sessions/`, or CodeBuddy user-level session transcripts (`~/.codebuddy/projects/<slug>/*.jsonl`) have files from the last 30 days; ③ `.harness/docs/failures.md` is in git with commits in the last 90 days | 4 | code |
| F3 | Doc changes traceable: `.harness/` files have git commits in the last 60 days | 3 | code |
| F4 | Improvement loop closed: ≥1 FAIL/PARTIAL item from historical evaluations has been upgraded to PASS (requires ≥2 evaluation records) | 3 | code+model |

> Eval ID namespace is stable; new items append new IDs, never reuse old IDs.

### Step 3: Score calculation and maturity level

**Scoring rules**:

- ✅ PASS: full score
- ⚠️ PARTIAL: 40% of full score (e.g. 5 → 2; 6 → 2.4, rounded)
- ❌ FAIL: 0 points

**Maturity levels**:

| Total score | Level | Name | One-line positioning |
|-------------|-------|------|----------------------|
| 0-19 | L0 | **No DEVSOP** | the project has only source code and scattered docs; team/AI collaboration is entirely word-of-mouth |
| 20-39 | L1 | **Basic constraints** | has AGENTS.md/README, basic lint, but gates and processes are missing |
| 40-59 | L2 | **Gates established** | CI + PreCommit + design flow starting to land, but the feedback loop is not closed |
| 60-79 | L3 | **Closed-loop flow** | the six pillars are basically complete, the feedback mechanism runs continuously, team + AI collaborate efficiently |
| 80-100 | L4 | **Continuous optimization** | measurement-driven improvement, docs/regulations iterate continuously, can be exported as a team exemplar |

### Step 4: Anti-pattern detection (mandatory, independent of scoring)

Even with a decent total score, scan the table below for anti-patterns. Any hit must be highlighted red in the report; it does not affect pillar scores but is emphasized in the "Core Conclusions".

| Anti-pattern | Detection method | Risk |
|--------------|------------------|------|
| Docs severely out of sync with code (files under `.harness/` not updated in >60 days) | `git log --since='60 days ago' -- .harness/` | AI generates code from stale constraints |
| Excessive test mocking (>20 mock files and no integration test files) | `find . -name '*_mock*.go' \| wc -l` + `find . -path '*/integration*' -name '*_test.go' \| wc -l` | AI gets distorted feedback |
| Sensitive files or artifacts committed (`*.env`, `*.key`, `vendor/`, `dist/`, `node_modules/`) | `git ls-files \| grep -E ...` | directly violates DEVSOP prohibitions |
| Important decisions only in commit messages / conversation history, not captured in docs | spot-check 5 recent large PR commit messages for spec/issue-tracker ticket references (`--story=` / `--bug=` / `#<id>`) | AI cannot trace constraints |
| `failures.md` long empty or only placeholder | `wc -l .harness/docs/failures.md` and no modifications in 90 days | the feedback mechanism exists in name only |
| `AGENTS.md` shallow (only project intro, no prohibitions/regulations index) | line count + chapter keyword check | AI has no effective constraint signals |
| Legacy harness residue not migrated (the new specs-devsop switched to the hidden `.harness/` + new doc names) | `ls -d harness/` hits a non-hidden legacy dir; or legacy files exist such as root `ARCHITECTURE.md`, `.harness/docs/dependency-map.md`, `.harness/docs/testing.md`, `.harness/plan.md` | the legacy layout is incompatible with the new devsop.init; the AI entry index may point to wrong paths; evaluation must be judged separately against the legacy layout |

### Step 5: Generate the report and write `.harness/devsop_report.md`

Render per `references/devsop-report-template.md`, **overwrite-writing `.harness/devsop_report.md` directly** (create the directory if missing).

The report contains the following sections (fixed order):

1. Meta info (project name, evaluation date, evaluator, DEVSOP version)
2. Overview score table (six-pillar scores + total + level + red/yellow/green blocks)
3. Capability Eval details (28-item detail table grouped A-F)
4. Anti-pattern detection results
5. Entropy management evaluation (doc freshness, test mock ratio, failures.md activity)
6. Prioritized improvement suggestions (high/medium/low priority; each references an Eval ID + gives an executable action + expected benefit; see `references/devsop-improvement-examples.md`)
7. Upgrade roadmap (key milestones from the current L? to L?+1)
8. Core conclusions (3-4 sentence summary)
9. **Todo Suggestions table** (right after core conclusions; extract 3-7 directly actionable items from the suggestions, two columns: `Todo title` / `Improvement plan`, for frontend parsing or direct conversion to issue-tracker tickets)

---

## Step 1: Parse user arguments

Parse the following optional flags from `$ARGUMENTS`:

- `--dry-run`: run the full scan and scoring but **do not write** `.harness/devsop_report.md`; only print the report to the console
- `--diff-from=<path>`: compare against a historical report (default: compare `.harness/devsop_report.md`'s previous evaluation), outputting "which items rose/fell vs last time" for tracking improvement. **Eval ID asymmetry handling**: if the new and old reports have different eval-schema versions (e.g. the old version lacks an Eval ID), new items are marked "new, no historical comparison", removed items are excluded from the comparison, and only IDs present in both are compared for rise/fall.
- `--only=<pillar>`: evaluate only the specified pillars (e.g. `--only=A,C` evaluates only AI-friendliness and quality gates), for quick re-testing of an improvement
- `--no-anti-patterns`: skip anti-pattern detection (not recommended; only for quick trial runs)
- `--json`: after generating the `.harness/devsop_report.md` report, additionally launch a sub-agent to extract the total score, each pillar score, and Todo Suggestions from the report, generate a structured JSON file (with scores + improvement tasks) to a temp directory, and finally return the file path (see Step 6)
- `--json-only`: **do not evaluate**; skip Steps 2-5 and directly extract data from the existing `.harness/devsop_report.md` to generate JSON. If the report file does not exist, print an error and exit (see Step 6)

**Three run modes**:

| Mode | Args | Behavior |
|------|------|----------|
| Report only (default) | no `--json`, no `--json-only` | run Steps 2-5, generate/update `.harness/devsop_report.md` |
| Report + JSON | `--json` | run Steps 2-5 to generate the report, then run Step 6 to generate JSON |
| JSON only | `--json-only` | skip Steps 2-5, directly run Step 6 to generate JSON from the existing report |

> `--json-only` and `--json` are mutually exclusive; when both are passed, `--json-only` takes precedence (no evaluation).
> `--json-only` is mutually exclusive with evaluation args like `--dry-run`/`--only`/`--no-anti-patterns`; when passed together, the evaluation args are ignored with a Warning.

Unrecognized args are preserved as-is and noted in the report header Warning section.

---

## Step 2: Environment detection (main agent, upfront)

> **`--json-only` mode**: skip Steps 2-5, go directly to Step 6.

**Prerequisite**: confirm paths are resolved (Steps A + B already ran at Skill startup; this is a defensive check only).

```bash
# Defensive check: ensure REPO_ROOT and SKILL_DIR are resolved
[ -z "$REPO_ROOT" ] && REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
[ -z "$SKILL_DIR" ] && echo "⚠️ SKILL_DIR not resolved, check the Skill startup steps" >&2
```

All subsequent scan commands run under `$REPO_ROOT`; references/scripts are always read via the `$SKILL_DIR` absolute path.

### 2.1 Basic detection

Run in parallel:

1. `ls` detects the existence of DEVSOP standard files (AGENTS.md / README.md / `.harness/docs/architecture.md` / `.harness/` / symlinks; note that in the new specs-devsop the architecture doc is under `.harness/docs/`; a root-level ARCHITECTURE.md counts as legacy residue)
2. Identify the language stack (per the Step 0 signal file table)
3. Commands like `git log -1 --format=%cI -- .harness/` for doc freshness

### 2.2 Build the Evidence Cache (key optimization)

**Purpose**: avoid 6 sub-agents re-running the same commands. The main agent collects shared evidence once and injects it into sub-agent contexts.

**Script**: `$SKILL_DIR/scripts/collect_evidence.sh`

```bash
cd "$REPO_ROOT" && bash "$SKILL_DIR/scripts/collect_evidence.sh"
```

The script outputs structured segmented text (`=== FILE_EXISTS ===`, `=== DIR_EXISTS ===`, `=== GIT_RECENCY ===` etc.). The main agent injects the full output into each sub-agent's prompt (section name: `# Evidence Cache`). Sub-agents consult the Cache first and only run commands themselves when the Cache lacks the data.

Output the detection-result matrix before entering Step 3.

---

## Step 3: 28-item Eval scan (parallel sub-agents recommended)

**Recommended architecture**: one sub-agent per pillar (6 total, `run_in_background: true`), each responsible for the 3-7 Eval items in its pillar.

### 3.1 Sub-agent prompt framework

```text
You are the DEVSOP evaluation sub-agent, responsible for the <N> Eval items (<ID list>) of pillar <X. pillar name>.

# Input
- Repository root (working dir): <actual absolute $REPO_ROOT injected by the main agent> (the main agent has already cd'd there)
- Scoring criteria: <actual absolute $SKILL_DIR injected by the main agent>/references/devsop-scoring-criteria.md (read only the chapter for your pillar)
- Improvement suggestion library: <actual absolute $SKILL_DIR injected by the main agent>/references/devsop-improvement-examples.md (read only the chapter for your pillar)
- Project language stack: <injected by the main agent>
- Project type: <injected by the main agent: service / library / cli / monorepo>
- **Tool-agnostic guidance (CI / Issue Tracker / dependency management)**: the DEVSOP framework does not mandate a specific tool stack. Improvement suggestions must stay consistent with the project's existing tools (e.g. Jenkins / GitHub Actions / GitLab CI / TAPD / GitHub Issues / Jira / Renovate / Dependabot) — do not force or forbid any specific platform.
  - **CI (C2/C6/C7)**: the improvement path must be ① check a CI config into the repo root (`.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, etc., with stages: Build → Lint → UnitTest → Coverage → Integration / Security); ② write clickable pipeline URLs in `.harness/docs/devops/development.md`. Evidence scanning checks any of `Jenkinsfile` / `Jenkinsfile.*` / `jenkins/` / `.jenkins/` / `.github/workflows/` / `.gitlab-ci.yml` first.
  - **Issue Tracker (B3/C4/F4)**: all suggestions of the "task list / ticket reference / defect tracking / requirements management" type must land on the team-designated issue tracker (default example: GitHub Issues). MR/commit message ticket references use the team's convention, e.g. `--story=<id>` / `--bug=<id>` or GitHub-style `#<id>`. Evidence scanning checks tracker references (`--<kind>=<id>`, `#<id>`, or tracker URLs) in the project.
  - **Dependency management (C6)**: recommend whichever dependency-update tool the project already uses (Renovate, Dependabot, etc.); do not force one.

# Evidence Cache (pre-collected by the main agent; use it first to avoid duplicate IO)

<the full Step 2.2 output injected by the main agent>

⚠️ Usage rules:
- Use data already in the Cache directly; **do not re-run the same commands**
- Only run new commands when the Cache lacks the data or deeper detection is needed (e.g. file content quality judgment)
- If an Eval item is marked N/A due to project type, skip it without evaluating

⚠️ Path constraints (strictly distinguish the two directories):
- $REPO_ROOT = project repo root → scan evidence by reading files only under this directory
- $SKILL_DIR = Skill install dir → only read references/ and scripts/
- Forbidden: writing any file to $SKILL_DIR / $HOME / ~/.codebuddy/
- Do not confuse: references/ under $SKILL_DIR is the scoring criteria, not project docs; files under $REPO_ROOT are the evaluation targets

# Steps

1. Read the chapter for your pillar in the scoring criteria; understand each Eval's judgment logic, commands, and PARTIAL boundaries

2. For each Eval:
   a. Run commands to collect evidence with "Code Grader first":
      - ls / cat / grep / find / wc -l / git log
      - Do not deeply traverse the whole repo; only read necessary files
   b. Give PASS / PARTIAL / FAIL per the scoring criteria
   c. Evidence ≤3 lines, must include concrete paths or command-output fragments

3. For FAIL/PARTIAL items, look up the matching improvement suggestion in devsop-improvement-examples.md;
   if no match, generate an executable improvement action with the model (must be of the form "add section Y to file X" / "configure tool Z"),
   empty phrases like "should strengthen X" are not allowed.

4. Output the structured result (do not write to disk):
   {
     "pillar": "C",
     "score": 16.4,
     "max": 25,
     "evals": [
       {"id": "C1", "result": "PARTIAL", "evidence": "...", "grader": "code", "improvement": "..."},
       ...
     ],
     "anti_patterns_observed": [...] // only record anti-pattern signals relevant to your pillar
   }

# Constraints
- Read-only; no file writes / git add / git commit
- Do not read .git/, node_modules/, vendor/, bin/, logs*/, dist/, build/
- When evidence is missing, prefer FAIL; never fabricate paths
- When evaluation confidence is low (e.g. purely subjective judgment), append "(confidence: low)" at the end of the evidence
```

### 3.2 Parallel control

- Launch all 6 sub-agents at once (multiple Agent tool calls in one message, `run_in_background: true`)
- The main agent gathers all pillar results with TaskOutput
- If any sub-agent fails → that pillar is marked `EVAL_FAILED`, scores 0, without blocking other pillars

---

## Step 4: Main agent aggregation

1. Sum the six pillar scores → total → map to a maturity level (per the Step 3 table)
2. Merge cross-pillar anti-pattern signals + the main agent runs its own anti-pattern detection once (so it does not depend on sub-agents)
3. Calculate entropy metrics:
   - `.harness/` file freshness: take each file's last commit time and compute the **median** days-to-today
     ```bash
     for f in $(find .harness -name '*.md' 2>/dev/null); do
       [ -f "$f" ] && git log -1 --format='%ct' -- "$f" 2>/dev/null
     done | sort -n | awk '{a[NR]=$1} END{print a[int(NR/2)+1]}'
     ```
     Use the median rather than the mean, to avoid one frequently-updated file masking other stale files
   - Mock and integration-test health = combined judgment:
     - `find . -name '*_mock*.go' -o -name '*mock*.go' | wc -l` (mock file count)
     - `find . -path '*/integration*' -name '*_test.go' -o -path '*/e2e*' -name '*_test.go' | wc -l` (integration test file count)
     - criteria: mock files >20 and integration test files =0 → 🔴 over-mocking; integration tests exist → 🟢
   - `failures.md` activity = `git log --since='90 days ago' -- .harness/docs/failures.md | wc -l`
4. Aggregate improvement suggestions by priority: FAIL items → high priority; PARTIAL items → medium priority; anti-patterns → high priority
5. Distill Todo Suggestions (3-7 items, chosen from the suggestions as independently actionable + completable within a week)

---

## Step 5: Render and write `.harness/devsop_report.md`

- Fill in per `$SKILL_DIR/references/devsop-report-template.md`
- Write path: `$REPO_ROOT/.harness/devsop_report.md` (**direct overwrite**; git keeps version history)
- If `$REPO_ROOT/.harness/` does not exist → create it (and prompt the user "the project has not run devsop.init")
- `--dry-run` mode: no disk write; print the full report to the console only

After writing, append a console hint line:

```
✅ DEVSOP evaluation complete
   Total: 72/100  Level: L3 closed-loop flow
   Report: .harness/devsop_report.md
   High-priority improvements: 3 / Anti-patterns: 1
   Next recommended evaluation: after 90 days or the next major process change
```

---

## Step 6: JSON output (`--json` or `--json-only` mode)

This step runs when the user passes `--json` or `--json-only`.

**Pre-checks (`--json-only` mode)**:

```bash
# Ensure cwd is at the project repo root (--json-only skips Step 2; depends on the cd at Skill startup)
[ -z "$REPO_ROOT" ] && REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# Check the report file exists (use the absolute path)
ls "$REPO_ROOT/.harness/devsop_report.md"
```

If the file does not exist, print an error and exit:
```
❌ .harness/devsop_report.md does not exist
   Run devsop.eval first (without --json-only) to generate the evaluation report, or confirm the report file path is correct.
```

**Report source determination**:

| Mode | Report source |
|------|---------------|
| `--json` (normal) | the `.harness/devsop_report.md` just written in Step 5 |
| `--json` + `--dry-run` | the main agent writes the report content to a temp file `$TMPDIR/devsop_report.md`; the sub-agent reads from that temp file |
| `--json-only` | the existing `.harness/devsop_report.md` (no evaluation) |

### 6.1 Launch a sub-agent to generate JSON

Use the Agent tool to launch a sub-agent responsible for extracting score data and Todo Suggestions from the report and generating a structured JSON file.

**Sub-agent prompt framework**:

```text
You are the DEVSOP report JSON conversion agent. Your task is to extract the total score, each pillar score, and Todo Suggestions from the generated DEVSOP evaluation report and generate a structured JSON file.

# Input
- Report file path: <actual $REPO_ROOT injected by the main agent>/.harness/devsop_report.md
- SKILL_DIR: <actual absolute $SKILL_DIR injected by the main agent>
- Working dir: already switched to $REPO_ROOT (the project repo root, not the Skill install dir)

⚠️ Path constraints:
- Read the report with $REPO_ROOT/.harness/devsop_report.md
- Read the validation script with $SKILL_DIR/scripts/validate_todo_json.py
- Forbidden: writing files to $SKILL_DIR / $HOME / ~/.codebuddy/

# Steps

## Step 1: Locate the content sources

**Extract score data**: read the "overview score" table and the "maturity level" section of the report; extract the total score, each pillar score, and level info.

**Extract Todos (HTML marker location preferred, full-text fallback)**:

**Path A (preferred): grep for HTML markers**

```bash
grep -n "DEVSOP_TODOS_START\|DEVSOP_TODOS_END" "$REPO_ROOT/.harness/devsop_report.md"
```

If grep finds both `DEVSOP_TODOS_START` and `DEVSOP_TODOS_END`, extract the content between the two markers (a Markdown table) as the todos input.

**Path B (fallback): grep the heading text**

If the HTML markers do not exist (old-version reports), fall back to `grep -n "Todo Suggestions"` to locate the section heading, then read its content until the next `---` or the end of the file.

**Path C (final fallback): read the full report**

If neither Path A nor B hits, read the full report and do full-text semantic understanding in Step 2.

## Step 2: Extract scores + Todos and generate JSON

Extract the total score, each pillar score, and Todo Suggestions from the report, generating JSON in the following format:

```json
{
  "schema_version": "2.0",
  "project_type": "service",
  "total_score": 72,
  "max_score": 100,
  "effective_max_score": 100,
  "level": "L3",
  "level_name": "closed-loop flow",
  "pillars": [
    {"id": "A", "name": "Project AI-friendliness", "score": 22, "max": 25},
    {"id": "B", "name": "Dev mode / role collaboration", "score": 11, "max": 15},
    {"id": "C", "name": "Quality checks & feedback mechanisms", "score": 17, "max": 25},
    {"id": "D", "name": "Design & change management", "score": 12, "max": 15},
    {"id": "E", "name": "Shared knowledge base", "score": 3, "max": 5},
    {"id": "F", "name": "Measurement mechanisms", "score": 7, "max": 15}
  ],
  "todos": [
    {
      "title": "Add commit / push conventions to AGENTS.md",
      "solution": "Add the commit message format, pre-commit build+lint+test checks, and post-push MR flow conventions to the '§2 DEVSOP' section of AGENTS.md, referencing Eval C1"
    },
    {
      "title": "Activate the failures.md pitfall records",
      "solution": "Add 3 typical recent issues to .harness/docs/failures.md this week, referencing Eval C5"
    }
  ]
}
```

**Top-level field descriptions**:
- `schema_version`: the Eval Schema version (consistent with the declaration at the top of SKILL.md), used for cross-version comparison compatibility
- `project_type`: project type (`service` / `library` / `cli` / `monorepo`), affects exemption logic
- `total_score`: the total score (0-100 numeric, already normalized to a percentage against effective_max_score)
- `max_score`: the full score, fixed at 100
- `effective_max_score`: the actual effective full score (the base after deducting N/A exemptions, e.g. 94 for a library project)
- `level`: the maturity level code (L0 / L1 / L2 / L3 / L4)
- `level_name`: the level name (no DEVSOP / basic constraints / gates established / closed-loop flow / continuous optimization)
- `pillars`: the six-pillar score array; each item has `id` (A-F), `name`, `score`, `max`
- `todos`: the improvement task list array

**todos field descriptions**:
- `title`: the task title, concise and actionable (≤30 chars)
- `solution`: the improvement plan, concrete operational steps (≤100 chars)

**Score extraction rules**:
- Extract the total score and each pillar score from the report's "overview score" table
- Extract level and level_name from the "maturity level" section
- Values must match the report; no re-calculation or estimation

**Todo semantic handling rules (Path A: from the Todo Suggestions table)**:
- Keep all improvement items in the original table; do not add or remove
- Clean up the content appropriately (remove extra whitespace, Markdown format symbols, etc.) without changing the meaning
- If a table row is incomplete (missing title or plan), skip that row

**Todo semantic handling rules (Path B: from full-text semantic understanding)**:
- Focus on: FAIL / PARTIAL items in the scoring details, prioritized improvement suggestions, issues in anti-pattern detection, high-risk items in the entropy management evaluation
- Distill 3-7 of the most valuable executable improvements

## Step 3: Format validation (loop until passing)

Write the generated JSON to a temp file, then run the validation script:

```bash
# create a temp directory
TMPDIR=$(mktemp -d)
echo '<generated JSON content>' > "$TMPDIR/devsop_todo.json"

# run the validation script (located in $SKILL_DIR, independent of whether the skill is user- or project-level installed)
python3 "$SKILL_DIR/scripts/validate_todo_json.py" "$TMPDIR/devsop_todo.json"
```

**Validation rules** (enforced by the script):
- The top-level structure must be a JSON object
- Must contain `total_score` (numeric 0-100), `max_score` (fixed 100), `level` (string L0-L4), `level_name` (non-empty string), `pillars` (array), `todos` (array)
- `pillars` must have 6 elements, each with `id` (A-F), `name` (non-empty string), `score` (numeric ≥0), `max` (numeric >0) and score ≤ max
- `todos` length between 1 and 20, each element containing only the two non-empty string fields `title` and `solution`

**If validation fails**: fix the JSON per the error message, re-validate, until it passes.

## Step 4: Output the result

After validation passes, output the temp file path:

```
✅ JSON generated
   File path: <TMPDIR>/devsop_todo.json
   Total: <total_score>/100  Level: <level> <level_name>
   Improvement tasks: <N>
```

# Constraints
- Read the report file only; do not modify any source code
- The JSON must pass the validation script
- Score data must match the report; no estimation
- Empty or extra fields are not allowed
```

### 6.2 Main agent reporting

After the sub-agent completes, the main agent prints supplementary output to the console:

```
📄 JSON report generated
   Path: /tmp/xxx/devsop_todo.json
   Total: 72/100  Level: L3 closed-loop flow
   Improvement tasks: N
   Ready for frontend parsing or importing into the task system
```

---

## Evaluation Guardrails

- **Read-only audit** — no source code, config, or regulation file is modified throughout; writes are limited to `.harness/devsop_report.md` and the temp directory in `--json` mode
- **Evidence first** — every Eval item must have a file path or command output; no evidence → FAIL; do not rely on "I feel"
- **Code Grader first** — anything determinable with `ls`/`grep`/`git log` must not go to the model
- **Honest scoring** — PARTIAL is a legitimate expression of the real state; do not fake PASS for "nicer numbers"
- **Executable improvements** — every suggestion must translate into concrete actions such as `mkdir`/`touch`/`echo`/`configure tool`/`add section`
- **DEVSOP perspective** — always evaluate from "does the project comply with the team DEVSOP v1.0", not the quality of the code itself
- **Anti-patterns mandatory** — even with a high overall score, scan and mark them clearly in the conclusions
- **Never commit unilaterally** — after the report is written, the user reviews it before committing; this Skill never runs `git add` / `git commit`

---

## Output Example (abridged)

```
Project: did-mgr-backend
Evaluation date: 2026-05-18
DEVSOP version: v1.0

Total: 72 / 100   Level: L3 closed-loop flow

Pillar scores:
  A. Project AI-friendliness      22 / 25  🟢
  B. Dev mode / role collaboration  11 / 15  🟢
  C. Quality checks & feedback     17 / 25  🟡
  D. Design & change management    12 / 15  🟢
  E. Shared knowledge base          3 / 5   🟢
  F. Measurement mechanisms        7 / 15  🟡

Anti-patterns:
  🔴 .harness/docs/failures.md not updated for 60+ days (feedback mechanism not running)
  🟢 the other 5 items not found

High-priority improvements (3):
  1. C5 - activate failures.md: add 3 recent pitfall records this week
  2. F1 - update devsop_report.md regularly: add the devsop report to the monthly review agenda
  3. C1 - memorize commit/push conventions: add commit message format + pre-commit checks + push flow conventions to AGENTS.md

Report: .harness/devsop_report.md
```

---

## Integration with Other Skills

### Relationship with `devsop.init`

- `devsop.init` (new specs-devsop): builds the `.harness/` DEVSOP system from scratch (creates the four-chapter AGENTS.md entry + `.harness/docs/` regulations library + `.harness/plans/` task templates + symlinks)
- `devsop.eval` (this Skill): evaluates the output of devsop.init and the quality of subsequent maintenance
- Recommended order: `devsop.init` first to build the skeleton → `devsop.eval` to run a baseline → then monthly `devsop.eval --diff-from=...` to track improvement

> `devsop.init` explicitly leaves `.harness/devsop_report.md` for this Skill to create.

### CI integration (optional)

> This section is tool-agnostic — any CI platform (Jenkins, GitHub Actions, GitLab CI, etc.) works.

- Add a stage in the project's CI pipeline to call `devsop.eval --dry-run`, writing the score into build logs / archiving as a `.harness/devsop_report.md` artifact
- When the total score drops below a threshold (e.g. 60), mark the build with `currentBuild.result = 'UNSTABLE'` (avoid rigid gates that freeze the flow; do not use FAILURE)
- Recommended with build-artifact retention (`archiveArtifacts '.harness/devsop_report.md'`) to keep historical evaluation comparisons

---

## Related Materials

- Detailed scoring criteria: `references/devsop-scoring-criteria.md`
- Report template: `references/devsop-report-template.md`
- Improvement suggestion examples: `references/devsop-improvement-examples.md`
