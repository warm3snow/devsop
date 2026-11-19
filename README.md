# devsop

devsop is a small library of two reusable Skills for starting and improving project development practices.

## Skills

- **devsop-init** inventories existing project guidance and source evidence, then links authoritative docs and adds only confirmed missing context. For a new project it provides starter docs under visible `docs/`; existing layouts and filenames are preserved.
- **devsop-eval** checks project practices against a consistent set of criteria and writes an evidence-based report to the existing report location or the project's documentation root.

These are Skills, not terminal commands. Ask an AI coding agent that supports the Skills format to use `devsop-init` or `devsop-eval` in the target repository. Skill discovery depends on the agent; this repository does not configure an agent product.

## Install

Link both Skills into the standard user-level Skills directory:

```bash
bash install.sh
bash install.sh --check
```

The installer only creates links in `~/.agents/skills/`. It does not install dependencies, configure an AI agent, or create shell commands. The Skills themselves use Bash, Git, and Python's standard library.

## Repository layout

```text
skills/
├── devsop-init/   # Project starter and documentation workflow
│   ├── assets/profiles/core/ # Required project context
│   ├── assets/profiles/full/ # Optional documentation
│   ├── references/ # Shared methodology and optional doc guides
│   └── scripts/    # Initializer and hook setup
└── devsop-eval/   # Evidence-based project assessment
    ├── references/ # Rubric and report format
    └── scripts/    # Evidence collection and validation
rules/             # Language coding standards
scripts/           # Repository validation
```

## Development checks

```bash
bash scripts/validate_skills.sh --strict
bash scripts/pre_commit_check.sh
bash scripts/commit_msg_check.sh
```

See [AGENTS.md](AGENTS.md) for repository contribution conventions.
