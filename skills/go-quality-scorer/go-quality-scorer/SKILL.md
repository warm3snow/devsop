# go-quality-scorer v1.1 Skill

> Go 代码质量评分器 - 六维度评分框架 + D3 规模复杂度扩展

**版本**: 1.1.0 | **更新时间**: 2026-06-26 | **状态**: ✅ 生产就绪

---

## 快速开始

```bash
# 1. 安装依赖工具（macOS 示例；完整安装见下方「安装」小节）
brew install gocyclo golangci-lint scc
go install github.com/uudashr/gocognit/cmd/gocognit@latest
go install github.com/securego/gosec/v2/cmd/gosec@latest

# 2. 运行评分器
python3 scripts/go-quality-scorer-v1.1.py /path/to/go/project

# 3. 查看报告
cat go-quality-report-v1.1.json
```

### 扫描范围（测试/mock 代码默认排除）

质量扫描只评估**生产代码**，下列文件/目录默认从所有维度（D1~D6）的指标采集与静态分析中剔除：

| 类别 | 命中规则 | 示例 |
|------|----------|------|
| Go 测试文件 | 文件名以 `_test.go` 结尾 | `foo_test.go` |
| mock 生成代码 | 文件名或父目录含 `mock` / `fake` / `stub` | `mock_client.go`、`mock/` |
| 测试数据目录 | 路径含 `testdata` / `fixtures` | `pkg/testdata/` |
| 依赖/构建/VCS | `vendor/` / `node_modules/` / `.git/` / `dist/` / `build/` 等 | — |

排除规则统一由 `go-quality-scorer-v1.1.py` 的 `_is_test_or_mock_file` 与 `collect-metrics.go` 的 `isTestOrMockPath` 实现，所有外部工具（gofmt / golangci-lint / gosec / gocyclo / gocognit / scc）均传入过滤后的文件列表，并对工具输出做二次过滤以防漏网。

> 注：测试覆盖率采集（D4）仍会执行 `go test` / `pytest`，这一步本身依赖测试文件，不受上述排除规则影响——排除的是「被评分的代码」，不是「参与测试运行的代码」。

---

## 执行流程与降级策略

### 语言识别与执行路径

先检测项目主语言（脚本 `_detect_language` 自动完成）：
- **Go**：有 `go.mod` 或 `.go` 文件 → 走 `_scan_coverage_go`
- **Python**：有 `pyproject.toml`/`setup.py`/`setup.cfg`/`requirements.txt` 或 `.py` 文件 → 走 `_scan_coverage_python`
- **其他**：降级到 LLM 估算

Go 与 Python **都走脚本路径**，不要因非 Go 直接降级。脚本 `go-quality-scorer-v1.1.py .` 已支持双语言覆盖率采集。

### 首选：脚本执行

```bash
# 全量扫描（默认）：评估项目所有生产 .go 文件
python3 scripts/go-quality-scorer-v1.1.py <project>

# 增量扫描：仅评估本次提交（HEAD~1..HEAD）改动的 .go 文件
python3 scripts/go-quality-scorer-v1.1.py <project> --mode diff

# 指定输出报告路径
python3 scripts/go-quality-scorer-v1.1.py <project> go-quality-report.json --mode diff
```

脚本采集真实指标，生成 `go-quality-report-v1.1.json`。

**扫描模式**：
- `--mode full`（默认）：全量扫描所有生产 .go 文件，跑 `go test` / `pytest` 采集真实覆盖率。大项目耗时较长（go test 编译+插桩是大头）。
- `--mode diff`：仅扫描本次提交（`HEAD~1..HEAD`）改动的 .go 生产文件，**跳过覆盖率采集**（`go test` 无法按文件切片，跑全量与增量语义冲突）。D4 按中性 50% 计分，报告标注 `"coverage_note": "增量模式未采集..."`。适合 MR/PR 增量检查、CI 门禁。

**Go 项目**：gocyclo / gocognit / golangci-lint / gosec / scc / go 通常已预装在 PATH，直接调用即可。仅当 `command -v <tool>` 确认缺失时才安装，禁止重复 go install。

**Python 项目**：clone 来的代码无 venv，必须先建 venv + 装依赖 + 装 pytest/coverage，再跑脚本。详见下方「Python 项目执行流程」。

**通用约束**：任何工具/依赖安装失败必须打印日志到 stderr，不得吞错继续；仅当工具缺失且安装失败时才降级到 LLM 估算（D4 标注"估算"且 ≤70）。

### 降级：模型能力生成

