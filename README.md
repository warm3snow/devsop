# devsop — Team R&D DEVSOP Skills Library

## Project Background and Business Goals

This repository is the team R&D DEVSOP (Standard Operating Procedures) **AI Skills library**, not a business application. It accumulates and distributes reusable AI collaboration conventions and quality-assessment capabilities for use by business projects, with the goal of keeping the AI entry and R&D conventions consistent across all AI coding agents (via the agent-agnostic `AGENTS.md` entry and `~/.agents/` standard skill locations) and multi-person collaboration.

Problems it solves:
- Scattered, duplicated AI entry files → unified as a single source of truth in `AGENTS.md` (the generic entry shared by all AI agents).
- Projects lacking AI-friendly structure, quality gates, and change flows → one-command scaffolding with `devsop-init`, quantified maturity with `devsop-eval`.

## Core Feature List

- **`devsop-init`**: one-command creation of the DEVSOP directory structure in the target project (`AGENTS.md` / `.docs/` regulations library + Git Hooks + the `clarify` skill under `.agents/skills/`).
- **`devsop-eval`**: read-only DEVSOP compliance audit of the target project (six pillars, 28 Eval items, anti-pattern detection), producing `.docs/devsop_report.md`.

## Repository Structure

```
skills/
├── devsop-init/            # DEVSOP directory scaffolding Skill
│   ├── SKILL.md
│   ├── references/      # templates + sub-agent instructions + hooks
│   └── assets/          # copyable configs such as .golangci.yml
├── devsop-eval/            # DEVSOP maturity audit Skill
│   ├── SKILL.md
│   ├── references/      # scoring criteria / report template / improvement examples
│   └── scripts/         # detection scripts + JSON validation

rules/                      # always-on language coding standards for AI agents
├── go-style-guide.md       #   Go (Google Golang style guide baseline)
├── python-style-guide.md   #   Python (PEP 8 + Google Python style baseline)
├── java-style-guide.md     #   Java (Google Java style guide baseline)
├── typescript-style-guide.md  # TypeScript/JS (Google TS style + gts baseline)
└── rust-style-guide.md     #   Rust (rustfmt + clippy + API Guidelines baseline)
```

## Installation and Invocation

Install the skills into the agent-agnostic standard user-level skills directory, then let your AI coding agent discover them:

```bash
bash install.sh            # symlinks skills/ → ~/.agents/skills/ (auto-discovers skills/*/SKILL.md)
bash install.sh --check    # verify the symlinks without changes
```

Only `devsop-init` and `devsop-eval` are distributed as standalone skills. Skills are discovered and invoked by the AI coding agent in the target project by the `skills/<name>` path. This repository itself needs no build or running service.

Entry-point invocation of each Skill (run at the target project root):

```bash
devsop-init              # initialize the DEVSOP directory (supports --dry-run / --skip-harness / --only / --update-only)
devsop-eval              # audit DEVSOP compliance (supports --dry-run / --only / --json / --json-only / --diff-from)
```

## Skill Scope

The library intentionally maintains two standalone skills: `devsop-init` for project onboarding and `devsop-eval` for maturity evaluation. Keep additional capabilities out of the default installation unless they are necessary to deliver one of these two workflows.

## Collaboration Conventions

- **`$SKILL_DIR` and `$REPO_ROOT` are strictly separated**: Skills only read the install directory and write only to the target project directory; never write to this repository or `$HOME`.
- **No auto-commit**: `devsop-init` / `devsop-eval` do not run `git add` / `git commit`; changes are left for the user to review.
- **Tool-agnostic audit**: the DEVSOP audit does not mandate a specific CI / issue-tracker / dependency-management stack. It evaluates whether the project consistently uses its team-designated tools (any of Jenkins, GitHub Actions, GitLab CI, TAPD, GitHub Issues, Jira, Renovate, Dependabot, etc.), and the commit-message ticket reference convention is configurable (default `--story=<id>` / `--bug=<id>`, GitHub-style `#<id>` also accepted).
- The AI collaboration entry for this repository is [AGENTS.md](AGENTS.md).
