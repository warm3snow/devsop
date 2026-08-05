# Coding Standards

> Status: Draft | Maintainer: {{name}} | Last Updated: {{YYYY-MM-DD}}

## Scope

Applies to all {{language}} code in this repository. {{whether frontend and backend are distinguished, whether scripts are included}}

> Security-related clauses (input validation, encryption, concurrency safety, etc.) see §10 "Security Coding" of this file. Interface-layer security (authentication, CORS, SSRF) see [api-standards.md](api-standards.md) §Security.

## 1. Mandatory Rules (violation = blocks merge)

| # | Item | Threshold | Exceptions |
|---|----|------|------|
| 1 | Formatting | `{{gofmt / prettier / black}}` passes | None |
| 2 | Static checks | `{{golangci-lint / eslint / ruff}}` passes; config `{{.golangci.yml / .eslintrc}}` | Must use `{{lint:disable}}` comment + reason |
| 3 | Line length | ≤120 columns | Generated code, long strings, struct tags, URLs |
| 4 | File length | ≤800 lines | Test files ≤1600 lines |
| 5 | Function length | ≤80 lines | Test functions ≤160 lines |
| 6 | Nesting depth | ≤4 levels | None |
| 7 | Cyclomatic complexity | ≤10 | None |
| 8 | Indentation | 4 spaces / `gofmt`; **forbidden** to mix spaces and tabs | None |
| 9 | Magic numbers | Must be named constants | Loop 0/1, exit code 1, 4 in discriminators |

## 2. Naming Conventions

### General Principles
- Names should be semantically clear, avoid abbreviations (unless industry-standard: URL, ID, API, UUID)
- **Forbidden** package/class names: `common`, `util`, `misc`, `global` (multi-level directories like `xx/util/encryption` are allowed)
- **Forbidden** receiver/method parameter names: `me`, `this`, `self`

### Per-Language Conventions (keep the relevant subsection per language, delete the others)

**Go**
- Package names: all lowercase, single words, no underscores, same as the directory name
- File names: `snake_case`
- Type names: `PascalCase`; receivers use 1-2 letter abbreviations, kept consistent
- Functions/methods: `camelCase` (private) / `PascalCase` (exported)
- Interfaces: single-method `er` suffix (Reader/Writer); multi-method use nouns
- Acronyms: for private variables, the first word is all lowercase (`apiClient`); otherwise keep the original case (`URLArray`, `UserID`)

**Python**
- Modules/packages: `snake_case`, no leading underscores (unless private)
- Functions/variables: `snake_case`
- Classes: `PascalCase`
- Constants: `UPPER_CASE_WITH_UNDERSCORES`
- Private: single underscore prefix; strongly private: double underscore prefix

**Java**
- Classes: `PascalCase`, **avoid** `I` prefix and `Interface` suffix
- Methods/variables: `camelCase`
- Constants: `UPPER_CASE_WITH_UNDERSCORES`
- Query semantics consistent: choose one of `find` / `search` / `query`, consistent across the project

**C++**
- File names: `snake_case.cpp` / `.h`
- Classes: `PascalCase`
- Functions/variables: choose `snake_case` or `camelCase` per project, consistent across the project
- Macros: `UPPER_CASE`

## 3. Comment Conventions

- **Must**: all exported symbols have doc comments, format `// Name description` (Go) / docstring (Python) / Javadoc (Java) / Doxygen (C++)
- **Must**: explain **Why**, not **What** — What should be expressed by the code itself
- **Forbidden**: keeping commented-out code (unless accompanied by a `TODO(name): removal timing` comment)
- Use Chinese comments for key business logic (team default language)
- Exceptions/errors: annotate with `@throws` / `@raises` (Java/Python)

## 4. Import Conventions

- Three-group separation (with blank lines): standard library → third-party → local packages
- **Forbidden** relative path imports (e.g. `from ..utils import x`)
- **Forbidden** dot imports `import .` and bare blank imports `import _` (main, test excepted, and must be commented)
- Aliases: use when package names conflict or are inconsistent with the directory; naming follows package naming conventions
- Tools: `{{goimports / isort / spotless}}` to organize automatically

## 5. Error Handling

### General
- Errors must be handled or explicitly ignored (`_ = ignored`, with a reason comment)
- Error messages: start with lowercase, no trailing punctuation, format `module: description`
- **Forbidden** to use `panic` / `throw` / `os.exit()` to control business flow

### Go
- Use `errors.New("xxx")` or `fmt.Errorf("module: %w", err)` to wrap errors
- error must be the last return value of a function
- `panic` only for invariant assertions, `init` failures, `MustXXX` factories; **forbidden** for business errors

### Python
- Exception types must be specific; **forbidden** `except:` / `except Exception:` (except for the outermost exception barrier)
- Use `with` to manage resources (files, locks, connections)

### Java
- Catch clauses must list specific exception types; **forbidden** bare `catch (Exception)` / `catch (Throwable)`
- Use `try-with-resources` to manage AutoCloseable resources
- When ignoring exceptions, the variable name must be `ignored` (expressing intent explicitly)

