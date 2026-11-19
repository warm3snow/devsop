---
name: devsop-init
description: Creates a compact DEVSOP starter structure with an AGENTS.md entry, core project docs, a task template, and lightweight Git Hooks. Use when setting up AI collaboration and project documentation.
---

# devsop-init

Create a small, useful starting point for project collaboration. The default setup is intentionally compact; add optional documentation only when it serves a real project need.

## What gets created

The default `core` profile creates:

- `AGENTS.md` — generic AI collaboration entry
- `.docs/review.md`
- `.docs/architecture.md`
- `.docs/coding-style.md`
- `.docs/code-review.md`
- `.docs/unittest/unittest.md`
- `.docs/plans/_template/00-overview.md` — lightweight task note
- Two lightweight Git Hooks: staged whitespace checks and commit-message validation
- `.golangci.yml` for Go projects, when one does not already exist

The `full` profile adds detailed task-stage templates and optional API, database, integration-test, DevOps, relationship, glossary, failure, and logging docs.

## Workflow

Resolve `SKILL_DIR` as the absolute directory containing this `SKILL.md`. Resolve `REPO_ROOT` as the target repository's Git root, or its current directory if it is not a Git repository.

1. Inspect the repository root, README, and project configuration. Identify the language, framework, and available test commands from evidence.
2. Run the initializer from the target repository:
   ```bash
   bash "$SKILL_DIR/scripts/init_docs.sh" "$REPO_ROOT"
   ```
   Use `--full` only when the project wants detailed task-stage templates and the complete optional documentation set.
3. Read the generated `AGENTS.md`, `.docs/architecture.md`, and `.docs/coding-style.md`; fill their project-specific content using evidence from the code and configuration. Do not invent unknown details—mark them as TODO for the project owner.
4. Add optional documentation only when it is relevant:
   - APIs: `.docs/apis/`
   - Database: `.docs/sqls/`
   - Integration tests: `.docs/integration_test/`
   - Environment and deployment: `.docs/devops/`
   - System relationships, failures, glossary, and logging: corresponding `.docs/` files
5. Summarize the created files, any project facts that need confirmation, and how to run tests.

The main agent can perform every step directly. Sub-agents may be used to speed up independent documentation work, but are never required.

## Initializer behavior

- The script accepts `[repo_root] [--full]`; without a repository path, it uses the current directory.
- The default profile creates the core docs and one lightweight task note template. `--full` includes detailed task-stage templates and optional docs.
- Existing documentation files are not overwritten.
- `AGENTS.md` is generated from `assets/agents.md.tmpl` only when it does not already exist.
- Go lint configuration is added only when absent.
- Git Hooks are installed by `scripts/setup_hooks.sh`.
- The script does not install dependencies, configure an AI product, or create `devsop-init` / `devsop-eval` terminal commands.

## Task workflow

For substantial work, create a task directory from `.docs/plans/_template/` and record the relevant details:

1. Clarify requirements
2. Plan the change and tests
3. Implement
4. Run unit tests
5. Deploy or run locally when applicable
6. Run integration tests when applicable
7. Update project docs
8. Review the diff
9. Commit with the project's conventions

Adapt the workflow to the change; do not create empty artifacts for irrelevant stages.

## References

- `references/docs-generation.md` — evidence-based documentation guidance
- `references/library-context.md` — guidance for libraries
- `references/framework-gozero.md` — Go-zero project guidance
- `references/special-agent-*.md` — optional focused prompts for independent documentation tasks
- `assets/docs-skeleton/` — core and optional documentation templates
- `assets/plans-template/` — task workflow templates
- `scripts/init_docs.sh` — project initializer
