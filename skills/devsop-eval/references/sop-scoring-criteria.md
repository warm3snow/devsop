# DEVSOP Scoring Criteria (detailed judgment logic)

## Contents

- [Pillar A: Project AI-friendliness](#pillar-a-project-ai-friendliness-25-points) — A1–A7
- [Pillar B: Dev mode / role collaboration](#pillar-b-dev-mode--role-collaboration-15-points) — B1–B4
- [Pillar C: Quality checks & feedback mechanisms](#pillar-c-quality-checks--feedback-mechanisms-25-points) — C1–C7
- [Pillar D: Design & change management](#pillar-d-design--change-management-15-points) — D1–D4
- [Pillar E: Shared knowledge base](#pillar-e-shared-knowledge-base-5-points) — E1–E2
- [Pillar F: Measurement mechanisms](#pillar-f-measurement-mechanisms-15-points) — F1–F4
- [Placeholder Template Recognition Rules](#placeholder-template-recognition-rules-basis-for-content-substance-judgment)
- [General PARTIAL Judgment Principles](#general-partial-judgment-principles)
- [Notes for Evaluators](#notes-for-evaluators)

This document provides `devsop-eval` with the judgment criteria, evidence sources, command examples, and PARTIAL boundaries for the 28 Eval items. Read the relevant chapters for each assessment.

> Basis: team AI R&D workflow DEVSOP v1.0
> Score mapping: ✅ PASS = full score, ⚠️ PARTIAL = full score × 40%, ❌ FAIL = 0

---

## Pillar A: Project AI-friendliness (25 points)

### A1: AGENTS.md exists and ≤300 lines + four chapters complete (3 points)

**DEVSOP basis**: §1.1 "AI entry file root AGENTS.md (≤300 lines)" + four-chapter structural completeness

**Code Grader**:
```bash
[ -f AGENTS.md ] && wc -l < AGENTS.md
```

**Model Grader** (chapter check):
```bash
# check four-chapter completeness
grep -c "^## §1 Quick Index" AGENTS.md
grep -c "^## §2 DEVSOP" AGENTS.md
grep -c "^## §3 Dev Guidelines" AGENTS.md
grep -c "^## §4 Forbidden Red Lines" AGENTS.md
```

**Judgment**:
- ✅ PASS: file exists + line count ≤300 + all four chapters (§1 quick index / §2 DEVSOP / §3 dev guidelines / §4 forbidden red lines) present and non-empty
- ⚠️ PARTIAL: file exists but 300-500 lines (near the limit), or file exists but 1-2 of the four chapters missing, or file exists but <30 lines (too shallow)
- ❌ FAIL: does not exist

> Grader type: code (line count) + model (chapter check).

---

### A2: README.md complete (5 points)

**DEVSOP basis**: §1.1 "project introduction README.md: project background and business goals, core feature list, upstream/downstream dependencies, quick start, deployment environment requirements, notes"

**Model Grader**: scan README.md and count whether it covers the following 6 categories:
1. Project background / business goals
2. Core feature list
3. Upstream/downstream dependencies
4. Quick start (commands)
5. Deployment environment requirements
6. Notes / known limitations

**Judgment**:
- ✅ PASS: covers at least 5 of the 6 categories
- ⚠️ PARTIAL: covers 3-4 categories
- ❌ FAIL: covers ≤2 categories, or only a project name + one-line description

---

### A3: .docs/architecture.md complete (5 points)

**DEVSOP basis**: the architecture doc lives at `.docs/architecture.md`. Content requirements: overall architecture diagram, module division and boundaries, data flow, tech selection rationale, core design decisions, known tech debt.

**Model Grader**: scan whether `.docs/architecture.md` covers:
1. Overall architecture diagram (text description or image reference / Mermaid)
2. Module division and boundaries
3. Data flow
4. Tech selection rationale
5. Core design decisions
6. Known tech debt

**Judgment**:
- ✅ PASS: covers at least 5 of the 6, and not a placeholder template (system positioning not `<project name>`, module division table has ≥1 row of valid data, overall view not a generic placeholder diagram)
- ⚠️ PARTIAL: covers 3-4, or the file exists but is still an empty template/placeholder content
- ❌ FAIL: file does not exist or is only a placeholder

> Placeholder recognition: see "Placeholder Template Recognition Rules" at the end.

---

### A4: .docs/ regulations library covers the new core docs (5 points)

**DEVSOP basis**: the new devsop-init's `.docs/` standard layout (§1.2 core docs + subdirectory docs).

**Required core docs (count OK if present and non-placeholder)**:
- `architecture.md` (system positioning/module division/views)
- `relationship.md` (upstream/downstream relationships)
- `coding-style.md`
- `code-review.md`
- `glossary.md`
- `failures.md`
- `logging.md`
- `unittest/unittest.md` (**replaces the old `testing.md`**)
- `integration_test/integration_test.md`

**On-demand subdirectory docs** (may be omitted when the capability is absent; no deduction; a missing one is only noted in the report):
- `apis/index.md` + `apis/api-standards.md` — may be omitted for projects without external APIs (note "no APIs")
- `sqls/README.md` + `sqls/database.md` — may be omitted for projects without databases (note "no database")
- `devops/deployment.md` / `devops/development.md` / `devops/env.md` / `devops/test-env-deploy.md` — library projects may partially omit

**Core judgment philosophy (from specs-checklist)**: **"file exists" ≠ "content is substantial"**. Each document must go beyond the initial placeholder template (see "Placeholder Template Recognition Rules" at the end); a document containing only a title + empty tables + `<fill>`/`TODO` placeholders counts as unfilled and is treated as missing.

**Code Grader**:
```bash
# required docs (9) — missing existence/content directly affects scoring
REQUIRED="architecture relationship coding-style code-review glossary failures logging unittest/unittest integration_test/integration_test"
req_ok=0; req_total=9; skeleton=0
for f in $REQUIRED; do
  if [ -f .docs/$f.md ]; then
    lines=$(wc -l < .docs/$f.md)
    # placeholder judgment: ≤10 lines or almost entirely placeholders/empty tables
    if [ "$lines" -le 10 ]; then
      skeleton=$((skeleton+1)); echo "SKELETON $f ($lines lines)"
    else
      req_ok=$((req_ok+1)); echo "OK $f"
    fi
  else
    echo "MISSING $f"
  fi
done

# on-demand subdirectory docs (report only, does not affect judgment; trimmed per project capability)
for f in .docs/apis/index.md .docs/sqls/README.md \
         .docs/devops/deployment.md .docs/devops/development.md \
         .docs/devops/env.md .docs/devops/test-env-deploy.md \
         .docs/review.md; do
  if [ -f "$f" ]; then
    lines=$(wc -l < "$f")
    [ "$lines" -gt 10 ] && echo "OPTIONAL_OK $f"
  fi
done

echo "Required(non-skeleton): $req_ok/$req_total (skeleton: $skeleton)"
```

**Judgment** (based only on content substance of the 9 required docs):
- ✅ PASS: all 9 required docs exist + each non-empty (>10 lines and non-placeholder); on-demand docs are trimmed per project capability and not mandatory
- ⚠️ PARTIAL: 5-8 of the required docs exist and are non-placeholder (skeleton counts as missing), or all 9 exist but ≥3 are empty skeletons (≤10 lines/pure placeholder)
- ❌ FAIL: ≤4 required docs exist or are non-placeholder

> **Equivalent recognition**: if a project uses `.docs/design.md` instead of `architecture.md`, or another naming carrying equivalent content, treat it equally as long as the information is equivalent; do not double-deduct (following the specs-checklist evaluation philosophy).
> Note: `devsop_report.md` does not count toward this item (it is this Skill's own output, evaluated by F1).
> Note: missing on-demand docs do not affect the PASS/PARTIAL/FAIL judgment.

---

### A5: Generic AI entry committed (AGENTS.md, 2 points)

**DEVSOP basis**: AGENTS.md is the single generic AI collaboration entry shared by all AI coding agents; no tool-specific entry files are required for scoring.

**Code Grader**:
```bash
# AGENTS.md exists at the repo root (regular file or symlink)
[ -e "AGENTS.md" ] && echo "OK AGENTS.md" || echo "MISSING AGENTS.md"

# check key files are not gitignored
grep -E "AGENTS\.md|ARCHITECTURE\.md|\.docs/" .gitignore 2>/dev/null && echo "FAIL: key files are gitignored"
```

**Judgment**:
- ✅ PASS: `AGENTS.md` exists at the repo root and key files are not gitignored
- ⚠️ PARTIAL: `AGENTS.md` exists but `.gitignore` includes key files
- ❌ FAIL: `AGENTS.md` is missing or ignored

---

### A6: One-command start (3 points)

**DEVSOP basis**: §1.1 "one-command start: ensure the project has `make dev` or an equivalent command that runs end-to-end"

**Code Grader**:
```bash
# Go projects
grep -E '^(dev|run|start):' Makefile 2>/dev/null

# JS/TS projects
node -e "console.log(JSON.stringify(require('./package.json').scripts))" 2>/dev/null | grep -iE '"(dev|start)"'

# Python projects
grep -E '(dev|start)' Makefile pyproject.toml 2>/dev/null
```

**Judgment**:
- ✅ PASS: `make dev` / `npm run dev` / `make run` or an equivalent target exists, and the README mentions it
- ⚠️ PARTIAL: the command exists but is not documented, or documented but the actual command does not run
- ❌ FAIL: no one-command start entry at all

---

### A7: Environment config template (2 points)

**DEVSOP basis**: implicit prerequisite of §1.1 "AI/newcomers get the project running within 30 minutes"

**Code Grader**:
```bash
ls .env.example .env.template .env.sample env.example 2>/dev/null
grep -l "environment variable\|ENV\|config" README.md .docs/devops/development.md 2>/dev/null
ls docker-compose.yml docker-compose.yaml 2>/dev/null
```

**Judgment**:
- ✅ PASS: `.env.example` or an equivalent config template exists, or `README`/`development.md` explicitly lists the required environment variables
- ⚠️ PARTIAL: env vars are only implied in `docker-compose.yml` with no standalone explanation doc
- ❌ FAIL: no env config template or explanation at all; new developers have to guess the config

---

## Pillar B: Dev mode / role collaboration (15 points)

### B1: 9-step R&D flow explicit (5 points)

**DEVSOP basis**: §2.1 "overall flow: Clarify → Plan → Implement → UT → Deploy → IT → Docs → Review → Commit"

**Model Grader**: check whether AGENTS.md's "§2 DEVSOP" describes the complete 9-step plans flow.

**Code Grader**:
```bash
grep -cE "Clarify|Plan|Implement|UT|Deploy|IT|Docs|Review|Commit" AGENTS.md
```

**Judgment**:
- ✅ PASS: the 9-step flow is explicitly documented (or a reasonably trimmed ≥7 steps), and each step describes its deliverable or tool
- ⚠️ PARTIAL: the flow is mentioned but only 3-6 steps, or only step names without deliverable descriptions
- ❌ FAIL: no flow description at all

---

### B2: Role responsibility conventions (4 points)

**DEVSOP basis**: § (role responsibility division) product/test/R&D, 4-6 responsibilities each

**Model Grader**: search for keywords such as "role responsibilities", "product manager", "QA", "R&D" and locate them in AGENTS.md / README.md / .docs/.

**Judgment**:
- ✅ PASS: all three roles (PM/QA/RD) have ≥3 concrete responsibility items each
- ⚠️ PARTIAL: only 1-2 roles covered, or responsibilities are vague/shallow (like "do requirements well")
- ❌ FAIL: no role definitions at all

---

### B3: Phase deliverables have ownership locations (4 points)

**DEVSOP basis**: §2.1 each phase (design, subtasks, unit tests) needs an explicit deliverable location

**Code Grader + model**:
- Check whether the `.docs/plans/` directory exists
- Check whether the `.docs/plans/_template/` template directory exists (with the 10 files)
- Check whether any created task directories exist (containing `00-overview.md`)

```bash
ls -d .docs/plans/ 2>/dev/null
ls -d .docs/plans/_template/ 2>/dev/null
find .docs/plans -maxdepth 2 -name 00-overview.md 2>/dev/null | wc -l
```

**Judgment**:
- ✅ PASS: `.docs/plans/_template/` exists + ≥1 created task directory (containing 00-overview.md)
- ⚠️ PARTIAL: `_template/` exists but no historical task directories
- ❌ FAIL: `.docs/plans/` does not exist or is empty

---

### B4: Branch naming + Commit Message conventions (2 points)

**DEVSOP basis**: §2 flow conventions + §3.2 prohibitions (non-conforming commit messages)

**Code Grader + model**:
```bash
# check commitlint / conventional commit config
ls commitlint.config.* .commitlintrc* .czrc 2>/dev/null
grep -l "commit" lefthook.yml .husky/commit-msg 2>/dev/null

# check branch naming convention docs
grep -iE "branch|feat/|fix/|hotfix/|naming" .docs/devops/development.md .docs/code-review.md AGENTS.md 2>/dev/null
```

**Judgment**:
- ✅ PASS: commit conventions documented (Conventional Commits or equivalent) + branch naming conventions have a documented home
- ⚠️ PARTIAL: only mentioned in docs without an enforcing tool (commitlint/hook), or only branch conventions without commit conventions
- ❌ FAIL: no branch/commit convention docs at all

---

## Pillar C: Quality checks & feedback mechanisms (25 points)

### C1: Commit / Push conventions memorized (AGENTS.md / project rules dir defines commit + push conventions) (5 points)

**DEVSOP basis**: §3.1 "pre-commit: build + lint + unit tests + prohibited-item checks → block the commit"

> **Architecture note**: this Skill runs on a server (pulls repo code to evaluate), so `.git/hooks/` is not distributed with the code and cannot be used as evidence. Instead, evaluate the equivalent target: **whether the commit / push behavior conventions are written into AI-readable project memory files** (`AGENTS.md` and rule files under the project rules dir `rules/`). Only when the rules are in the memory files do AI and humans have gate conventions to follow when collaborating.

**Code Grader**:
```bash
# memory file existence
ls AGENTS.md 2>/dev/null
ls rules/ 2>/dev/null

# commit convention signals: message format / pre-commit checks / ticket references / amend constraints
grep -inE 'commit' AGENTS.md rules/*.md 2>/dev/null | head -15

# push convention signals: pre-push checks / MR flow / force-push constraints / no direct pushes
grep -inE 'push|force-with-lease|MR|merge' AGENTS.md rules/*.md 2>/dev/null | head -15
```

**Model Grader**: read the hit passages and judge whether the rules are concrete and executable (with explicit commands / formats / prohibitions), not empty phrases like "pay attention to commit conventions".

**Judgment**:
- ✅ PASS: the memory files **simultaneously** define commit conventions (e.g. message format, mandatory build/lint/test before commit, ticket references `--story=` / `--bug=`, one MR one commit / amend constraints) **and** push conventions (e.g. pre-push checks, post-push MR flow, `--force-with-lease` constraints, no direct pushes to protected branches), and the rules are concrete and executable
- ⚠️ PARTIAL: only one category defined (commit conventions without push conventions, or vice versa), or both mentioned but only as a vague one-liner without executable details
- ❌ FAIL: neither `AGENTS.md` nor any recognized rules dir contains commit/push conventions (including when neither exists)

> ⚠️ **Boundary with adjacent Evals**: B4 evaluates "branch naming + Commit Message format conventions"; C4 evaluates "branch protection and Review flow docs"; C1 evaluates "**whether rule constraints on commit and push behavior enter the AI memory files**" — the same passage can support multiple items; no double-deduction and no mutual exemption.
>
> ⚠️ **Anti-false-hit**: do not count "the Commit step name in the 9-step flow" as a commit convention — there must be constraint clauses about the commit/push behavior itself (format, pre-checks, prohibitions) to count.

---

### C2: CI pipeline with full unit tests + coverage gate (5 points)

**DEVSOP basis**: §3.1 "CI (post-commit/pre-MR): full unit tests (coverage) + interface tests (full) + integration tests + code review → block merges"

**Code Grader**:
```bash
# Path ①: CI config checked into the repo (any platform — GitHub Actions / GitLab CI / Jenkinsfile / etc.)
ls .github/workflows/ .gitlab-ci.yml Jenkinsfile Jenkinsfile.* jenkins/ .jenkins/ 2>/dev/null

# Path ②: README.md or .docs/devops/development.md explicitly writes the CI/CD platform URL
#   recognized platforms: GitHub Actions / GitLab CI / Jenkins / ArgoCD / etc.
#   match: the same line mentions the platform name and contains an http(s):// link (URL may be an IP address)
grep -iE '(github.?actions|gitlab.?ci|jenkins|argocd|argo.?cd|travis|circleci).*https?://|https?://.*(github\.com/.*/(actions|workflows)|gitlab|jenkins|argocd|argo.?cd|travis|circleci)' \
  README.md .docs/devops/development.md AGENTS.md 2>/dev/null | head -5

# coverage gate (CI config/Makefile usually uses cobertura/jacoco or a shell check)
grep -rE 'coverage|COVERAGE_THRESHOLD|cover|cobertura|jacoco' \
  Makefile .github/ .gitlab-ci.yml Jenkinsfile jenkins/ 2>/dev/null
```

**Judgment** (either Path ① or ② hit counts as having CI):
- ✅ PASS: satisfies either path + runs unit tests + has a coverage threshold
  - Path ①: a CI config checked in (GitHub Actions workflow / GitLab CI / Jenkinsfile) + stages include unit tests + includes coverage-gate logic
  - Path ②: README/development.md writes the CI platform URL + docs explain the pipeline includes unit tests and a coverage gate
- ⚠️ PARTIAL:
  - Path ① hit but the CI config only runs build/lint without unit tests, or has unit tests without a coverage gate
  - Path ② hit but the docs do not explain the stage contents/have no coverage-gate explanation
  - only the platform name is mentioned (e.g. "we use GitHub Actions for CI") without a URL
- ❌ FAIL: no CI config in the repo, and no CI platform URL in README/development.md

> **Core rule**: the URL must be a clickable http(s):// link; just writing "we use <CI platform>" does not count as PASS (AI/newcomers still cannot reach the pipeline directly).

---

### C3: Prohibited-item protection (4 points)

**DEVSOP basis**: §3.2 prohibited-item list

**Code Grader + model**:
```bash
# 1. does .gitignore cover sensitive files and artifacts
grep -E '\.env|\.pem|\.key|vendor/|node_modules/|dist/|\.exe' .gitignore

# 2. are there already-committed violations
git ls-files | grep -E '\.env$|\.pem$|\.key$|^vendor/|^node_modules/'

# 3. are the prohibited items explicit in .docs/code-review.md or a PreCommit Hook
grep -iE 'forbid|not allowed|must not|never' .docs/code-review.md .docs/coding-style.md 2>/dev/null
```

**Judgment**:
- ✅ PASS: .gitignore complete + no violating files committed + prohibited items explicitly listed in docs
- ⚠️ PARTIAL: .gitignore complete but prohibited items not documented, or documented but .gitignore has gaps
- ❌ FAIL: .gitignore severely lacking or sensitive files already committed

---

### C4: Branch protection and Review flow (3 points)

**DEVSOP basis**: §3.2 flow conventions (bypassing Review, direct pushes to main, PRs over 500 lines, commits without ticket references, etc.)

**Model Grader**: look in `.docs/code-review.md` or README/AGENTS for:
- no direct pushes to main / master
- PRs must reference a requirement ticket
- PR line-count limits
- merge only after Review passes

**Judgment**:
- ✅ PASS: ≥3 flow constraints documented
- ⚠️ PARTIAL: 1-2 constraints
- ❌ FAIL: no documentation at all (even if the platform has it configured, it still counts as FAIL)

---

### C5: Feedback mechanism / failures.md active (3 points)

**DEVSOP basis**: §3.3 feedback mechanism + §3.4 "review failures.md every two weeks"

**Code Grader**:
```bash
# file exists + line count
wc -l .docs/failures.md 2>/dev/null

# commits in the last 90 days
git log --since='90 days ago' --oneline -- .docs/failures.md | wc -l
```

**Judgment**:
- ✅ PASS: exists + ≥30 lines + commits in the last 90 days
- ⚠️ PARTIAL: exists but <30 lines, or no commits in 90 days but rich content
- ❌ FAIL: does not exist or is only a placeholder (<10 lines)

---

### C6: Security scanning / dependency vulnerability detection (2 points)

**DEVSOP basis**: §3.2 prohibited item "committing dependencies with vulnerabilities" + industry security baseline

> **Tooling scope**: team Go projects no longer use the `gosec` binary standalone; it is carried uniformly through `golangci-lint` (the `.golangci.yml` injected by devsop-init enables `gosec` in `linters.enable` by default). The primary evidence for Go projects is **`gosec` being enabled in `.golangci.yml`**.

**Code Grader**:
```bash
# 1. Go project primary path: gosec enabled in .golangci.yml
ls .golangci.yml .golangci.yaml 2>/dev/null
# gosec present in the enable list (PASS signal)
grep -A30 'enable:' .golangci.yml .golangci.yaml 2>/dev/null | grep -E '^\s*-\s*gosec'
# gosec present in the disable list (negative signal; hit means not enabled)
grep -A30 'disable:' .golangci.yml .golangci.yaml 2>/dev/null | grep -E '^\s*-\s*gosec'

# 2. other security scan tool configs / CI integration (trivy / snyk / govulncheck / sonar etc.)
ls .trivyignore .snyk 2>/dev/null
grep -rE "trivy|snyk|renovate|npm.audit|safety|govulncheck|sonar" \
  Jenkinsfile jenkins/ Makefile lefthook.yml .github/ .gitlab-ci.yml 2>/dev/null

# 3. check whether .docs/ declares a security scan integrated in an external CI repo
#   (security scan config may live in a separate CI/Argo Workflow repo; development.md must declare the repo address and tools)
grep -iE 'gosec|golangci|trivy|snyk|sonar|govulncheck|security|vulnerability' \
  .docs/devops/development.md .docs/devops/deployment.md 2>/dev/null
# confirm an external CI repo address is declared (a URL makes it traceable)
grep -E 'https?://' .docs/devops/development.md .docs/devops/deployment.md 2>/dev/null | \
  grep -iE 'ci|workflow|pipeline|argo|security|scan'

# 4. dependency-update / vulnerability tooling (Renovate / Dependabot / trivy etc.)
ls renovate.json renovate.json5 .renovaterc .github/dependabot.yml .trivyignore 2>/dev/null
```

**Judgment**:
- ✅ PASS: satisfies any of — ① Go project `.golangci.yml` / `.golangci.yaml` exists and `gosec` is in `linters.enable` (not in the disable list); ② local security-scan tool config files exist; ③ local CI config (GitHub Actions/GitLab CI/Jenkinsfile/Makefile) includes security scanning; ④ security scanning integrated in Argo Workflow or external CI yaml; ⑤ .docs/ explicitly declares the security scan is integrated in an external CI pipeline (with tool name and location); ⑥ dependency-update / vulnerability tooling exists (Renovate / Dependabot / trivy etc.)
- ⚠️ PARTIAL: `.golangci.yml` exists but `gosec` not enabled (lint system present, security linter missing); or only dependency-update tooling without proactive vulnerability scanning; or .docs/ mentions security scanning but does not state the specific tool/location; or the config exists but the rules are empty
- ❌ FAIL: no `.golangci.yml` or the enable list is empty, no other security-scan config, and .docs/ does not declare external-CI security scanning

---

### C7: E2E / integration tests exist (3 points)

**DEVSOP basis**: §3.1 "interface tests (full) + integration tests → block merges"

**Code Grader**:
```bash
# check E2E/integration test dirs
ls -d tests/e2e/ tests/integration/ test/e2e/ e2e/ integration/ 2>/dev/null

# check integration test files (Go / JS / Python)
find . -name '*integration*test*' -o -name '*e2e*test*' -o -name '*_integration_test.go' 2>/dev/null | head -5

# check whether CI has an E2E/integration test stage (any CI platform)
grep -iE "e2e|integration.test|interface test" Jenkinsfile jenkins/ Makefile .docs/devops/deployment.md 2>/dev/null
grep -iE "e2e|integration.test|interface test" .github/workflows/*.yml .gitlab-ci.yml 2>/dev/null
```

**Judgment**:
- ✅ PASS: an independent E2E/integration test dir + non-empty files + a corresponding step in CI
- ⚠️ PARTIAL: integration test files exist but no CI integration, or CI has a step but the test dir is empty
- ❌ FAIL: no E2E/integration test traces at all

---

## Pillar D: Design & change management (15 points)

> Uniformly use the `.docs/plans/` system to manage all changes (Clarify → Plan → Implement → UT → Deploy → IT → Docs → Review → Commit).

---

### D1: Task directories exist with substantive content (4 points)

**DEVSOP basis**: §4 "design before coding" — manage changes through the `.docs/plans/` system

**Code Grader**:
```bash
# check the task directory count under plans/ (excluding _template)
task_dirs=$(find .docs/plans -mindepth 1 -maxdepth 1 -type d -not -name '_template' 2>/dev/null | wc -l)

# check the 10-file completeness of each task directory
find .docs/plans -mindepth 1 -maxdepth 1 -type d -not -name '_template' 2>/dev/null | while read d; do
  files=$(ls "$d"/*.md 2>/dev/null | wc -l)
  echo "$d: $files step files"
done
```

**Judgment**:
- ✅ PASS: ≥1 task directory, and at least 1 contains ≥8 step files (00-overview.md + 01-09)
- ⚠️ PARTIAL: task directories exist but with incomplete files (1-7 step files)
- ❌ FAIL: no task directories or only `_template/`

---

### D2: 00-overview.md maintenance activity (4 points)

**DEVSOP basis**: §4 "design before coding" — the task overview file is continuously maintained

**Code Grader**:
```bash
# check the latest update of 00-overview.md under plans/
find .docs/plans -name 00-overview.md -not -path '*/_template/*' -exec git log -1 --format='%cI' {} \; 2>/dev/null | sort -r | head -1
```

**Judgment**:
- ✅ PASS: a task `00-overview.md` has git updates in the last 90 days
- ⚠️ PARTIAL: task directories exist but no updates in 90 days
- ❌ FAIL: no task `00-overview.md`

---

### D3: Small-change TDD/regression testing + template completeness (4 points)

**DEVSOP basis**: §4.2 "bug fixes must include regression tests" + §3.1 "unit test gate"

**Code Grader + model**:
```bash
# check the 10-file completeness under plans/_template/
ls .docs/plans/_template/ 2>/dev/null | wc -l

# TDD requirement (documented in unittest/unittest.md)
grep -iE 'TDD|write tests first|regression' .docs/unittest/unittest.md AGENTS.md 2>/dev/null
```

**Judgment**:
- ✅ PASS: `_template/` has the 10 files + TDD explicitly in `unittest/unittest.md` or `AGENTS.md`
- ⚠️ PARTIAL: the template exists but <10 files, or TDD is only a verbal convention
- ❌ FAIL: the template does not exist and there is no TDD requirement

---

### D4: Change-classification standard documented (3 points)

**DEVSOP basis**: §4.1 change classification rules

**Model Grader**:
```bash
grep -iE "classification|large|medium|small|person.day|change scale|impact scope" \
  .docs/devops/development.md AGENTS.md .docs/code-review.md 2>/dev/null
```

Look for the change-classification definition in `.docs/devops/development.md`, `AGENTS.md`, or `.docs/code-review.md`.

**Judgment**:
- ✅ PASS: the doc clearly defines how large/medium/small changes are judged (e.g. person-day thresholds, number of affected modules, code line counts) and points to the process for each level
- ⚠️ PARTIAL: only the "large/medium/small change" concept is mentioned without clear judgment criteria, or the criteria are vague
- ❌ FAIL: no change-classification description

---

## Pillar E: Shared knowledge base (5 points)

### E1: In-project Skills accumulation directory (2 points)

**DEVSOP basis**: §5.1 "Skills & Hooks: useful skill files"

**Code Grader**:
```bash
# the standard repo-local skills dir
ls -d .agents/skills/ 2>/dev/null
ls .agents/skills/*/SKILL.md 2>/dev/null | wc -l
```

**Judgment**:
- ✅ PASS: `skills/` exists + ≥3 SKILL.md files (including this Skill itself)
- ⚠️ PARTIAL: only 1-2 Skills
- ❌ FAIL: no accumulation directory at all

---

### E2: Knowledge accumulation completeness (3 points)

**DEVSOP basis**: §5 "shared knowledge base: build a shared knowledge-accumulation space" — the DEVSOP does not restrict where knowledge lives; local `.docs/` in the repo and remote wikis have equal value, and local accumulation is even easier for AI to consume directly.

**Criteria**: PASS when any of the following paths is satisfied (choose one of three).

**Path ① `.docs/` doc count (Code Grader)**:
```bash
# number of Markdown docs under .docs/
find .docs/ -name '*.md' 2>/dev/null | wc -l
```
- ≥10 Markdown docs under `.docs/` → PASS

**Path ② remote team knowledge-base references (Code Grader + Model Grader)**:
```bash
# check for external knowledge-base links in README/AGENTS
# recognized keywords: wiki, confluence, notion, yuque, feishu, knowledge bases, shared repos, etc.
grep -iE '(wiki|confluence|notion|yuque|feishu|knowledge|doc.center)' \
  README.md AGENTS.md 2>/dev/null | grep -E 'https?://'
```
- a line or file contains both a knowledge-platform keyword and an http(s):// link → Code Grader hit
- Model Grader confirms: the link points to a valid team knowledge base with a usage description → PASS

**Path ③ `.docs/plans/` task count (Code Grader)**:
```bash
# task directory count under .docs/plans/ (excluding _template)
find .docs/plans -mindepth 1 -maxdepth 1 -type d -not -name '_template' 2>/dev/null | wc -l
```
- ≥3 created task directories → PASS

**Judgment**:
- ✅ PASS: satisfies any of ①/②/③
- ⚠️ PARTIAL: `.docs/` has 1-9 docs, or external resources are only mentioned without links, or `.docs/plans/` has 1-2 task directories
- ❌ FAIL: no accumulation traces at all

---

## Pillar F: Measurement mechanisms (15 points)

### F1: devsop_report.md exists and is updated regularly + improvement actions recorded (5 points)

**DEVSOP basis**: §6.1 "DEVSOP measurement Skill measures each project's build status and outputs scores"

This item is split into two sub-dimensions to resolve the self-referential paradox of "running eval counts as PASS":

#### F1a: Report exists and is not the first time (2 points)

**Code Grader**:
```bash
[ -f .docs/devsop_report.md ] && \
  git log --oneline -- .docs/devsop_report.md 2>/dev/null | wc -l
```

**Judgment**:
- ✅ PASS: file exists + git history has ≥2 commits (meaning it is not the first evaluation)
- ⚠️ PARTIAL: file exists but only 0-1 commits (first evaluation or just checked in)
- ❌ FAIL: file does not exist

> **First-evaluation special handling**: this run creates the file, automatically counted as ⚠️ PARTIAL (does not penalize new projects).

#### F1b: The report has explicit improvement tracking records (3 points)

**Code Grader + model**:
```bash
# check whether the report has a non-empty "comparison with the previous evaluation" section
grep -A5 "comparison with the previous evaluation" .docs/devsop_report.md 2>/dev/null | grep -E "↑|↓|PASS|PARTIAL|FAIL"

# or check whether .docs/ has an improvement-tracking file
ls .docs/devsop_improvements.md .docs/devsop_changelog.md 2>/dev/null
```

**Judgment**:
- ✅ PASS: the report has a non-empty "comparison with the previous evaluation" section (with concrete rise/fall records), or a standalone improvement-tracking file records FAIL→PASS actions
- ⚠️ PARTIAL: the report exists but has no comparison section (only the first evaluation, or evaluations never compared), or the comparison section is only a placeholder without substance
- ❌ FAIL: there is no proof the team acted upon the evaluation results (no report, or the report exists but never had comparison/improvement records)

> **Core logic**: F1 does not measure "someone remembers to run the command"; it measures "the team took action based on the evaluation results".

---

### F2: AI session/memory/failure-case retention (4 points)

**DEVSOP basis**: §6.2 "keep logs of key AI sessions (Prompt + output) / accumulate failure cases" — the DEVSOP cares about "whether the AI collaboration process is traceable"; the carrier is the agent-agnostic standard locations (repo-local `.agents/memory/` and `.agents/sessions/`, or user-level `~/.agents/projects/<slug>/memory/`).

**Criteria**: PASS when any of the following paths is satisfied.

**Path ① AI memory store (Code Grader · recommended)**:
```bash
# standard memory locations (user-level dir named with the project absolute-path slug: / → -, leading - removed)
slug=$(pwd | sed 's|/|-|g; s/^-//')
for m in ".agents/memory/" "$HOME/.agents/projects/$slug/memory/"; do
  ls "$m" 2>/dev/null
  find "$m" -name '*.md' 2>/dev/null | wc -l
done
# fallback scan when the slug does not match
find "$HOME/.agents/projects" -maxdepth 2 -name MEMORY.md 2>/dev/null | head -5
```
- the `memory/` dir for the current project exists + ≥3 memory files → PASS (memory is already structured AI-context accumulation)
- Note: memory may live in the **user-level** directory (outside the repo), a legitimate evidence source; scanning is read-only, no writes involved

**Path ② session logs (Code Grader)**:
```bash
# in-repo session dirs
ls -d logs/ai-sessions/ .agents/sessions/ 2>/dev/null
find logs/ai-sessions/ .agents/sessions/ -name '*.md' -o -name '*.jsonl' 2>/dev/null | head -5
```
- any in-repo session dir exists + has files in the last 30 days → PASS

**Path ③ failure cases in git (Code Grader)**:
```bash
git ls-files .docs/failures.md >/dev/null 2>&1 && \
  git log --since='90 days ago' --format='%cI' -- .docs/failures.md | head -1
```
- failures.md is tracked + has commits in the last 90 days → PASS

**Judgment**:
- ✅ PASS: satisfies any of ①/②/③
- ⚠️ PARTIAL: only failures.md exists but not in git, or the memory store exists but <3 files, or session dirs exist but no new files in 30+ days
- ❌ FAIL: no session/memory/failure retention at all

---

### F3: .docs/ doc changes traceable (3 points)

**DEVSOP basis**: §6.1 phase 2 "scan the change status of DEVSOP regulation docs to ensure the feedback mechanism operates effectively"

**Code Grader**:
```bash
git log --since='60 days ago' --format='%cI %s' -- .docs/ | wc -l
git log --since='60 days ago' --format='%cI' -- .docs/ | head -1
```

**Judgment**:
- ✅ PASS: ≥3 commits in 60 days
- ⚠️ PARTIAL: 1-2 commits in 60 days
- ❌ FAIL: no commits in 60 days (or just created — may be exempt, but must be noted in the report)

---

### F4: Improvement-loop closure verification (3 points)

**DEVSOP basis**: §6 continuous improvement "measurement-driven improvement"

**Code Grader + model**:
```bash
# check whether multiple historical evaluation records exist
git log --oneline -- .docs/devsop_report.md 2>/dev/null | wc -l
```

If there are ≥2 git commit records, read the current report and compare the FAIL/PARTIAL items against previous versions.

**Judgment**:
- ✅ PASS: ≥2 historical evaluation records (git commits) exist, and the latest one shows ≥1 FAIL→PASS or PARTIAL→PASS improvement over the previous
- ⚠️ PARTIAL: historical evaluations exist but no clear improvement (items unchanged), or only 1 historical evaluation (including this first creation)
- ❌ FAIL: cannot verify the improvement loop (devsop_report.md has no git history or does not exist)

> **First-evaluation special handling**: if this is the first evaluation (devsop_report.md's git log has only 0-1 commits), this item is automatically counted as ⚠️ PARTIAL (does not penalize new projects, but notes "first evaluation, loop to be verified later").

---

## Placeholder Template Recognition Rules (basis for content-substance judgment)

> From the specs-checklist evaluation philosophy: **"file exists" ≠ "content is substantial"**. Doc-type Evals such as A4/D1/D3 must use this to judge whether content goes beyond the initial placeholder template.

**Generic placeholder features (any hit = placeholder/unfilled)**:
1. Placeholder variables: the file contains angle-bracket/double-brace placeholders such as `<project name>`, `<fill>`, `<example>`, `<module>`, `<ActionName>`, `<X.Y.Z>`, `<APP>`, `<pkg1>`, `{{PROJECT_NAME}}` with no corresponding real value
2. Empty table rows: all Markdown data rows are `|  |  |  |` / `| | | |` (separators only, no data)
3. Pure TODO content: body only has `<!-- TODO -->` / `# TODO:` comments without actual descriptions
4. Zero valid content: after removing heading lines, blockquotes, HTML comments, blank lines, and table headers+separator rows, fewer than 3 non-empty lines remain

**Per-file special judgment**:
| File | Still-a-placeholder marker |
|------|----------------------------|
| `architecture.md` | "system positioning" is still `<!-- one sentence ... -->`; module division table has no valid rows; the overall view is still the generic placeholder diagram `[external trigger] → [entry / dispatch layer] → ...` |
| `relationship.md` | upstream/downstream tables have no valid rows; the topology is still the generic placeholder `[external caller] → [this project] → [downstream A]` |
| `apis/index.md` | the module/interface list table has no valid rows |
| `sqls/README.md` | the database list table has no valid rows |
| `unittest/unittest.md` | the tech-selection table's test framework is still `<fill...>`; the run command is still `<fill: sh run_test.sh ...>` |
| `integration_test/integration_test.md` | §1 form determination is all placeholders without the project's actual form; §3 run command is still `<fill: sh run_it.sh ...>`; more than 8 placeholders |
| `devops/env.md` | the runtime environment table has no valid rows; the quick start is still `# TODO:` |
| `devops/test-env-deploy.md` | the tool-readiness check table has no valid rows; the sync command is still `# TODO:` |
| `review.md` | a generic template; project customization is not required; existence alone counts as ✅ |

**Equivalent recognition**: using `design.md` instead of `architecture.md`, using GitHub Issues instead of task registration, etc. — as long as the information is equivalent, treat it equally; do not deduct for different filenames.

---

## General PARTIAL Judgment Principles

When the PASS / FAIL boundary is unclear, use the following decision tree:

1. **Completeness**: does it meet the required core conditions? No → FAIL
2. **Sufficiency**: core conditions met but shallow / incomplete → PARTIAL
3. **Usability**: the content exists but AI/team members cannot work from it → PARTIAL
4. **Freshness**: the content exists but is severely stale (out of sync with code) → PARTIAL (FAIL only if extremely severe)

**Evaluation confidence markers**:

- 🟢 high: pure Code Grader, clear evidence
- 🟡 medium: model-based judgment but with objective anchors (chapter keywords, line counts, etc.)
- 🔴 low: purely subjective judgment; manual review recommended

---

## Notes for Evaluators

- Read only the chapters needed for the current assessment
- Prefer executing command examples with the `Bash` / `Grep` / `Glob` tools rather than depending on external commands
- When a command does not apply to the project's language stack (e.g. running npm commands on a Go project), skip that command rather than error out
- Keep command-output fragments in evidence (first 3 lines); do not keep full stderr
