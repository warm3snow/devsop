# 03. Implement

> **Purpose**: Write code according to the Plan, and record decisions that deviate from the Plan.
> **Input**: `02-plan.md`
> **Output**: code changes + this file (do not copy code, only record decisions and checks)
> **TDD mode**: this stage follows the cases in `02-plan.md §6` — first write UT and run it red (Red) → write minimal implementation to turn it green (Green) → refactor while keeping UT green (Refactor); the UT/IT boundary and Red-Green cycle constraints are detailed in `04-ut.md` §0.5.

---

## 1. Implementation Highlights

> Record the **key** implementation details per file. Do not copy code; only write **why it was written this way**, **pitfalls encountered**, and **special handling**.

### 1.1 `<File Path>`

- Key logic:
- Special handling:
- Compatibility considerations:
- References / sources:

### 1.2 `<File Path>`

<!-- Repeat -->

## 2. Deviations from the Plan

> If the implementation deviates from `02-plan.md`, you must record the reason here and go back to update the Plan document accordingly.

| # | Deviation | Reason | 02-plan.md Updated |
|---|--------|------|------------------|
|  |  |  | ⬜ Yes |

## 3. Code Self-Check Checklist

> Self-check by AI / developer before committing; only proceed to UT when all boxes are checked.

### 3.1 General

- [ ] No hardcoded credentials / tokens / passwords
- [ ] All SQL parameterized, no string concatenation
- [ ] All external inputs validated
- [ ] Error paths have logs, including context
- [ ] Key paths have metrics / trace instrumentation
- [ ] No infinite loops / no unbounded recursion

### 3.2 Concurrency / Performance

- [ ] Shared state is locked or stateless
- [ ] Long loops yield the scheduler (mandatory check for coroutine projects)
- [ ] No O(n²)+ computations in request handling
- [ ] External calls have timeout settings

### 3.3 Style / Tools

<!-- Project-specific, fill in as needed -->

- [ ] Lint passes
- [ ] Formatter run
- [ ] Type check passes
- [ ] No unused imports / variables

## 4. Code Check Records

```bash
# TODO: project-specific commands, e.g.:
# make check        # golangci-lint run
# make format       # gofmt -w / goimports -w
# go vet ./...
```

| Check Item | Result | Remarks |
|--------|------|------|
| Lint | ⬜ Pass / Fail |  |
| Format | ⬜ Pass / Fail |  |
| Type check | ⬜ Pass / Fail |  |

## 5. Debug Records (fill in only when bugs were found and fixed during implementation)

> Systematic root-cause discipline (optional section, but required once a non-trivial bug occurs):
> **reproduce → localize → minimize → fix → guard**. Never fix by guessing; a fix without a root cause is a new bug in disguise.

| # | Symptom (how to reproduce) | Root cause (evidence) | Fix (minimal change) | Guard (test/check added to prevent recurrence) |
|---|---------------------------|-----------------------|----------------------|-----------------------------------------------|
| 1 |  |  |  |  |
| 2 |  |  |  |  |

> Rule: if you cannot fill the "Root cause" column with evidence (logs / stack trace / failing test), STOP — you have not localized the bug yet; keep investigating instead of patching around it.

---

## Decision Framework

1. **Minimal change principle**: if an existing pattern suffices, do not introduce a new pattern or new dependency.
2. **Error path first, then success path**: error handling is often the breeding ground for bugs; think it through first.
3. **Logs = the future of debugging**: when writing logs, imagine whether the oncall you six months from now can understand them.
4. **Dependency isolation**: put external calls in the adapter layer; business code should not `import requests` directly.

## Anti-examples

❌ **Modifying business code to satisfy tests** → unit tests test existing behavior. If tests fail, either change the test (if the behavior was already wrong, document it), or you found a real bug (open a new task to fix it).
❌ **Logging only "error"** → `logger.error("create_instance failed", extra={"uin": uin, "request": req_body, "stage": "vpc_check", "err": str(e)})`
❌ **Catching exceptions without handling them** (`except Exception: pass`) → either let it propagate, or have a clear recovery logic + logs. Silently swallowing exceptions is a P0 hazard.

## Completion Criteria

- [ ] All changed files implemented
- [ ] Plan deviations recorded and Plan doc synced
- [ ] All code self-checks pass
- [ ] Lint / Format tools pass
- [ ] `00-overview.md` Progress / Current Step / Time Tracking synced
- [ ] End confirmation completed with the user
