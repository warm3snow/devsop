# 08. Review

> **Purpose**: Human / AI review as a safety net, the last gate before Commit.
> **Reference**: the checklist in `.docs/review.md`

---

## 1. Review Overview

| Item | Value |
|----|----|
| Reviewer |  |
| Review time |  |
| MR / PR link |  |
| Commit scope |  |

## 2. Self-Check (author first)

> The author self-checks against the mandatory items in `.docs/review.md`; only then may the Review be initiated.

### 2.1 Security
- [ ] SQL parameterized
- [ ] No hardcoded credentials
- [ ] Input validation
- [ ] Output escaping
- [ ] Encryption uses the standard library

### 2.2 Correctness
- [ ] Boundary conditions covered
- [ ] Concurrency protection
- [ ] Transaction boundaries clear
- [ ] Idempotency / retry / timeout

### 2.3 Observability
- [ ] Logs include trace_id
- [ ] Error logs include context
- [ ] Metrics / alerts in place

### 2.4 Testability / maintainability
- [ ] UT coverage meets target
- [ ] Naming clear
- [ ] No duplicate code
- [ ] Docs in sync

## 3. Issues Found by the Reviewer

| # | Severity | File:Line | Issue Description | Suggestion | Fix Status | Fix Commit |
|---|-------|---------|---------|------|---------|-----------|
| 1 | 🔴 High |  |  |  | ⬜ To fix / ✅ Fixed |  |

> Severity: 🔴 High (blocking) \| 🟡 Medium (must fix or explicitly ignore) \| 🟢 Low (optional)

## 4. Discussion and Decisions

> Non-trivial points of contention are recorded here for future traceability.

| # | Topic | Discussion | Conclusion | Decision Maker |
|---|------|------|------|-------|
|  |  |  |  |  |

## 5. Final Conclusion

- [ ] All 🔴 high-severity issues fixed
- [ ] All 🟡 medium-severity issues fixed **or** have a written reason for ignoring
- [ ] 🟢 low-severity issues evaluated
- [ ] Reviewer approved the merge

**Reviewer signature** (or comment link):

---

## Anti-examples

❌ **Anti-example 1: author reviews the author**
> Merged without a second person ever looking at the code.

✅ **Principle**
> At least one other person (or AI as an aid) fully walks through the checklist.

❌ **Anti-example 2: nit-pick blocking**
> Debated variable naming for a long time while the real concurrency bug went unnoticed.

✅ **Principle**
> Tier the severity; high issues first; low issues are optional / open a separate task.

❌ **Anti-example 3: ignoring an issue without a reason**
> "We won't change this for now" — the future handover person cannot see the reason.

✅ **Rewritten**
> "Issue X not fixed for now; reason: large blast radius, needs a performance-regression evaluation; registered as ADR-0015, expected to be handled next iteration."

---

## Completion Criteria

- [ ] All author self-checks checked
- [ ] All issues found by the reviewer have a disposition (fixed or recorded)
- [ ] Discussion decisions archived
- [ ] Reviewer approved
- [ ] Checked off 08. in `00-overview.md` Progress
- [ ] End confirmation completed with the user
