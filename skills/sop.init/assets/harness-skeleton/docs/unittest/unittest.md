# Unit Test Standards (Go environment / generation / running and debugging)

> Let any member (or AI Agent) be able to **set up, write correctly, run successfully, and debug** Go unit tests locally.
> Three-part structure: ① Environment Setup / ② Generation Standards / ③ Running and Debugging.
>
> **If the repository has `.codebuddy/rules/unittest_*.md`, that is the authoritative source**: this document inherits it in the form of excerpts + links and does not introduce conflicting rules; adjusting this document must keep the rules in sync.

> Source: <information source: go.mod + Makefile + CI config + .codebuddy/rules/unittest_*.md>
> Last-verified: <YYYY-MM-DD>

---

## §1 Environment Setup and Dependency Installation

### 0. Recommended Technology Choices (Go)

| Category | Recommended | Alternative |
|------|------|------|
| Build / test runner | **`go test`** (standard library, zero dependencies) | — |
| Assertion library | **`github.com/stretchr/testify`** (assert + require) | standard library `testing` |
| Mock framework | **`go.uber.org/mock` (gomock)** or **`github.com/stretchr/testify/mock`** | hand-written interface implementations |
| HTTP testing | **`net/http/httptest`** (standard library) | — |
| SQL/DB testing | **`github.com/DATA-DOG/go-sqlmock`** | `pgx` / `database/sql` real database (integration tests) |
| Coverage | **`go test -cover` / `-coverprofile`** (standard library) | `gocov` |
| Fuzz testing | **`go test -fuzz`** (standard library 1.18+) | — |
| Benchmark testing | **`go test -bench`** (standard library) | `github.com/onsi/ginkgo/v2` |

> **Why trust only the standard library + testify by default**:
> - `go test` is a first-class citizen in Go, no extra runner needed; table-driven testing is its officially recommended paradigm
> - `testify/assert` reports the diff point on failure, `require` calls `t.FailNow()` after failure to avoid assertion avalanche
> - `go.uber.org/mock` is maintained by Google, integrates with `go generate` for automatic Mock generation, fitting Go's "interface as contract" philosophy

### 1. Prerequisite Dependency Check List (check first, then install)

> Skip the corresponding installation step if any item is already satisfied; do not blindly `go clean` and rebuild.

```bash
# (1) Go toolchain
command -v go >/dev/null && go version || echo "Go needs to be installed"

# (2) Go version required by the project (consistent with the go directive in go.mod)
grep -E "^go +[0-9]" go.mod | awk '{print $2}' | xargs -I{} go version | grep -F "{}" \
  >/dev/null && echo "Go version OK" || echo "Go version needs to be switched"

# (3) Key test dependencies
go list -m github.com/stretchr/testify >/dev/null 2>&1 && echo "testify OK" || echo "testify missing"
go list -m go.uber.org/mock >/dev/null 2>&1 && echo "mock OK" || echo "mock missing"

# (4) Build artifacts / generated code (mock_gen, protobuf, etc., as needed)
test -f <generated mock file> && echo "mocks OK" || echo "mocks need to be generated"
```

Judgment logic: all 4 items pass → run tests directly; some item fails → **only fix the failed item**, do not rebuild everything (unless the Go version is wrong).

### 2. Step-by-Step Installation (only execute when the checks above fail)

#### Step 1: Install the Go Toolchain

```bash
# macOS
brew install go

# Linux / general: download the matching version from https://go.dev/dl/, or use gvm / asdf to manage multiple versions
# write to shell config (first time only)
export GOROOT="$(go env GOROOT)"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
```

#### Step 2: Pin the Project's Go Version

```bash
# Follow the go directive in go.mod (e.g. go 1.22)
go mod edit -go=1.22
go mod tidy
```

#### Step 3: Install Test Dependencies

```bash
go get github.com/stretchr/testify@latest
go get go.uber.org/mock/gomock@latest
go get github.com/DATA-DOG/go-sqlmock@latest
go install go.uber.org/mock/mockgen@latest   # mock code generator
```

#### Step 4: Generate Mock Code (if depending on interfaces)

