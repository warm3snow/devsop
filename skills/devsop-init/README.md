# devsop-init

`devsop-init` is an AI Skill, not a terminal command. Invoke it through an AI coding agent that supports the Skills format.

For a new project without existing documentation, the default setup creates `AGENTS.md` plus four core `docs/` files (architecture, API standards, coding style, code review), two lightweight Git Hooks, and a Go lint config when applicable. If project documentation already exists, the initializer leaves it in place and skips bulk template copying. `--full` adds `docs/optional-docs.md`, a catalog of on-demand templates (unit/integration testing, database, logging, DevOps, glossary, pitfall log, upstream/downstream, per-API docs) — specific docs are created from it only for confirmed gaps.

**`devsop-init global`** initializes an *orchestration repo* — the repo that owns global requirements across multiple service repos and dispatches projections to them. It creates `AGENTS.md` with an Orchestration section, a system-view `architecture.md`, the hand-maintained `docs/services.md` service registry, a derived `docs/service-dependencies.md` view, and `docs/plans/README.md` projection rules. Code-oriented docs, Git hooks, and lint config are skipped. See `SKILL.md` ("Entry modes" and "Global profile") for the doc-set rationale.

The source assets live under `assets/docs/` — four starter docs plus `optional-docs.md` (the on-demand catalog); orchestration-repo docs live under `assets/docs/global/`. Existing directory layout and file names are preserved. Use `--docs-dir` to select an existing documentation root when needed, and `--include` only for confirmed gaps (standard profile only).

Users invoke the skill through an AI agent (`devsop-init`, `devsop-init global`) and never run the script themselves; the agent resolves the target repo and profile. The initializer can still be run directly for testing:

```bash
bash /path/to/skills/devsop-init/scripts/init_docs.sh [repo_root] [--profile core|global] [--full] [--docs-dir path] [--include template-path]
```

Without a repository path, it uses the current directory. Existing documentation files are left untouched.
