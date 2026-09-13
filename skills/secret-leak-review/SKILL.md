---
name: secret-leak-review
description: "Detects potential secret leaks (passwords, tokens, credentials, keys, PII) printed to logs or output in code changes within a commit range, including indirect whole-struct serialization leaks. Language-agnostic — works with Go, Python, JS/TS, Java, Rust, and more. Use when reviewing incremental changes for privacy/security before merge."
disable-model-invocation: true
---

# secret-leak-review Skill

> Incremental-code privacy-leak reviewer — focused on the high-risk pattern "sensitive values printed to logs/output", including **indirect leaks** (whole struct/object serialization printing). **Language-agnostic**: the review protocol applies to any language; the extraction layer scans all mainstream source files.

**Version**: 2.0.0 | **Status**: ✅ Available

---

## Problem Solved

During development, someone may print sensitive data into logs, including **direct printing** and **indirect leaks**:

```go
log.Printf("user login pwd=%s", password)          // ❌ password leaked (Go)
```

```python
logging.info(f"token={access_token}")              # ❌ token leaked (Python)
```

```javascript
console.log("user:", JSON.stringify(user));        // ❌ indirect leak: user.password serialized (JS)
```

```go
type User struct {
    ID       int    `json:"id"`
    Password string `json:"password"`   // ❌ not "-", will be serialized
}
b, _ := json.Marshal(user); log.Printf("user=%s", b)  // ❌ effectively leaks password
```

This skill performs a dedicated review of **incremental code in the commitA..commitB range**, locating leak positions (file:line) via **sub-agents**, covering:

- values of `password` / `passwd` / `passphrase` / `pwd`
- private keys / certificates (`-----BEGIN ... PRIVATE KEY-----`)
- values of `token` / `apiKey` / `secretKey` / `accessKey` / `sign` / `auth`
- database connection strings with credentials, raw `Authorization` header values
- PII (ID card / phone number / bank card and other personal data)
- **Indirect leaks**: structs / objects / dicts containing sensitive fields printed as a whole via serializers (`json.Marshal` / `JSON.stringify` / `str()` / `repr()`), where the fields lack redaction (e.g. `json:"-"`, `@JsonIgnore`) and the type has no redacting serializer

The review is **limited to privacy leaks**; it does not do generic lint / performance / architecture review.

Sensitive data levels (L0-L4) and redaction rules: the "Sensitive Data Levels (L0-L4) and Redaction Rules" section of `references/secret-leak-review-prompt.md` is the single authoritative source.

---

## Quick Start

```bash
SKILL_DIR=skills/secret-leak-review

# Step A: extract the code (writes secret-leak-diff.txt under REPO_ROOT)

#   Incremental mode: commitA..commitB range
python3 $SKILL_DIR/scripts/review_secret_leak.py extract \
    /path/to/repo <commitA> <commitB> [--path=subdir] [--out=diff.txt]

#   Single-commit mode: only scan this commit's changes relative to its parent (pass - / empty / single as commitB)
python3 $SKILL_DIR/scripts/review_secret_leak.py extract \
    /path/to/repo <commitID> - [--path=subdir] [--out=diff.txt]

#   Full mode: pass all/* as either commitA or commitB → scan all source files in the working tree
python3 $SKILL_DIR/scripts/review_secret_leak.py extract \
    /path/to/repo all all [--path=subdir] [--out=diff.txt]
#   Equivalent: ALL / * (case-insensitive)

# Step B: the caller (an AI coding agent) dispatches a sub-agent
#   Read $SKILL_DIR/references/secret-leak-review-prompt.md as the sub-agent instructions,
#   inject the diff text from the previous step; the sub-agent returns findings JSON (not written to disk).
#   Use the agent's sub-agent mechanism (run in parallel/background if supported);
#   constraints: read-only, no git writes, no file writes.

# Step C: aggregate into the final report (writes secret-leak-report.json under REPO_ROOT)
#   assemble's commit params must match extract (mode recognized from the params)
python3 $SKILL_DIR/scripts/review_secret_leak.py assemble \
    /path/to/repo <commitA|commitID|all> <commitB|-|all> --findings=findings.json [--out=report.json]
```

