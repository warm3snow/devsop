# v1.0 → v1.1 Migration Guide

## Overview

go-quality-scorer v1.1 significantly extends the D3 maintainability dimension by introducing 6 new size and complexity metrics. This guide helps users migrate smoothly.

---

## Main Changes

### 1. Dimension name update

```
v1.0  → v1.1
"D3 Maintainability"  →  "D3 Maintainability & Scale-Complexity"
```

### 2. New D3 sub-metrics

| No. | New metric | Tool | Weight | Description |
|-----|------------|------|--------|-------------|
| 1 | Average cyclomatic complexity | gocyclo | 20% | mean function CC |
| 2 | Peak cyclomatic complexity | gocyclo | 15% | max CC of a single function |
| 3 | Cognitive complexity | gocognit | 15% | nesting-weighted |
| 4 | Code size | scc | 20% | source lines of code |
| 5 | Function length distribution | scc + parse | 15% | average function lines |
| 6 | Maintainability Index | Halstead formula | 15% | MI composite metric |

### 3. Score fusion logic

**v1.0** (simple):
```
D3 = gocyclo_score + style_score
```

**v1.1** (fused):
```
D3_ScaleComplexity = Weighted_Average(6 new metrics)
D3_Final = D3_Base(60%) + D3_ScaleComplexity(40%)
```

### 4. New red lines

| No. | Red-line condition | Consequence |
|-----|--------------------|-------------|
| 7 | Single-function CC > 50 | Rating F (fail) |
| 8 | Average CC > 25 | Rating F (fail) |
| 9 | Single-file SLOC > 2000 | Rating F (fail) |

---

## Compatibility Guarantees

### ✅ Unchanged parts

1. **D1-D2, D4-D6 dimensions** - scoring algorithms are exactly the same
2. **Overall scoring weights** - six-dimension weights unchanged (D1 25%, D2 20%, etc.)
3. **Output format base** - JSON structure is backward compatible
4. **CLI interface** - command-line arguments are the same

### ⚠️ Changed parts

1. **D3 field** - `D3` is now the fused score (not the raw score)
2. **New fields** - `D3_base` and `D3_scale_complexity` added
3. **Tool dependencies** - `gocognit` and `scc` must be installed additionally
4. **Score distribution** - D3 average may drop by 3-8 points (stricter)

---

## Migration Steps

### Step 1: Update the toolchain

```bash
# Install the new tools
brew install gocognit scc

# or via Go
go install github.com/uudashr/gocognit/cmd/gocognit@latest
go install github.com/boyter/scc/v3@latest

# Verify installation
gocognit --version
scc --version
```

### Step 2: Update the scoring script

```bash
# Replace the old script
cp scripts/go-quality-scorer-v1.1.py /path/to/your/installation/

# or update the version number in CI/CD
# from: go-quality-scorer v1.0
# to:   go-quality-scorer v1.1.0
```

### Step 3: Run the new scorer

```bash
# Old command (still valid)
python3 go-quality-scorer.py /path/to/project

# New command (recommended)
python3 scripts/go-quality-scorer-v1.1.py /path/to/project -o report-v1.1.json
```

### Step 4: Analyze the comparison

```bash
# View the old vs new D3 score difference
jq '{
  old_d3: .dimensions.D3_base,
  new_d3: .dimensions.D3_maintainability_scale_complexity,
  diff: (.dimensions.D3_maintainability_scale_complexity - .dimensions.D3_base)
}' report-v1.1.json

# Analyze specific metrics
jq '.metrics | {avg_cc, peak_cc, cognitive_cc, sloc, mi}' report-v1.1.json
```

---

## Data Migration

### Historical report comparison

```bash
# Script: compare v1.0 and v1.1 reports
cat > compare.jq << 'EOF'
{
  timestamp: .timestamp,
  version: .version,
  dimensions: {
    D1: .dimensions.D1_correctness,
    D2: .dimensions.D2_security,
    D3_base: .dimensions.D3_base,
    D3_new: .dimensions.D3_maintainability_scale_complexity,
    D3_delta: (.dimensions.D3_maintainability_scale_complexity - .dimensions.D3_base),
    D4: .dimensions.D4_testing,
    D5: .dimensions.D5_architecture,
    D6: .dimensions.D6_performance
  },
  overall_score: .overall_score,
  rating: .rating
}
EOF

jq -f compare.jq report-v1.1.json > comparison.json
```

### Batch conversion

```bash
# Batch-score all old reports
for project_dir in /path/to/projects/*; do
  echo "Evaluating $project_dir..."
  python3 scripts/go-quality-scorer-v1.1.py "$project_dir" \
    "reports/$(basename $project_dir)-v1.1.json"
done
```

---

## Common Migration Questions

### Q1: D3 score dropped by 5-10 points; is that normal?

**A**: Yes, this is normal. v1.1 added 6 stricter metrics. Recommended:
1. Check the specific difference between `D3_base` and `D3_scale_complexity`
2. Improve one by one against the reference document D3-maintainability-scale-complexity
3. Expect recovery to near the original level within 2-4 weeks

### Q2: Some projects lack tool output; what should I do?

**A**: Check the dependency tools:
```bash
# Check that all tools are in place
which gocyclo gocognit scc golangci-lint gosec

# Install any that are missing
go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
go install github.com/uudashr/gocognit/cmd/gocognit@latest
go install github.com/securego/gosec/v2/cmd/gosec@latest
go install github.com/boyter/scc/v3@latest
```

### Q3: What happens if the old script is used in CI/CD?

**A**: The old script does not recognize the new dimensions, which results in:
- Missing new D3 metric data
- No new red-line checks
- Incomplete output format

We recommend syncing the CI/CD environment to v1.1.0.

### Q4: Can I keep the original D3 score while adding the scale metrics?

**A**: Yes, by modifying the script weights:

```python
# Modify in go-quality-scorer-v1.1.py
# D3_Final = D3_Base(60%) + D3_ScaleComplexity(40%)
# change to
D3_Final = D3_Base(100%) + D3_ScaleComplexity(0%)  # 100% original score
# or
D3_Final = D3_Base(80%) + D3_ScaleComplexity(20%)  # 80% original, 20% new metrics
```

But it is not recommended. We recommend using the default 60%/40% fusion ratio.

---

## Performance Impact

| Operation | v1.0 | v1.1 | Difference |
|-----------|------|------|------------|
| Single project scoring | ~3-5s | ~5-8s | +2-3s (new tool collection) |
| Batch scoring 100 projects | ~5min | ~8-10min | +3-5min |
| Memory usage | ~50MB | ~80MB | +30MB |
| Disk usage (reports) | ~100KB | ~150KB | +50KB |

**Recommendation**: increase the timeout setting by +10s in CI/CD.

---

## Rollback Plan

If you need to return to v1.0:

```bash
# 1. Back up the new report
cp go-quality-report-v1.1.json go-quality-report-v1.1.backup.json

# 2. Restore the old scorer
cp /backup/go-quality-scorer-v1.0.py scripts/go-quality-scorer.py

# 3. Uninstall the new tools (optional)
brew uninstall gocognit scc

# 4. Run the old version
python3 scripts/go-quality-scorer.py /path/to/project
```

---

## Support & Feedback

- 📖 See SKILL.md and the reference documents
- 🐛 Found a problem? Submit an Issue
- 💡 Have an improvement suggestion? Submit a PR

---

**Updated**: 2026-06-26  
**Version**: v1.1.0
