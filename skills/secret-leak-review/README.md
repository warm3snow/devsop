# secret-leak-review Skill

**Dedicated incremental-code privacy-leak reviewer (language-agnostic)** — detects the risk of passwords / private keys / tokens / credentials / PII being printed to logs or standard output, in any mainstream language (Go, Python, JS/TS, Java, Rust, ...).

## Problem Solved

It is easy to print sensitive values into logs during development:

```go
log.Printf("user login pwd=%s", password)     // ❌ password leaked (Go)
```

```python
logging.info(f"token={access_token}")         # ❌ token leaked (Python)
```

```javascript
console.log("user:", JSON.stringify(user));   // ❌ indirect leak (JS)
```

This skill performs a dedicated Code Review of the **incremental code** in the specified `commitA..commitB` range, locating leaked `file:line` positions via sub-agents.

## Prerequisites

Only depends on `git` (bundled with the system) + `python3`; no additional tools need to be installed.

## Usage Flow

```bash
SKILL_DIR=skills/secret-leak-review

# Step A: extract the incremental diff (writes secret-leak-diff.txt under REPO_ROOT)
python3 $SKILL_DIR/scripts/review_secret_leak.py extract \
    /path/to/repo <commitA> <commitB> [--path=subdir] [--out=diff.txt]

# Step B: the caller (an AI coding agent) dispatches a sub-agent
#   instruction file: $SKILL_DIR/references/secret-leak-review-prompt.md
#   input: REPO_ROOT + the diff text from Step A
#   constraints: read-only, no git writes, no file writes; returns findings JSON

# Step C: aggregate into the final report (writes secret-leak-report.json under REPO_ROOT)
python3 $SKILL_DIR/scripts/review_secret_leak.py assemble \
    /path/to/repo <commitA> <commitB> --findings=findings.json [--out=report.json]
```

### Range semantics

`git diff commitA commitB` = **the changes in commitB relative to commitA** (commitA excluded, commitB included). Identical commits → empty range; Step A directly produces a "no increment" report. Full mode (`all all`) scans all git-tracked source files.

## Report Fields

`secret-leak-report.json`:

| Field | Description |
|-------|-------------|
| `commit_range` | `<A>..<B>` |
| `summary.total_findings` | total hit count |
| `summary.by_level` | distribution count by L1-L4 |
| `summary.by_confidence` | distribution count by high/medium/low |
| `findings[].file` | path relative to the repo |
| `findings[].line` | target line number in the diff |
| `findings[].level` | `L1` / `L2` / `L3` / `L4` (sensitive data level) |
| `findings[].confidence` | `high` / `medium` / `low` (judgment confidence, may be low due to false positives) |
| `findings[].evidence` | the matched code line text |
| `findings[].reason` | the basis for judging the leak |
| `findings[].suggestion` | suggestions such as redaction / masking / removing the log |

## Detection Scope and False-Positive Exemptions

**Detects**: passwords, private keys/certificates, tokens/API keys/secret keys, database connection strings with credentials, raw Authorization header values, PII (ID card/bank card/passport, phone number/email/name/IP).

**Exempt** (not reported): the variable name contains `mock/dummy/example/fake/test`, masking is already applied (`Mask()`/`****`/only the first few digits printed), the value printed is a field name/type name constant rather than a value, Debug-level demo literals, unit-test assertions on literals, or only meta-information such as `len()`/`Contains()` is printed.

## Constraints

- Read-only analysis; never modify the code under review.
- Output is written only to `REPO_ROOT`, never to `$SKILL_DIR`/`$HOME`/`/tmp`.
- `git add`/`git commit` are forbidden; changes are committed by the user after review.

## Version

| Version | Date | Description |
|---------|------|-------------|
| 2.0.0 | 2026-09-13 | Renamed from `go-secret-leak-review`; language-agnostic extraction (multi-language source scan); examples cover Go/Python/JS |
| 1.1.0 | 2026-07-22 | Added indirect-leak detection (whole struct/container serialization printing); aligned with L0-L4 sensitive data levels; report adds level (L1-L4) + confidence; removed redundant severity and category dimensions |
| 1.0.0 | 2026-07-16 | Initial release: incremental diff extraction + sub-agent privacy-leak review |

> The single authoritative source for sensitive data levels (L0-L4) and redaction rules is `references/secret-leak-review-prompt.md`.

**License**: MIT