**Commit parameter semantics** (three modes auto-detected):
- **Incremental mode**: both `commitA` and `commitB` are valid commits. `git diff commitA commitB` represents the changes in commitB relative to commitA (commitA excluded, commitB included). Identical commits produce an empty range.
- **Single-commit mode**: `commitA` is a valid commit; pass `-` / `single` / empty as `commitB`. Equivalent to `git diff commitA^ commitA` (scan this commit's changes relative to its parent); the root commit automatically compares against the empty tree.
- **Full mode**: either `commitA` or `commitB` is the keyword `all` / `ALL` / `*` (case-insensitive). Scans all git-tracked source files (`.go` / `.py` / `.js` / `.ts` / `.java` / `.rs` / config formats; auto-excludes `vendor/` / `third_party/` / generated code / lockfiles / `mocks/`), output in pseudo-diff format with line numbers as real file line numbers. Recommend passing `all all`.

---

## Sub-agent Dispatch Rules (caller must follow)

Following this repo's conventions (modeled on `devsop.init` / `devsop.eval`):

- **Tool**: the agent's sub-agent dispatch mechanism (a general-purpose read-write sub-agent; run in parallel where the agent supports it).
- **Input injected into the sub-agent**:
  - `REPO_ROOT`: absolute path of the target repo (only used to read context on demand via `git show`/`git blame`).
  - `DIFF_TEXT`: the full incremental diff extracted in Step A.
  - Instruction file path: `$SKILL_DIR/references/secret-leak-review-prompt.md` (the sub-agent reads it and follows its rules / false-positive exemptions / output schema).
- **Sub-agent constraints**:
  - Read-only; may use `git show`/`git blame` to aid context judgment.
  - **Forbidden** from any write operation such as `git add/commit/checkout/reset/push`.
  - **Forbidden** from writing any file; the review result is returned only as JSON in the reply (schema in the instruction file).
  - Must not modify the code under review.
- **Result collection**: after the sub-agent returns the findings JSON, save it as `findings.json` and pass it to `assemble` in Step C.

---

## Report Format

`secret-leak-report.json`:

```json
{
  "skill": "secret-leak-review",
  "mode": "incremental",
  "repo": "/path/to/repo",
  "commit_range": "<A>..<B>",
  "generated_at": "2026-07-16T11:30:00.000",
  "summary": {"total_findings": 2, "by_level": {"L1": 0, "L2": 0, "L3": 0, "L4": 2}, "by_confidence": {"high": 2, "medium": 0, "low": 0}},
  "findings": [
    {
      "file": "internal/auth/login.go",
      "line": 42,
      "level": "L4",
      "confidence": "high",
      "indirect": false,
      "evidence": "log.Printf(\"pwd=%s\", password)",
      "reason": "password variable value printed directly to logs",
      "suggestion": "remove the log output, or replace the value with [REDACTED]"
    },
    {
      "file": "internal/auth/login.go",
      "line": 58,
      "level": "L4",
      "confidence": "high",
      "indirect": true,
      "leak_path": "User.Password -> json.Marshal(u) -> log.Printf(\"user=%s\", b)",
      "evidence": "b, _ := json.Marshal(u); log.Printf(\"user=%s\", b)",
      "reason": "User contains a Password field (json:\"password\", not \"-\"); printed after whole-struct serialization, effectively leaking the password",
      "suggestion": "add a `json:\"-\"` tag to the Password field, or implement MarshalJSON() to redact sensitive fields"
    }
  ]
}
```

- `level`: `L1` / `L2` / `L3` / `L4`, based on the "Sensitive Data Levels" table in `references/secret-leak-review-prompt.md` (e.g. password→L4, ID card→L3, phone number/name→L2). Indirect leaks are leveled by the **most sensitive field leaked**.
- `confidence`: `high` / `medium` / `low`, indicating judgment confidence (may be low due to false positives). `low`/`medium` findings should be manually reviewed before action.
- `summary.by_level`: distribution count by L1-L4.
- `summary.by_confidence`: distribution count by high/medium/low.
- `indirect`: `true` means an indirect leak (whole-struct/container serialization printing); in this case `leak_path` describes the chain from the sensitive field to the log outlet; omitted or `false` means a scalar value is printed directly.
- `mode`: `incremental` / `single` / `full`.
- `commit_range`: `<A>..<B>` for incremental mode; `<commit>^ (single commit)` for single-commit mode; `FULL (full scan)` for full mode.
- Empty range or no hits → `findings: []`, `summary` all 0.

---

## False-Positive Exemptions (sub-agent reduces noise accordingly)

Do not report when any of the following hit: the variable name contains `mock/dummy/example/fake/test`, masking is already applied (`Mask()`/`****`/only the first few digits printed), the value printed is a field name/type name constant rather than a value, Debug-level demo literals, unit-test assertions on literals, or only meta-information such as `len()`/`Contains()` is printed.

---

## Key Constraints (hard)

- `$SKILL_DIR` is read-only (scripts/instructions); all output is written only to `$REPO_ROOT`, **never** to `$SKILL_DIR`/`$HOME`/`/tmp`.
- **Forbidden** `git add` / `git commit`; changes are left for the user to review and commit.
- Read-only analysis; never modify the code under review.

---

## Rationalizations (excuses that must not fly)

If you catch yourself thinking any of these, STOP — the rebuttal wins:

| Excuse | Rebuttal |
|--------|----------|
| "The diff is small, I'll just eyeball it instead of running extract" | The extract step is deterministic and cheap; eyeballing misses indirect leaks (whole-struct prints), which are the most common real incidents |
| "This is a false positive, I'll drop it from the findings" | Findings with `confidence: low/medium` are kept and flagged for manual review — the schema carries confidence precisely so nothing is silently dropped |
| "Only production code matters, tests/scripts can be skipped" | Full-mode scans every git-tracked source file (`.go` / `.py` / `.js` / `.ts` / `.java` / configs); exclusion lists are defined (vendor/generated/lockfiles/mocks), everything else is in scope |
| "I'll fix the leak myself while reviewing" | This skill is read-only by contract; fixes happen in a separate normal task flow so review and change stay separated |
| "No hits found, I'll skip assembling the report" | A zero-finding report is itself an artifact (`findings: []`, summary all 0) and proves the review ran; skipping it breaks traceability |
| "I can estimate the level instead of checking the sensitivity table" | Levels L1–L4 come from the reference table; a mis-levelled L4 (password) finding defeats the whole severity scheme |

---

## File Structure

```
secret-leak-review/
├── SKILL.md                              # this file
├── README.md                             # usage + examples
├── scripts/
│   ├── extract_diff.sh                   # read-only extraction of the commitA..commitB incremental diff
│   └── review_secret_leak.py             # main entry: extract / assemble modes
└── references/
    └── secret-leak-review-prompt.md      # sub-agent review instructions (rules + false-positive exemptions + output schema)
```

**Maintainers**: secret-leak-review team  
**License**: MIT
