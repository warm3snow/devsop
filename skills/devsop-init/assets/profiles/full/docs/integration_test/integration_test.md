# Integration Test Standards (Environment / Test Cases / Running and Debugging)

> Let any member (or AI Agent) be able to **set up, write correctly, run successfully, and debug** integration tests in a **real or near-real environment**.
> Three-part structure: ① Environment and Dependencies / ② Test Case Design and Organization / ③ Running and Debugging.
>
> **Boundary with unit tests**:
> - Unit tests (`../unittest/unittest.md`): function / module level, **no** real external calls, all mocked.
> - Integration tests (this document): cross-module / cross-service / cross-process chains, **allowed** to call real test-environment dependencies (DB / MQ / upstream-downstream services / third-party SDK test stubs).
>
> **If the repository has integration-test project rules (`rules/integration_test_*.md`, or a synonymously named file like `it_rule.md` / `api_test_rule.md`), they are the authoritative source**: this document inherits them in the form of excerpts + links and does not introduce conflicting rules; adjusting this document must keep the rules in sync.

> Source: <information source: `*_integration_test.go` with `//go:build integration` + CI integration test job (with `-tags=integration`) + integration-test project rules + test environment deployment doc>
> Last-verified: <YYYY-MM-DD>

---

## §1 Environment and Dependencies

### 1. Integration Test Form Determination

> Different projects mean different things by "integration tests"; first clarify which form(s) this project falls into (multiple can be selected), then decide how to set up the environment.

| Form | Typical Scenario | Dependency Preparation Method |
|------|---------|-------------|
| **Interface-level IT** (API black box) | call HTTP/RPC interfaces to verify business flows | needs a usable test environment address + authentication |
| **Chain-level IT** (multi-service interaction) | verify the end-to-end A→B→C chain | full-chain test environment + data isolation solution |
| **Database IT** | verify DAO / migration / transaction behavior | independent test database (container or shared DB + isolated schema) |
| **Message / Async IT** | verify MQ consumption / scheduled tasks / callbacks | independent topic / queue + consumer group isolation |
| **Frontend IT** (E2E) | verify page interactions, cross-page flows | Playwright / Cypress + backend mock or test environment |

> Fill in the **actual form of this project** below, and mark the weights (which are primary, which are secondary):
>
> <!-- TODO: e.g. "This project is primarily interface-level IT, with database IT as secondary; no frontend E2E." -->

### 2. Test Environment Information

> When deployment or environment setup is documented elsewhere, link to that project documentation rather than duplicating it here.

| Item | Description | Example / Actual Value |
|----|------|--------------|
| Environment name / type | persistent shared environment or temporary on-demand environment | <fill in> |
| Access address | entry domain / IP / port | <fill in> |
| Authentication method | Token / certificate / IAM / temporary AKSK | <fill in> |
| Data isolation policy | independent account / independent schema / independent namespace / tag isolation | <fill in> |
| Cleanup policy | auto cleanup (TTL / label deletion) / manual cleanup / no cleanup | <fill in> |
| Upstream/downstream dependencies | see `../relationship.md`, list the dependencies IT must reach | <fill in> |

### 3. Prerequisite Dependency Check List (check first, then install)

> Skip the corresponding installation step if any item is already satisfied; do not blindly reset the environment.

```bash
# (1) Test environment reachability
<fill in: curl -sS --max-time 5 <env-endpoint>/healthz && echo "env OK" || echo "env unreachable">

# (2) Authentication credentials ready (do not print plaintext)
<fill in: test -n "$<APP>_IT_TOKEN" && echo "token OK" || echo "token missing">

# (3) Integration test dependencies ready (Go: dependencies started as real services via testcontainers / docker-compose, or test endpoints injected by CI)
<fill in: docker ps --format '{{.Names}}' | grep -q <svc> && echo "deps OK" || echo "deps missing">
<fill in: curl -sS --max-time 5 <mysql/redis/kafka test address>/healthz && echo "deps OK" || echo "deps missing">

# (4) Test data fixtures / seed data
<fill in: test -f testdata/it/<seed>.sql && echo "fixture OK" || echo "need to import fixture">

# (5) Isolated resources (independent topic / namespace etc.)
<fill in: project-specific check command>
```

Judgment logic: all 5 items pass → run IT directly; some item fails → **only fix the failed item**, do not rebuild everything.

### 4. Environment Variables and Configuration

