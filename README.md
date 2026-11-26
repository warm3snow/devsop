# devsop

devsop is a small library of reusable Skills for starting, running, and improving project development practices.

## Skills

**Setup and assessment**

- **devsop-init** inventories existing project guidance and source evidence, then links authoritative docs and adds only confirmed missing context. For a new project it provides four starter docs (`architecture`, `api-standards`, `coding-style`, `code-review`) plus `AGENTS.md`; a `--full` catalog covers on-demand topics (testing, database, logging, DevOps, glossary, pitfalls, relationships). `devsop-init global` initializes an orchestration repo (service registry, derived dependency view, global plan projection rules) instead. For a repository with no code yet it runs an interactive initialization (asks what the repo will do, confirms the shape, scaffolds, then documents it). Existing layouts and filenames are preserved.
- **devsop-eval** checks project practices against a consistent set of criteria and writes an evidence-based report to the existing report location or the project's documentation root.

**Delivery stages** (each standalone, or composed end-to-end by **devsop-flow**)

- **devsop-plan** — challenge the user's input into user stories, acceptance criteria, and test cases (`docs/plans/<date-topic>/`).
- **devsop-design** — map the plan onto the architecture: impact analysis, exact interface changes, and an ordered task list with frontend tasks first.
- **devsop-code** — implement the task list with TDD discipline (failing test first, verified steps, progress ledger).
- **devsop-test** — execute the plan's test cases and report a pass/fail matrix per acceptance criterion.
- **devsop-ship** — deploy to the development environment; optional and always behind an explicit human confirmation gate.
- **devsop-flow** — orchestrate plan → design → code → test → ship (with optional init), or route a request to the right single stage.

These are Skills, not terminal commands. Ask an AI coding agent that supports the Skills format to use a devsop skill in the target repository. Skill discovery depends on the agent; this repository does not configure an agent product.

## Install

Link both Skills into the standard user-level Skills directory:

```bash
bash install.sh
bash install.sh --check
```

The installer only creates links in `~/.agents/skills/`. It does not install dependencies, configure an AI agent, or create shell commands. The Skills themselves use Bash, Git, and Python's standard library.

## Repository layout

```text
install.sh         # Links all bundled skills into ~/.agents/skills/
AGENTS.md          # AI collaboration entry for this repository
README.md          # This file
skills/            # The skills (each dir = one skill, discovered by install.sh)
├── devsop-init/   # Project starter and documentation workflow (incl. greenfield interactive init)
│   ├── assets/docs/    # Four starter docs + optional-docs.md catalog (on-demand topics)
│   ├── references/     # Evidence-first documentation method
│   └── scripts/        # Initializer, hook setup, black-box tests
├── devsop-eval/    # Evidence-based project assessment
│   ├── references/ # Rubric and report format
│   └── scripts/    # Evidence collection, validation, black-box tests
├── devsop-plan/    # Stories, acceptance criteria, test cases
├── devsop-design/  # Impact analysis, interface changes, task list
├── devsop-code/    # TDD implementation of the task list
├── devsop-test/    # Criteria-based verification report
├── devsop-ship/    # Human-confirmed dev-env deployment
└── devsop-flow/    # Stage orchestration and routing
rules/             # Language coding standards (Go / Python / Java / TypeScript / Rust)
scripts/           # This repo's own tooling (validate_skills.sh + hook symlinks)
```

## Language neutrality

The devsop Skills are **language-neutral by design**. The workflow stages (plan → design → code → test → ship) operate on artifacts, acceptance criteria, and project evidence — they never assume a specific programming language, framework, or toolchain. Commands a stage runs (test, lint, deploy) always come from the target project's own configuration (Makefile, package.json, CI config, docs), not from the Skills.

Language-specific content exists only in two clearly marked places:

- `rules/` — per-language style guides (Go / Python / Java / TypeScript / Rust), loaded by the target project as always-on rules when it uses that language.
- `skills/devsop-init/` starter templates — the four core docs are language-neutral skeletons with `{{placeholders}}`; the optional-docs catalog carries per-language hints inline. The `coding-style.md` starter defers per-language detail to `rules/<lang>-style-guide.md`.

Adding a new language means adding a `rules/<lang>-style-guide.md`; the Skills themselves need no change.

## Development checks

```bash
# Validate the skills library (frontmatter, naming, line counts, script syntax)
bash scripts/validate_skills.sh --strict

# Skill-library black-box tests
bash skills/devsop-init/scripts/test_init_docs_profile.sh
bash skills/devsop-eval/scripts/test_doc_discovery.sh

# Git Hook checks
bash scripts/pre_commit_check.sh
bash scripts/commit_msg_check.sh
```

See [AGENTS.md](AGENTS.md) for repository contribution conventions.
