---
name: devsop-eval
description: "Audits how well a project implements the DEVSOP standard and writes a scored report (six pillars, maturity level L0-L4, anti-patterns, improvement todos) to .docs/devsop_report.md. Use for baseline evaluation after devsop-init, monthly compliance reviews, or cross-project maturity benchmarking."
disable-model-invocation: true
---

# devsop-eval

**Eval Schema version**: `2.0` (28 Eval items, stable ID namespace. Adapted to the `.docs/` artifact system of the new devsop-init. New Eval items append new IDs; the version number increments. `--diff-from` comparison must check version consistency.)

## User Input

```text
$ARGUMENTS
```

## Overview

Perform a **read-only audit** of the current project against the team R&D DEVSOP v1.0, quantify compliance (six pillars / 28 Eval items), generate actionable improvements, and write the report to `.docs/devsop_report.md` (checked into the repo for team review). Three modes: **report-only** (default) / **report+JSON** (`--json`) / **JSON-only** (`--json-only`).

> **This Skill is self-contained**: the evaluation criteria are embedded below; no external DEVSOP document is needed. When the DEVSOP version evolves, update this SKILL.md and `references/devsop-scoring-criteria.md` together.

---

## Path Variable Definitions (prevent mis-writes)

| Variable | Meaning | How it is resolved | Usage |
|----------|---------|--------------------|-------|
| `$SKILL_DIR` | this Skill's install dir (the agent-agnostic standard locations: user-level `~/.agents/skills/devsop-eval`, or repo-level `<repo>/.agents/skills/devsop-eval`) | the directory containing this SKILL.md (usually injected by the agent as the `$SKILL_DIR` env var; otherwise the candidate scan below) | **read-only**: read references/ and scripts/ |
| `$REPO_ROOT` | current project repo root | `git rev-parse --show-toplevel`, falling back to cwd on failure | **read/write**: scan evidence + write `.docs/devsop_report.md` |

Hard constraints:
- The output file `.docs/devsop_report.md` **must** be written to `$REPO_ROOT`; writing to `$SKILL_DIR` / `$HOME` is forbidden
- Scoring/scanning commands (`ls` / `grep` / `git log`) **must** run under `$REPO_ROOT`
- Reading templates/scripts must use `$SKILL_DIR/...`; hardcoding a skills path is forbidden
- **Path resolution**: run `eval "$(bash "$SKILL_DIR/scripts/resolve_paths.sh")"` at Skill startup (fallback scan over the `~/.agents/` standard locations when the agent did not inject `$SKILL_DIR`). All subsequent `$SKILL_DIR` references must use the absolute path; relative paths are forbidden.

---

## When to Use This Skill

- Baseline evaluation after `devsop-init` sets up the `.docs/` structure
- Monthly DEVSOP freshness review; after introducing new dev processes or tooling changes
- Cross-project maturity benchmarking with unified scoring
- Converting an existing report to JSON (`--json-only`)

---

## Evaluation Dimensions (self-contained · six pillars · total 100)

The schema is adapted to the `.docs/` artifact system: the regulations library lives under `.docs/` (`architecture.md` / `relationship.md` / `coding-style.md` / `code-review.md` / `glossary.md` / `failures.md` / `logging.md` / `unittest/` / `integration_test/` / `apis/` / `sqls/` / `devops/`); the top level keeps only `.docs/review.md` + `.docs/plans/`. The six-pillar index (items, weights, core questions) is in Step 2 below; the complete per-item judgment logic is in `references/devsop-scoring-criteria.md`.

---

## Evaluation Flow (5 steps)

### Step 0: Detect the project language stack and project type

**Detect the language stack** (decides which files to scan; mixed stacks scan each toolchain separately):

| Signal file | Language | Toolchain to watch |
|-------------|----------|--------------------|
| `go.mod` / `*.go` | Go | `.golangci.yml`, `*_test.go`, `Makefile`, `go vet` |
| `package.json` / `tsconfig.json` | JS/TS | `.eslintrc*`, `*.test.*`, `vitest`/`jest` |
| `pyproject.toml` / `requirements.txt` | Python | `ruff`/`pylint`, `pytest` |
| `Cargo.toml` | Rust | `clippy`, `#[test]` |
| `pom.xml` / `build.gradle` | Java | `checkstyle`, `*Test.java` |

**Detect the project type** (decides exemptions; run `cd "$REPO_ROOT" && bash "$SKILL_DIR/scripts/detect_project_type.sh"` → `PROJECT_TYPE=`):

| Signal | Type | Exemption |
|--------|------|-----------|
| `cmd/` or `main.go` + HTTP handler/router code | **service** | none (default) |
| `go.mod` but no `main.go`/`cmd/`, only exported packages | **library** | A6 (one-command start), C7 (E2E → examples/benchmarks) |
| `main.go` but no HTTP handlers; cobra/flag CLI | **cli** | A6 (→ `make build`), C7 (→ integration scripts) |
| multiple `go.mod` / root `packages/` with per-dir entry points | **monorepo** | none; note "evaluate each sub-module separately" |

