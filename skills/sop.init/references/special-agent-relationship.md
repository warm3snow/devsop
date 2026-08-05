# Upstream/Downstream & Integration Relationships Review Sub-Agent Instructions

> This file serves as the **supplementary instructions** for the `relationship` review sub-agent, on top of the common prompt. The main Agent passes it along when dispatching.
> Target: `.harness/docs/relationship.md`.

---

## Core Goal

Fill `.harness/docs/relationship.md` into an **actionable upstream/downstream & integration relationship document** (upstream callers / downstream dependencies / call-relationship descriptions / topology diagram / failure propagation matrix).

---

## Steps

### 0. Prerequisite check: clean up the legacy dependency-map.md

> Older `sop.init` versions initialized `dependency-map.md` (old format: mermaid call-relationship diagram + failure propagation analysis); the new-version skeleton has changed to a single `relationship.md` (new format, focused on internal call relationships).
> When upgrading old projects, a legacy `dependency-map.md` may remain; its substantive content must be migrated into `relationship.md` and laid out in the new format, and the leftover file is then deleted. The new-version skeleton no longer contains `dependency-map.md`, so there is nothing to keep.

Check for the following leftover old files (in priority order):
- Whether `.harness/docs/dependency-map.md` contains **substantive content that is neither placeholder nor template comments** (i.e. fields filled by the old version before migration: upstream callers, downstream data storage/third-party services/middleware, call-relationship diagram, failure propagation analysis, etc.).
- If a legacy top-level `harness/` leftover exists (`.harness/dependency-map.md` or `harness/dependency-map.md`), treat it as old-version output participating in the migration.

**If substantive legacy `dependency-map.md` content exists** (old-version sop.init output):
- Read all the content of the leftover `dependency-map.md`
- Migrate its substantive content to `.harness/docs/relationship.md` using the following mapping:
  - The "Upstream callers (who calls me)" table (caller / entry point / frequency / failure impact) → merge into the `relationship.md` "## Upstream (who uses this project)" table (caller / code repository / purpose / protocol integration method / key entry points / contact)
  - The three tables "Data storage", "Third-party/internal services", "Middleware" under "Downstream dependencies" → merge into the `relationship.md` "## Downstream (what this project uses)" table (called party / code repository / purpose / protocol integration method / key entry points / SLA version constraints / failure handling / integration code location)
  - The "Call-relationship diagram (mermaid)" → convert into `relationship.md`'s "## Topology Diagram" (ASCII or mermaid, covering all strong dependencies)
  - The "Failure propagation analysis" → merge into `relationship.md`'s "## Failure Propagation Matrix" (downstream external condition / affected function / failure symptom / whether degradable / degradation fallback plan)
- After migration completes, **delete** the leftover legacy `dependency-map.md` (any of `.harness/docs/dependency-map.md`, `.harness/dependency-map.md`, `harness/dependency-map.md`)
- Output `migrated(dependency-map.md → relationship.md)` + a migration content summary

**If no legacy leftover exists** (no substantive content):
- Proceed directly to step 1, analyze the code based on the project's actual situation, and update `relationship.md`
- Output `no-migration(no legacy dependency-map.md)`

### 1. Scan upstream/downstream & integration relationship facts

- **Upstream callers**: who calls this project — route registration, HTTP/gRPC services exposed by the `main` package, packages `import`ed by other repositories, subscribed WebHooks / Topics
- **Downstream dependencies**: what this project calls — `go.mod` dependencies, `import`ed external SDKs/clients, adapter / client directories, addresses and credentials in config files, message production/consumption
- **Integration methods**: HTTP / RPC(gRPC/Thrift) / package dependency / CLI embedding / SDK inclusion / WebHook subscription / message consumption
- **Call topology**: the key call chains from entry points to downstream, the actual paths across modules and services
- **Failure handling**: real code implementations of timeout, retry, degradation (e.g. `circuit breaker`, fallback functions, config switches)
- Sources must come from real code / config / dependency files; **fabricating is forbidden**

### 2. Generate / update the document

Fill `relationship.md` per the skeleton's five-part structure:
- **Upstream (who uses this project)** — caller / code repository / purpose / protocol integration method / key entry points / contact
- **Downstream (what this project uses)** — called party / code repository / purpose / protocol integration method / key entry points / SLA version constraints / failure handling (timeout retry degradation) / integration code location
- **Call-Relationship Descriptions** — key call chains organized by business scenario/functional module (triggering scenario / call topology / data transmitted / key code / failure impact / related docs)
- **Topology Diagram** — ASCII or mermaid, covering all strong dependencies; may be omitted for pure library projects
- **Failure Propagation Matrix** — downstream failure → affected function → failure symptom → whether degradable → degradation fallback plan

### 3. Align and reference

- Fill in the file header `> Source:` and `> Last-verified:` (source and scan date)
- Link the "related docs" of call chains to the corresponding `apis/<module>/<Action>.md` or downstream repository docs
- Keep dependency relationships consistent with `architecture.md` and `devops/`, using `@` references rather than copies
- The degradation plans in the failure propagation matrix must come from real code (e.g. retry config, fallback branches); fabricating is forbidden

---

## Constraints

- Commands / dependencies / callers / failure handling must come from real code, config, `go.mod`, CI config; fabricating is forbidden
- After migrating the legacy `dependency-map.md`, it must be deleted; do not leave redundant files
- Only touch `relationship.md` and the legacy `dependency-map.md` to be deleted; do not touch other docs
- For pure library projects (no external interfaces, no downstream services), only the upstream (imported parties) and downstream (third-party dependencies) need to be filled; the topology diagram may be omitted
- If the project has no external dependencies or callers at all (an isolated tool) → keep the template structure and note "no upstream/downstream relationships yet"
