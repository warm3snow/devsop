# devsop — Team R&D DEVSOP Skills Library

## Project Background and Business Goals

This repository is the team R&D DEVSOP (Standard Operating Procedures) **CodeBuddy Skills library**, not a business application. It accumulates and distributes reusable AI collaboration conventions and quality-assessment capabilities for installation and use by business projects, with the goal of keeping the AI entry and R&D conventions consistent across multiple tools (CodeBuddy / Claude Code / Cursor / Gemini, etc.) and multi-person collaboration.

Problems it solves:
- Scattered, duplicated AI entry files → unified as a single source of truth in `AGENTS.md` + symlinks to abstract tool differences.
- Projects lacking AI-friendly structure, quality gates, and change flows → one-command scaffolding with `devsop.init`, quantified maturity with `devsop.eval`.
- No unified quantitative standard for Go project code quality → `go-quality-scorer` provides six-dimension scoring.

## Core Feature List

- **`devsop.init`**: one-command creation of the DEVSOP directory structure in the target project (`AGENTS.md` / `README.md` / `ARCHITECTURE.md` / `.harness/` regulations library + Git Hooks + symlinks).
- **`devsop.eval`**: read-only DEVSOP compliance audit of the target project (six pillars, 28 Eval items, anti-pattern detection), producing `.harness/devsop_report.md`.
- **`go-quality-scorer`**: six-dimension code-quality scoring of Go projects (correctness / security / maintainability & scale-complexity / testing / architecture / performance), outputting a JSON report.

## Repository Structure

```
skills/
├── devsop.init/            # DEVSOP directory scaffolding Skill
│   ├── SKILL.md
│   ├── references/      # templates + sub-agent instructions + hooks
│   └── assets/          # copyable configs such as .golangci.yml
├── devsop.eval/            # DEVSOP maturity audit Skill
│   ├── SKILL.md
│   ├── references/      # scoring criteria / report template / improvement examples
│   └── scripts/         # detection scripts + JSON validation
└── go-quality-scorer/   # Go code quality scoring Skill
    ├── SKILL.md
    ├── references/      # per-dimension guides + D3 metric description
    ├── scripts/         # main scorer (Python) + metric collection (Go)
    └── examples/        # migration guide + example report
```

## Installation and Invocation

Skills are discovered and invoked by CodeBuddy in the target project by the `skills/<name>` path. This repository itself needs no build or running service.

Entry-point invocation of each Skill (run at the target project root):

```bash
devsop.init              # initialize the DEVSOP directory (supports --dry-run / --skip-harness / --only / --update-only)
devsop.eval              # audit DEVSOP compliance (supports --dry-run / --only / --json / --json-only / --diff-from)
```

`go-quality-scorer` requires installing the external toolchain first, then running the main script:

```bash
# Install dependency tools
brew install gocyclo golangci-lint scc
go install github.com/AllanDay/gocognit@latest
go install github.com/boyter/scc@latest

# Score a Go project
python3 skills/go-quality-scorer/scripts/go-quality-scorer-v1.1.py /path/to/go/project
cat go-quality-report-v1.1.json | jq '.overall_score, .rating'
```

## Collaboration Conventions

- **`$SKILL_DIR` and `$REPO_ROOT` are strictly separated**: Skills only read the install directory and write only to the target project directory; never write to this repository or `$HOME`.
- **No auto-commit**: `devsop.init` / `devsop.eval` do not run `git add` / `git commit`; changes are left for the user to review.
- **Fixed team tool stack**: the DEVSOP audit is based on Jenkins (CI), Tapd (Issues; commit messages use `--story=<id>` / `--bug=<id>`), and self-hosted Renovate (dependencies); GitHub Actions / GitLab CI / Jira / Dependabot are not introduced.
- The AI collaboration entry for this repository is [CODEBUDDY.md](CODEBUDDY.md).