**Exemption rules**: exempted items are marked `N/A` (reason noted); their full score is deducted from the total base (e.g. library exempts A6+C7 → base 94; percentage thresholds unchanged, only the base adjusts).

### Step 1: Collect raw evidence (three-layer Grader priority)

1. **Code Grader** (deterministic): file existence, command output, config completeness. **Use first.**
2. **Model Grader** (subjective): doc quality, regulation depth, constraint clarity.
3. **Manual marking** (high cost): only when the first two cannot judge; mark the item "evaluation confidence: low".

### Step 2: Run the 28 Capability Eval items one by one

Score the six pillars item by item. Record for each:

- **Conclusion**: ✅ PASS / ⚠️ PARTIAL / ❌ FAIL
- **Evidence**: concrete file path / command output / doc excerpt (≤3 lines)
- **Grader**: code / model / manual

**28-item Eval index** (full per-item judgment logic, commands, and PARTIAL boundaries are in `references/devsop-scoring-criteria.md` — the sub-agents read only their pillar's chapter):

| Pillar | Items | Full score | Core question |
|--------|-------|-----------|---------------|
| A. Project AI-friendliness | A1–A7 | 25 | Can AI/newcomers get the project running and understand its structure within 30 minutes? |
| B. Dev mode / role collaboration | B1–B4 | 15 | Is there a clear R&D process definition with per-phase deliverables? |
| C. Quality checks & feedback mechanisms | C1–C7 | 25 | Do key checkpoints have gates that can block bad code from merging? |
| D. Design & change management | D1–D4 | 15 | Do large/medium/small changes have matching design processes and doc artifacts? |
| E. Shared knowledge base | E1–E2 | 5 | Is there reusable knowledge accumulated across teams/projects? |
| F. Measurement mechanisms | F1–F4 | 15 | Does the project have a self-measurement and continuous-improvement loop? |

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
| Docs severely out of sync with code (files under `.docs/` not updated in >60 days) | `git log --since='60 days ago' -- .docs/` | AI generates code from stale constraints |
| Excessive test mocking (>20 mock files and no integration test files) | `find . -name '*_mock*.go' \| wc -l` + `find . -path '*/integration*' -name '*_test.go' \| wc -l` | AI gets distorted feedback |
| Sensitive files or artifacts committed (`*.env`, `*.key`, `vendor/`, `dist/`, `node_modules/`) | `git ls-files \| grep -E ...` | directly violates DEVSOP prohibitions |
| Important decisions only in commit messages / conversation history, not captured in docs | spot-check 5 recent large PR commit messages for spec/issue-tracker ticket references (`--story=` / `--bug=` / `#<id>`) | AI cannot trace constraints |
| `failures.md` long empty or only placeholder | `wc -l .docs/failures.md` and no modifications in 90 days | the feedback mechanism exists in name only |
| `AGENTS.md` shallow (only project intro, no prohibitions/regulations index) | line count + chapter keyword check | AI has no effective constraint signals |
| Code changes without task planning (unplanned edits): frequent code commits but `.docs/plans/` has no new task dirs in the same window | compare `git log --since='30 days ago' --oneline --name-only` (code files) vs `find .docs/plans -maxdepth 1 -type d -not -name '_template' -newermt '30 days ago'` | process discipline broken: agents edit code directly without clarify/plan artifacts |
| Skills present but never triggered (skill files exist, yet sessions/commits show no skill usage) | `.agents/skills/` has SKILL.md files + `git log --since='60 days ago' --grep='devsop'` empty | the skill library is decoration; the activation loop is broken |

### Step 5: Generate the report and write `.docs/devsop_report.md`

Render per `references/devsop-report-template.md`, **overwrite-writing `.docs/devsop_report.md` directly** (create the directory if missing). The report has 9 fixed sections: meta info → overview score → 28-item details → anti-patterns → entropy management → prioritized improvements (see `references/devsop-improvement-examples.md`) → upgrade roadmap → core conclusions → **Todo Suggestions table** (3-7 directly actionable items: `Todo title` / `Improvement plan`, for frontend parsing or issue-tracker conversion).

---

## Step 1: Parse user arguments

| Flag | Behavior |
|------|----------|
| `--dry-run` | full scan + scoring, but do **not** write `.docs/devsop_report.md`; print to console only |
| `--diff-from=<path>` | compare against a historical report (default: the report's previous evaluation) and output rise/fall per Eval ID; IDs absent in the old schema are marked "new, no historical comparison" |
| `--only=<pillar>` | evaluate only the given pillars (e.g. `--only=A,C`) for quick re-testing of an improvement |
| `--no-anti-patterns` | skip anti-pattern detection (not recommended; only for quick trial runs) |
| `--json` | after generating the report, also produce structured JSON (scores + todos) to a temp dir via the Step 6 sub-agent |
| `--json-only` | **no evaluation**; convert the existing `.docs/devsop_report.md` to JSON directly (error if the report is missing) |

**Modes**: report-only (default) / report+JSON (`--json`) / JSON-only (`--json-only`). `--json-only` takes precedence over `--json` and ignores evaluation args with a Warning. Unrecognized args are preserved and noted in the report header.

---

## Step 2: Environment detection (main agent, upfront)

> **`--json-only` mode**: skip Steps 2-5, go directly to Step 6. All scan commands run under `$REPO_ROOT`; references/scripts are read via the `$SKILL_DIR` absolute path.

### 2.1 Basic detection (run in parallel)

1. `ls` the DEVSOP standard files (AGENTS.md / README.md / `.docs/architecture.md` / `.docs/`)
2. Identify the language stack (per the Step 0 signal file table)
3. Doc freshness: `git log -1 --format=%cI -- .docs/`

### 2.2 Build the Evidence Cache (key optimization)

Collect shared evidence once and inject it into all sub-agents (avoids 6× duplicate IO):

```bash
cd "$REPO_ROOT" && bash "$SKILL_DIR/scripts/collect_evidence.sh"
```

The script outputs segmented text (`=== FILE_EXISTS ===`, `=== DIR_EXISTS ===`, `=== GIT_RECENCY ===` ...). The main agent injects the full output into each sub-agent's prompt as the `# Evidence Cache` section; sub-agents consult the Cache first and run new commands only when the Cache lacks data. Output the detection-result matrix before entering Step 3.

---

## Step 3: 28-item Eval scan (parallel sub-agents recommended)

**Recommended architecture**: one sub-agent per pillar (6 total, all launched in parallel), each responsible for the 3-7 Eval items in its pillar.

### 3.1 Sub-agent dispatch

- The complete pillar-evaluation sub-agent prompt framework is in **`references/subagent-prompts.md`** (Prompt 1). The main agent injects `$REPO_ROOT` / `$SKILL_DIR` absolute paths, the language stack, the project type, and the Step 2.2 Evidence Cache output into the placeholders.
- Each sub-agent reads only its pillar's chapter of `devsop-scoring-criteria.md` and `devsop-improvement-examples.md`, and returns a structured JSON result (pillar / score / per-item evidence / anti-pattern signals) without writing to disk.

### 3.2 Parallel control

- Launch all 6 sub-agents at once (multiple sub-agent dispatches in one message, run in parallel)
- The main agent gathers all pillar results from the sub-agents' final outputs
- If any sub-agent fails → that pillar is marked `EVAL_FAILED`, scores 0, without blocking other pillars

---

## Step 4: Main agent aggregation

1. Sum the six pillar scores → total → map to a maturity level (per the Step 3 table)
2. Merge cross-pillar anti-pattern signals + the main agent runs its own anti-pattern detection once (so it does not depend on sub-agents)
3. Calculate entropy metrics:
   - `.docs/` freshness: median of each file's last-commit age (`for f in $(find .docs -name '*.md'); do git log -1 --format='%ct' -- "$f"; done | sort -n | awk ...`) — use the **median**, not the mean, so one hot file cannot mask stale files
   - Mock health: mock files (`find . -name '*_mock*.go' | wc -l`) vs integration tests (`find . -path '*/integration*' -name '*_test.go' | wc -l`): mocks >20 and IT =0 → 🔴 over-mocking
   - `failures.md` activity: `git log --since='90 days ago' -- .docs/failures.md | wc -l`
4. Aggregate improvement suggestions by priority: FAIL items → high priority; PARTIAL items → medium priority; anti-patterns → high priority
5. Distill Todo Suggestions (3-7 items, chosen from the suggestions as independently actionable + completable within a week)

---

## Step 5: Render and write `.docs/devsop_report.md`

- Fill in per `$SKILL_DIR/references/devsop-report-template.md`
- Write path: `$REPO_ROOT/.docs/devsop_report.md` (**direct overwrite**; git keeps version history)
- If `$REPO_ROOT/.docs/` does not exist → create it (and prompt the user "the project has not run devsop-init")
- `--dry-run` mode: no disk write; print the full report to the console only

After writing, print a console summary (Total / Level / Report path / high-priority count / next-evaluation hint).

---

## Step 6: JSON output (`--json` or `--json-only` mode)

**Pre-check (`--json-only`)**: `cd "$REPO_ROOT"` and confirm `.docs/devsop_report.md` exists; if missing, print an error and exit.

**Report source**: `--json` → the report just written in Step 5; `--json`+`--dry-run` → a temp file `$TMPDIR/devsop_report.md`; `--json-only` → the existing report (no evaluation).

### 6.1 Launch a sub-agent to generate JSON

Launch one sub-agent to extract score data and Todo Suggestions from the report and generate structured JSON.

- The complete JSON-conversion sub-agent prompt framework is in **`references/subagent-prompts.md`** (Prompt 2), including the extraction paths (HTML markers → heading grep → full text), the JSON schema, and the validation loop.
- Key contract points the main agent must ensure:
  - The sub-agent validates its output with `python3 $SKILL_DIR/scripts/validate_todo_json.py` and loops until it passes.
  - Score data must match the report verbatim — no recalculation, no estimation.
  - `pillars` must have exactly 6 elements (A–F); `todos` 1–20 items with `title` (≤30 chars) + `solution` (≤100 chars).

### 6.2 Main agent reporting

Print the JSON file path + total/level/task count as the final console output.

---

## Evaluation Guardrails

- **Read-only audit** — no source code, config, or regulation file is modified throughout; writes are limited to `.docs/devsop_report.md` and the temp directory in `--json` mode
- **Evidence first** — every Eval item must have a file path or command output; no evidence → FAIL; do not rely on "I feel"
- **Code Grader first** — anything determinable with `ls`/`grep`/`git log` must not go to the model
- **Honest scoring** — PARTIAL is a legitimate expression of the real state; do not fake PASS for "nicer numbers"
- **Executable improvements** — every suggestion must translate into concrete actions such as `mkdir`/`touch`/`echo`/`configure tool`/`add section`
- **DEVSOP perspective** — always evaluate from "does the project comply with the team DEVSOP v1.0", not the quality of the code itself
- **Anti-patterns mandatory** — even with a high overall score, scan and mark them clearly in the conclusions
- **Never commit unilaterally** — after the report is written, the user reviews it before committing; this Skill never runs `git add` / `git commit`

---

## Rationalizations (excuses that must not fly)

If you catch yourself thinking any of these, STOP — the rebuttal wins:

| Excuse | Rebuttal |
|--------|----------|
| "The project is small / just started, an audit is overkill" | Baseline evaluation is exactly what small projects need — it is cheap now and expensive to retrofit later; F1's first-evaluation special handling already avoids penalizing new projects |
| "I already know roughly how the project looks, no need to run the scans" | The report must contain file paths + command output as evidence; "I feel it's fine" is not evidence, and every Eval needs a Grader record |
| "Some items are subjective, let me give PASS to keep the score friendly" | PARTIAL is a legitimate state; faking PASS corrupts the improvement loop (F4) and hides real debt |
| "The anti-pattern scan looks clean enough, I can skip it" | Anti-patterns are mandatory and independent of the score — a high score with a red anti-pattern is exactly the signal the team needs |
| "I'll write the report to a temp dir to keep the repo clean" | The report's contract location is `.docs/devsop_report.md` in git; anywhere else breaks F1 and the diff-based tracking |
| "The user only asked for a quick check, so --dry-run-ish partial output is fine" | Modes are explicit (`--dry-run` / `--only` / `--json`); silently producing a partial evaluation without the user asking for it is forbidden |
| "One sub-agent failed; let me just estimate its pillar score myself" | A failed sub-agent marks that pillar `EVAL_FAILED` = 0; estimating breaks evidence-first scoring |

---

## Output Example (abridged)

```
Project: did-mgr-backend    Evaluation date: 2026-05-18    DEVSOP version: v1.0
Total: 72 / 100   Level: L3 closed-loop flow
Pillar scores:  A 22/25 🟢  B 11/15 🟢  C 17/25 🟡  D 12/15 🟢  E 3/5 🟢  F 7/15 🟡
Anti-patterns:  🔴 .docs/failures.md not updated for 60+ days
High-priority improvements (3): C5 activate failures.md · F1 monthly eval ritual · C1 commit/push conventions
Report: .docs/devsop_report.md
```

---

## Integration with Other Skills

- **`devsop-init`** builds the `.docs/` system; **`devsop-eval`** measures it. Recommended order: `devsop-init` → baseline `devsop-eval` → monthly `devsop-eval --diff-from=...`. `devsop-init` explicitly leaves `.docs/devsop_report.md` for this Skill to create.
- **CI integration (optional, tool-agnostic)**: add a pipeline stage calling `devsop-eval --dry-run`; mark the build UNSTABLE (not FAILURE) below a threshold (e.g. 60) and archive the report artifact for historical comparison.

---

## Related Materials

- Detailed scoring criteria: `references/devsop-scoring-criteria.md`
- Report template: `references/devsop-report-template.md`
- Improvement suggestion examples: `references/devsop-improvement-examples.md`
