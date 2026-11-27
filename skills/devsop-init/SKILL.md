---
name: devsop-init
description: Creates a compact, agent-neutral project context with an AGENTS.md entry, core project docs, and lightweight Git Hooks. Supports a global mode for orchestration repos. Use when documenting project facts and quality constraints; "devsop-init global" initializes an orchestration repo.
---

# devsop-init

Create a small, useful starting point for project collaboration. Only four docs matter up front; everything else is added on demand for confirmed gaps.

## Entry modes

The caller states the intent; the agent resolves everything else — there is no terminal command:

- **`devsop-init`** (or "document this project / make it AI-friendly") — standard profile for the current repository. The agent resolves `REPO_ROOT` as the target repository's Git root (or the current directory) and runs the workflow below.
- **`devsop-init global`** (or "initialize this orchestration repo") — global profile for an orchestration repo. The agent resolves the target repo the same way (the user's current repo/working directory, unless they name another path), runs the initializer with `--profile global`, then helps fill `docs/services.md` and the Orchestration section in AGENTS.md. Use this mode when the target repo will own global requirements and dispatch projections to service repos, per the orchestration rules below.
- If the mode is ambiguous (for example the repo could be either a service repo or an orchestration repo), ask one question before running; never infer the profile from repo content.

## What gets created

The profile determines the doc set (explicitly declared, never inferred from repo content).

### Standard profile (default)

- `AGENTS.md` — generic AI collaboration entry
- `docs/architecture.md` — positioning, module breakdown, key flows and decisions
- `docs/api-standards.md` — API protocol, response/error conventions, auth and security baseline
- `docs/coding-style.md` — mandatory rules, naming, error handling, security baseline
- `docs/code-review.md` — submitter rules, reviewer checklist, merge criteria
- Two lightweight Git Hooks: staged whitespace checks and commit-message validation
- `.golangci.yml` for Go projects, when one does not already exist

`--full` adds `docs/optional-docs.md` — a catalog of templates (unit/integration testing, database, logging, DevOps, glossary, pitfall log, upstream/downstream, per-API docs). Docs from the catalog are created one at a time, only for confirmed gaps.

### Global profile (`devsop-init global`)

For the orchestration repo in a multi-repo system (see `../devsop-flow/SKILL.md` for how projections are dispatched). Every generated doc answers a cross-service question; code-oriented docs (coding style, code review, API standards), Git hooks, and lint config are skipped:

- `AGENTS.md` — generic entry plus an **Orchestration** section (service registry handling, projection dispatch and back-link rules, sync-before-plan, integration verification here)
- `docs/architecture.md` — system topology and cross-service flows (module breakdown = services from `docs/services.md`); links to service repos instead of copying their content
- `docs/services.md` — hand-maintained service registry: the only hand-edited input (`source: dev` rows point at devsop-managed repos; `manual` rows record external platforms / 中台 metadata)
- `docs/service-dependencies.md` — derived capability/dependency view with failure-propagation matrix; regenerated from `services.md` + dev repos' AGENTS.md/architecture.md before planning; never hand-edited
- `docs/plans/README.md` — projection rules: global plans are authoritative, service repos receive generated projections under `docs/plans/<dir-id>/` with a back-link

## Greenfield repositories (no code yet)

Greenfield handling is orthogonal to the profile choice (standard or global):

- **Existing code (default):** the workflow above — inventory what exists and make it AI-friendly. This is an independent step, not tied to any task workflow.
- **No code yet (interactive init):** when the target repository is empty, do not scaffold from guesses. Ask, one at a time: (1) what the repository should do, in the user's words; (2) who consumes it — users, other services, cron; (3) constraints already decided — language, framework, deployment target, team conventions; (4) reference material — an existing repo, a doc, a spec. Play back the proposed project shape (type, stack, structure, tooling) and ask for confirmation before scaffolding. If the answers are thin, propose a minimal conventional stack (the user's strongest hint, else the team's most common language) and confirm. Scaffold the confirmed structure (README, gitignore, starter code, build/test commands), then run this skill's documentation workflow on the result. For `devsop-init global` the questions target the whole system: what services exist (or are planned), which are devsop-managed repos vs external platforms (中台), and how they depend on each other — the answers go straight into `docs/services.md`. This section is the authority for greenfield init whether this skill runs standalone or under `devsop-flow`.

## Workflow

Resolve `SKILL_DIR` as the absolute directory containing this `SKILL.md`. Resolve `REPO_ROOT` as the target repository's Git root (the user's current repository or working directory unless they name a specific path), or its current directory if it is not a Git repository. Choose the profile from the entry mode above (default `core`; `global` for `devsop-init global`).

