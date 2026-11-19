# docs-generation.md

## Contents

0. Before reading this methodology · 1. Core Principles · 2. Documentation lenses · 3. Documentation update loop · 4. Trigger timing · 5. Anti-patterns · 6. Documentation layout · 7. Discoverability and authority · 8. Recommended workflow · 9. Quality self-check · Appendix A: Minimal viable output

> Project-documentation discovery and maintenance methodology. **Generic version** — not tied to any language, framework, documentation directory, or filename.
>
> When to load:
> 1. After initialization, when project-specific facts need to be documented
> 2. When adding or revising documentation in an existing project
> 3. When a code or configuration change makes project guidance inaccurate

---

## 0. Before reading this methodology

The directory structure, section templates, and extraction scripts below are **illustrative**, not hard constraints. Preserve and reuse the project's authoritative sources instead of introducing a parallel documentation set.

1. **Why**: the purpose of docs (Section 1 core principles)
2. **What to look for**: orientation / contracts / internals / operability (Section 2 as optional lenses)
3. **How methodology**: inventory sources, identify gaps and verify only changes made (Section 3)
4. **When**: trigger timing and corresponding actions (Section 4)
5. **Invariant anti-patterns** (Section 5)

Which sources a project uses is decided from the actual repository and any linked authoritative team documentation.

---

## 1. Core Principles

Project guidance should help contributors discover relevant knowledge; it complements rather than duplicates the README, source code, specifications, and team handbooks.

Four principles, independent of project type:

| # | Principle | Meaning |
|---|-----------|---------|
| 1 | **Code is the truth, docs are the map** | Check project guidance against implementation and configuration when it describes behavior; note sources or verification dates when useful |
| 2 | **Write for the reader, not the author** | Contract docs are written from the caller's perspective; architecture docs are written from the new maintainer's perspective; ADRs are written from the future maintainer's perspective |
| 3 | **Evidence before assertion** | Unsupported claims mislead maintainers; distinguish observed facts from assumptions |
| 4 | **On-demand, incremental** | Improve the smallest useful set of authoritative sources and avoid documentation quotas |

---

## 2. What — the four-layer model of docs (decoupled from project type)

These four questions are useful lenses when reviewing a backend service, frontend SPA, CLI tool, SDK / library, mobile app, or data pipeline. They are not a required file set:

| Layer | Name | Question it answers | Cost of losing it |
|-------|------|---------------------|-------------------|
| L1 | **Orientation layer** | What is this? What does it look like when running? How are modules split? How does data flow? | Newcomers / AI cannot form a mental model, and all lower-layer docs become unreadable |
| L2 | **Contract layer** | How do others use it? What interfaces / APIs / commands / events / props / CLI flags exist? | Integrators stumble; breaking changes from version upgrades are uncontrollable |
| L3 | **Internals layer** | Why is it implemented this way? What are the key algorithms, state machines, data models, and persistence structures? | Maintainers can only reverse-engineer; refactoring is like groping an elephant in the dark |
| L4 | **Operability layer** | How to run locally? How to test? How to release? How to observe? How to roll back? | Project handover = re-stumbling through all the same pitfalls |

Use the lenses that are relevant to the specific gap. Do not generate an orientation document just to satisfy an order before documenting another missing topic.

> Use the layers as optional lenses; the project's actual documentation layout is covered in Section 6.

---

## 3. How — generic generation method (all layers share the same loop)

When creating or changing documentation, use this lightweight loop:

```
Inventory   →  Identify gap →  Update source →  Verify evidence
```

### Step 1: Scan — find the information sources

Identify authoritative information sources before writing. Common source types include:

| Information source type | Examples |
|-------------------------|----------|
| **Entry files** | `main.*` / `index.*` / `server.*` / `cli.*` / `App.*` / `__main__.py` |
| **Routing / dispatch / entry registries** | `router.*` / `routes/` / `*.routing.ts` / `urls.py` / the `pub` list in `mod.rs` |
| **Type / interface definitions** | `*.proto` / `*.thrift` / `openapi.yaml` / `*.d.ts` / `schema.graphql` / IDL |
| **Build / run configuration** | `Makefile` / `package.json` / `Cargo.toml` / `pyproject.toml` / `pom.xml` / `Dockerfile` |
| **Test entries** | `tests/` / `__tests__/` / `*_test.go` / `spec/` |
| **Persistence schemas** | DB `SHOW CREATE TABLE` / migrations / ORM models / `*.proto` for storage |
| **CI / CD configuration** | `.github/workflows/` / `.gitlab-ci.yml` / Jenkinsfile |
| **Dependency graphs** | lockfile / `go mod graph` / `npm ls` / `cargo tree` |

Inspect the repository and use the available file/code search tools; do not assume paths or commands exist.

### Step 2: Extract — extract structured facts

Extract claims from repository and linked team sources. Verify important statements against the implementation/configuration; mark uncertain facts as uncertain rather than inventing details.

| Fact to extract | Extraction means (pick one) |
|-----------------|------------------------------|
| Module inventory | Top-level directory tree + README / first-line docstring of each directory |
| Entry points and startup methods | Entry file name + startup command (extracted from `package.json scripts` / `Makefile` / `Dockerfile CMD`) |
| External contracts | IDL first; then annotations / decorators; finally fall back to handler / exported function signatures |
| Error codes / exceptions | grep `raise` / `throw` / `return Err` / `Error(...)` statements + centralized error code table |
| Dependency graphs | Output of package manager commands |
| DB schema | Directly connect to the test DB `SHOW CREATE TABLE` / read migration history |

Automation is optional; do not add tooling or CI solely to generate documentation.

### Step 3: Draft — generate the draft

