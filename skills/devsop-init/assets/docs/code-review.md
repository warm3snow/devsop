# Code Review Standards

> Status: Draft | Maintainer: {{name}} | Last Updated: {{YYYY-MM-DD}}

## Scope

All PRs/MRs merged into `{{main / master}}` go through review; AI-generated code is subject to the same rule.

## 1. Submitter Rules

- ❌ Pushing directly to the main branch (must go through feature branch + PR)
- ❌ PR > **500** lines not split (split by module/layer)
- ❌ Submitting AI code without understanding it (you must be able to answer: "What does this code do? Why?")
- ❌ Deleting existing tests (unless there is a clear reason, stated in the PR description)
- ❌ Committing `.env` / `*.key` / `credentials.json` / build artifacts
- ✅ PR description includes: background, changes, impact surface, testing approach, rollback plan

## 2. Pre-Commit Self-Check

- [ ] Build, lint, and unit tests pass (`{{make build / make lint / make ut}}` — use the project's real commands)
- [ ] New/modified logic has corresponding tests (TDD: red first, then green)
- [ ] No `.env` / `*.key` / `vendor/` / `node_modules/` / `dist/` committed
- [ ] Commit title follows `<type>(<module>): <subject>` (`feat` / `fix` / `docs` / `refactor`)
- [ ] I fully understand what this code does

## 3. Reviewer Checklist

### 🔴 Blocking (must fix before merge)

**Security**
- [ ] Parameterized queries, no string-concatenated SQL; no command/path injection
- [ ] No hardcoded keys, Tokens, passwords; log redaction in place
- [ ] Input validation covers all external sources; encryption uses standard algorithms (no MD5/SHA1)

**Correctness**
- [ ] Edge cases covered (empty, overlong, concurrent, retry idempotency)
- [ ] Error handling complete, no swallowed errors
- [ ] Transaction boundaries clear; external interfaces follow idempotency/timeout conventions

**AI-Hallucination check (AI-generated code)**
- [ ] Referenced methods/fields/packages actually exist
- [ ] Library usage matches the project's real dependency versions
- [ ] Magic values (timeouts, thresholds) have a basis; error codes reference real constants

**Resource safety**
- [ ] Resource release paired; no goroutine/thread leaks; context propagated and cancellable

**Testing**
- [ ] New code has test coverage (normal + edge + error cases); assertions are effective

### 🟡 Recommended

- [ ] Naming consistent; comments explain "why"
- [ ] Functions ≤80 lines, nesting ≤4 levels; no obvious duplication
- [ ] No N+1 queries or unnecessary scans; key paths have logs with trace identifiers
- [ ] {{Framework-specific conventions, when the project has a framework}}

### 🟢 Optional

- [ ] Hardcoded text extracted for i18n when relevant
- [ ] README / architecture / API docs kept in sync

## 4. Review Etiquette

- Severity: `must-fix` (blocking) / `should-fix` / `nice-to-have` / `nit` / `question`
- Give concrete change suggestions, not "this is badly written"
- Submitter answers every comment; merge requires all `must-fix` resolved and no unanswered `question`s
- Merge criteria: CI green (build / lint / tests), ≥1 approval, all blocking items resolved

## 5. AI-Assisted Review

- AI review output is reference input, never a replacement for human review
- Human review is done by someone other than the submitter

## References

- Coding standards: {{link to the project's authoritative coding-conventions source}}
- Testing standards: {{link when present}}
- API standards: {{link when present}}
