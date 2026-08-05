# go-quality-scorer Skill

**Go 代码质量评分器 - 六维度评分框架 + D3 规模复杂度扩展**

## 概述

`go-quality-scorer` 是一个用于 Go 项目代码质量评估的 Skill，基于 **ISO/IEC 25010** 和 **ISO/IEC 5055 CISQ** 标准，提供六维度的量化评分：

| 维度 | 权重 | 说明 |
|------|------|------|
| **D1** | 25% | 正确性与可靠性 |
| **D2** | 20% | 安全性 |
| **D3** | 20% | 可维护性·规模复杂度 ⭐ (v1.1 新增) |
| **D4** | 15% | 测试有效性 |
| **D5** | 12% | 架构与设计 |
| **D6** | 8% | 性能效率 |

---

## 快速开始

### 1. 安装工具链

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

### 2. 运行评分器

```bash
# 全量扫描（默认）：评估项目所有生产 .go 文件
python3 scripts/go-quality-scorer-v1.1.py /path/to/your/go/project

# 增量扫描：仅评估本次提交（HEAD~1..HEAD）改动的 .go 文件
python3 scripts/go-quality-scorer-v1.1.py /path/to/your/go/project --mode diff

# 指定输出报告路径
python3 scripts/go-quality-scorer-v1.1.py /path/to/your/go/project report.json --mode diff
```

**两种模式**：

| 模式 | 范围 | 覆盖率 | 适用场景 |
|------|------|--------|----------|
| `full`（默认） | 全项目生产 .go 文件 | 跑 `go test`/`pytest` 采集真实覆盖率 | 周期性全量体检、基线建立 |
| `diff` | 本次提交（HEAD~1..HEAD）改动的 .go 文件 | 跳过（D4 按中性 50% 计分） | MR/PR 增量检查、CI 门禁 |

### 3. 查看报告

```bash
# 查看 JSON 报告
cat go-quality-report-v1.1.json | jq

# 核心指标
jq '.dimensions, .overall_score, .rating' go-quality-report-v1.1.json
```

### 4. 扫描范围说明（测试/mock 代码默认排除）

质量评分只针对**生产代码**，下列文件/目录自动从扫描中剔除：

- Go 测试文件：`*_test.go`
- mock/fake/stub 生成代码（文件名或父目录命中关键词）
- 测试数据目录：`testdata/`、`fixtures/`
- 依赖与构建产物：`vendor/`、`node_modules/`、`.git/`、`dist/`、`build/` 等

测试覆盖率（D4）仍会正常执行 `go test` / `pytest`——排除的是"被评分的代码"，不是"参与测试运行的代码"。

---

## 文件结构

```
go-quality-scorer-skill/
├── SKILL.md                          # Skill 主文档
├── README.md                         # 本文件
├── LICENSE                           # MIT 许可
├── scripts/
│   ├── go-quality-scorer-v1.1.py    # 主评分器（融合所有维度）
│   ├── collect-metrics.go           # Phase 1 指标采集（Go）
│   └── calculate-d3-score.py        # Phase 2 D3 评分计算（Python）
├── references/
│   ├── D3-可维护性·规模复杂度.md    # D3 详细指标指南
│   ├── D1-correctness.md            # D1 正确性维度指南
│   ├── D2-security.md               # D2 安全性维度指南
│   ├── D4-testing.md                # D4 测试维度指南
│   ├── D5-architecture.md           # D5 架构维度指南
│   └── D6-performance.md            # D6 性能维度指南
├── assets/
│   └── example-report-v1.1.json     # 示例报告
└── examples/
    ├── example-excellent.md         # 优秀代码案例
    ├── example-poor.md              # 问题代码案例
    └── migration-guide.md           # v1.0 → v1.1 迁移指南
```

---

## D3 规模复杂度维度（v1.1 新增）

### 核心指标

v1.1 版本对 D3 可维护性维度进行了扩展，新增 6 个精细化指标：

1. **平均圈复杂度（Avg CC）** - 所有函数 CC 均值  
   - 优秀：≤5 | 良好：≤10 | 一般：≤15 | 差：>15

2. **峰值圈复杂度（Peak CC）** - 单函数最大 CC  
   - 优秀：≤10 | 良好：≤20 | 一般：≤30 | 差：>30

3. **认知复杂度（Cognitive CC）** - 嵌套加权复杂度  
   - 优秀：≤10 | 良好：≤15 | 一般：≤25 | 差：>25

4. **代码规模（SLOC）** - 源代码行数（剔除注释/空行）  
   - 优秀：≤400 | 良好：≤800 | 一般：≤1500 | 差：>1500

5. **函数长度分布** - 平均函数行数 + 长函数比例  
   - 优秀：平均 ≤50 行 | 良好：≤70 | 一般：≤100 | 差：>100

