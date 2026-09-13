# logging.md Special Sub-Agent Instructions

> This file serves as the **supplementary instructions** for the `logging.md` sub-agent, on top of the common prompt. The main agent passes it along when dispatching.
> Target: `.docs/logging.md`.

---

## Core Goal

Apply `.docs/logging.md` from the common template into conventions for the project's actual logging system — logging library, level mapping, tracing fields, and masking rules all come from code evidence.

---

## Relevance Determination (prerequisite)

- No evidence of any logging output in the project (a pure library project that only returns errors without logging, no logging library dependency, no log calls found by grep) → judged a **project without logging**, delete `.docs/logging.md` and output `skipped(no logging)`
- Evidence exists → proceed to the steps below

---

## Steps

### 1. Collect logging facts

- Logging library identification (based on dependency files + import evidence):
  - Go: `zap` / `logrus` / `logx` (go-zero) / `slog` in `go.mod` / custom wrapper (grep `log.` / `logger.` call sites to confirm the actual wrapper package)
  - Python: `logging` standard library / `loguru` / `structlog`
  - Java: `slf4j` + `logback` / `log4j2`
- Level system: the set of levels actually used by the project (e.g. logx only has Info/Error/Slow, etc.) → map to the template level table; delete levels that do not exist or mark them N/A
- Tracing fields: grep the real trace field names in the code (`traceId` / `trace_id` / `TraceId` / `spanId`), replacing the "traceId" in the template with the project's actual fields
- Log format: whether it is JSON-structured (look at initialization code / config files), whether there are unified fields (time / level / caller / msg)
- Masking status: masking utility functions already in the code (grep `mask` / `desensit` / `***`); if any, reference the actual function names in the "Forbidden to print" section
- Dynamic level adjustment: whether there is a mechanism to adjust the log level at runtime (config center / admin API / signal); if so, fill in the "Principles" section
- Log output location: log paths / collection methods in `devops/env.md` or deployment config (stdout → ELK / file → Fluent Bit); append a "Log Collection and Query" section at the end of the document (use `<!-- TODO(devsop.init) -->` if there is no evidence)

### 2. Generate / update the document

- "Scope" section: fill in the actual logging library and applicable modules
- "Log Level Definitions" table: trim per the project's actual levels; keep the level-semantics column; delete rows for levels the project does not have
- "Scenarios that must log" table: keep the common structure; replace traceId in the "must include information" column with the actual field name
- "Scenarios that must not / should reduce logging" table: keep it; align the sensitive-fields list with `coding-style.md` §10 keys and sensitive-information clauses, using `@` references rather than copying
- "Code Review checklist": keep it; if the project has custom check items (e.g. required parameters of a custom logging wrapper), add them
- "References" section: fix broken links (`deployment.md` → `devops/deployment.md`; `api-standards.md` → `apis/api-standards.md`; delete that line for projects without APIs)

---

## Constraints

- Only touch `.docs/logging.md`; do not touch other docs
- Logging library / field names / levels must come from code evidence; fabricating is forbidden; fields without evidence keep `<!-- TODO(devsop.init) -->`
- Sensitive-information masking clauses align with `coding-style.md` §10, using references rather than copies to avoid dual-track drift
- After deleting the file for a no-logging project, check whether the AGENTS.md index references `logging.md` — if it does, note "remove the logging.md index line" in the main agent's summary report (this Agent does not touch AGENTS.md; that is handled by Agent A's output or the main agent's wrap-up)
