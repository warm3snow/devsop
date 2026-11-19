# devsop-init

`devsop-init` is an AI Skill, not a terminal command. Invoke it through an AI coding agent that supports the Skills format.

For a new project without existing documentation, the default setup creates `AGENTS.md`, five core `docs/` files, two lightweight Git Hooks, and a Go lint config when applicable. If project documentation already exists, the initializer leaves it in place and skips bulk template copying. Optional API, database, integration-test, DevOps, relationship, glossary, failure, and logging docs are included in the full profile.

The source assets are grouped under `assets/profiles/core/` and `assets/profiles/full/`. Both profiles include the core docs; `--full` adds optional docs. Existing directory layout and file names are preserved. Use `--docs-dir` to select an existing documentation root when needed, and `--include` only for confirmed gaps.

The initializer can also be run directly:

```bash
bash /path/to/skills/devsop-init/scripts/init_docs.sh [repo_root] [--full] [--docs-dir path] [--include template-path]
```

Without a repository path, it uses the current directory. Existing documentation files are left untouched.
