# go-quality-scorer Skill

**Go code quality scorer - six-dimension scoring framework + D3 scale-complexity extension**

## Overview

`go-quality-scorer` is a Skill for evaluating the code quality of Go projects. Based on **ISO/IEC 25010** and **ISO/IEC 5055 CISQ** standards, it provides quantitative scoring across six dimensions:

| Dimension | Weight | Description |
|-----------|--------|-------------|
| **D1** | 25% | Correctness & Reliability |
| **D2** | 20% | Security |
| **D3** | 20% | Maintainability & Scale-Complexity ⭐ (new in v1.1) |
| **D4** | 15% | Testing Effectiveness |
| **D5** | 12% | Architecture & Design |
| **D6** | 8% | Performance Efficiency |

---

## Quick Start

### 1. Install the toolchain

```bash
# macOS
brew install gocyclo golangci-lint scc
go install github.com/uudashr/gocognit/cmd/gocognit@latest
go install github.com/securego/gosec/v2/cmd/gosec@latest

# Ubuntu/Debian
sudo apt-get install golangci-lint
go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
go install github.com/uudashr/gocognit/cmd/gocognit@latest
go install github.com/securego/gosec/v2/cmd/gosec@latest
go install github.com/boyter/scc/v3@latest
```

### 2. Run the scorer

```bash
# Full scan (default): evaluate all production .go files in the project
python3 scripts/go-quality-scorer-v1.1.py /path/to/your/go/project

# Incremental scan: only evaluate .go files changed in this commit (HEAD~1..HEAD)
python3 scripts/go-quality-scorer-v1.1.py /path/to/your/go/project --mode diff

# Specify the output report path
python3 scripts/go-quality-scorer-v1.1.py /path/to/your/go/project report.json --mode diff
```

**Two modes**:

| Mode | Scope | Coverage | Use case |
|------|-------|----------|----------|
| `full` (default) | all production .go files in the project | runs `go test`/`pytest` to collect real coverage | periodic full inspection, baseline establishment |
| `diff` | .go files changed in this commit (HEAD~1..HEAD) | skipped (D4 scored at a neutral 50%) | MR/PR incremental check, CI gate |

### 3. View the report

```bash
# View the JSON report
cat go-quality-report-v1.1.json | jq

# Core metrics
jq '.dimensions, .overall_score, .rating' go-quality-report-v1.1.json
```

### 4. Scan scope (test/mock code excluded by default)

Quality scoring only targets **production code**; the following files/directories are automatically excluded from scanning:

- Go test files: `*_test.go`
- mock/fake/stub generated code (filename or parent dir matches keywords)
- Test data dirs: `testdata/`, `fixtures/`
- Dependencies and build artifacts: `vendor/`, `node_modules/`, `.git/`, `dist/`, `build/`, etc.

Test coverage (D4) still runs `go test` / `pytest` normally — what is excluded is "the code being scored", not "the code participating in test runs".

---

## File Structure

```
go-quality-scorer-skill/
├── SKILL.md                          # main Skill document
├── README.md                         # this file
├── LICENSE                           # MIT license
├── scripts/
│   ├── go-quality-scorer-v1.1.py    # main scorer (fuses all dimensions)
│   ├── collect-metrics.go           # Phase 1 metric collection (Go)
│   └── calculate-d3-score.py        # Phase 2 D3 score calculation (Python)
├── references/
│   ├── D3-maintainability-scale-complexity.md    # D3 detailed metric guide
│   ├── D1-correctness.md            # D1 correctness dimension guide
│   ├── D2-security.md               # D2 security dimension guide
│   ├── D4-testing.md                # D4 testing dimension guide
│   ├── D5-architecture.md           # D5 architecture dimension guide
│   └── D6-performance.md            # D6 performance dimension guide
├── assets/
│   └── example-report-v1.1.json     # example report
└── examples/
    ├── example-excellent.md         # excellent code example
    ├── example-poor.md              # problematic code example
    └── migration-guide.md           # v1.0 → v1.1 migration guide
```

---

## D3 Scale-Complexity Dimension (new in v1.1)

### Core metrics

v1.1 extends the D3 maintainability dimension with 6 refined metrics:

1. **Average Cyclomatic Complexity (Avg CC)** - mean CC across all functions  
   - Excellent: ≤5 | Good: ≤10 | Fair: ≤15 | Poor: >15

2. **Peak Cyclomatic Complexity (Peak CC)** - max CC of a single function  
   - Excellent: ≤10 | Good: ≤20 | Fair: ≤30 | Poor: >30

3. **Cognitive Complexity (Cognitive CC)** - nesting-weighted complexity  
   - Excellent: ≤10 | Good: ≤15 | Fair: ≤25 | Poor: >25

4. **Code Size (SLOC)** - source lines of code (excluding comments/blank lines)  
   - Excellent: ≤400 | Good: ≤800 | Fair: ≤1500 | Poor: >1500

5. **Function Length Distribution** - average function lines + long-function ratio  
   - Excellent: avg ≤50 lines | Good: ≤70 | Fair: ≤100 | Poor: >100

