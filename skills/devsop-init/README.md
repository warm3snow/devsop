# devsop-init

`devsop-init` is an AI Skill, not a terminal command. Invoke it through an AI coding agent that supports the Skills format.

The default setup creates `AGENTS.md`, five core `.docs/` files, a one-file task note template, two lightweight Git Hooks, and a Go lint config when applicable. Detailed task templates and optional API, database, integration-test, DevOps, relationship, glossary, failure, and logging docs are included in the full profile.

The initializer can also be run directly:

```bash
bash /path/to/skills/devsop-init/scripts/init_docs.sh [repo_root] [--full]
```

Without a repository path, it uses the current directory. Existing documentation files are left untouched.