**触发条件**（任一即降级）：
- 脚本执行失败（退出码非 0 且未产出 JSON）
- 脚本超时（>10 分钟未完成）
- 工具缺失且安装失败（Go：gocyclo/golangci-lint/gosec/scc/go 任一不可用；Python：pytest/coverage 装不上）
- 项目既非 Go 也非 Python（无 go.mod 且无 pyproject.toml/setup.py/setup.cfg/requirements.txt，且 Go 文件 < 3 个且 Python 文件 < 3 个）
- 脚本产出 JSON 但关键字段全缺失（dimensions/total_score 为空）

> 注：脚本 `go-quality-scorer-v1.1.py` 已支持 Python 项目（`_detect_language` → `_scan_coverage_python`）。
> Python 项目走脚本路径，不要直接降级到 LLM 估算。Python 覆盖率采集前需先在项目根创建 venv 并安装依赖（见下方「Python 项目执行流程」）。

**降级执行步骤**：
1. 用模型自身能力读项目代码（go 文件结构、错误处理、安全模式、测试覆盖、架构分层等）
2. 按六维度框架（D1~D6 + 红线）逐项评分，证据须基于实际代码而非臆测
3. 生成与脚本相同结构的 JSON 报告，写入 `go-quality-report-v1.1.json`
4. metadata 加 `"mode": "llm-fallback"` 标注降级来源
5. metadata.tools 列出实际用到的工具（如 `["llm-code-analysis"]` 或 `["golangci-lint", "llm-fallback"]`）
6. issues 每条须含 file:line 位置（基于代码阅读定位）

**降级评分约束**：
- 无真实覆盖率数据时 D4 不得给 ≥80（上限 70，标注"估算"）
- 无 gosec/govulncheck 数据时 D2 不得给 ≥85（上限 75，标注"未做依赖 CVE 扫描"）
- 无 gocyclo/gocognit 数据时 D3 scale_complexity 子项标注"估算"
- 红线检查仍须执行（硬编码密钥/SQL 注入等可由代码阅读判定）

**禁止**：
- 降级时不得跳过任何维度（D1~D6 全部必须有分）
- 不得直接复用上次评分结果
- 不得产出空 issues 列表（至少给出代码阅读发现的 top 3 改进点）

---

## Python 项目执行流程

脚本 `go-quality-scorer-v1.1.py` 已支持 Python 项目（`_detect_language` 返回 `"python"` → `_scan_coverage_python` 采集真实覆盖率）。Python 项目按以下流程执行，**不要降级到 LLM 估算**：

1. **定位 Python 工程根**：脚本 `_detect_python_root` 自动处理（monorepo 如 `backend/` 子目录也能识别）
2. **创建 venv 并安装依赖**（脚本 `_detect_python_bin` 优先找 `.venv/bin/python`，无 venv 时退回系统 python3，系统 python3 通常没装项目依赖会导致 `coverage run -m pytest` 失败）：
   ```bash
   # 在 Python 工程根（脚本会打印 root=...）
   python3 -m venv .venv
   .venv/bin/python -m pip install -U pip
   # 依赖声明优先级：requirements.txt > pyproject.toml > setup.py
   .venv/bin/python -m pip install -r requirements.txt 2>/dev/null \
     || .venv/bin/python -m pip install -e . 2>/dev/null \
     || true
   # 覆盖率采集必需
   .venv/bin/python -m pip install pytest coverage
   ```
3. **跑评分脚本**：
   ```bash
   python3 scripts/go-quality-scorer-v1.1.py /path/to/python/project
   ```
   脚本会自动用 `.venv/bin/python` 跑 `coverage run -m pytest -o addopts=` 采集真实覆盖率。
4. **产出报告**：脚本写 `go-quality-report-v1.1.json`，结构与 Go 项目一致。

**约束**：
- venv 创建 + 装依赖失败时，打印失败日志到 stderr，不得静默跳过
- 装依赖超时（>5 分钟）可降级，但 D4 必须标注"估算"且 ≤70

---

## 六维度评分框架

```
D1 正确性与可靠性 (25%)           →  逻辑、边界、错误、并发
D2 安全性 (20%)                   →  输入校验、鉴权、密钥、依赖
D3 可维护性·规模复杂度 (20%)      →  CC + 认知CC + SLOC + MI + 函数长度
D4 测试有效性 (15%)               →  覆盖率、断言、边界、可测性
D5 架构与设计 (12%)               →  分层、耦合、接口、扩展
D6 性能效率 (8%)                  →  时间复杂度、空间、资源、开销
────────────────────────────────────────────────────────────
总分 (100%)  →  A/B/C/D/F 五级评级
```

---

## D3 可维护性·规模复杂度（新）

### 六个新指标

