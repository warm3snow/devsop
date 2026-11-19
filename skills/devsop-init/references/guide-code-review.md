# Code Review Documentation Guide

> Use this guide only after the project documentation inventory identifies a gap in review-process guidance. Adapt the target to the project's existing documentation location and naming convention.

---

## Core Goal

Replace template placeholders with verified project values (main branch name / build-check commands / coverage threshold). Do not create a second review document when an existing authoritative source already covers the topic; link or update that source as appropriate.

---

## Boundary Notes (read first)

| File | Positioning | Controller |
|------|------|--------|
| AI-assisted review guidance | Checklist for AI self-review and AI-assisted review | May be part of a combined review guide |
| Team review process guidance | Submitter constraints / Reviewer checklist / merge criteria | Use the project's authoritative review source |

When both topics are documented, keep their responsibilities clear; do not require separate files.

---

## Steps

### 1. Collect project facts

- Main branch name: use `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || git branch -a` to determine `main` / `master` / other, replacing `{{main / master}}`
- Self-check commands: read `Makefile` (or `package.json` scripts / CI config) to confirm whether `make build` / `make lint` / `make ut` actually exist; if not, replace them with actual commands (e.g. `go build ./...` / `golangci-lint run` / `go test ./...`)
- Coverage threshold: extract the actual threshold from CI config / `.golangci.yml` / `Makefile`; without evidence keep the default ≥60%
- commit message format: read `.git/hooks/commit-msg` or `commit_msg_check.sh`, confirm the actual validated type list and issue-tracker ticket number format (`--story=<id>` / `--bug=<id>` or `#<id>`), aligning with the clauses in §1 / §2
- Merge criteria: if the project's CI / GitLab has an explicit approver-count configuration (`.gitlab-ci.yml` / CODEOWNERS), fill in §5 per the actual values

### 2. Generate / update the document

- "Scope" section: fill in the actual main branch name
- §1 Submitter constraints / §2 Self-check checklist: replace with real commands and thresholds; when a command has no corresponding Makefile target, write the shell command directly
- §3 Reviewer checklist: keep the template structure; if the project has no DB (Agent D has already determined `skipped(no database)`) → delete SQL-injection-related items or mark "this project has no DB, N/A"; framework-related items (e.g. go-zero) are kept only when the main agent injects framework context
- §5 Merge criteria: align CI check items with the real CI pipeline (delete check items that do not exist)
- "References" section: link to the project's actual testing and API sources when they exist; remove irrelevant links.

---

## Constraints

- Only create or update the selected authoritative review source when a gap is confirmed; preserve unrelated docs.
- Commands / thresholds / branch names must come from real evidence; fabricating is forbidden; fields without evidence keep `<!-- TODO(devsop-init) -->`
- Forbidden to copy the entire AI checklist from review.md into this file — see "Boundary Notes" for the two files' responsibilities
- No skipped determination: every project has a Review process