1. Inspect the repository root, README, project configuration, and documentation files. Build a topic inventory covering architecture, interfaces, data, coding conventions, tests, and operations. Verify key claims against source/configuration (route registrations, schemas, migrations, CI commands); do not use filenames alone to decide a topic is missing.
2. For each topic, classify the evidence as authoritative and useful, incomplete/stale, missing, or conflicting. Preserve existing directory layout and names (for example, `docs/conventions.md` may already be the coding-style authority). When sources conflict, report the paths and discrepancy; do not silently choose, rename, or merge them.
3. Run the initializer from the target repository, passing the chosen profile:
   ```bash
   bash "$SKILL_DIR/scripts/init_docs.sh" "$REPO_ROOT" --profile <core|global>
   ```
   The initializer uses an existing `docs/` or `.docs/` directory, defaults to visible `docs/` for a new project, and refuses to choose if both exist. For a populated repository it skips bulk template copying. Use `--docs-dir <path>` only after choosing the existing documentation root. Use `--include <template-path>` only for a confirmed gap; otherwise create missing content in the project's established location and naming convention. Do not create a parallel directory or same-topic duplicate.
4. If `AGENTS.md` was generated, complete its project documentation links using the inventory. If it already existed, preserve it and give the user a concise suggested index update rather than editing it automatically.
5. Beyond the four core docs, add documentation only when a real need is confirmed and no authoritative source covers it. Follow `references/docs-generation.md` for the evidence-first method. When the project uses a specific framework or is a library, the project's own conventions are the authority — this skill does not ship per-framework or per-language specializations.
6. Summarize the topic inventory, authoritative source paths, gaps/conflicts, files changed, and how to run tests.

The main agent can perform every step directly. Sub-agents may be used to speed up independent documentation work, but are never required.

## Initializer behavior

- The script accepts `[repo_root] [--profile core|global] [--full] [--docs-dir path] [--include template-path]`; without a repository path, it uses the current directory. Users never invoke the script directly — the agent resolves `REPO_ROOT` and the profile from the entry mode and runs it on their behalf.
- `--profile` selects the repo role explicitly (`core` default; `global` for orchestration repos). The profile is never inferred from repository content. `--include` is not supported under the global profile; its doc set is fixed.
- For a new repository with no existing Markdown documentation, the default profile creates the core docs under `docs/`; `--full` also adds the optional-docs catalog. The global profile creates the orchestration docs and `docs/plans/README.md` instead.
- For a repository with existing Markdown documentation, it skips bulk template copying. Explicitly select a missing template with `--include` only after a content review (standard profile only).
- Existing `docs/` or `.docs/` layout and file names are preserved. If both roots exist, specify `--docs-dir` after reviewing them.
- Existing documentation files are not overwritten.
- `AGENTS.md` is generated from `assets/agents.md.tmpl` only when it does not already exist; under the global profile the orchestration section is appended at generation time.
- Git hooks and the Go lint configuration install only under the standard profile.
- The script does not install dependencies, configure an AI product, or create `devsop-init` / `devsop-eval` terminal commands.

## Workflow boundary

This Skill organizes project context and quality constraints; it does not prescribe a task-management or implementation workflow. Follow the workflow the project already uses. Avoid duplicating plans, task records, or documentation topics across tools and files.

## References

- `references/docs-generation.md` — evidence-first documentation method (scan → extract → verify → hand off), project-type adjustments
- `assets/docs/` — the four starter docs plus the optional-docs catalog
- `assets/docs/global/` — orchestration-repo docs (system architecture, services registry, derived dependencies view, plans README)
- `assets/global-orchestration.tmpl` — Orchestration section appended to AGENTS.md under the global profile
- `assets/agents.md.tmpl` and `assets/.golangci.yml` — shared files used by the initializer
- `scripts/init_docs.sh` — project initializer
