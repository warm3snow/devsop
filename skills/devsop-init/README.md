# devsop-init

`devsop-init` is an AI Skill, not a terminal command. Invoke it through an AI coding agent that supports the Skills format.

For a new project without existing documentation, the default setup creates `AGENTS.md` plus four core `docs/` files (architecture, API standards, coding style, code review), two lightweight Git Hooks, and a Go lint config when applicable. If project documentation already exists, the initializer leaves it in place and skips bulk template copying. `--full` adds `docs/optional-docs.md`, a catalog of on-demand templates (unit/integration testing, database, logging, DevOps, glossary, pitfall log, upstream/downstream, per-API docs) — specific docs are created from it only for confirmed gaps.

The source assets live under `assets/docs/` — four starter docs plus `optional-docs.md` (the on-demand catalog). Existing directory layout and file names are preserved. Use `--docs-dir` to select an existing documentation root when needed, and `--include` only for confirmed gaps.

The initializer can also be run directly:

```bash
bash /path/to/skills/devsop-init/scripts/init_docs.sh [repo_root] [--full] [--docs-dir path] [--include template-path]
```

Without a repository path, it uses the current directory. Existing documentation files are left untouched.
