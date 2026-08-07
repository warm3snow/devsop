---
name: go-secret-leak-review
description: "Performs a dedicated privacy-leak Code Review on incremental code in a given commit range, detecting the risk of passwords/private keys/tokens/credentials being printed to logs or standard output (including indirect leaks via whole-struct serialization)"
disable-model-invocation: true
---

# go-secret-leak-review Skill

> Incremental-code privacy-leak reviewer — focused on the high-risk pattern "sensitive values printed to logs/output", including **indirect leaks** (whole struct/container serialization printing).

**Version**: 1.1.0 | **Status**: ✅ Available

---

## Problem Solved

During development, someone may print sensitive data into logs, including **direct printing** and **indirect leaks**:

```go
// Direct leak
log.Printf("user login pwd=%s", password)              // ❌ password leaked
fmt.Println("private key:", privateKeyPEM)              // ❌ private key leaked
zap.S().Infof("token=%s", accessToken)                  // ❌ token leaked

// Indirect leak (more subtle; new detection in v1.1)
type User struct {
    ID       int    `json:"id"`
    Password string `json:"password"`   // ❌ not "-", will be serialized
    Token    string `json:"token"`
}
b, _ := json.Marshal(user); log.Printf("user=%s", b)    // ❌ effectively leaks password+token
log.Printf("user=%+v", user)                            // ❌ %+v expands all field values
fmt.Println(user)                                       // ❌ depends on String(); leaks if not redacted
```

This skill performs a dedicated review of **incremental code in the commitA..commitB range**, locating leak positions (file:line) via **sub-agents**, covering:

- values of `password` / `passwd` / `passphrase` / `pwd`
- private keys / certificates (`-----BEGIN ... PRIVATE KEY-----`)
- values of `token` / `apiKey` / `secretKey` / `accessKey` / `sign` / `auth`
- database connection strings with credentials, raw `Authorization` header values
- PII (ID card / phone number / bank card and other personal data)
- **Indirect leaks**: structs / maps / slices containing sensitive fields printed as a whole via `json.Marshal` / `%v` / `%+v` / custom serializers, where the fields lack `json:"-"` and the type does not implement redacting `MarshalJSON`/`String`

The review is **limited to privacy leaks**; it does not do generic lint / performance / architecture review. It complements `go-quality-scorer` without overlap.

Sensitive data levels (L0-L4) and redaction rules: the "Sensitive Data Levels (L0-L4) and Redaction Rules" section of `references/secret-leak-review-prompt.md` is the single authoritative source.

---

## Quick Start

```bash
SKILL_DIR=skills/go-secret-leak-review

# Step A: extract the code (writes go-secret-leak-diff.txt under REPO_ROOT)

#   Incremental mode: commitA..commitB range
python3 $SKILL_DIR/scripts/review_secret_leak.py extract \
    /path/to/repo <commitA> <commitB> [--path=subdir] [--out=diff.txt]

#   Single-commit mode: only scan this commit's changes relative to its parent (pass - / empty / single as commitB)
python3 $SKILL_DIR/scripts/review_secret_leak.py extract \
    /path/to/repo <commitID> - [--path=subdir] [--out=diff.txt]

#   Full mode: pass all/* as either commitA or commitB → scan all Go source in the working tree
python3 $SKILL_DIR/scripts/review_secret_leak.py extract \
    /path/to/repo all all [--path=subdir] [--out=diff.txt]
#   Equivalent: ALL / * (case-insensitive)

# Step B: the caller (an AI coding agent) dispatches a sub-agent
#   Read $SKILL_DIR/references/secret-leak-review-prompt.md as the sub-agent instructions,
#   inject the diff text from the previous step; the sub-agent returns findings JSON (not written to disk).
#   Use the Agent tool, run_in_background=true, constraints: read-only, no git writes, no file writes.

# Step C: aggregate into the final report (writes go-secret-leak-report.json under REPO_ROOT)
#   assemble's commit params must match extract (mode recognized from the params)
python3 $SKILL_DIR/scripts/review_secret_leak.py assemble \
    /path/to/repo <commitA|commitID|all> <commitB|-|all> --findings=findings.json [--out=report.json]
```

**Commit parameter semantics** (three modes auto-detected):
- **Incremental mode**: both `commitA` and `commitB` are valid commits. `git diff commitA commitB` represents the changes in commitB relative to commitA (commitA excluded, commitB included). Identical commits produce an empty range.
- **Single-commit mode**: `commitA` is a valid commit; pass `-` / `single` / empty as `commitB`. Equivalent to `git diff commitA^ commitA` (scan this commit's changes relative to its parent); the root commit automatically compares against the empty tree.
- **Full mode**: either `commitA` or `commitB` is the keyword `all` / `ALL` / `*` (case-insensitive). Scans all git-tracked `.go` files in the working tree (auto-excludes `vendor/` / `third_party/` / `*.pb.go` / `_gen.go` / `mocks/`), output in pseudo-diff format with line numbers as real file line numbers. Recommend passing `all all`.

---

## Sub-agent Dispatch Rules (caller must follow)

Following this repo's conventions (modeled on `devsop.init` / `devsop.eval`):

- **Tool**: Agent tool, param `run_in_background: true`, `subagent_type` defaults to `general-purpose`.
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

`go-secret-leak-report.json`:

```json
{
  "skill": "go-secret-leak-review",
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

- `$SKILL_DIR` is read-only (scripts/instructions); all output is written only to `$REPO_ROOT`, **never** to `$SKILL_DIR`/`$HOME`/`~/.codebuddy`/`/tmp`.
- **Forbidden** `git add` / `git commit`; changes are left for the user to review and commit.
- Read-only analysis; never modify the code under review.

---

## File Structure

```
go-secret-leak-review/
├── SKILL.md                              # this file
├── README.md                             # usage + examples
├── scripts/
│   ├── extract_diff.sh                   # read-only extraction of the commitA..commitB incremental diff
│   └── review_secret_leak.py             # main entry: extract / assemble modes
└── references/
    └── secret-leak-review-prompt.md      # sub-agent review instructions (rules + false-positive exemptions + output schema)
```

**Maintainers**: go-secret-leak-review team  
**License**: MIT
