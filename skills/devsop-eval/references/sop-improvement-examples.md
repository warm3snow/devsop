# DEVSOP Improvement Suggestion Examples

## Contents

- [Pillar A: Project AI-friendliness](#pillar-a-project-ai-friendliness) — A1–A7
- [Pillar B: Dev mode / role collaboration](#pillar-b-dev-mode--role-collaboration) — B1–B4
- [Pillar C: Quality checks & feedback mechanisms](#pillar-c-quality-checks--feedback-mechanisms) — C1–C6
- [Pillar D: Design & change management](#pillar-d) — D1–D4
- [Pillar E: Shared knowledge base](#pillar-e) — E1–E2
- [Pillar F: Measurement mechanisms](#pillar-f) — F1–F4
- [Anti-pattern Specialized Improvements](#anti-pattern-specialized-improvements)
- [General Suggestion Generation Rules](#general-suggestion-generation-rules)

This document provides `devsop-eval` with examples for turning findings into executable improvement actions. Use the closest example when relevant; otherwise write a specific, evidence-based action.

> **Three elements of an improvement suggestion**:
> 1. **Executable**: must be of the form "add section Y to file X" / "configure tool Z" / "run command N"; empty phrases like "should strengthen X" are forbidden
> 2. **Verifiable**: once done, you can directly see the Eval status rise from PARTIAL/FAIL to PASS
> 3. **Small granularity**: expected effort of a single suggestion is <1 person-day; split anything larger into multiple suggestions

---

## Pillar A: Project AI-friendliness

### A1 AGENTS.md missing or too long

| Current state | Improvement action |
|---------------|--------------------|
| Does not exist | Run the `devsop-init` skill to auto-generate; or create AGENTS.md manually, at least including: tech stack / directory structure / regulations index / quick start / core conventions / prohibited items |
| Line count >300 | Split detailed chapters into `.docs/` sub-regulations or `rules/*.mdc`; AGENTS.md keeps only the index and core constraints (refer to the slimming experience of mature projects) |
| Line count <30 (shallow) | Add the following sections: ① tech stack versions ② directory structure ③ .docs/ regulation links ④ one-command start ⑤ 5+ prohibited items |
| Four chapters incomplete (1-2 of quick index/DEVSOP/dev guidelines/forbidden red lines missing) | Add the missing chapters: ① quick index table (incl. .docs/ doc location mapping) ② §2 DEVSOP (incl. 9-step plans flow, context recovery, task isolation, scale branching) ③ §3 dev guidelines (fill per the project's actual situation) ④ §4 forbidden red lines (≥5 hard constraints). Reference the `assets/agents.md.tmpl` template structure of the `devsop-init` skill |

### A2 README.md incomplete

| Missing section | Improvement action |
|-----------------|--------------------|
| Project background / business goals | Add "## Project Introduction" at the top of the README; explain the business background and target users in 2-3 paragraphs |
| Core feature list | Add "## Core Features", listing 5-10 features as bullets |
| Upstream/downstream dependencies | Add "## External Dependencies", listing the dependent services, SDKs, and infrastructure (DB / Redis / external APIs) |
| Quick start | Add "## Quick Start", giving the complete command sequence from `git clone` → `make dev` |
| Deployment environment requirements | Add "## Environment Requirements", listing Go/Node/Python versions, required service dependencies, and minimal hardware config |
| Notes | Add "## Notes", listing known limitations, incompatible scenarios, and pitfall-avoidance tips |

### A3 .docs/architecture.md incomplete

| Missing section | Improvement action |
|-----------------|--------------------|
| Overall architecture diagram | Draw a layered architecture diagram with mermaid `graph TD` (frontend → gateway → service → DB), embedded in `.docs/architecture.md` |
| Module division and boundaries | List the top-level directory tree; describe each module's responsibility and what it should not do in 1-2 sentences |
| Data flow | Draw 1-2 core-scenario data-flow sequence diagrams (e.g. "user login", "core business interface") |
| Tech selection rationale | For each key technology (framework/middleware/storage) write "what + why + alternatives and why they were rejected" |
| Core design decisions | List 3-5 project-level key decisions (e.g. "why event-driven", "why monolith rather than microservices") |
| Known tech debt | Add "## Known Tech Debt", listing currently-known but unfixed issues and their planned handling time |

### A4 .docs/ regulations library incomplete

| Missing file | Improvement action |
|--------------|--------------------|
| Any new core doc missing | Run the `devsop-init` skill to auto-fill; or manually create the files under `.docs/` per the DEVSOP requirements |
| File exists but ≤10 lines (skeleton) | Fill in per the file's topic: architecture → architecture diagram/modules/tech debt; relationship → upstream/downstream dependency graph/failure propagation; coding-style → naming/format/security rules; unittest → test strategy/coverage/run commands; integration_test → integration test scope/how to run; code-review → Review checklist; glossary → business glossary; failures → pitfall records (≥3 items); logging → log levels/format/redaction. Each at least 30 lines of substantive content; avoid placeholders |

### A5 Generic AI entry missing or gitignored

> **Principle**: `AGENTS.md` at the repo root is the single generic AI collaboration entry shared by all AI coding agents; no tool-specific entry files are required.

| Current state | Improvement action |
|---------------|--------------------|
| `AGENTS.md` missing | Generate it via `devsop-init` (the single generic AI entry) |
| Key files gitignored | Remove the `AGENTS.md` / `.docs/` entries from .gitignore |

### A6 No one-command start

| Current state | Improvement action |
|---------------|--------------------|
| No Makefile or scripts | Create a Makefile with a `dev:` target wrapping the local start commands; or add `scripts.dev` to package.json |
| Command exists but not documented | Explicitly write the single `make dev` command + expected output in the README's "## Quick Start" section |
| Command exists but does not actually run | Walk through it on a clean machine and add the missing dependencies (DB startup, env vars) to the command chain or the README |

### A7 Environment config template missing

| Current state | Improvement action |
|---------------|--------------------|
| No .env.example | Export the required env vars from the current runtime and create `.env.example`: `env | grep -E "^(DB_|REDIS_|APP_|PORT)" > .env.example`, then manually clean sensitive values into placeholders |
| Env vars scattered in multiple places | Add a "## Environment Variables" section in `.docs/devops/development.md` listing all required vars (name + description + example value + whether required) |
| docker-compose.yml exists but no explanation | Add a line to the README quick-start section: "for environment variable configuration, see .env.example or the environment section of docker-compose.yml" |

---

## Pillar B: Dev mode / role collaboration

### B1 9-step R&D flow not documented

**Improvement action**: add the 9-step plans flow description to the "§2 DEVSOP" section of `AGENTS.md`, explaining for each step:
- The corresponding artifact file (`.docs/plans/<task>/0N-xxx.md`)
- Input/output
- Confirmation points (start confirmation + end confirmation)
- Time-record requirements

Refer to the "DEVSOP startup prerequisites" and "step execution rules" sections in the `assets/agents.md.tmpl` template of the `devsop-init` skill.

### B2 Role responsibilities not defined

**Improvement action**: add a "## Role Responsibilities" section at the top of `AGENTS.md`, listing 4-6 responsibilities each for PM / QA / RD per the DEVSOP "role responsibility division" table. For small teams, simplify to "in small teams role X also handles role Y".

### B3 Phase deliverable ownership unclear

**Improvement action**:
- Task directories: uniformly under `.docs/plans/<YYYY-MM-DD_task-title>/`, each task with the 10 files (00-overview through 09-commit)
- Design docs: accumulate in `.docs/architecture.md` + `.docs/apis/`
- Unit test conventions: state "same directory as source / standalone `tests/` dir" in `.docs/unittest/unittest.md`
- Task discovery: `ls .docs/plans/` or `find .docs/plans -maxdepth 2 -name 00-overview.md`

### B4 Branch/Commit conventions not documented

**Improvement action**:

1. **Document commit conventions**: add a "## Commit Conventions" section to `.docs/devops/development.md` or `.docs/code-review.md`:
   ```markdown
   ## Commit Conventions

   Use Conventional Commits:
   - `feat: new feature`
   - `fix: bug fix`
   - `refactor: refactor (not a new feature / not a fix)`
   - `docs: documentation changes`
   - `test: test-related`
   - `chore: build/tooling changes`

   Every commit message must reference a task ticket (e.g. `feat: add user auth #123`)
   ```

2. **Document branch naming conventions**:
   ```markdown
   ## Branch Conventions

   - Feature branch: `feat/<ticket>-<summary>` (e.g. `feat/123-user-auth`)
   - Fix branch: `fix/<ticket>-<summary>`
   - Hotfix: `hotfix/<ticket>-<summary>`
   - Forbidden: developing directly on main/master
   ```

3. **Optional: add commitlint enforcement**:
   ```bash
   # lefthook.yml
   commit-msg:
     commands:
       conventional:
         run: 'echo "$1" | grep -E "^(feat|fix|refactor|docs|test|chore|style|perf|ci|build|revert)(\(.+\))?: .+"'
   ```

---

## Pillar C: Quality checks & feedback mechanisms

### C1 Commit / Push conventions not memorized

**Improvement action**: write the commit / push behavior conventions into AI-readable project memory files (`AGENTS.md` or the project rules dir `rules/`); only then do AI and humans have gate conventions to follow when collaborating.

1. **Commit conventions** (write into the "§2 DEVSOP" section of `AGENTS.md` or a rules file like `rules/commit.md`):
   ```markdown
   ## Commit Conventions
   - message format: `type(scope): summary --story=<id>` (type ∈ feat / fix / refactor / docs / test / chore; defects use `--bug=<id>`)
   - mandatory before commit: `make build && make lint && make ut`; commit only when all green
   - one MR one commit; fixes are always accumulated with `git commit --amend`; adding a second commit is forbidden
   ```

2. **Push conventions** (append to the same file):
   ```markdown
   ## Push Conventions
   - confirm local build + lint + unit tests are all green before push
   - after amend, always `git push --force-with-lease`; bare `--force` is forbidden
   - no direct pushes to main / master; always feature branch + MR
   ```

### C2 No CI pipeline

> Any CI platform counts: GitHub Actions / GitLab CI / Jenkins / Argo CD / etc. Either of two counts as having CI: ① a CI config checked into the repo (`.github/workflows/` / `.gitlab-ci.yml` / `Jenkinsfile`); ② README/deployment.md explicitly writes the CI platform URL.

| Current state | Improvement action |
|---------------|--------------------|
| Path ①: CI config checked in | Create a CI workflow at the repo root (e.g. `.github/workflows/ci.yml` / `.gitlab-ci.yml` / `Jenkinsfile`), stages: Checkout → Build → Lint → UnitTest → Coverage → IntegrationTest. Skeleton below |
| Path ②: pipeline configured on the CI platform, not in the repo | Add a "## CI Pipeline" section to `README.md` or `.docs/devops/deployment.md`, which must include: CI platform name + **clickable URL** (http(s)://) + trigger conditions + stage list + failure contact. Platform name only without URL does not count |
| Platform name only, no URL | Add the URL: the pipeline page of the CI platform in use — paste it into deployment.md |
| No coverage gate | Add `COVERAGE_THRESHOLD := 60` to the Makefile; in the CI config, after `sh 'go test -coverprofile=coverage.out ./...'`, validate with a shell `awk` check; on failure mark the build UNSTABLE |

**CI workflow reference skeleton (Go project, GitHub Actions example)**:
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.22' }
      - run: make build
      - run: make lint
      - run: go test -coverprofile=coverage.out ./...
      - name: Coverage gate (>=60%)
        run: |
          pct=$(go tool cover -func=coverage.out | tail -1 | awk '{print $3}' | tr -d '%')
          awk -v p=$pct -v t=60 'BEGIN{exit !(p>=t)}' || { echo "coverage $pct% < 60%"; exit 1; }
      - run: make integration-test
```
> Jenkinsfile / GitLab CI equivalents are equally valid — the framework does not mandate a specific platform.

**deployment.md section template (Path ②)**:
```markdown
## CI Pipeline

- Platform: {GitHub Actions / GitLab CI / Jenkins / ...}
- URL: https://github.com/<org>/<repo>/actions (or the pipeline page of the platform in use)
- Trigger: push to main / MR
- Stages: Build → Lint → UnitTest → Coverage(≥60%) → Integration
- Failure contact: @xxx
```

### C3 Prohibited-item protection insufficient

**Improvement action**:
1. **Complete .gitignore**: add `.env*`, `*.pem`, `*.key`, `vendor/`, `node_modules/`, `dist/`, `build/`, `*.exe`, `bin/`
2. **Add a sensitive-file check to PreCommit**:
   ```yaml
   # lefthook.yml
   pre-commit:
     commands:
       no-secrets:
         run: |
           git diff --cached --name-only | grep -E '\.(env|pem|key)$' && exit 1 || exit 0
   ```
3. **List the prohibited items in `.docs/code-review.md`**: copy the 12 prohibited items from DEVSOP §3.2

### C4 Branch protection and Review flow not documented

**Improvement action**: add a section to `.docs/code-review.md` listing:
- No direct pushes to main / master (always feature branch + MR)
- MRs must reference an issue-tracker ticket (MR title/description contains the ticket reference, e.g. `--story=<id>` / `--bug=<id>` or `#<id>`, per the team's tracker convention)
- MR line count ≤500; anything larger must be split
- At least 1 Reviewer approval required before merge
- AI-generated code must be human-reviewed before commit (including an "I understand this code" confirmation)

If using a code platform that supports Branch Protection (e.g. Gongfeng), configure repo protection rules accordingly.

### C5 failures.md long empty

**Improvement action**:
1. **Add 3 recent pitfall records this week**: use the following template in `.docs/failures.md`:
   ```markdown
   ## 2026-05-18 — short title
   **Symptom**: ...
   **Root cause**: ...
   **Fix**: ...
   **Prevention**: (which regulation to update / what test to add)
   ```
2. **Establish a mechanism**: add the convention "add to failures.md within 24 hours of hitting a pitfall" in `AGENTS.md`
3. **Biweekly review**: add failures.md to the team weekly meeting agenda; convert newly-added items from the past two weeks into regulation updates

### C6 No security-scan mechanism

**Improvement action (choose by language stack)**:

| Language | Recommended tool | Install and configure |
|----------|------------------|-----------------------|
| Go | `golangci-lint` (enable `gosec`) + `govulncheck` | Add `- gosec` to the `linters.enable` list in `.golangci.yml` (gosec runs with `golangci-lint run`, no separate install needed); `go install golang.org/x/vuln/cmd/govulncheck@latest`; add `security: govulncheck ./...` to the Makefile |
| JS/TS | `npm audit` + Snyk | Add `npm audit --production` to CI; or `npx snyk test` |
| Python | `safety` + `bandit` | `pip install safety bandit && safety check && bandit -r src/` |
| Generic | Renovate / Dependabot | Configure `renovate.json` or `.github/dependabot.yml` to auto-detect dependency updates (whichever the project already uses) |

**Go project `.golangci.yml` config example**:
```yaml
linters:
  enable:
    - gosec    # secure coding check
    - govet
    - staticcheck
```

**CI integration example** (Makefile target approach, so any CI config can call `make security`):
```makefile
# Makefile (gosec already runs via golangci-lint in make lint; this adds dependency-vulnerability scanning)
security:
	govulncheck ./...
```

Call `make security` in CI (GitHub Actions / GitLab CI / Jenkinsfile all work the same way). Example:
```yaml
# .github/workflows/ci.yml — Security stage
      - run: make lint && make security
```

### C7 No E2E/integration tests

**Improvement action**:

1. **Create the integration test directory**:
   ```bash
   mkdir -p tests/integration
   # or for Go projects
   mkdir -p tests/e2e
   ```

2. **Write the first integration test** (Go example):
   - Choose a core business flow (e.g. "create user → query user")
   - Use `testcontainers-go` or `docker-compose` to start real dependencies
   - File naming: `tests/integration/user_flow_test.go`

3. **CI integration** (GitHub Actions example; Jenkinsfile/GitLab CI equivalents work the same):
   ```yaml
   # .github/workflows/ci.yml — Integration stage
      - name: Integration
        run: |
          docker-compose -f docker-compose.test.yml up -d
          go test ./tests/integration/ -v -tags=integration
          docker-compose -f docker-compose.test.yml down
   ```

4. **Add conventions to `.docs/unittest/unittest.md` (unit tests) and `.docs/integration_test/integration_test.md` (integration tests)**: explain the integration test scope, how to run it, and how it differs from unit tests

---

## Pillar D: Design & change management

> The new devsop-init uniformly uses the 10-file DEVSOP system under `.docs/plans/<task>/`. Evaluation is based on task-directory existence, template completeness, and TDD documentation.

### D1 No task directories or incomplete artifacts

| Current state | Improvement action |
|---------------|--------------------|
| No `.docs/plans/` directory | Run the `devsop-init` skill to initialize the DEVSOP system |
| Has `_template/` but no historical tasks | Pick an in-progress feature and run: `cp -r .docs/plans/_template .docs/plans/YYYY-MM-DD_<task-title>`, then fill the Meta info of 00-overview.md per the DEVSOP flow |
| Task directory exists but files incomplete (<8 step files) | Rebuild the missing step files from `_template/`, ensuring 00-09 = 10 files complete |

### D2 00-overview.md maintenance inactive

| Current state | Improvement action |
|---------------|--------------------|
| Task dirs exist but no git updates in 90 days | Review in-progress tasks and update the Progress checkboxes and time records in `00-overview.md` |
| Tasks completed but not archived | Mark the completion time in `00-overview.md`; append the final commit info to the key-decision notes |

### D3 Small-change TDD not documented or template incomplete

| Current state | Improvement action |
|---------------|--------------------|
| `_template/` file count <10 | Re-run the `devsop-init` skill to refresh `_template/` (idempotent; it fills gaps) |
| TDD requirement not documented | Add a TDD principles section to `.docs/unittest/unittest.md` (see the TDD content in the A1 improvement suggestion) |

### D4 Change-classification standard not documented

**Improvement action**: add a "## Change Classification Standard" section to the "§3 Dev Guidelines" of `AGENTS.md` or to `.docs/devops/development.md`:

```markdown
## Change Classification Standard

| Level | Judgment criteria | Corresponding flow | Deliverables |
|-------|-------------------|--------------------|--------------|
| **Large** | ≥5 person-days, or affecting ≥3 modules | full 9-step DEVSOP (01-09) | full artifacts under `.docs/plans/<task>/` |
| **Medium** | 1-5 person-days, affecting 1-2 modules | standard DEVSOP (some step confirmations may be merged) | `.docs/plans/<task>/` |
| **Small** | <1 person-day, bug fixes, config changes | small-requirement mode (≤10-line changes may merge 03-04, 07-09 confirmations) | regression tests + MR |
```

---

## Pillar E: Shared knowledge base

### E1 No Skills accumulation directory

**Improvement action**:
```bash
mkdir -p .agents/skills   # the agent-agnostic standard repo-local skills dir
# wrap repeatedly-used project commands as Skills
# create at least 3 common Skills (e.g. fix-bug / commit / code-review)
```

### E2 Knowledge accumulation incomplete

**Improvement action** (any one of three counts as PASS; local first):

**Path ① strengthen local spec accumulation (recommended; AI consumes it directly)**:
- `specs/` covers at least 5 core modules, each with a design doc + interface definitions
- `openspec/changes/` continuously records medium changes, archiving them to `archive/`
- Let AI read regulations through local files; more reliable than remote wiki search

**Path ② reference the team's remote knowledge base**: add a "## Team Shared Materials" section to `AGENTS.md` or `README.md` listing:
- Team Wiki links (e.g. a Confluence space)
- Shared Skill / Hook repo links
- Business-standards exemplar repos

**Path ③ build an in-project knowledge base**: accumulate ≥10 business/technical docs in the `.docs/` or `knowledge/` directory, indexed in the AGENTS.md Index section.

If all three are missing, start with Path ① — local spec accumulation is the most efficient knowledge form in the AI-collaboration era.

---

## Pillar F: Measurement mechanisms

### F1 devsop_report.md long not updated

**Improvement action**:
1. **Run devsop-eval through an AI coding agent** to create the report (creating the report satisfies the first-evaluation requirement)
2. **Establish a monthly evaluation reminder**: add "ask an AI agent to run devsop-eval" to the team review agenda

### F2 No AI session/memory/failure-case retention

**Improvement action** (any one of three counts as PASS):

**Path ① enable the AI memory store (recommended)**:
```bash
# The agent-agnostic standard memory locations:
#   repo-local: .agents/memory/          (any agent can read/write it)
#   user-level: ~/.agents/projects/<project path slug>/memory/
# Prompt AI in AGENTS.md to actively maintain memory and let it accumulate
# user preferences/project facts/feedback (≥3 memory files + MEMORY.md index)
mkdir -p .agents/memory
```
Memory files are themselves structured AI-session accumulation, easier to reuse than raw logs. Prompt AI in `AGENTS.md` to actively maintain memory.

**Path ② configure a session-log directory**:
```bash
mkdir -p logs/ai-sessions
echo "logs/ai-sessions/" >> .gitignore  # sessions may contain sensitive content
```
Convention: after each significant feature development, save the AI session as `logs/ai-sessions/{YYYY-MM-DD}-{topic}.md`; archive to external storage after 30 days.

> Note: having session logs under `logs/ai-sessions/` or `.agents/sessions/` from the last 30 days automatically satisfies this path.

**Path ③ keep failures.md in git and maintained**:
```bash
git add .docs/failures.md && git commit -m "docs: track failures log"
```
Convention: append after each pitfall fix so historical issues are traceable in git history.

### F3 .docs/ doc changes stalled

**Improvement action**:
1. Check whether there really was no regulation-change need in 60 days (normal if the project is stable)
2. If there were changes but not captured: organize recent code-review feedback and pitfall lessons into the corresponding `.docs/` regulations
3. Establish a mechanism: review at the end of each month, identifying ≥1 regulation update point

### F4 Improvement actions not closed-loop

**Improvement action**:
1. **Review the previous devsop_report.md**: find all FAIL and PARTIAL items and confirm one by one whether they have been improved
2. **Immediately fix 1-2 high-priority FAIL items**: see the improvement suggestions for the corresponding Eval in this document
3. **Establish a closure mechanism**: add a "DEVSOP improvement tracking" agenda item to the team monthly meeting:
   - Have the previous FAIL/PARTIAL items been fixed?
   - After fixing, ask the agent to run `devsop-eval` again and verify the evidence
4. **Mark the improvement trajectory in `.docs/devsop_report.md`**: after each evaluation, compare with the previous result and record the change in the "comparison with the previous evaluation" section

---

## Anti-pattern Specialized Improvements

### Docs severely out of sync with code

**Improvement action**:
1. Sample-verify 5 rules in `.docs/` to confirm they match the current code
2. For mismatches: either update the docs, or fix the code to comply with the regulations
3. For long-unmaintained regulation files: mark with `<!-- TODO: expired, to be updated in 2026-Qx -->` or delete them

### Excessive test mocking

**Improvement action**:
1. Identify directories with a high mock ratio (e.g. `*_mock.go` accounting for >70% of `*_test.go`)
2. Add 1 real integration test per core business flow (using an in-memory SQLite DB / testcontainers)
3. Make it explicit in `.docs/unittest/unittest.md`: the DAL/Repository layer must not mock the DB; use a real test DB

### Sensitive files or artifacts committed

**Improvement action (urgent)**:
```bash
# 1. immediately remove the sensitive files from git history
git rm --cached <sensitive file path>
git commit -m "chore: remove leaked sensitive files"

# 2. if already pushed to remote, rewrite history with git filter-repo (notify all collaborators)
# 3. immediately rotate the leaked keys / credentials
# 4. add the corresponding files to .gitignore
```

### Important decisions not captured in docs

**Improvement action**:
1. Spot-check the 5 most recent large PRs and sync the design decisions from the PR descriptions to the "core design decisions" section of `.docs/architecture.md`
2. Add a PR Review checklist item to `.docs/code-review.md`: "have design decisions been captured in architecture.md or a spec?"

### AGENTS.md shallow

**Improvement action**: refer to the A1 improvement actions and fill in the core 7 sections (tech stack / directory / regulations index / quick start / core conventions / prohibited items / sub-doc routing table)

---

## General Suggestion Generation Rules

When this library does not match a specific scenario, generate suggestions using these principles:

1. **Anchor on Eval ID**: every suggestion must clearly reference 1 Eval ID
2. **Three executable elements**: where to change (file path) + what to change (specific content) + how to change (command or modification example)
3. **Quantify the expected benefit**: after completion, expected Eval rise from X to Y (e.g. "PARTIAL → PASS")
4. **Small granularity**: single suggestion <1 person-day; split anything larger
5. **No empty phrases**: no "strengthen X", "improve Y", "polish Z"; must specify concrete actions