6. **Maintainability Index (MI)** - comprehensive maintainability metric  
   - Excellent: ≥65 | Good: ≥50 | Fair: ≥40 | Poor: <40

### Score fusion

```
D3_ScaleComplexity = 
  Avg_CC_Score(20%) + 
  Peak_CC_Score(15%) + 
  Cognitive_CC_Score(15%) + 
  SLOC_Score(20%) + 
  Function_Length_Score(15%) + 
  MI_Score(15%)

D3_Final = D3_Base(60%) + D3_ScaleComplexity(40%)
```

---

## Output Report Format

```json
{
  "project": "/path/to/project",
  "timestamp": "2026-06-26T11:30:00",
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
  "overall_score": 80.5,
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

## Veto Red Lines

Any of the following violations results in a final rating of **F** (fail), regardless of the overall score:

1. ✗ Hardcoded secrets, Tokens, or other credentials
2. ✗ Security vulnerabilities such as SQL injection, privilege escalation
3. ✗ Known high-severity CVE dependencies
4. ✗ Widespread fake tests (only true/false without real assertions)
5. ✗ Lots of silently swallowed errors (`_ = err`)
6. ✗ Code that does not compile
7. ✗ **[New]** Single-function cyclomatic complexity > 50
8. ✗ **[New]** Average cyclomatic complexity > 25
9. ✗ **[New]** Single-file line count > 2000

---

## Upgrade Guide (v1.0 → v1.1)

### Main changes

| Item | v1.0 | v1.1 |
|------|------|------|
| Dimension count | 6 | 6 (D3 extended) |
| D3 metric count | 2 (CC + style) | 8 (6 new + 2 original) |
| Scoring weights | - | D3_Base(60%) + ScaleComplexity(40%) |
| New tools | - | gocognit, scc |
| New red lines | 6 | +3 |

### Compatibility

- ✅ Original D1-D2, D4-D6 dimension scoring algorithms **unchanged**
- ✅ The `dimensions` field of existing reports **retains** `D3_base`
- ✅ New `D3_scale_complexity` field added; the final D3 score is stored in `D3`
- ✅ Historical reports can be compared via `D3_base` and `D3_final`

### Data migration

```bash
# Comparative analysis: old score vs new score
jq '{
  old: .dimensions.D3_base,
  new: .dimensions.D3_maintainability_scale_complexity,
  diff: (.dimensions.D3_maintainability_scale_complexity - .dimensions.D3_base)
}' go-quality-report-v1.1.json
```

---

## Improvement Roadmap

### Quick wins (1-2 weeks)

1. **Reduce average CC** - split complex functions (target: ≤10)
2. **Reduce long functions** - function reuse and extraction (target: avg ≤50 lines)
3. **Increase test coverage** - add critical-path tests (target: ≥80%)

### Mid-term optimization (1-2 months)

4. **Improve the MI index** - optimize code structure and comments (target: ≥65)
5. **Reduce SLOC** - code modularization and library reuse (target: ≤800 per file)
6. **Cognitive complexity governance** - simplify nesting and conditional branches (target: ≤15)

### Long-term architecture (3-6 months)

7. **Architecture optimization** - layering, decoupling, design patterns (D5)
8. **Performance optimization** - algorithms, concurrency, resource management (D6)
9. **Security hardening** - dependency management, permission models, encryption (D2)

---

## FAQ

**Q1: Why did the D3 score drop?**

A: v1.1 added 6 more metrics, making the quality requirements stricter. This is expected. We recommend improving against the reference documents one by one.

**Q2: How do I interpret D3_base vs D3_scale_complexity?**

A: `D3_base` is the original cyclomatic complexity and style score; `D3_scale_complexity` is the fused score of the 6 new metrics; the final D3 = Base(60%) + ScaleComplexity(40%).

**Q3: Can the weight ratio be adjusted?**

A: We recommend contacting the team. The default configuration (60%/40%) is based on best practices. For custom weights, you can modify the weight parameters in `go-quality-scorer-v1.1.py`.

**Q4: How do I integrate with CI/CD?**

A: 
```yaml
# GitHub Actions example
- name: Go Quality Check
  run: python3 scripts/go-quality-scorer-v1.1.py . go-quality-report.json
  
- name: Check Rating
  run: |
    rating=$(jq -r '.rating' go-quality-report.json)
    if [ "$rating" = "F" ]; then exit 1; fi
```

---

## Reference Standards

- 📖 [ISO/IEC 25010](https://iso.org/standard/35733.html) - software product quality
- 📖 [ISO/IEC 5055 CISQ](https://www.omg.org/cgi-bin/doc?omg/20150401-1) - code maintainability
- 📖 [NIST Software Assurance](https://www.nist.gov/) - software assurance

---

## License

MIT License - see the LICENSE file

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.1.0 | 2026-06-26 | ✨ D3 scale-complexity extension; 3 new red lines; integrated gocognit + scc |
| 1.0.0 | 2026-06-25 | 🎉 Initial release; six-dimension scoring framework |

---

**Maintainers**: go-quality-scorer team  
**Contributing**: Issues and PRs are welcome  
**Contact**: [team@example.com]