- Preserve manual edits. Use a draft only when the change is substantial or the source owner should review it first.
- Mark uncertain facts clearly; do not leave boilerplate placeholders in user-facing guidance.
- Add source/verification notes when they materially help future maintainers:
  ```markdown
  > Source: <extraction source file / command>
  > Generated: <date>  by <skill / script name>
  ```

### Step 4: Verify — sample-check

Verify important claims and commands against source code or configuration when practical:
- Do the names (interface names / field names / command names) match the code?
- Are the default values, required/optional relationships correct?
- Is error handling / failure semantics complete?

If inconsistencies are found, update the authoritative source with verified information and note unresolved discrepancies for the maintainer.

### Step 5: Review — leave changes for the project owner

- Show the changed authoritative sources and any remaining decisions for the owner.
- Do not commit changes or create a second index when an existing project entry point can link to the source.

---

## 4. When — trigger timing and corresponding actions

| Trigger scenario | Corresponding action | Output location |
|------------------|----------------------|-----------------|
| **Project just initialized (Scenario A)** | Inventory source evidence and existing guidance; create only useful missing context | Project's chosen documentation location |
| **First-time backfill of an existing project** | Record authoritative sources, gaps, and conflicts; update only confirmed gaps | Existing authoritative sources |
| **Behavior or configuration changes** | Derive **incremental** updates from the change; only touch guidance affected by it | Only the docs involved this time |
| **Quarterly / version health check** | Sample-check (names / default values / error codes); open a chore task for inconsistencies | Exposed problems → task → fix |
| **After a major refactor / architecture evolution** | Review relevant guidance and record lasting decisions when useful | Existing authoritative design/decision source |
| **Major dependency version upgrade** | Review affected setup/operations guidance against the new version | Existing authoritative setup/operations source |

---

## 5. Anti-patterns (project-type independent, all must be avoided)

| # | Anti-pattern | Consequence | Correct approach |
|---|--------------|-------------|------------------|
| 1 | **Generate all docs in one batch** | Large volume, low quality, nobody reviews, rotten as soon as written | Add only project-relevant missing information |
| 2 | **AI merges directly after generating** | AI will fabricate parameters / default values / error codes | Sample-check ≥3 places against the code |
| 3 | **Docs and code in unrelated changes** | Guidance may remain stale | Update relevant docs with the change when practical |
| 4 | **Only record "what" not "why"** | Nobody understands the decision six months later | ADR records "why"; contract layer / internals layer record "what" |
| 5 | **Contract docs copy the source code** | Lose the caller's perspective, become "code translation" | Write from the caller's perspective: how to call / what it returns / how to diagnose errors |
| 6 | **Require an unrelated orientation doc before addressing a concrete gap** | Adds process and files without helping users | Address the relevant gap directly |
| 7 | **Copy persistence schema as code strings** | Inconsistent with production | Export directly from the test DB / real migration state |
| 8 | **Overwrite or duplicate existing guidance** | User revisions are lost and conflicting sources emerge | Preserve existing sources; edit only with evidence and report conflicts |
| 9 | **AI substitutes memory for scanning** | File paths / command names are made up | Inspect repository evidence before making claims |
| 10 | **Docs without source footnotes** | Don't know when or with whom to sync | Fixed `Source` + `Generated` footer at the top |

---

## 6. Documentation layout

There is no required documentation root, directory structure, or filename. Respect the project's existing layout and use content—not names alone—to identify equivalent guidance. The starter profile paths are examples for new projects; they are not required when a project already has authoritative sources. If two sources conflict, report the paths and discrepancy for maintainer resolution rather than silently merging or choosing one.

### Information source mapping examples (by form)

| Fact to extract | Backend service | CLI | Library/SDK | Frontend |
|-----------------|-----------------|-----|-------------|----------|
| Entry | `main.py` / `server.go` / `app.js` | `cmd/root.go` / `bin/<name>.js` | `__init__.py` / `lib.rs` / `index.ts` | `main.tsx` / `App.vue` |
| Contracts | router registrations + handler signatures | `argparse` / `cobra` / `clap` subcommands | `__all__` / `pub` exports / `export` | route table + component props |
| Error codes | centralized `raise <Exc>` table | exit code table | custom Error classes | error boundaries + toast copy |
| Persistence | DB schema | config files / cache directories | none (or file format spec) | localStorage / IndexedDB schema |

---

## 7. Discoverability and authority

1. Link the authoritative sources from an existing repository entry point when that improves discoverability.
2. Use concise summaries or indexes only when useful; do not maintain a parallel copy of detailed guidance.
3. Determine authority from project references, ownership, content, and source evidence. Do not assume a particular directory (including `rules/`) always wins.
4. When sources conflict, cite both and ask the project owner to resolve the conflict; do not silently select or merge them.
5. Add documents and indexes only when they address a confirmed need.

---

## 8. Recommended workflow (after initialization)

```
1. Inspect the repository and identify which project facts are useful to document.
2. Draft only the relevant docs using source/configuration evidence.
3. Verify commands and factual details when practical; mark anything unverified.
4. Link the docs from the project entry point and keep them updated as needed.
```

---

## 9. Quality self-check (apply where relevant)

- [ ] Claims are grounded in repository or linked team evidence; uncertainties are explicit
- [ ] The chosen source is authoritative, discoverable, and does not duplicate another source
- [ ] Guidance is specific enough for its intended readers and reflects actual project behavior
- [ ] Instructions and commands were checked when practical
- [ ] Conflicts, stale content, and unverified assumptions are reported rather than silently resolved
- [ ] The update is limited to the topics affected by the identified gap or change

---

## Appendix A: Minimal viable output (MVP docs)

Start with the docs that answer immediate project questions, usually architecture, coding conventions, and test commands. Add API, data, deployment, or operational docs only when the project needs them. Do not create placeholder files or TODOs solely to make the documentation set look complete.
