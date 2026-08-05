# go-quality-scorer v1.1 Skill

> Go code quality scorer - six-dimension scoring framework + D3 scale-complexity extension

**Version**: 1.1.0 | **Updated**: 2026-06-26 | **Status**: ✅ Production-ready

---

## Quick Start

```bash
# 1. Install dependency tools (macOS example; full install in the "Installation" section below)
brew install gocyclo golangci-lint scc
go install github.com/uudashr/gocognit/cmd/gocognit@latest
go install github.com/securego/gosec/v2/cmd/gosec@latest

# 2. Run the scorer
python3 scripts/go-quality-scorer-v1.1.py /path/to/go/project

# 3. View the report
cat go-quality-report-v1.1.json
```

### Scan scope (test/mock code excluded by default)

Quality scanning only evaluates **production code**. The following files/directories are excluded from metric collection and static analysis across all dimensions (D1~D6) by default:

| Category | Match rule | Example |
|----------|------------|---------|
| Go test files | Filename ends with `_test.go` | `foo_test.go` |
| Mock-generated code | Filename or parent dir contains `mock` / `fake` / `stub` | `mock_client.go`, `mock/` |
| Test data dirs | Path contains `testdata` / `fixtures` | `pkg/testdata/` |
| Dependencies/build/VCS | `vendor/` / `node_modules/` / `.git/` / `dist/` / `build/` etc. | — |

The exclusion rules are implemented uniformly by `_is_test_or_mock_file` in `go-quality-scorer-v1.1.py` and `isTestOrMockPath` in `collect-metrics.go`. All external tools (gofmt / golangci-lint / gosec / gocyclo / gocognit / scc) receive the filtered file list, and their output is re-filtered to prevent leakage.

> Note: test coverage collection (D4) still runs `go test` / `pytest`, which depends on test files and is not affected by the exclusion rules above — what is excluded is "the code being scored", not "the code participating in test runs".

---

## Execution Flow and Degradation Strategy

### Language detection and execution path

First detect the project's primary language (done automatically by the `_detect_language` script):
- **Go**: has `go.mod` or `.go` files → use `_scan_coverage_go`
- **Python**: has `pyproject.toml`/`setup.py`/`setup.cfg`/`requirements.txt` or `.py` files → use `_scan_coverage_python`
- **Other**: degrade to LLM estimation

Both Go and Python **use the script path**; do not degrade just because it is not Go. The script `go-quality-scorer-v1.1.py .` already supports dual-language coverage collection.

### Preferred: script execution

```bash
# Full scan (default): evaluate all production .go files in the project
python3 scripts/go-quality-scorer-v1.1.py <project>

# Incremental scan: only evaluate .go files changed in this commit (HEAD~1..HEAD)
python3 scripts/go-quality-scorer-v1.1.py <project> --mode diff

# Specify the output report path
python3 scripts/go-quality-scorer-v1.1.py <project> go-quality-report.json --mode diff
```

The script collects real metrics and generates `go-quality-report-v1.1.json`.

**Scan modes**:
- `--mode full` (default): full scan of all production .go files; runs `go test` / `pytest` to collect real coverage. Can be slow on large projects (go test compilation + instrumentation dominates).
- `--mode diff`: only scans .go production files changed in this commit (`HEAD~1..HEAD`), **skips coverage collection** (`go test` cannot slice per file; running the full suite conflicts with the incremental semantics). D4 is scored at a neutral 50%, and the report marks `"coverage_note": "incremental mode did not collect..."`. Suitable for MR/PR incremental checks and CI gates.

**Go projects**: gocyclo / gocognit / golangci-lint / gosec / scc / go are usually already in PATH and can be invoked directly. Only install when `command -v <tool>` confirms they are missing; never run duplicate `go install`.

**Python projects**: cloned code has no venv; you must first create a venv + install dependencies + install pytest/coverage, then run the script. See "Python Project Execution Flow" below.

**General constraints**: any tool/dependency installation failure must print logs to stderr; do not swallow errors and continue. Only degrade to LLM estimation when a tool is missing AND installation fails (D4 marked "estimated" and ≤70).

### Degradation: model capability generation

**Trigger conditions** (degrade on any):
- Script execution failed (non-zero exit code and no JSON produced)
- Script timed out (>10 minutes without completion)
- A tool is missing and installation failed (Go: any of gocyclo/golangci-lint/gosec/scc/go unavailable; Python: pytest/coverage cannot be installed)
- Project is neither Go nor Python (no go.mod and no pyproject.toml/setup.py/setup.cfg/requirements.txt, and Go files < 3 and Python files < 3)
- Script produced JSON but key fields are all missing (dimensions/total_score empty)

> Note: the script `go-quality-scorer-v1.1.py` already supports Python projects (`_detect_language` → `_scan_coverage_python`).
> Python projects use the script path; do not degrade to LLM estimation directly. Before Python coverage collection, create a venv at the project root and install dependencies (see "Python Project Execution Flow" below).