6. **可维护性指数（MI）** - 综合可维护性量化指标  
   - 优秀：≥65 | 良好：≥50 | 一般：≥40 | 差：<40

### 评分融合

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

## 输出报告格式

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

## 一票否决红线

以下任何一项违反都会导致最终评级为 **F**（失败），无论综合得分如何：

1. ✗ 硬编码密钥、Token 或其他凭据
2. ✗ SQL 注入、权限绕过等安全漏洞
3. ✗ 已知高危 CVE 依赖
4. ✗ 大面积假测试（仅 true/false 没有实际断言）
5. ✗ 大量静默吞错（`_ = err`）
6. ✗ 代码无法编译
7. ✗ **[新增]** 单函数圈复杂度 > 50
8. ✗ **[新增]** 平均圈复杂度 > 25
9. ✗ **[新增]** 单文件代码行数 > 2000

---

## 升级指南（v1.0 → v1.1）

### 主要变化

| 项目 | v1.0 | v1.1 |
|------|------|------|
| 维度数 | 6 维 | 6 维（D3 扩展） |
| D3 指标数 | 2 (CC + 风格) | 8 (6 新 + 2 原) |
| 评分权重 | - | D3_Base(60%) + ScaleComplexity(40%) |
| 新工具 | - | gocognit, scc |
| 新红线 | 6 条 | +3 条 |

### 兼容性

- ✅ 原有 D1-D2, D4-D6 维度评分算法**不变**
- ✅ 原有报告的 `dimensions` 字段**保留** `D3_base`
- ✅ 新增 `D3_scale_complexity` 字段，最终 D3 得分存于 `D3`
- ✅ 历史报告可通过 `D3_base` 和 `D3_final` 对比分析

### 数据迁移

```bash
# 对比分析：旧分数 vs 新分数
jq '{
  old: .dimensions.D3_base,
  new: .dimensions.D3_maintainability_scale_complexity,
  diff: (.dimensions.D3_maintainability_scale_complexity - .dimensions.D3_base)
}' go-quality-report-v1.1.json
```

---

## 改进路线

### 快速提升（1-2 周）

1. **降低平均 CC** - 拆分复杂函数（目标：≤10）
2. **减少长函数** - 函数复用和提取（目标：平均 ≤50 行）
3. **增加测试覆盖率** - 补充关键路径测试（目标：≥80%）

### 中期优化（1-2 月）

4. **提升 MI 指数** - 优化代码结构和注释（目标：≥65）
5. **降低 SLOC** - 代码模块化和库复用（目标：≤800 per file）
6. **认知复杂度治理** - 简化嵌套和条件分支（目标：≤15）

### 长期架构（3-6 月）

7. **架构优化** - 分层、解耦、设计模式（D5）
8. **性能优化** - 算法、并发、资源管理（D6）
9. **安全强化** - 依赖管理、权限模型、加密（D2）

---

## 常见问题

**Q1: 为什么 D3 评分下降了？**

A: v1.1 新增了 6 个维度更多的指标，对代码质量要求更严格。这是正常的。建议对照参考文献逐一改进。

**Q2: 如何解释 D3_base vs D3_scale_complexity？**

A: `D3_base` 是原有圈复杂度和风格评分，`D3_scale_complexity` 是新增的 6 个指标融合分，最终 D3 = Base(60%) + ScaleComplexity(40%)。

**Q3: 能否调整权重比例？**

A: 建议联系团队。默认配置 (60%/40%) 基于最佳实践。如需自定义，可修改 `go-quality-scorer-v1.1.py` 中的权重参数。

**Q4: 如何在 CI/CD 中集成？**

A: 
```yaml
# GitHub Actions 示例
- name: Go Quality Check
  run: python3 scripts/go-quality-scorer-v1.1.py . go-quality-report.json
  
- name: Check Rating
  run: |
    rating=$(jq -r '.rating' go-quality-report.json)
    if [ "$rating" = "F" ]; then exit 1; fi
```

---

## 参考标准

- 📖 [ISO/IEC 25010](https://iso.org/standard/35733.html) - 软件产品质量
- 📖 [ISO/IEC 5055 CISQ](https://www.omg.org/cgi-bin/doc?omg/20150401-1) - 代码可维护性
- 📖 [NIST Software Assurance](https://www.nist.gov/) - 软件保证

---

## 许可证

MIT License - 详见 LICENSE 文件

---

## 版本历史

| 版本 | 日期 | 变化 |
|------|------|------|
| 1.1.0 | 2026-06-26 | ✨ D3 规模复杂度扩展；新增 3 条红线；集成 gocognit + scc |
| 1.0.0 | 2026-06-25 | 🎉 初始发布；六维评分框架 |

---

**维护者**: go-quality-scorer 团队  
**贡献指南**: 欢迎提交 Issue 和 PR  
**联系方式**: [team@example.com]
