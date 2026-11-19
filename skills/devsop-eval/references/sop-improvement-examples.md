# DEVSOP Improvement Suggestion Examples

## Contents

- [Pillar A: Project AI-friendliness](#pillar-a-project-ai-friendliness) — A1–A7
- [Pillar B: Development coordination](#pillar-b-development-coordination) — B1–B4
- [Pillar C: Quality checks & feedback mechanisms](#pillar-c-quality-checks--feedback-mechanisms) — C1–C6
- [Pillar D: Design & change management](#pillar-d) — D1–D4
- [Pillar E: Shared project knowledge](#pillar-e) — E1–E2
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
| Entry is unwieldy | Split detailed chapters into focused project docs in the existing documentation layout; keep the entry concise and link to authoritative sources |
| Entry is too sparse | Add concise, project-specific facts and links for relevant topics such as stack, structure, validation commands, and constraints |
| Project entry is missing important guidance | Add concise, project-specific facts and links: repository structure, build/test commands, coding/security constraints, and relevant docs. Avoid prescribing a specific agent or task workflow. Reference `assets/agents.md.tmpl` in `devsop-init` |

### A2 README.md incomplete

| Missing section | Improvement action |
|-----------------|--------------------|
| Project background / business goals | Add "## Project Introduction" at the top of the README; explain the business background and target users in 2-3 paragraphs |
| Core feature list | Add "## Core Features", listing 5-10 features as bullets |
| Upstream/downstream dependencies | Add "## External Dependencies", listing the dependent services, SDKs, and infrastructure (DB / Redis / external APIs) |
| Quick start | Add "## Quick Start", giving the complete command sequence from `git clone` → `make dev` |
| Deployment environment requirements | Add "## Environment Requirements", listing Go/Node/Python versions, required service dependencies, and minimal hardware config |
| Notes | Add "## Notes", listing known limitations, incompatible scenarios, and pitfall-avoidance tips |

### A3 Architecture guidance incomplete

| Missing section | Improvement action |
|-----------------|--------------------|
| Overall architecture diagram | Add a verified system overview to the existing authoritative architecture source, using a diagram when it clarifies the design |
| Module division and boundaries | List the top-level directory tree; describe each module's responsibility and what it should not do in 1-2 sentences |
| Data flow | Draw 1-2 core-scenario data-flow sequence diagrams (e.g. "user login", "core business interface") |
| Tech selection rationale | For each key technology (framework/middleware/storage) write "what + why + alternatives and why they were rejected" |
| Core design decisions | List 3-5 project-level key decisions (e.g. "why event-driven", "why monolith rather than microservices") |
| Known tech debt | Add "## Known Tech Debt", listing currently-known but unfixed issues and their planned handling time |

### A4 Core project guidance is incomplete

| Missing file | Improvement action |
|--------------|--------------------|
| Project-specific architecture, coding, review, or testing guidance is missing | Run `devsop-init` or write the missing guidance in the project's established location and naming convention |
| Guidance is a generic placeholder | Replace it with verified project facts and actionable conventions; remove sections that do not apply instead of filling them with boilerplate |

### A5 Generic AI entry missing or gitignored

> **Principle**: `AGENTS.md` at the repo root is the single generic AI collaboration entry shared by all AI coding agents; no tool-specific entry files are required.

| Current state | Improvement action |
|---------------|--------------------|
| `AGENTS.md` missing | Generate it via `devsop-init` (the single generic AI entry) |
| Key files gitignored | Remove discovered authoritative entry/document paths from .gitignore |

### A6 No one-command start

| Current state | Improvement action |
|---------------|--------------------|
| No Makefile or scripts | Create a Makefile with a `dev:` target wrapping the local start commands; or add `scripts.dev` to package.json |
| Command exists but not documented | Explicitly write the single `make dev` command + expected output in the README's "## Quick Start" section |
| Command exists but does not actually run | Walk through it on a clean machine and add the missing dependencies (DB startup, env vars) to the command chain or the README |

### A7 Environment config template missing

| Current state | Improvement action |
|---------------|--------------------|
| No .env.example | Derive required variable names from code and existing configuration, then create a safe template containing placeholders only; never export current environment values |
| Env vars scattered in multiple places | Add a "## Environment Variables" section to the project's existing setup documentation (name + description + placeholder example + whether required) |
| docker-compose.yml exists but no explanation | Add a line to the README quick-start section linking to the project's existing environment configuration guidance |

---

## Pillar B: Development coordination

### B1 Project workflow is hard to discover

**Improvement action**: add a short "Development workflow" section to `AGENTS.md` or README that links to the team's existing issue, implementation, verification, and review process. Keep the existing workflow as the source of truth; do not copy it into a second planning system.

### B2 Ownership and responsibilities are unclear

**Improvement action**: document the actual maintainers, service owners, or review responsibilities in `CODEOWNERS`, `AGENTS.md`, or the team's contributor guide. Do not invent PM/QA/R&D roles when the team does not use them.

### B3 Change context and outputs are hard to find

**Improvement action**: link the team's existing issue tracker, pull-request process, test instructions, and project documentation from the repository entry point. Use the team's chosen systems rather than adding a mandatory task-plan directory.

### B4 Branch/Commit conventions not documented

**Improvement action**:

1. **Document commit conventions**: add a "## Commit Conventions" section to the project's existing contributor or review guidance:
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

### C1 Commit / Push conventions are hard to discover

**Improvement action**: document the project's actual commit and push conventions in its existing contributor guidance. Do not prescribe a commit format, verification command, branch model, or history-rewrite behavior that the maintainers have not adopted.

### C2 No CI pipeline

> Any CI platform counts: GitHub Actions / GitLab CI / Jenkins / Argo CD / etc. Either of two counts as having CI: ① a CI config checked into the repo (`.github/workflows/` / `.gitlab-ci.yml` / `Jenkinsfile`); ② README/deployment.md explicitly writes the CI platform URL.

| Current state | Improvement action |
|---------------|--------------------|
| Path ①: CI config checked in | Create a CI workflow at the repo root (e.g. `.github/workflows/ci.yml` / `.gitlab-ci.yml` / `Jenkinsfile`), stages: Checkout → Build → Lint → UnitTest → Coverage → IntegrationTest. Skeleton below |
| Path ②: pipeline configured on the CI platform, not in the repo | Add a "## CI Pipeline" section to the README or existing deployment guidance, including platform name, clickable URL, trigger conditions, stages, and failure contact |
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
3. **List applicable prohibited items in the project's existing review guidance**; do not copy unrelated generic rules.

### C4 Branch protection and Review flow not documented

**Improvement action**: add a section to the project's existing review guidance listing:
- No direct pushes to main / master (always feature branch + MR)
- MRs must reference an issue-tracker ticket (MR title/description contains the ticket reference, e.g. `--story=<id>` / `--bug=<id>` or `#<id>`, per the team's tracker convention)
- MR line count ≤500; anything larger must be split
- At least 1 Reviewer approval required before merge
- AI-generated code must be human-reviewed before commit (including an "I understand this code" confirmation)

If using a code platform that supports Branch Protection (e.g. Gongfeng), configure repo protection rules accordingly.

### C5 Recurring-issue feedback is missing

**Improvement action**:
1. **Record representative recurring issues in the existing troubleshooting or incident source**:
   ```markdown
   ## 2026-05-18 — short title
   **Symptom**: ...
   **Root cause**: ...
   **Fix**: ...
   **Prevention**: (which regulation to update / what test to add)
   ```
2. **Establish a mechanism**: document how maintainers record and review recurring issues in the project's existing guidance.
3. **Review periodically**: convert relevant lessons into code, tests, or authoritative guidance when useful.

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

4. **Document test scope and run commands in the project's existing testing guidance**, clarifying the difference between unit and integration tests.

---

## Pillar D: Design & change management

### D1 Significant change intent is missing

**Improvement action**: for future substantial changes, record the problem and expected outcome in the team's existing issue, pull request, design note, or equivalent. Keep small changes lightweight.

### D2 Change outcomes are hard to trace

**Improvement action**: ensure existing change records link to the resulting pull request/commit and record completion or follow-up status. Use the team's current tracker rather than adding another task system.

### D3 Verification is insufficient for change risk

**Improvement action**: add the relevant automated or manual check to the existing test/CI workflow. For a defect, add a regression check when practical; TDD is optional, not a required process.

### D4 Project guidance is stale

**Improvement action**: update the relevant existing documentation source with behavior, setup, interface, or operational changes. Do not add documentation for changes with no lasting user or maintainer impact.

---

## Pillar E: Shared project knowledge

### E1 Project guidance is difficult to discover

**Improvement action**: link substantive project guidance from the README or `AGENTS.md`. Guidance may be local docs, a team handbook, scripts, or optional agent Skills; no specific format or minimum count is required.

### E2 Shared project knowledge is incomplete

**Improvement action**: record the specific missing decision, operational detail, or recurring pitfall in the existing project docs, issue tracker, or team handbook, then link it from the project entry point. Do not create a documentation quota.

---

## Pillar F: Measurement mechanisms

### F1 devsop_report.md long not updated

**Improvement action**:
1. Run `devsop-eval` to create the initial report.
2. Set a review cadence that fits the project and assign an owner for acting on findings.

### F2 Important decisions and recurring failures are not retained

**Improvement action**: document a recent, representative design decision or recurring failure in the project's existing decision record, incident review, issue tracker, or troubleshooting guide. Link the record from the README or project docs index. Do not store AI conversations or user-level agent memory as a project requirement.

**Path ③ keep recurring-issue records in the project's version-controlled source**: maintain the existing troubleshooting, incident, or retrospective records so useful lessons remain traceable.

### F3 Project-guidance changes stalled

**Improvement action**:
1. Check whether there really was no regulation-change need in 60 days (normal if the project is stable)
2. If there were relevant changes not captured: update the authoritative docs for the affected topics
3. Establish a mechanism: review at the end of each month, identifying ≥1 regulation update point

### F4 Improvement actions not closed-loop

**Improvement action**:
1. **Review the previous devsop_report.md**: find all FAIL and PARTIAL items and confirm one by one whether they have been improved
2. **Immediately fix 1-2 high-priority FAIL items**: see the improvement suggestions for the corresponding Eval in this document
3. **Establish a closure mechanism**: add a "DEVSOP improvement tracking" agenda item to the team monthly meeting:
   - Have the previous FAIL/PARTIAL items been fixed?
   - After fixing, ask the agent to run `devsop-eval` again and verify the evidence
4. **Mark the improvement trajectory in the evaluation report**: preserve its existing location and compare with the previous result

---

## Anti-pattern Specialized Improvements

### Docs severely out of sync with code

**Improvement action**:
1. Sample-verify relevant project guidance against current code and configuration
2. For mismatches: either update the docs, or fix the code to comply with the regulations
3. For long-unmaintained regulation files: mark with `<!-- TODO: expired, to be updated in 2026-Qx -->` or delete them

### Excessive test mocking

**Improvement action**:
1. Identify directories with a high mock ratio (e.g. `*_mock.go` accounting for >70% of `*_test.go`)
2. Add 1 real integration test per core business flow (using an in-memory SQLite DB / testcontainers)
3. Document the verified database-testing approach in the project's existing test guidance

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
1. Spot-check recent substantial PRs and sync lasting decisions to the authoritative architecture/design source
2. Add a review checklist item to the existing review guidance: "Have lasting design decisions been captured in the project's authoritative design source?"

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
