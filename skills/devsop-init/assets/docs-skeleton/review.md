# Code Review Guide

> A checklist followed by both AI and human Reviewers.

---

## Categories and Priorities

| Severity | Description | Handling |
|--------|------|------|
| 🔴 High (blocking) | security vulnerabilities, data loss risk, protocol breaks, performance regressions | must be fixed before merging |
| 🟡 Medium | poor testability, missed edge cases, missing error handling, confusing naming | needs fixing or explicit documentation |
| 🟢 Low | style suggestions, refactoring opportunities, doc completion | optional |

---

## Must-Check Items (high severity)

### Security
- [ ] All SQL uses parameterized queries, no string concatenation
- [ ] No hardcoded keys, Tokens, passwords
- [ ] Input validation covers all external sources (HTTP parameters, messages, files)
- [ ] Output escaped per scenario (HTML / SQL / Shell)
- [ ] Encryption uses the standard library

### Correctness
- [ ] Edge cases covered (empty, single element, overlong, negative, out of bounds)
- [ ] Concurrent reads/writes of shared resources are protected
- [ ] Transaction boundaries clear, correct rollback on failure
- [ ] External interfaces follow idempotency / retry / timeout conventions

### Observability
- [ ] Key paths have logs, including trace_id / request_id
- [ ] Error path logs contain sufficient context
- [ ] Monitoring metrics / alerts configured

---

## Regular Check Items (medium severity)

### Testability
- [ ] Corresponding UT exists, coverage meets the target
- [ ] Public interfaces have contracts (input/output/errors)
- [ ] No hidden global state

### Maintainability
- [ ] Clear naming, avoiding ambiguous abbreviations
- [ ] Functions short, single responsibility
- [ ] Common code extracted to a reasonable level
- [ ] No duplicate code (rule: the same logic appearing more than 3 times must be abstracted)

### Interfaces and Data
- [ ] API and data-model changes match the agreed requirements
- [ ] Tests cover behavior affected by interface or schema changes
- [ ] Dependency versions consistent with project constraints

---

## Suggested Items (low severity)

- [ ] Comments explain "why" rather than "what"
- [ ] Documentation kept in sync (`.docs/apis/`, `.docs/sqls/`, `.docs/architecture.md`, `.docs/devops/`, `.docs/unittest/` etc., supplemented per the directories affected by the change)
- [ ] Test data realistic

---

## Review Feedback Template

```
[severity] [file:line] brief problem description

Details:

Suggested change:

```
