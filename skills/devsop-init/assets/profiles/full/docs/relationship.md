# Upstream/Downstream / Integration Relationships

> This project's relationship with the outside world: who uses it, who it depends on, what happens when a dependency breaks.
> Keep in sync when introducing new external dependencies, adjusting the call topology, or modifying integration methods.

> Source: <source of scanned dependency relationships: dependency management files / config / adapter directory etc.>
> Last-verified: <YYYY-MM-DD>

---

## Upstream (who uses this project)

| Caller / Integrator | Code Repository | Purpose | Protocol / Integration Method | Key Entry Point | Contact |
|-----------------|---------|------|-----------------|---------|-------|
|  |  |  |  |  |  |

> Integration method examples: HTTP / RPC / package dependency (npm / pypi / cargo / maven) / CLI embedding / SDK import / WebHook subscription / message consumption
> **Code repository**: fill in the full git address or short repository name (e.g. `git.code.tencent.com/ChainWeaver/xxx`, `github.com/org/repo`); for internal components, provide the full path for easy cross-repository navigation.

---

## Downstream (what this project uses)

| Callee / Dependency | Code Repository | Purpose | Protocol / Integration Method | Key Entry Point | SLA / Version Constraint | Failure Handling (timeout / retry / degradation) | Integration Code Location |
|-------------------|---------|------|-----------------|---------|---------------|------------------------------|--------------|
|  |  |  |  |  |  |  |  |

---

## Call Relationship Description

> Provide a functional description for each **key call chain**, so that readers don't just see a table without knowing "why the call happens".
> Recommended organization by **business scenario / functional module**; each description includes: trigger scenario, caller→callee, data transferred, failure impact.

### 1. <call chain name, e.g. user places order → order service → inventory service>

- **Trigger scenario**: <what user action / scheduled task / event triggers this chain>
- **Call topology**: `<upstream component>` ─→ `<this project's module>` ─→ `<downstream component>`
- **Data transferred**: <key field or message body summary, sensitive fields marked as redacted>
- **Key code**: `<entry file / function path within this project>`
- **Failure impact**: <what business consequences occur if this chain breaks>
- **Related docs**: <corresponding `apis/<module>/<Action>.md` or downstream repository doc link>

### 2. <next call chain>

- **Trigger scenario**:
- **Call topology**:
- **Data transferred**:
- **Key code**:
- **Failure impact**:
- **Related docs**:

---

## Topology Diagram

<!-- ASCII or mermaid, covering all strong dependencies; pure library projects may omit -->

```
[external caller]
     ↓
[this project] ─→ [downstream A]
   ├──────→ [downstream B]
   └──────→ [storage / queue / third-party API]
```

---

## Failure Propagation Matrix

| Downstream / External Condition | Affected Features | Failure Manifestation | Degradable? | Degradation / Fallback Solution |
|----------------|-----------|---------|-----------|----------------|
|  |  |  |  |  |
