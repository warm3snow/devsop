---
name: devsop-init
description: Creates a compact, agent-neutral project context with an AGENTS.md entry, core project docs, and lightweight Git Hooks. Use when documenting project facts and quality constraints.
---

# devsop-init

Create a small, useful starting point for project collaboration. The default setup is intentionally compact; add optional documentation only when it serves a real project need.

## What gets created

For a new project with no existing documentation, the default `core` profile creates:

- `AGENTS.md` — generic AI collaboration entry
- `docs/review.md`
- `docs/architecture.md`
- `docs/coding-style.md`
- `docs/code-review.md`
- `docs/unittest/unittest.md`
- Two lightweight Git Hooks: staged whitespace checks and commit-message validation
- `.golangci.yml` for Go projects, when one does not already exist

The `full` profile adds optional API, database, integration-test, DevOps, relationship, glossary, failure, and logging docs to a new documentation set.

## Workflow

Resolve `SKILL_DIR` as the absolute directory containing this `SKILL.md`. Resolve `REPO_ROOT` as the target repository's Git root, or its current directory if it is not a Git repository.

1. Inspect the repository root, README, project configuration, and documentation files. Build a topic inventory covering architecture, interfaces, data, coding conventions, tests, and operations. Use file headings and content, then verify key claims against source/configuration (for example OpenAPI/Swagger, Protocol Buffers, GraphQL schemas, route registrations, migrations, and test/CI commands). Do not use filenames alone to decide a topic is missing.
2. For each topic, classify the evidence as authoritative and useful, incomplete/stale, missing, or conflicting. Preserve existing directory layout and names (for example, `docs/conventions.md` may already be the coding-style authority). When sources conflict, report the paths and discrepancy; do not silently choose, rename, or merge them.
3. Run the initializer from the target repository:
   ```bash
   bash "$SKILL_DIR/scripts/init_docs.sh" "$REPO_ROOT"
   ```
   The initializer uses an existing `docs/` or `.docs/` directory, defaults to visible `docs/` for a new project, and refuses to choose if both exist. For a populated repository it skips bulk template copying. Use `--docs-dir <path>` only after choosing the existing documentation root. Use `--include <template-path>` only for a confirmed gap; otherwise create missing content in the project's established location and naming convention. Do not create a parallel directory or same-topic duplicate.
4. If `AGENTS.md` was generated, complete its project documentation links using the inventory. If it already existed, preserve it and give the user a concise suggested index update rather than editing it automatically.
5. Add optional documentation only when it is relevant and no authoritative source already covers it. For API topics, prefer linking to source-of-truth schemas/specs; summarize only where that improves discoverability.
6. Summarize the topic inventory, authoritative source paths, gaps/conflicts, files changed, and how to run tests.

The main agent can perform every step directly. Sub-agents may be used to speed up independent documentation work, but are never required.

## Initializer behavior

- The script accepts `[repo_root] [--full] [--docs-dir path] [--include template-path]`; without a repository path, it uses the current directory.
- For a new repository with no existing Markdown documentation, the default profile creates the core docs under `docs/`; `--full` also adds optional docs.
- For a repository with existing Markdown documentation, it skips bulk template copying. Explicitly select a missing template with `--include` only after a content review.
- Existing `docs/` or `.docs/` layout and file names are preserved. If both roots exist, specify `--docs-dir` after reviewing them.
- Existing documentation files are not overwritten.
- `AGENTS.md` is generated from `assets/agents.md.tmpl` only when it does not already exist.
- Go lint configuration is added only when absent.
- Git Hooks are installed by `scripts/setup_hooks.sh`.
- The script does not install dependencies, configure an AI product, or create `devsop-init` / `devsop-eval` terminal commands.

## Workflow boundary

This Skill organizes project context and quality constraints; it does not prescribe a task-management or implementation workflow. Follow the workflow the project already uses. Avoid duplicating plans, task records, or documentation topics across tools and files.

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

- `assets/profiles/core/` — starter project docs for new projects or explicitly selected gaps
- `assets/profiles/full/` — optional project docs
- `assets/agents.md.tmpl` and `assets/.golangci.yml` — shared files used by the initializer
- `scripts/init_docs.sh` — project initializer
