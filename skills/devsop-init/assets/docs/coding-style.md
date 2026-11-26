# Coding Standards

> Status: Draft | Maintainer: {{name}} | Last Updated: {{YYYY-MM-DD}}

## Scope

Applies to all {{language}} code in this repository. For per-language detail, prefer the project's existing conventions source or the devsop library's `rules/<lang>-style-guide.md` over re-deriving rules here.

## 1. Mandatory Rules (violation = blocks merge)

| # | Item | Threshold |
|---|----|------|
| 1 | Formatting | `{{formatter: gofmt / prettier / black …}}` passes |
| 2 | Static checks | `{{linter: golangci-lint / eslint / ruff …}}` passes |
| 3 | Line length | ≤120 columns (generated code exempt) |
| 4 | File / function length | ≤800 / ≤80 lines |
| 5 | Nesting depth / cyclomatic complexity | ≤4 / ≤10 |
| 6 | Magic numbers | Must be named constants |

## 2. Naming

- Semantic names; no abbreviations unless industry-standard (URL, ID, API)
- Forbidden package/class names: `common`, `util`, `misc`, `global`
- Follow the language's community convention (see the project's `rules/<lang>-style-guide.md` when present)

## 3. Comments

- Exported symbols have doc comments; explain **why**, not **what**
- No commented-out code (unless paired with a `TODO(name): removal timing`)

## 4. Error Handling

- Errors handled or explicitly ignored (with a reason comment)
- No `panic` / `throw` / `exit` to control business flow
- No bare `catch (Exception)` / `except Exception:` swallowing

## 5. Security Baseline

- Parameterized queries; no string-concatenated SQL or shell commands
- No hardcoded credentials; secrets via environment/config injection
- Log redaction for sensitive fields; standard crypto only (SHA-2/AES-GCM; no MD5/SHA1/DES)
- CSPRNG for security scenarios (no `rand()`)

## 6. Toolchain

| Tool | Purpose | Trigger |
|------|------|----------|
| `{{formatter}}` | Auto formatting | pre-commit |
| `{{linter}}` | Static checks | pre-commit / CI |
| `{{test command}}` | Tests | CI |

## References

- Per-language detail: `rules/<lang>-style-guide.md` in the devsop library, or {{the project's own conventions source}}
