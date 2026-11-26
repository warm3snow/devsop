---
name: devsop-init
description: Creates a compact, agent-neutral project context with an AGENTS.md entry, core project docs, and lightweight Git Hooks. Use when documenting project facts and quality constraints.
---

# devsop-init

Create a small, useful starting point for project collaboration. Only four docs matter up front; everything else is added on demand for confirmed gaps.

## What gets created

For a new project with no existing documentation:

- `AGENTS.md` — generic AI collaboration entry
- `docs/architecture.md` — positioning, module breakdown, key flows and decisions
- `docs/api-standards.md` — API protocol, response/error conventions, auth and security baseline
- `docs/coding-style.md` — mandatory rules, naming, error handling, security baseline
- `docs/code-review.md` — submitter rules, reviewer checklist, merge criteria
- Two lightweight Git Hooks: staged whitespace checks and commit-message validation
- `.golangci.yml` for Go projects, when one does not already exist

`--full` adds `docs/optional-docs.md` — a catalog of templates (unit/integration testing, database, logging, DevOps, glossary, pitfall log, upstream/downstream, per-API docs). Docs from the catalog are created one at a time, only for confirmed gaps.

## Greenfield repositories (no code yet)

This skill has two entry modes:

- **Existing code (default):** the workflow above — inventory what exists and make it AI-friendly. This is an independent step, not tied to any task workflow.
- **No code yet (interactive init):** when the target repository is empty, do not scaffold from guesses. Ask the user what the repository will do (purpose, consumers, decided constraints such as language/framework/deployment, reference material), play back a proposed project shape for confirmation, scaffold the confirmed structure, then run the documentation workflow on it. Follow `../devsop-flow/SKILL.md` → "Greenfield init" for the question flow when `devsop-flow` orchestrates; use the same interactive rules when this skill runs standalone.

## Workflow

Resolve `SKILL_DIR` as the absolute directory containing this `SKILL.md`. Resolve `REPO_ROOT` as the target repository's Git root, or its current directory if it is not a Git repository.

1. Inspect the repository root, README, project configuration, and documentation files. Build a topic inventory covering architecture, interfaces, data, coding conventions, tests, and operations. Verify key claims against source/configuration (route registrations, schemas, migrations, CI commands); do not use filenames alone to decide a topic is missing.
2. For each topic, classify the evidence as authoritative and useful, incomplete/stale, missing, or conflicting. Preserve existing directory layout and names (for example, `docs/conventions.md` may already be the coding-style authority). When sources conflict, report the paths and discrepancy; do not silently choose, rename, or merge them.
3. Run the initializer from the target repository:
   ```bash
   bash "$SKILL_DIR/scripts/init_docs.sh" "$REPO_ROOT"
   ```
   The initializer uses an existing `docs/` or `.docs/` directory, defaults to visible `docs/` for a new project, and refuses to choose if both exist. For a populated repository it skips bulk template copying. Use `--docs-dir <path>` only after choosing the existing documentation root. Use `--include <template-path>` only for a confirmed gap; otherwise create missing content in the project's established location and naming convention. Do not create a parallel directory or same-topic duplicate.
4. If `AGENTS.md` was generated, complete its project documentation links using the inventory. If it already existed, preserve it and give the user a concise suggested index update rather than editing it automatically.
5. Beyond the four core docs, add documentation only when a real need is confirmed and no authoritative source covers it. Follow `references/docs-generation.md` for the evidence-first method. When the project uses a specific framework or is a library, the project's own conventions are the authority — this skill does not ship per-framework or per-language specializations.
6. Summarize the topic inventory, authoritative source paths, gaps/conflicts, files changed, and how to run tests.

The main agent can perform every step directly. Sub-agents may be used to speed up independent documentation work, but are never required.

## Initializer behavior

- The script accepts `[repo_root] [--full] [--docs-dir path] [--include template-path]`; without a repository path, it uses the current directory.
- For a new repository with no existing Markdown documentation, the default profile creates the core docs under `docs/`; `--full` also adds the optional-docs catalog.
- For a repository with existing Markdown documentation, it skips bulk template copying. Explicitly select a missing template with `--include` only after a content review.
- Existing `docs/` or `.docs/` layout and file names are preserved. If both roots exist, specify `--docs-dir` after reviewing them.
- Existing documentation files are not overwritten.
- `AGENTS.md` is generated from `assets/agents.md.tmpl` only when it does not already exist.
- Go lint configuration is added only when absent (Go-specific convenience; other languages untouched).
- The script does not install dependencies, configure an AI product, or create `devsop-init` / `devsop-eval` terminal commands.

## Workflow boundary

This Skill organizes project context and quality constraints; it does not prescribe a task-management or implementation workflow. Follow the workflow the project already uses. Avoid duplicating plans, task records, or documentation topics across tools and files.

## References

- `references/docs-generation.md` — evidence-first documentation method (scan → extract → verify → hand off), project-type adjustments
- `assets/docs/` — the four starter docs plus the optional-docs catalog
- `assets/agents.md.tmpl` and `assets/.golangci.yml` — shared files used by the initializer
- `scripts/init_docs.sh` — project initializer