## 6. Resource Management

- Write the release code **immediately** after acquiring a resource (Go: `defer` / Python: `with` / Java: try-with-resources / C++: RAII)
- **Forbidden** to use `defer` in loops (Go)
- Files, connections, locks, semaphores must be released in pairs
- C++ must use smart pointers (`unique_ptr` / `shared_ptr`), **forbidden** bare `new` / `delete`

## 7. Concurrency and Parallelism

- Shared state must be protected: `sync.Mutex` / `sync.RWMutex` / `sync.Map` / `Atomic`
- **Forbidden** concurrent writes to maps (Go); **forbidden** closing channels repeatedly
- Closures capturing loop variables must pass via parameters or local variables
- 64-bit values (long/double) reads/writes must guarantee atomicity (Java: use volatile/Atomic)
- Must ensure goroutines/threads can exit (avoid leaks): timeouts, exit signals, context cancellation
- Deadlock protection: fixed lock ordering

## 8. Types and Zero Values

- Empty slices/lists use `nil` / `None`, not `[]` initialization (Go)
- Pre-allocate map/slice/list capacity to reduce reallocation
- String concatenation: avoid `+` in loops, use `StringBuilder` (Java) / `strings.Builder` (Go) / `''.join()` (Python)
- Float comparison: use epsilon, **forbidden** `==`

## 9. Code Style

### Functions and Methods
- Parameter count ≤5; beyond that consider struct/object encapsulation
- Named return values: use only when returning 2-3 values of the same type or when context is unclear (Go)
- Method names should not repeat the semantic info of the receiver/parameters/return value
- Prefer value passing; do not pass pointers for map/slice/chan/interface (Go)

### Control Flow
- **Prefer early returns**, reduce nesting
- if-else chains over 3 segments consider switching to switch / strategy pattern
- switch must have a `default` (Go)

### Variable Declarations
- Proximity principle: declare right before first use
- Local variables prefer short names; when scope is large, names should be descriptive

## 10. Security Coding (Language Layer)

> Interface-layer security (authentication, CORS, SSRF, CSRF) see [api-standards.md](api-standards.md).

### Input and Concatenation
- **【Must】** Database queries use prepared/parameterized statements; **forbidden** string-concatenated SQL
- **【Must】** Fields that cannot be parameterized (ORDER BY, table names) use whitelist validation
- **【Must】** Command execution uses structured APIs (`exec.Command` array form / `subprocess.run([...], shell=False)`), **forbidden** to concatenate user input into shell
- **【Must】** Path operations use `filepath.Clean()` + `startsWith()` validation, **forbidden** to tolerate `..`
- **【Must】** External input whitelist validation: type, length, range, format
- **【Must】** HTML output escapes third-party data (`html.EscapeString` / `bleach.clean`)

### Secrets and Sensitive Information
- **【Forbidden】** Hardcoding AK/SK, passwords, keys, internal IPs, employee information
- **【Must】** Inject sensitive config via config center, environment variables, KMS
- **【Must】** Log redaction: ID card numbers show first and last digits, phone numbers mask the middle 6 digits, bank cards show only the last 4 digits
- **【Forbidden】** Log output of: passwords, keys, Tokens, pointer values
- **【Must】** Encryption: use SHA-2 / RSA / AES-GCM; **disable** DES, 3DES, MD5, SHA1, RC4
- **【Must】** Password hashing: random salt + multiple rounds (bcrypt / scrypt / argon2id)
- C++: clear sensitive data immediately after use (`OPENSSL_cleanse()` / `SecureZeroMemory()`)

### Random Numbers
- **【Forbidden】** `rand()` / `math/random` for security scenarios
- **【Must】** Use CSPRNG: `crypto/rand` (Go), `secrets` (Python), `SecureRandom` (Java), `RAND_bytes` (OpenSSL/C++)
- **【Forbidden】** `rand.Int() % n` form, use `rand.Intn(n)`

### TLS and Transport
- **【Must】** TLS ≥1.2, TLS 1.3 recommended; **forbidden** plaintext transmission of sensitive data
- **【Must】** Enable certificate verification; **forbidden** `InsecureSkipVerify: true` (unless test environment and annotated in code)

## 11. Toolchain

| Tool | Purpose | Trigger |
|------|------|----------|
| `{{formatter}}` | Auto formatting | Save / pre-commit |
| `{{linter}}` | Static checks | pre-commit / CI |
| `{{security scanner}}` | Dependency vulnerabilities / SAST | CI |
| `{{test coverage}}` | Coverage reports | CI |

## 12. Exceptions and Waiver Process

If there are sufficient reasons to violate the above standards:
1. Add a `{{lint:disable comment}}` at the code location and state the reason
2. Explain the impact surface and mitigation measures in the PR description
3. Reviewer confirms a second time

## References

- Project-level language standards: {{link to team/company standards}}
- Test assertion standards: [unittest/unittest.md](unittest/unittest.md)
- API and interface security: [api-standards.md](apis/api-standards.md)
- Code Review checklist: [code-review.md](code-review.md)