```bash
# generate a mock for the specified interface (written to <package>/mock_<package> or a mocks subpackage)
mockgen -source=internal/repo/user.go -destination=internal/repo/mock/user_mock.go -package=mock
# or add //go:generate mockgen ... on the interface, then run go generate ./...
```

#### Step 5: One-Command Script (if any)

> Projects usually provide `make test-setup` / `bash scripts/setup_test.sh` etc. **Prefer the one-command script**; this section explains its semantics.

### 3. Environment Variables and Configuration

| Variable | Purpose | Example |
|------|------|------|
| `GODEBUG` | debug scheduler / GC behavior (as needed) | `GODEBUG=gctrace=1` |
| `TEST_LOG_LEVEL` | test log level, read by internal `log.SetLevel` | `TEST_LOG_LEVEL=debug` |
| `MOCK_FLAG` | force-enable local mocks, forbid real external calls | `MOCK_FLAG=1` |
| `GOFLAGS` | inject global flags such as `-mod=mod` | `GOFLAGS=-mod=mod` |

> Test-related environment variables must be **set inside the test code or in a Makefile target** (e.g. `os.Setenv` in `TestMain`), to avoid members manually exporting them.

---

## §2 Unit Test Generation Standards

### 1. Universal Mandatory Clauses (red lines)

| # | Red Line |
|---|------|
| 1 | Do not modify the business code under test to make tests pass |
| 2 | Do not call real external services / write to a real database; use `go-sqlmock` for databases, `httptest` for HTTP, in-memory implementations for messages |
| 3 | Do not share mutable state between tests / do not depend on execution order; each `t.Run` subtest is independent |
| 4 | Do not delete existing test code, only append |
| 5 | New Mocks / helpers / fixtures may only be appended to the **end** of the corresponding file |
| 6 | Do not hardcode environment information (domains / paths / credentials); use `t.TempDir()` instead of fixed temporary paths |
| 7 | Forbidden to use runtime patching of production functions like `gomonkey` / `monkey` (breaks portability, CI easily crashes); dependencies should be abstracted as interfaces then mocked |
| 8 | Do not mix `t.Parallel()` with shared mutable global state in tests, to avoid data races |

### 2. Test Types and Applicable Scenarios

| Test Type | Applicable To | File Naming / Location | Style |
|---------|------|----------------|------|
| Function-level unit test | single / small set of functions with minor changes | `xxx_test.go` (same package and directory as the `xxx.go` under test) | table-driven |
| Interface / entry-level test (handler/service) | end-to-end entry flows | `xxx_test.go` + `httptest` | table-driven + Mock dependencies |
| Fuzz test | parsing / deserialization and other paths with untrusted input | `FuzzXxx` function | `go test -fuzz` |
| Benchmark test | performance-sensitive paths | `BenchmarkXxx` function | `b.ResetTimer()` |

### 3. File Naming and Organization Hard Constraints

- Test files are in the **same package and same directory** as the code under test, with the `_test.go` suffix; use white-box internal tests (`package xxx`), use external tests (`package xxx_test`) only when testing the exported API and black-box is needed
- Multiple functions / multiple scenario tests for the same file under test **go into the same `xxx_test.go`**; add → append, do not create parallel new files
- Table-driven: within one `TestXxx`, use `tests := []struct{...}{...}` + `for _, tt := range tests { t.Run(tt.name, ...) }` to cover multiple cases
- Mock code goes in a `mocks` subpackage or `mock_<pkg>` package, generated by `mockgen`, **not hand-maintained**

### 4. Mock Strategy (Go's interface-as-contract)

| Category | Default Strategy |
|------|---------|
| In-project functions (utils / validators / pure functions) | real calls allowed by default (not mocked) |
| External dependencies (DB / HTTP client / MQ / filesystem / third-party SDKs) | must be abstracted as **interfaces** then mocked with gomock / testify-mock |
| Observability (logs / metrics) | not mocked; verify with `t.Log` / in-memory sinks |
| Time / random | inject a `Clock` interface or `func() time.Time` field, fixed in tests |
| Global config / constants | passed in via dependency injection (constructor parameters), not relying on package-level variables |

> **Dependency injection paradigm**: the struct under test holds dependencies as interface fields, tests inject mock implementations. Avoid package-level hardcoded dependencies like `var db *sql.DB` — they cannot be mocked.

