# D3 Maintainability & Scale-Complexity Scoring Details

## Overview

The D3 dimension evaluates code **maintainability**; the core concern is "whether the code is easy to understand, modify, and test".

**Version 2.0** (2026-06-26) adds the **scale-complexity** sub-model, supplementing the original complexity metrics with quantitative metrics such as code size and Maintainability Index.

---

## Scoring Structure

```
D3 Final Score = (D3_Base × 60%) + (D3_ScaleComplexity × 40%)
│
├─ D3_Base (60%)
│  ├ Cyclomatic Complexity (CC) ✓ existing
│  ├ Code Style ✓ existing
│  └ Naming Conventions ✓ existing
│
└─ D3_ScaleComplexity (40%) new
   ├ Average Cyclomatic Complexity (Avg CC)     20%
   ├ Peak Cyclomatic Complexity (Peak CC)       15%
   ├ Cognitive Complexity (Cognitive CC)        15%
   ├ Code Size (SLOC)                           20%
   ├ Function Length Distribution               15%
   └ Maintainability Index (MI)                 15%
```

---

## The Six New Metrics in Detail

### 1. Average Cyclomatic Complexity (Avg CC)

**Definition**: the average cyclomatic complexity of functions.

**Tool**: `gocyclo`

**Thresholds**:
| Rating | Avg CC | Score | Description |
|--------|--------|-------|-------------|
| A | ≤ 5 | 100 | excellent, function logic is simple |
| B | 6-10 | 80 | good, acceptable |
| C | 11-15 | 60 | fair, needs attention |
| D | 16-25 | 40 | poor, needs improvement |
| F | > 25 | 0 | very poor, triggers red line |

**Excellent example** (Avg CC = 4):
```go
func Add(a, b int) int {
    return a + b
}

func Divide(a, b int) (int, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}
```

**Poor example** (Avg CC = 18):
```go
func Process(status string, flag bool, value int) string {
    if status == "active" {
        if flag {
            if value > 100 {
                if condition1 {
                    // ...deep nesting
                }
            }
        }
    }
    // ... complex conditional branches
}
```

---

### 2. Peak Cyclomatic Complexity (Peak CC)

**Definition**: the highest cyclomatic complexity of a single function in the project.

**Tool**: `gocyclo`

**Thresholds**:
| Peak CC | Score | Description |
|---------|-------|-------------|
| ≤ 10 | 100 | excellent, highly testable |
| 11-20 | 75 | fair, acceptable |
| 21-50 | 50 | poor, hard to test |
| > 50 | 0 | **red line**, untestable |

**Red-line trigger**:
- Peak CC > 50 → directly flagged as untestable function
- Mandatory refactoring required

---

### 3. Cognitive Complexity (Cognitive CC)

**Definition**: measures complexity from a **human-cognition** perspective, complementary to cyclomatic complexity.

Characteristics:
- Ignores simple nesting (e.g. a `return` right after an `if`)
- Weights nested branches more heavily (deeper nesting = higher cognitive load)
- Aligned with the SonarQube algorithm

**Tool**: `gocognit`

**Thresholds**:
| Cognitive CC | Score | Description |
|--------------|-------|-------------|
| ≤ 10 | 100 | excellent, easy to understand |
| 11-15 | 80 | good |
| 16-25 | 60 | fair |
| 26-35 | 40 | poor |
| > 35 | 20 | very poor, needs refactoring |

**Comparison example** (CC vs Cognitive CC):
```go
// cyclomatic complexity = 5, cognitive complexity = 5 (simple conditions)
if a > 0 {
    b = 1
}
if c > 0 {
    d = 2
}

// ─────────────────────────────────────

// cyclomatic complexity = 4, cognitive complexity = 8 (nesting-weighted)
if a > 0 {
    if b > 0 {
        if c > 0 {
            d = 1
        }
    }
}
```

---

### 4. Code Size (SLOC)

**Definition**: Source Lines of Code, the number of effective code lines excluding comments and blank lines.

**Tool**: `scc` (Sloc Cloc and Code)

**Counting scope**:
- ✓ Effective code lines (including Go package declarations, imports)
- ✗ Comment lines
- ✗ Blank lines
- ✗ Braces alone on their own line

**Thresholds** (single file):
| SLOC | Score | Description |
|------|-------|-------------|
| ≤ 300 | 100 | well modularized, easy to understand |
| 301-800 | 85 | good |
| 801-1500 | 70 | fair, needs attention |
| 1501-2000 | 50 | poor, needs splitting |
| > 2000 | 0 | **red line**, monster file |

**Whole-project size reference**:
| Project size | Recommended SLOC | Typical project example |
|--------------|------------------|--------------------------|
| Small library | < 5K | a single util package |
| Medium service | 10-50K | order microservice |
| Large application | 50-200K | platform-level application |

---

### 5. Function Length Distribution

**Definition**: counts function line counts, focusing on the ratio of abnormally long functions.

**Metrics**:
- Average Function Length
- Ratio of overlong functions (% of functions > 80 lines)

