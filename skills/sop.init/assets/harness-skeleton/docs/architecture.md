# <ProjectName> Architecture Document

> Let newcomers / AI Agents form a mental model of this project within 10 minutes.
> Keep in sync on architecture-level changes (module split, entry replacement, concurrency model changes, key dependency additions/removals).

> Source: <main entry / routes / build file paths scanned>
> Last-verified: <YYYY-MM-DD>

---

## System Positioning

<!-- One sentence: what is this project? What problem does it solve? Who is it for? -->

---

## Overall View

<!-- An ASCII / mermaid diagram. Minimal version: [trigger] → [entry] → [core] → [sink] -->

```
[external trigger]
     ↓
[entry / scheduling layer]
     ↓
[core business / computing layer]
     ↓
[output / storage / side effects]
```

---

## Module Breakdown

| Module | Responsibility | Entry File | Main Dependencies |
|------|------|---------|---------|
|  |  |  |  |

---

## Typical Flows

<!-- Draw at least one end-to-end flow; if there is a "read / write" distinction, draw one for each -->

### Flow A: <Example>

---

## Concurrency / Performance / Resource Model

<!-- Process / thread / goroutine / event loop model; number of startups; key bottlenecks; non-blocking requirements, etc. -->

---

## Data Flow (if applicable)

<!-- The complete path of data from entry to persistence (DB / file / remote service / cache) -->

---

## Key Design Decisions

| # | Decision | Notes |
|---|------|------|
|  |  |  |

---

## Deployment / Distribution Topology (if applicable)

<!-- Node scale / network topology / high availability plan / multi-end strategy / IaC resource boundaries -->