| Variable | Purpose | Example |
|------|------|------|
| <e.g. `<APP>_IT_ENDPOINT`> | test environment entry address | `https://test-api.example.com` |
| <e.g. `<APP>_IT_TOKEN`> | authentication token (**strictly forbidden to hardcode**) | injected from vault / environment variables |
| <e.g. `<APP>_IT_NAMESPACE`> | resource isolation namespace | `it-<branch>-<run-id>` |
| <e.g. `IT_DRY_RUN`> | only print requests, no real submission | `1` / `0` |

> Integration test environment variables **must be injected from vault / CI secrets / local `.env.local` (already gitignored)**, forbidden to write into the repository.

---

## §2 Test Case Design and Organization

### 1. Universal Mandatory Clauses (red lines)

| # | Red Line |
|---|------|
| 1 | **Forbidden** to point at production environment / shared online databases; only run on test or staging environments |
| 2 | **Forbidden** to use real users' real credentials in IT; use dedicated test accounts |
| 3 | **Forbidden** to leave dirty test data: each test case has its own setup / teardown, or global cleanup hooks to guarantee idempotency |
| 4 | **Forbidden** to share mutable state between test cases / depend on execution order (unless `@order` is explicitly declared and documented) |
| 5 | **Forbidden** to hardcode environment information (domains / paths / credentials / resource IDs) |
| 6 | **Must** record `req_id` / `trace_id` to logs or reports for later tracing |
| 7 | **Must** add protection switches for test cases that may incur costs / irreversible operations (`IT_DRY_RUN` / explicit confirm) |

### 2. Test Case Types and Applicable Scenarios

| Type | Applicable To | File Naming / Location | Example Style |
|------|------|----------------|---------|
| Interface positive test case | verify the main flow happy path | `<package>/<module>_integration_test.go` (`//go:build integration`) | `TestXxx_Normal` |
| Interface negative test case | parameter errors / auth failures / resource not found | same as above, independent `TestXxx_Negative` functions | `TestXxx_Negative` |
| End-to-end chain test case | cross-service / cross-module flows | `it/scenarios/<scenario>_integration_test.go` | `TestScenarioXxx` |
| Data consistency test case | DB / cache / replica data verification | `TestXxx_DataConsistency` inside `<package>/<module>_integration_test.go` | `TestXxx_DataConsistency` |
| Async / timing test case | MQ consumption / callbacks / scheduled tasks | `TestXxx_Async` inside `<package>/<module>_integration_test.go` | `TestXxx_Async` |

### 3. File Naming Hard Constraints

- Integration test files are **isolated with the `//go:build integration` build tag**; normal `go test ./...` does not compile or run them, avoiding pollution of UT and slowing down CI
- Integration test files are in the **same package and same directory** as the code under test (`<module>_integration_test.go`), or centrally placed in the `it/` package; do not mix them into the same file as UT
- Each interface / scenario under test has an **independent `TestXxx` function**, with naming that clearly reflects "what is being tested + positive/negative"
- go-zero projects: inject real test dependencies (mysql/redis started via testcontainers) through `svc.ServiceContext`, reuse `TestMain` for unified startup/shutdown

### 4. Test Case Design Self-Check List (four dimensions)

> Each test case must clearly define the following four dimensions, to avoid "testing for nothing".

| Dimension | Checkpoint |
|------|-------|
| **Input** | required / optional / boundary values / illegal inputs covered |
| **State** | whether the precondition state preparation (DB rows / resources created / upstream mocked) is clear |
| **Dependencies** | which upstream/downstream dependencies (see `relationship.md`) need to be real, which can be stubbed |
| **Assertions** | assert not only the response code, but also key fields and side effects (DB writes / message sending / log output) |

### 5. Mock / Stub Strategy

> Integration tests call **real dependencies by default**, but there are still scenarios needing stubs, to avoid unreachable / uncontrollable dependencies turning IT red.

| Category | Default Strategy |
|------|---------|
| Core interfaces of this project | **real calls** |
| Downstream services in the same test environment | **real calls** |
| Cross-domain / third-party SDKs (SMS / payment / email) | use the sandbox / test mode provided by the third party; use local stubs when no sandbox is available |
| Uncontrollable externals (e.g. carriers / real physical devices) | must be stubbed; mark the test case with `@requires_real` to explicitly exclude |
| Time / random | use with caution; if necessary, isolate with dedicated fixtures |

### 6. Connection to Project Rules