**Thresholds**:
| Avg function length | Score | Overlong-function ratio | Bonus/deduction |
|---------------------|-------|--------------------------|-----------------|
| ≤ 30 | 100 | < 5% | +0 |
| 31-50 | 80 | 5-10% | -5 |
| 51-80 | 60 | 10-20% | -15 |
| 81-150 | 40 | 20-40% | -30 |
| > 150 | 0 | > 40% | -50 |

**Excellent example** (avg 25 lines):
```go
func Validate(email string) bool {
    if email == "" {
        return false
    }
    return strings.Contains(email, "@")
}

func Send(msg string) error {
    return client.Post(msg)
}
```

**Poor example** (avg 120 lines):
```go
func HandleRequest(r *http.Request) {
    // 60 lines of validation
    // 30 lines of business logic
    // 20 lines of error handling
    // 10 lines of cache update
    // all mixed together
}
```

---

### 6. Maintainability Index (MI)

**Definition**: a composite index based on Halstead volume, cyclomatic complexity, and code line count.

**Formula** (Visual Studio derivation):
```
V = (N1+N2)·log₂(n1+n2)  // Halstead volume
    where N1 = total number of operators
          N2 = total number of operands
          n1 = number of unique operators
          n2 = number of unique operands

MI = MAX(0, (171 − 5.2·ln(V) − 0.23·CC − 16.2·ln(LOC)) × 100 / 171)
    where CC = cyclomatic complexity
          LOC = code line count
```

**Thresholds**:
| MI value | Rating | Score | Description |
|----------|--------|-------|-------------|
| 85-100 | ⭐⭐⭐ high | 100 | easy to maintain |
| 65-84 | ⭐⭐ medium | 85 | normal |
| 50-64 | ⭐ low | 60 | has risks |
| 25-49 | very low | 30 | hard to maintain |
| < 25 | unmaintainable | 0 | **red zone** |

**Meaning**:
- **MI ≥ 65**: code quality is good; even newcomers can understand it
- **MI 50-64**: code requires some experience to modify; risky
- **MI < 50**: code is high-risk; modifications easily introduce bugs

---

## Red-Line Rules

### New D3 red lines

1. **Single-function CC > 50**
   - Symptom: the function cannot be fully covered by unit tests
   - Action: force splitting

2. **Average CC > 25**
   - Symptom: overall code structure is chaotic
   - Action: architecture re-review

3. **Single-file SLOC > 2000**
   - Symptom: monster file, extremely high maintenance cost
   - Action: split into multiple files/packages

4. **Files with MI < 10 exceed 10%**
   - Symptom: large amounts of unmaintainable code
   - Action: refactor immediately

---

## Scoring Examples

### Case 1: excellent code (D3 = 88)

```
D3_Base = 90
  - Avg CC = 8 → 85 points
  - Style = 95 points
  - Naming = 90 points
  - Base weighted = (85+95+90) / 3 ≈ 90 points

D3_ScaleComplexity = 85
  - Avg CC = 8 → 85
  - Peak CC = 18 → 75
  - Cognitive CC = 12 → 80
  - SLOC = 500 → 90
  - Function length = avg 35 lines → 85
  - MI = 72 → 85
  - Weighted = 85 points

Final D3 = 90×0.6 + 85×0.4 = 54 + 34 = 88
```

### Case 2: fair code (D3 = 65)

```
D3_Base = 70
  - Avg CC = 15 → 60 points
  - Style = 75 points
  - Naming = 75 points
  - Base weighted ≈ 70 points

D3_ScaleComplexity = 60
  - Avg CC = 15 → 60
  - Peak CC = 28 → 65
  - Cognitive CC = 22 → 65
  - SLOC = 1200 → 70
  - Function length = avg 60 lines → 65
  - MI = 55 → 60
  - Weighted = 64 points

Final D3 = 70×0.6 + 60×0.4 = 42 + 24 = 66
```

---

## Review Checklist

- [ ] Most complex function CC < 20
- [ ] Average CC < 10
- [ ] Cognitive complexity < 15
- [ ] All functions < 100 lines
- [ ] Average function < 50 lines
- [ ] Single file < 800 lines
- [ ] No single file > 2000 lines
- [ ] More than 90% of files have MI > 65
- [ ] Naming is clear, understandable at a glance
- [ ] Comments cover complex logic

---

## Improvement Roadmap

### Quick improvements (1-2 days)
1. Use IDE refactoring tools to split overlong functions
2. Extract duplicated conditional logic
3. Optimize if-else nesting

### Mid-term improvements (1-2 weeks)
1. Introduce the strategy pattern to reduce CC
2. Apply guard clauses to simplify flows
3. Split monster files

### Long-term improvements (ongoing)
1. Focus on complexity during Code Review
2. Establish a CI/CD quality gate (D3 ≥ 75)
3. Run analysis tools regularly and track trends

---

## Tool Command Reference

```bash
# View cyclomatic complexity
gocyclo -top 10 ./...

# Cognitive complexity
gocognit -top 10 ./...

# Size statistics
scc -l go ./...

# Code line count statistics
scc --by-file ./...

# MI calculation (Python script)
python3 calculate-mi.py ./...
```

---

**Reference standards**:
- ISO/IEC 25010:2023 (quality model)
- ISO/IEC 5055 CISQ (complexity measurement)
- SonarQube cognitive complexity standard
- Visual Studio Maintainability Index

**Updated**: 2026-06-26
