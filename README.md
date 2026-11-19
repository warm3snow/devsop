# devsop

devsop is a small library of two reusable Skills for starting and improving project development practices.

## Skills

- **devsop-init** creates a compact project starter: `AGENTS.md`, core `.docs/` files, a lightweight task note template, and Git Hooks. Detailed task templates and optional documentation are available with the full profile.
- **devsop-eval** checks project practices against a consistent set of criteria and writes an evidence-based report to `.docs/devsop_report.md`.

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
└── devsop-eval/   # Evidence-based project assessment
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
