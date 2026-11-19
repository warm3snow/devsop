# System Relationship Documentation Guide

> Use this guide when the project's upstream, downstream, or integration relationships need documenting. The main agent can follow it directly or delegate the task when supported.
> Target: `.docs/relationship.md`.

---

## Core Goal

Fill `.docs/relationship.md` into an **actionable upstream/downstream & integration relationship document** (upstream callers / downstream dependencies / call-relationship descriptions / topology diagram / failure propagation matrix).

---

## Steps

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
- Only touch `relationship.md`; do not touch other docs
- For pure library projects (no external interfaces, no downstream services), only the upstream (imported parties) and downstream (third-party dependencies) need to be filled; the topology diagram may be omitted
- If the project has no external dependencies or callers at all (an isolated tool) → keep the template structure and note "no upstream/downstream relationships yet"