- If the repository has integration-test project rules (`rules/integration_test_*.md` / `it_*.md`): change §2 of this document to point to that rules anchor, do not duplicate
- Otherwise use this document's standards as the minimum baseline
- Record individual test results in the project's existing test or change-tracking system; this guide defines reusable test conventions.

---

## §3 Running and Debugging

### 1. Standard Execution Commands

```bash
# Full integration tests (CI main entry; must include the integration build tag)
<fill in: go test -tags=integration -race ./... >
<fill in: make it   # if the project provides a make it wrapper (internally go test -tags=integration)>

# Specific package
<fill in: go test -tags=integration ./internal/logic/...>

# Single test case
<fill in: go test -tags=integration -run 'TestXxx_Normal' ./internal/logic/>

# Dry-run (no real submission, only validate the constructed request)
<fill in: IT_DRY_RUN=1 go test -tags=integration -run 'TestXxx' ./...>

# Only rerun failed test cases
<fill in: go test -tags=integration -run 'TestXxx' ./... -count=1>

# With trace / verbose logs
<fill in: go test -tags=integration -v -run 'TestXxx' ./... 2>&1 | grep -E "PASS|FAIL|req_id|trace_id">
```

> **Must** match the command run in CI; cases that pass locally but fail in CI are mostly environment variable / network access / permission differences.

### 2. What the Test Runner Usually Does (if there is a wrapper script)

> e.g. `run_it.sh` usually handles:
> 1. Check test environment reachability (healthz / readiness)
> 2. Inject test token / endpoint environment variables
> 3. Create an isolated namespace for this run (`it-<run-id>`)
> 4. Invoke the runner to execute test cases
> 5. On failure, automatically collect: the `req_id` list of failed test cases, key log fragments, environment snapshot
> 6. On completion, clean up resources per the isolation policy (even on failure; keep artifacts to artifacts/)

### 3. Debugging Approaches

| Symptom | Check First | Debug Command |
|------|---------|---------|
| All fail | environment reachability / auth / config | go through the 5-item check list in §1 |
| All time out | network / DNS / test environment overloaded | `curl -v <endpoint>/healthz`; check test environment monitoring |
| Flaky failures | async timing / resource contention / dependency jitter | rerun multiple times with `--lf`; check whether it depends on fixed timing |
| Single interface failure | grab req_id to check the upstream/downstream chain logs | see the §4 fault location flow |
| Cross-test interference | data isolation broken / global state | check setup/teardown / namespace isolation |
| Auth failure | token expired / insufficient permissions | re-issue the token; verify account permissions |

### 4. Fault Location Flow (common for interface-level IT)

```
failed test case → take req_id / trace_id
    → check this service's logs (filter by req_id)
    → look at the upstream/downstream call chain (linked by trace_id)
    → locate the fault point (this service / downstream / data issue)
    → fix / follow up with the owner
    → rerun the test case to confirm
```

> Record the failure, suspected cause, and follow-up in the project's existing test or issue-tracking system when useful.

### 5. Don'ts / Use with Caution

| Item | Reason |
|----|------|
| Using `time.sleep` and other blind waits in IT | use explicit polling via `wait_until(condition, timeout)` |
| Sharing the same test data without cleanup | data pollution makes subsequent test cases non-repeatable |
| Test cases depending on resources created by a previous test case | test cases must be independent; if a chain is needed, cover the full chain with a single test case |
| Disabling some test cases (`@skip` / `xfail`) to "make CI pass" | document the reason and track a follow-up when appropriate |
| Mixing IT and UT in the same runner | runs slow, failure causes mixed, reports hard to read |

### 6. Test Artifacts

| Artifact | Path | Purpose |
|------|------|------|
| JSON test report | <fill in: `it_report.json` (`go test -json`)> | CI ingestion (pipeline display) |
| JUnit XML | <fill in: `junit-it.xml` (`go test -json | gotestfmt`)> | CI ingestion (pipeline display) |
| Failed test case trace bundle | <fill in: `artifacts/failed/<run-id>/`> | contains logs, req_id, environment snapshot |
| Terminal summary | stdout | pass / fail / skip statistics |

### 7. CI Integration

- Consider running slow integration tests separately from fast unit tests when that improves feedback time.
- Set merge-blocking policy and artifact retention based on the project's risk, infrastructure, and CI cost.
- Test environment setup and deployment: see the relevant project-owned documentation when available.

---

## §4 Related Project Guidance

- Dependencies and service boundaries: `../relationship.md`, when present
- Unit-test conventions: `../unittest/unittest.md`
- Environment and deployment setup: relevant `../devops/` documentation, when present