### 5. Table-Driven Test Case Design Self-Check List

> See `plans/_template/04-ut.md` § test case design checklist for details. Each test case must cover at least:
> - **Normal path**: typical input → expected output
> - **Boundary values**: empty slices / nil / zero values / maximum values
> - **Error path**: whether upper-layer handling is correct when the dependency returns an error
> - **Idempotency**: repeated calls with the same input produce consistent results

### 6. Connection to Project Rules

- If the repository has `.codebuddy/rules/unittest_*.md`: change §2 of this document to point to that rules anchor, do not duplicate
- Otherwise use this document's standards as the minimum baseline

---

## §3 Running and Debugging Standards

### 1. Standard Execution Commands

```bash
# Full run (current module and submodules)
go test ./...

# Specific package / file
go test ./internal/service/...
go test ./internal/repo/user_test.go ./internal/repo/user.go

# Specific test case (regex matching Test names / subtest names)
go test ./internal/service/ -run 'TestCreateUser/empty_name' -v

# Only rerun the last failed test cases
go test ./... -run '^(TestCreateUser|TestUpdateUser)$'

# With coverage
go test ./... -cover
go test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out

# Interactively view uncovered lines
go tool cover -html=coverage.out

# Benchmark / fuzz
go test ./... -bench=. -benchmem
go test ./... -fuzz=FuzzParse -fuzztime=30s
```

> **Must** match the command run in CI; cases that pass locally but fail in CI are mostly environment variable / path differences (e.g. `t.TempDir()` having different path permissions in CI).

### 2. What the Test Runner Usually Does (if there is a Makefile target)

> e.g. `make test` usually handles:
> 1. Set necessary environment variables (`TEST_LOG_LEVEL` etc.)
> 2. Clean up residue from the previous run (`coverage.out` etc.)
> 3. Call `go test ./... "$@"`, passing through command-line arguments
> 4. Optional: `go vet ./...` + `golangci-lint run` pre-checks

### 3. Debugging Approaches

| Symptom | Check First | Debug Command |
|------|---------|---------|
| All fail | environment / dependencies / Go version | go through the 4-item check list in §1 |
| Single file fails | isolate and reproduce | `go test ./pkg -run TestXxx -v` |
| Flaky failures | concurrent races / shared state | `go test -race ./...` |
| Coverage below target | look at uncovered lines | `go tool cover -func=coverage.out` |
| Import errors | module corrupted / wrong path | `go list -m all | grep <pkg>` |
| Mock not taking effect | `EXPECT()` not called / wrong order | gomock reports `missing call(s)` → check `ctrl.Finish()` / `defer ctrl.Finish()` |

### 4. Don'ts / Use with Caution

| Item | Reason |
|----|------|
| Modifying shared config like `Makefile` / `go.mod` / CI test config | affects everyone, needs PR review |
| Using runtime function patching like `gomonkey` | breaks cross-platform / CI (macOS ARM easily crashes); replace with interface mocks |
| Using `fmt.Println` for lots of debug info in tests | use `t.Log` / `-v` instead |
| Skipping test cases (`t.Skip`) to "make CI pass" | must note the reason in `04-ut.md` + track the fix |
| Tests depending on real network / database | slow, unstable, CI cannot reproduce; always mock |

### 5. Test Artifacts

| Artifact | Path | Purpose |
|------|------|------|
| Coverage profile | `coverage.out` | `go tool cover` analysis |
| Coverage HTML | `coverage.html` | local interactive view of uncovered lines |
| Benchmark results | stdout / `bench.out` | performance regression comparison |
| Terminal summary | stdout | pass / fail / duration |

### 6. CI Integration

- CI test runs must **match the local commands** (only output parameters like `-coverprofile` / `-race` may be added)
- **`-race` is mandatory** to detect data races (must be enabled for Go concurrent projects)
- Failures must block merging
- **Coverage gate: unit test coverage minimum 60%**, below 60% must block merging; regression (below baseline or down from the previous run) triggers a warning
- Recommended CI command: `go vet ./... && go test -race -coverprofile=coverage.out ./... && go tool cover -func=coverage.out | tail -1`