**Degradation steps**:
1. Read the project code using the model's own capability (go file structure, error handling, security patterns, test coverage, architecture layering, etc.)
2. Score each item against the six-dimension framework (D1~D6 + red lines); evidence must be based on actual code, not speculation
3. Generate a JSON report with the same structure as the script, writing to `go-quality-report-v1.1.json`
4. Add `"mode": "llm-fallback"` to metadata to mark the degradation source
5. List the tools actually used in metadata.tools (e.g. `["llm-code-analysis"]` or `["golangci-lint", "llm-fallback"]`)
6. Each issue must include a file:line location (located via code reading)

**Degradation scoring constraints**:
- Without real coverage data, D4 must not be ≥80 (cap 70, marked "estimated")
- Without gosec/govulncheck data, D2 must not be ≥85 (cap 75, marked "dependency CVE scan not performed")
- Without gocyclo/gocognit data, the D3 scale_complexity sub-item is marked "estimated"
- Red-line checks must still run (hardcoded secrets/SQL injection etc. can be judged by code reading)

**Forbidden**:
- Must not skip any dimension when degraded (D1~D6 all must have scores)
- Must not directly reuse the previous scoring result
- Must not produce an empty issues list (at least give the top 3 improvement points found by code reading)

---

## Python Project Execution Flow

The script `go-quality-scorer-v1.1.py` already supports Python projects (`_detect_language` returns `"python"` → `_scan_coverage_python` collects real coverage). Python projects follow this flow; **do not degrade to LLM estimation**:

1. **Locate the Python project root**: handled automatically by the script's `_detect_python_root` (monorepos such as a `backend/` subdirectory are also recognized)
2. **Create a venv and install dependencies** (the script's `_detect_python_bin` prefers `.venv/bin/python`; without a venv it falls back to system python3, which usually lacks project dependencies and causes `coverage run -m pytest` to fail):
   ```bash
   # At the Python project root (the script prints root=...)
   python3 -m venv .venv
   .venv/bin/python -m pip install -U pip
   # Dependency declaration priority: requirements.txt > pyproject.toml > setup.py
   .venv/bin/python -m pip install -r requirements.txt 2>/dev/null \
     || .venv/bin/python -m pip install -e . 2>/dev/null \
     || true
   # Required for coverage collection
   .venv/bin/python -m pip install pytest coverage
   ```
3. **Run the scoring script**:
   ```bash
   python3 scripts/go-quality-scorer-v1.1.py /path/to/python/project
   ```
   The script automatically uses `.venv/bin/python` to run `coverage run -m pytest -o addopts=` to collect real coverage.
4. **Produce the report**: the script writes `go-quality-report-v1.1.json` with the same structure as for Go projects.

**Constraints**:
- If venv creation + dependency installation fails, print failure logs to stderr; do not silently skip
- Dependency installation timeout (>5 minutes) may degrade, but D4 must be marked "estimated" and ≤70

---

## Six-Dimension Scoring Framework

```
D1 Correctness & Reliability (25%)   →  logic, boundaries, errors, concurrency
D2 Security (20%)                    →  input validation, auth, secrets, dependencies
D3 Maintainability & Scale-Complexity (20%) →  CC + Cognitive CC + SLOC + MI + Function Length
D4 Testing Effectiveness (15%)       →  coverage, assertions, boundaries, testability
D5 Architecture & Design (12%)       →  layering, coupling, interfaces, extensibility
D6 Performance Efficiency (8%)       →  time complexity, space, resources, overhead
────────────────────────────────────────────────────────────
Total (100%)  →  A/B/C/D/F five-level rating
```

---

## D3 Maintainability & Scale-Complexity (New)

### Six new metrics

| Metric | Tool | Weight | Threshold |
|--------|------|--------|-----------|
| **Average Cyclomatic Complexity (Avg CC)** | gocyclo | 20% | CC ≤ 10 full score |
| **Peak Cyclomatic Complexity (Peak CC)** | gocyclo | 15% | CC ≤ 20 full score |
| **Cognitive Complexity (Cognitive CC)** | gocognit | 15% | ≤ 15 full score |
| **Code size (SLOC)** | scc | 20% | ≤ 800 full score |
| **Function length distribution** | scc + parse | 15% | avg ≤ 50 full score |
| **Maintainability Index (MI)** | Halstead formula | 15% | MI ≥ 65 full score |

### Score fusion

```
D3_ScaleComplexity = Avg_CC(20%) + Peak_CC(15%) + Cognitive_CC(15%) 
                   + SLOC(20%) + FuncLength(15%) + MI(15%)

D3_Final = D3_Base(60%) + D3_ScaleComplexity(40%)
```

---

## Tool Support

### Integrated

- **gocyclo** - cyclomatic complexity collection
- **golangci-lint** - code style & checks
- **go test** - test coverage
- **gosec** - security issue scanning (invoked independently, covers the full rule set)
- **gocognit** - cognitive complexity (new)
- **scc** - code size statistics (new)

> Note: gosec is invoked independently rather than relying on the gosec linter bundled in golangci-lint,
> because golangci-lint does not enable gosec by default, and independent invocation avoids issue truncation/version lag.

### Installation

```bash
# macOS
brew install gocyclo golangci-lint scc
go install github.com/uudashr/gocognit/cmd/gocognit@latest
go install github.com/securego/gosec/v2/cmd/gosec@latest

# Linux
sudo apt-get install golangci-lint
go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
go install github.com/uudashr/gocognit/cmd/gocognit@latest
go install github.com/securego/gosec/v2/cmd/gosec@latest
go install github.com/boyter/scc/v3@latest
```

---

## Key Thresholds Overview

| Dimension | Excellent | Fair | Poor | Red line |
|-----------|-----------|------|------|----------|
| D1 error handling | no missed | a few missed | bare catch | ✗ |
| D2 security | no hardcoded | low-severity CVE | hardcoded secrets | ✗ (red line) |
| D3 cyclomatic complexity | CC 1-10 | CC 11-20 | CC >20 | ✗ CC >50 (red line) |
| D3 cognitive complexity | ≤15 | 16-25 | >25 | ✗ Avg CC >25 (red line) |
| D3 SLOC | ≤800 | 800-2000 | >2000 | ✗ >2000 (red line) |
| D3 MI index | ≥65 | 50-64 | <50 | - |
| D4 coverage | ≥80% | 60-79% | <60% | - |
| D6 time complexity | O(n log n) | O(n²) | O(2ⁿ) | ✗ (red line) |

---

## Veto Red Lines

Hitting any of the following → direct **F** grade (regardless of total score):

1. ✗ Hardcoded secret / Token
2. ✗ SQL injection / privilege escalation vulnerability
3. ✗ Known high-severity CVE dependency
4. ✗ Widespread fake tests
5. ✗ Silently swallowing errors
6. ✗ Compilation failure
7. ✗ Single-function CC > 50
8. ✗ Average CC > 25
9. ✗ Single-file SLOC > 2000

---

## Output Format

```json
{
  "project": "/path/to/project",
  "timestamp": "2026-06-26T11:30:00.000000",
  "version": "1.1.0",
  "dimensions": {
    "D1_correctness": 85,
    "D2_security": 90,
    "D3_maintainability_scale_complexity": 78,
    "D3_base": 82,
    "D3_scale_complexity": 68,
    "D4_testing": 75,
    "D5_architecture": 80,
    "D6_performance": 75
  },
  "overall_score": 80,
  "rating": "B",
  "metrics": {
    "avg_cc": 8.5,
    "peak_cc": 22,
    "cognitive_cc": 10.2,
    "sloc": 1200,
    "test_coverage": 75.5,
    "mi": 68
  },
  "issues": [...],
  "summary": {
    "total_issues": 12,
    "critical": 0,
    "major": 3,
    "minor": 9
  }
}
```

---

## Upgrade Guide (v1.0 → v1.1)

### Changes

1. **Dimension rename**: D3 Maintainability → **D3 Maintainability & Scale-Complexity**
2. **New sub-model**: 6 new metrics (CC, Cognitive CC, SLOC, MI, Function Length)
3. **Fusion algorithm**: D3_Final = Base(60%) + ScaleComplexity(40%)
4. **New red lines**: 3 scale-complexity-related red lines
5. **Weights unchanged**: the overall six-dimension weight system is unchanged

### Migration strategy

- ✅ Existing reports compatible (D3_base field retained)
- ✅ New D3_Final usually differs from the original D3 by < 5 points
- ✅ Recommended to compare historical data

---

## References

- 📘 `references/D3-maintainability-scale-complexity.md` - detailed metric description
- 📘 `references/D1-correctness.md` - correctness dimension guide
- 📘 `references/D2-security.md` - security dimension guide
- 📘 `references/D4-testing.md` - testing dimension guide
- 📘 `references/D5-architecture.md` - architecture dimension guide
- 📘 `references/D6-performance.md` - performance dimension guide

---

## FAQ

**Q: Why did the D3 score drop?**  
A: v1.1 added scale-complexity metrics, making the quality requirements stricter. We recommend consulting the new document D3-maintainability-scale-complexity for the specific metrics.

**Q: How to quickly improve the D3 score?**  
A: Priority: MI (15%) → SLOC (20%) → Avg CC (20%). See the improvement roadmap in the reference documents.

**Q: Can I use only D3_base (without the new metrics)?**  
A: Yes. Set the weight to 100% D3_base in the invocation. But we recommend fully adopting v1.1.
