---
name: devsop-init
description: Creates a compact, agent-neutral project context with an AGENTS.md entry, core project docs, and lightweight Git Hooks. Use when documenting project facts and quality constraints.
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
- Two lightweight Git Hooks: staged whitespace checks and commit-message validation
- `.golangci.yml` for Go projects, when one does not already exist

The `full` profile adds optional API, database, integration-test, DevOps, relationship, glossary, failure, and logging docs.

## Workflow

Resolve `SKILL_DIR` as the absolute directory containing this `SKILL.md`. Resolve `REPO_ROOT` as the target repository's Git root, or its current directory if it is not a Git repository.

1. Inspect the repository root, README, and project configuration. Identify the language, framework, and available test commands from evidence.
2. Run the initializer from the target repository:
   ```bash
   bash "$SKILL_DIR/scripts/init_docs.sh" "$REPO_ROOT"
   ```
   Use `--full` only when the project needs the optional documentation set.
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
- The default profile creates only the core project docs. `--full` adds optional docs.
- Existing documentation files are not overwritten.
- `AGENTS.md` is generated from `assets/agents.md.tmpl` only when it does not already exist.
- Go lint configuration is added only when absent.
- Git Hooks are installed by `scripts/setup_hooks.sh`.
- The script does not install dependencies, configure an AI product, or create `devsop-init` / `devsop-eval` terminal commands.

## Workflow boundary

This Skill documents project context and quality constraints; it does not prescribe a task-management or implementation workflow. Follow the workflow the project already uses. Avoid duplicating plans or task records across tools.

## References

- `references/docs-generation.md` — evidence-based documentation guidance
- `references/library-context.md` — guidance for libraries
- `references/framework-gozero.md` — extra guidance when the project uses Go-zero
- `references/guide-*.md` — optional document-specific checklists, loaded as needed:

  | Guide | Load when |
  |---|---|
  | `guide-apis.md` | The project exposes APIs |
  | `guide-sqls.md` | The project uses persistent storage |
  | `guide-devops.md` | Environment or deployment docs are needed |
  | `guide-integration-test.md` | Integration-test guidance is needed |
  | `guide-relationship.md` | Upstream/downstream relationships need documenting |
  | `guide-glossary.md` | The project has domain-specific terminology |
  | `guide-failures.md` | There are evidence-backed failure records to capture |
  | `guide-logging.md` | The project has meaningful logging conventions |
  | `guide-unittest.md` | Filling or reviewing unit-test guidance |
  | `guide-coding-style.md` | Filling or reviewing coding conventions |
  | `guide-code-review.md` | Filling or reviewing code-review guidance |

- `assets/profiles/core/` — default project docs
- `assets/profiles/full/` — optional project docs
- `assets/agents.md.tmpl` and `assets/.golangci.yml` — shared files used by the initializer
- `scripts/init_docs.sh` — project initializer
