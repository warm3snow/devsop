# code-review.md Special Sub-Agent Instructions

> This file serves as the **supplementary instructions** for the `code-review.md` sub-agent, on top of the common prompt. The main Agent passes it along when dispatching.
> Target: `.harness/docs/code-review.md`.

---

## Core Goal

Replace the `{{placeholder}}` values and common conventions in `.harness/docs/code-review.md` with real project values (main branch name / build-check commands / coverage threshold), and draw a clear boundary with the top-level `.harness/review.md`.

---

## Boundary Notes (read first)

| File | Positioning | Controller |
|------|------|--------|
| `.harness/review.md` | AI Code Review checklist (for AI self-review + AI-assisted Review) | skill-controlled, not customized by the project |
| `.harness/docs/code-review.md` | Team manual Review process conventions (submitter constraints / Reviewer checklist / merge criteria) | project-customized; this Agent fills it |

The two are **complementary, not merged**: code-review.md does not copy review.md's checklist items; the Reviewer checklist focuses on process and manual-judgment items; in terms of references, code-review.md can point to `../../review.md` in the "AI-assisted Review" section.

---

## Steps

### 1. Collect project facts

- Main branch name: use `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || git branch -a` to determine `main` / `master` / other, replacing `{{main / master}}`
- Self-check commands: read `Makefile` (or `package.json` scripts / CI config) to confirm whether `make build` / `make lint` / `make ut` actually exist; if not, replace them with actual commands (e.g. `go build ./...` / `golangci-lint run` / `go test ./...`)
- Coverage threshold: extract the actual threshold from CI config / `.golangci.yml` / `Makefile`; without evidence keep the default ≥60%
- commit message format: read `.git/hooks/commit-msg` or `commit_msg_check.sh`, confirm the actual validated type list and TAPD ticket number format (`--story=<id>` / `--bug=<id>`), aligning with the clauses in §1 / §2
- Merge criteria: if the project's CI / GitLab has an explicit approver-count configuration (`.gitlab-ci.yml` / CODEOWNERS), fill in §5 per the actual values

### 2. Generate / update the document

- "Scope" section: fill in the actual main branch name
- §1 Submitter constraints / §2 Self-check checklist: replace with real commands and thresholds; when a command has no corresponding Makefile target, write the shell command directly
- §3 Reviewer checklist: keep the template structure; if the project has no DB (Agent D has already determined `skipped(no database)`) → delete SQL-injection-related items or mark "this project has no DB, N/A"; framework-related items (e.g. go-zero) are kept only when the main Agent injects framework context
- §5 Merge criteria: align CI check items with the real CI pipeline (delete check items that do not exist)
- "References" section: fix broken links (`testing.md` → `unittest/unittest.md`; `api-standards.md` → `apis/api-standards.md`; delete that line for projects without APIs)

---

## Constraints

- Only touch `.harness/docs/code-review.md`; do not touch other docs, do not touch the top-level `review.md`
- Commands / thresholds / branch names must come from real evidence; fabricating is forbidden; fields without evidence keep `<!-- TODO(devsop.init) -->`
- Forbidden to copy the entire AI checklist from review.md into this file — see "Boundary Notes" for the two files' responsibilities
- No skipped determination: every project has a Review process
