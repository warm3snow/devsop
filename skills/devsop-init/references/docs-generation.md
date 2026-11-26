# Documentation Generation Method

> Load when documenting project-specific facts after initialization, or when a change makes project guidance inaccurate. The project's existing layout, filenames, and authoritative sources always win over anything here.

## Core principles

| # | Principle | Meaning |
|---|-----------|---------|
| 1 | **Code is the truth, docs are the map** | Verify docs against implementation/config; note sources or verification dates |
| 2 | **Write for the reader** | Contract docs from the caller's perspective; architecture docs from the newcomer's perspective |
| 3 | **Evidence before assertion** | Distinguish observed facts from assumptions; never invent names, commands, or default values |
| 4 | **On-demand, incremental** | Improve the smallest useful set of sources; no documentation quotas, no placeholder files |

## Documentation lenses (optional questions, not a required file set)

| Lens | Question | Cost of losing it |
|------|----------|-------------------|
| Orientation | What is this? How do modules split? How does data flow? | Newcomers/AI cannot form a mental model |
| Contract | How do others use it — APIs, commands, events? | Breaking changes become uncontrollable |
| Internals | Why is it implemented this way? | Maintainers reverse-engineer everything |
| Operability | How to run, test, release, roll back? | Handover re-stumbles through every pitfall |

## Generation loop

```
Inventory → Identify gap → Update source → Verify evidence
```

1. **Scan** for authoritative sources: entry files, route registrations, IDL/schema files, build configs (Makefile/package.json/pom.xml/Cargo.toml), test directories, CI configs, dependency manifests. Inspect the repository; never assume paths exist.
2. **Extract** structured facts: module inventory, entry points and startup commands, external contracts (IDL first, then annotations, then handler signatures), error-code tables, DB schemas (from migrations, not memory).
3. **Draft** preserving manual edits; add a `> Source: ... / > Last-verified: ...` footnote when it helps future maintainers.
4. **Verify** names, defaults, and commands against code/config when practical; mark unverified claims.
5. **Hand off**: show changes to the project owner; never commit, never create a second index when an existing entry point can link.

## Anti-patterns

| # | Anti-pattern | Correct approach |
|---|--------------|------------------|
| 1 | Batch-generate every doc | Add only project-relevant missing information |
| 2 | Merge AI output unverified | Sample-check ≥3 claims against the code |
| 3 | Contract docs copy source code | Write from the caller's perspective |
| 4 | Overwrite or duplicate existing guidance | Preserve sources; edit with evidence; report conflicts |
| 5 | Memory instead of scanning | Inspect repository evidence first |
| 6 | Docs without source footnotes | Record source + verification date |

## Discoverability

Link authoritative sources from an existing repository entry point (AGENTS.md, README). Use summaries only when useful; never maintain a parallel copy of detailed guidance. When two sources conflict, cite both and ask the owner to resolve.

## Project-type adjustments

- **Library/SDK**: delete deployment/runtime/DB/service sections. Focus on exported API surface, semver compatibility, consumer docs (install + quick example + version matrix), thread safety. Architecture doc uses a module dependency graph, not a service topology.
- **CLI**: contracts are subcommands and exit codes; no service topology.
- **Frontend**: contracts are routes, component props, and data schemas; entries are `main.*` / `App.vue`.
