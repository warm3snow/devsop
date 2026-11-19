# devsop-init

`devsop-init` is an AI Skill, not a terminal command. Invoke it through an AI coding agent that supports the Skills format.

The default setup creates `AGENTS.md`, five core `.docs/` files, two lightweight Git Hooks, and a Go lint config when applicable. Optional API, database, integration-test, DevOps, relationship, glossary, failure, and logging docs are included in the full profile.

The source assets are grouped under `assets/profiles/core/` and `assets/profiles/full/`. Both profiles include the core docs; `--full` adds optional docs. Existing project files are never overwritten.

The initializer can also be run directly:

```bash
bash /path/to/skills/devsop-init/scripts/init_docs.sh [repo_root] [--full]
```

Without a repository path, it uses the current directory. Existing documentation files are left untouched.