| 指标 | 工具 | 权重 | 阈值 |
|------|------|------|------|
| **平均圈复杂度（Avg CC）** | gocyclo | 20% | CC ≤ 10 满分 |
| **峰值圈复杂度（Peak CC）** | gocyclo | 15% | CC ≤ 20 满分 |
| **认知复杂度（Cognitive CC）** | gocognit | 15% | ≤ 15 满分 |
| **代码规模（SLOC）** | scc | 20% | ≤ 800 满分 |
| **函数长度分布** | scc + 解析 | 15% | 平均 ≤ 50 满分 |
| **可维护性指数（MI）** | Halstead 公式 | 15% | MI ≥ 65 满分 |

### 评分融合

```
D3_ScaleComplexity = Avg_CC(20%) + Peak_CC(15%) + Cognitive_CC(15%) 
                   + SLOC(20%) + FuncLength(15%) + MI(15%)

D3_Final = D3_Base(60%) + D3_ScaleComplexity(40%)
```

---

## 工具支持

### 已集成

- **gocyclo** - 圈复杂度采集
- **golangci-lint** - 代码风格 & 检查
- **go test** - 测试覆盖率
- **gosec** - 安全隐患扫描（独立调用，覆盖完整规则集）
- **gocognit** - 认知复杂度（新）
- **scc** - 代码规模统计（新）

> 注：gosec 独立调用而非依赖 golangci-lint 内含的 gosec linter，
> 因为 golangci-lint 默认不启用 gosec，且独立调用避免 issue 截断/版本滞后。

### 安装

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

## 关键阈值一览

| 维度 | 优秀 | 一般 | 差 | 红线 |
|------|------|------|------|------|
| D1 错误处理 | 无漏掉 | 少量漏掉 | 裸 catch | ✗ |
| D2 安全 | 无硬编码 | 低危 CVE | 硬编码密钥 | ✗ (红线) |
| D3 圈复杂度 | CC 1-10 | CC 11-20 | CC >20 | ✗ CC >50 (红线) |
| D3 认知复杂度 | ≤15 | 16-25 | >25 | ✗ Avg CC >25 (红线) |
| D3 SLOC | ≤800 | 800-2000 | >2000 | ✗ >2000 (红线) |
| D3 MI 指数 | ≥65 | 50-64 | <50 | - |
| D4 覆盖率 | ≥80% | 60-79% | <60% | - |
| D6 时间复杂 | O(n log n) | O(n²) | O(2ⁿ) | ✗ (红线) |

---

## 一票否决红线

命中以下任一项 → 直接 **F** 级（不论总分）：

1. ✗ 硬编码密钥 / Token
2. ✗ SQL 注入 / 越权漏洞
3. ✗ 已知高危 CVE 依赖
4. ✗ 大面积假测试
5. ✗ 静默吞错
6. ✗ 编译失败
7. ✗ 单函数 CC > 50
8. ✗ 平均 CC > 25
9. ✗ 单文件 SLOC > 2000

---

## 输出格式

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

## 升级指南（从 v1.0 → v1.1）

### 变化点

1. **维度名改**: D3 可维护性 → **D3 可维护性·规模复杂度**
2. **新增子模型**: 6 个新指标（CC、认知 CC、SLOC、MI、函数长度）
3. **融合算法**: D3_Final = Base(60%) + ScaleComplexity(40%)
4. **新增红线**: 3 条规模复杂度相关的红线
5. **权重不变**: 总体六维评分权重体系不变

### 迁移策略

- ✅ 原有报告兼容（D3_base 字段保留）
- ✅ 新 D3_Final 与原 D3 通常差异 < 5 分
- ✅ 建议对比分析历史数据

---

## 参考文献

- 📘 `references/D3-可维护性·规模复杂度.md` - 详细指标说明
- 📘 `references/D1-correctness.md` - 正确性维度指南
- 📘 `references/D2-security.md` - 安全性维度指南
- 📘 `references/D4-testing.md` - 测试维度指南
- 📘 `references/D5-architecture.md` - 架构维度指南
- 📘 `references/D6-performance.md` - 性能维度指南

---

## 常见问题

**Q: 为什么 D3 分数变低了？**  
A: v1.1 新增了规模复杂度指标，对代码质量要求更严格。建议对照新文档 D3-可维护性·规模复杂度 了解具体指标。

**Q: 如何快速改进 D3 评分？**  
A: 优先级：MI (15%) → SLOC (20%) → Avg CC (20%)。详见参考文献中的改进路线。

**Q: 能否只用 D3_base（不用新指标）？**  
A: 可以。在调用中设置权重为 100% D3_base。但建议全面采用 v1.1。

