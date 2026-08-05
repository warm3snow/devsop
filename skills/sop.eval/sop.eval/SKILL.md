---
name: sop.eval
description: "按团队研发 SOP v1.0 评估项目 SOP 标准实现程度。扫描项目结构、文档、CI、测试与流程证据，生成结构化评分报告（六大支柱、28 项 Eval、PASS/PARTIAL/FAIL、反模式检测、改进建议、升级路线图），最终写入 .harness/sop_report.md。"
disable-model-invocation: true
---

# sop.eval

**Eval Schema 版本**：`2.0`（28 项 Eval，ID 命名空间稳定。适配新版 sop.init (specs-sop) 的 `.harness/` 产物体系。新增 Eval 追加新 ID，版本号递增。`--diff-from` 对比时需检查版本一致性。）

## 用户输入

```text
$ARGUMENTS
```

## 概述

按团队研发 SOP v1.0 的「大原则 + 六大章节」对当前项目做一次只读审计，量化项目对 SOP 的实现程度，生成可执行改进建议，最终把报告**写入 `.harness/sop_report.md`**（这是 SOP §1.2 项目目录结构里规约库的标准位置，会随仓库一起入库以便团队评审）。

支持三种运行模式：
1. **仅报告**（默认）：执行评估并写入 `.harness/sop_report.md`
2. **报告 + JSON**（`--json`）：执行评估写入报告后，额外生成结构化 JSON 到临时目录
3. **仅 JSON**（`--json-only`）：不做评估，直接从已有 `.harness/sop_report.md` 转换为 JSON

> **本 Skill 自包含**：SOP 的评判要点已内嵌在下文「评判维度」一节，无需外部 SOP 文档。如团队的 SOP 版本演进，更新本 SKILL.md 与 `references/sop-scoring-criteria.md` 同步即可。

---

## 路径变量定义（防误写）

| 变量 | 含义 | 取值方式 | 用途 |
|------|------|---------|------|
| `$SKILL_DIR` | 本 Skill 安装目录（可能为 `~/.codebuddy/skills/sop.eval` 用户级，或 `<repo>/.codebuddy/skills/sop.eval` 项目级） | 包含本 SKILL.md 的目录 | **只读**：读 references/ 与 scripts/ |
| `$REPO_ROOT` | 当前项目仓库根目录 | `git rev-parse --show-toplevel` 失败则取 cwd | **读写**：扫描证据 + 写 `.harness/sop_report.md` |

强约束：
- 产出文件 `.harness/sop_report.md` **必须**写入 `$REPO_ROOT`，禁止写入 `$SKILL_DIR` / `$HOME` / `~/.codebuddy/`
- 评分扫描命令（`ls` / `grep` / `git log`）**必须**在 `$REPO_ROOT` 下执行
- 读模板/脚本必须用 `$SKILL_DIR/...`，禁止硬编码 `.codebuddy/skills/sop.eval/...`（仅项目级安装时才存在）
- Skill 启动时主 Agent 先执行以下两步解析路径：

```bash
# Step A: 解析 REPO_ROOT（当前项目仓库）
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# Step B: 解析 SKILL_DIR（Skill 安装目录，优先用户级）
if [ -d "$HOME/.codebuddy/skills/sop.eval/references" ]; then
  SKILL_DIR="$HOME/.codebuddy/skills/sop.eval"
elif [ -d "$REPO_ROOT/.codebuddy/skills/sop.eval/references" ]; then
  SKILL_DIR="$REPO_ROOT/.codebuddy/skills/sop.eval"
else
  echo "⚠️ 无法定位 sop.eval skill 目录" >&2
fi
```

> ⚠️ 后续所有 `$SKILL_DIR` 引用（读 references/、scripts/）必须使用上面解析出的绝对路径，禁止用相对路径。

---

## 何时使用本 Skill

- 项目已通过 `sop.init` 完成 SOP 目录结构搭建后，做一次基线评估
- 每月例行 SOP 时效性 Review（SOP §3.4 记忆机制 + 整理机制）
- 引入新研发流程或工具变更后，验证是否仍满足 SOP 门禁要求
- 跨项目对标：用统一打分对比多个项目的 SOP 成熟度
- 需要将已有报告转换为 JSON 供前端/任务系统消费（`--json-only`）

---

## 评判维度（自包含 · 六大支柱 · 总分 100）

直接对应 SOP v1.0 的章节，每支柱按其在 SOP 中的权重和门禁强度赋分：

| 支柱 | 满分 | 对应 SOP 章节 | 核心拷问 |
|------|------|--------------|----------|
| **A. 项目 AI 友好化** | 25 | §一（友好化前提 + 目录结构 + 软链接屏蔽工具差异） | AI/新人 30 分钟内能否跑通项目并理解结构？ |

> **布局对齐说明**：本 Schema 适配**新版 specs-sop（`sop.init`）**的 `.harness/` 隐藏目录产物体系。核心布局约定：
> - 规约库统一在 `.harness/docs/` 下（`architecture.md` / `relationship.md` / `coding-style.md` / `code-review.md` / `glossary.md` / `failures.md` / `logging.md` / `unittest/unittest.md` / `integration_test/integration_test.md` / `apis/` / `sqls/` / `devops/`）；
> - 顶层仅保留 `.harness/review.md` 与 `.harness/plans/`；**严禁**全局 `plan.md` 任务总览（任务总览下沉到各 `plans/<任务>/00-overview.md`）。
> - 若项目仍残留旧版非隐藏 `harness/` 目录或旧文档名（`dependency-map.md` / `testing.md` 顶层），按「旧版 harness 残留」反模式提示迁移，不重复扣分。
| **B. 开发模式 / 角色协作** | 15 | §二（整体流程 + SOLO/P-G-E 架构） | 是否有清晰的研发流程定义和阶段产出物？ |
| **C. 质量检查与反馈机制** | 25 | §三（质量门禁 + 禁止项 + 反馈机制） | 关键检查点是否设了门禁、能否阻断坏代码合入？ |
| **D. 设计与变更管理** | 15 | §四（按规模分级 + 设计先于编码 + TDD） | 大/中/小变更是否有匹配的设计流程与文档沉淀？ |
| **E. 公共资料库** | 5 | §五（内部沉淀 + 外部资料） | 团队/跨团队是否有可复用的知识沉淀？ |
| **F. 度量机制** | 15 | §六（SOP 成熟度 + AI 运行指标） | 项目是否有自我度量与持续改进闭环？ |

> 总分 100，区间 → 等级映射详见下文「成熟度等级」。

每支柱拆成 3-7 个独立 Eval 项，每项给出 ✅ PASS / ⚠️ PARTIAL / ❌ FAIL，证据必须是文件路径、命令输出或文档摘要。完整 28 项 Eval 的判定逻辑见 `references/sop-scoring-criteria.md`。

---

## 评估流程（5 个步骤）

### Step 0：探测项目语言栈与项目类型

**探测语言栈**（决定后续扫描什么文件）：

| 信号文件 | 语言 | 关注的工具链 |
|----------|------|------------|
| `go.mod` / `*.go` | Go | `.golangci.yml`、`*_test.go`、`Makefile`、`go vet` |
| `package.json` / `tsconfig.json` | JS/TS | `.eslintrc*`、`*.test.*` / `*.spec.*`、`vitest`/`jest` |
| `pyproject.toml` / `requirements.txt` | Python | `ruff`/`pylint`、`pytest`、`tox.ini` |
| `Cargo.toml` | Rust | `clippy`、`#[test]` |
| `pom.xml` / `build.gradle` | Java | `checkstyle`、`*Test.java` |

混合语言栈分别扫各自工具链。

**探测项目类型**（决定哪些 Eval 项可豁免）：

| 信号 | 项目类型 | 判定逻辑 |
|------|---------|----------|
| 有 `cmd/` 或 `main.go`/`main.py` + HTTP handler/router 代码 | **service** | 默认类型，无豁免 |
| 有 `go.mod` 但无 `main.go`/`cmd/`，仅导出 package | **library** | 豁免 A6（一键启动）、C7（E2E 测试，改为检测示例/benchmark） |
| 有 `main.go` 但无 HTTP handler，有 cobra/flag 等 CLI 框架 | **cli** | 豁免 A6（改为检测 `make build`）、C7（改为集成测试脚本） |
| 有多个 `go.mod` / 或根目录有 `packages/` + 子目录各含入口 | **monorepo** | 不豁免，但子 Agent 应注明"建议各子模块单独评估" |

**豁免处理规则**：
- 豁免的 Eval 标记为 `N/A`，在报告中注明原因（如 "library 项目无需一键启动"）
- 该 Eval 的满分从总分基数中扣除（如 library 豁免 A6+C7 → 总分基数变为 94 分，按 94 分算百分比后映射等级）
- 等级映射表的百分比阈值不变（如 L3 = 60-79%），只是基数调整

**项目类型探测脚本**：`$SKILL_DIR/scripts/detect_project_type.sh`

```bash
cd "$REPO_ROOT" && bash "$SKILL_DIR/scripts/detect_project_type.sh"
# 输出：PROJECT_TYPE=service / library / cli / monorepo
```

### Step 1：收集原始证据（三层 Grader 优先级）

1. **代码 Grader**（确定性）：文件存在性、命令输出、配置完整性。**优先使用**。
2. **模型 Grader**（主观）：文档质量、规约深度、约束清晰度。
3. **人工标记**（高成本）：仅在前两者均无法判断时使用，对应项标"评估置信度：低"。

### Step 2：逐项执行 28 项 Capability Eval

对六大支柱逐项打分。每项记录：

- **结论**：✅ PASS / ⚠️ PARTIAL / ❌ FAIL
- **证据**：具体文件路径 / 命令输出 / 文档摘要（≤3 行）
- **Grader**：代码 / 模型 / 人工

**28 项 Eval 索引**（详细判定标准见 `references/sop-scoring-criteria.md`）：

#### A. 项目 AI 友好化（25 分）

| ID | 评估项 | 满分 | Grader |
|----|--------|------|--------|
| A1 | `AGENTS.md` 存在且 ≤300 行 + 四章完整性（一、快速索引 / 二、SOP / 三、开发准则 / 四、禁止红线） | 3 | 代码+模型 |
| A2 | `README.md` 含项目背景/快速启动/部署要求 | 5 | 模型 |
| A3 | `.harness/docs/architecture.md` 含架构图/模块边界/技术债（新版 specs-sop 已将架构文档迁入 `.harness/docs/` 下，根目录 `ARCHITECTURE.md` 不再作为评分目标；若项目仍残留根目录旧文件，按迁移反模式提示） | 5 | 模型 |
| A4 | `.harness/docs/` 规约库覆盖新版核心文档：`architecture.md`、`relationship.md`（替代旧 `dependency-map.md`）、`coding-style.md`、`code-review.md`、`glossary.md`、`failures.md`、`logging.md`、`unittest/unittest.md`（替代旧 `testing.md`）、`integration_test/integration_test.md`；以及子目录文档 `apis/index.md`、`sqls/README.md`、`devops/deployment.md`、`devops/development.md`、`devops/env.md`、`devops/test-env-deploy.md`（按需，无 API/DB 的项目可缺省，详见支柱 A 评分标准 §等价识别）。**判定强调"内容充实度"而非仅文件存在**（占位模板视为缺失，详见支柱 A 评分标准 §占位识别） | 5 | 代码 |
| A5 | 检测项目已有哪些 AI 工具软链接（CODEBUDDY.md / CLAUDE.md → AGENTS.md），至少 1 个存在且未被 .gitignore；**不要求项目添加未使用 AI 工具的软链接** | 2 | 代码 |
| A6 | `make dev` 或等效一键启动命令存在并能跑通 | 3 | 代码 |
| A7 | 环境配置模板（`.env.example` 或等效）存在，新开发者无需猜测配置 | 2 | 代码 |

#### B. 开发模式 / 角色协作（15 分）

| ID | 评估项 | 满分 | Grader |
|----|--------|------|--------|
| B1 | `AGENTS.md`「二、SOP」章节明确研发流程 9 步（Clarify→Plan→Implement→UT→Deploy→IT→Docs→Review→Commit） | 5 | 模型 |
| B2 | 角色职责约定（产品/测试/研发）有文档承载或在 `AGENTS.md` 中说明 | 4 | 模型 |
| B3 | 阶段产出物有明确归属位置（`.harness/plans/<任务>/` 任务目录 + `_template/` 模板）；任务/需求/缺陷必须使用 **Tapd**，禁出现 Jira/Linear/GitHub Issues | 4 | 代码+模型 |
| B4 | 分支命名规范 + Commit Message 规范有文档承载（Conventional Commits 或等效约定），引用单号格式 `--story=<id>` / `--bug=<id>`（Tapd） | 2 | 代码+模型 |

#### C. 质量检查与反馈机制（25 分）

| ID | 评估项 | 满分 | Grader |
|----|--------|------|--------|
| C1 | 提交 / Push 规范记忆化：`AGENTS.md` 与 `.codebuddy/rules/` 下的规则文件中显式定义 commit 规范（message 格式 / 提交前检查 / 单号关联）与 push 规范（push 前检查 / MR 流程 / force push 约束）。**注意**：本 Skill 跑在服务器上，`.git/hooks/` 不随代码分发，Git Hook 不作为证据 | 5 | 代码+模型 |
| C2 | CI 流水线全量单测 + 覆盖率门禁（判定二选一即认定有 CI：① 仓库内有 `Jenkinsfile`/`jenkins/`；② `README.md` 或 `.harness/docs/devops/development.md` 明确写出 Jenkins / Argo CD / 智研 流水线 URL）。**禁用证据**：仅有 `.github/workflows/` 或 `.gitlab-ci.yml` 不可作为 PASS 主证据，仅在无 Jenkins 痕迹时降级为 PARTIAL 兜底信号 | 5 | 代码 |
| C3 | 禁止项防护：敏感文件、生成物、未格式化代码、未审 AI 代码（在 `.gitignore` / Hook / `.harness/docs/code-review.md` 中体现） | 4 | 代码+模型 |
| C4 | 分支保护：禁止直推 main、PR 必须 Review、PR 行数约束等流程约定有文档 | 3 | 模型 |
| C5 | 反馈机制（failures.md / 踩坑记录有持续更新，非空文档） | 3 | 代码+模型 |
| C6 | 安全扫描 / 依赖漏洞检测（Go 项目主查 `.golangci.yml` 的 `linters.enable` 是否启用 `gosec`；或 `trivy`/`snyk`/`govulncheck`/`Renovate` 或 Jenkins 流水线集成安全检查） | 2 | 代码 |
| C7 | E2E / 集成测试存在（独立目录 + 文件非空 + CI 中有对应步骤） | 3 | 代码 |

#### D. 设计与变更管理（15 分）

> **统一体系**：新版 sop.init 使用 `.harness/plans/<任务>/` 的 10 文件 SOP 体系，所有变更通过 plans 目录下的任务产物进行管理。

| ID | 评估项 | 满分 | Grader |
|----|--------|------|--------|
| D1 | 任务目录存在且有实质内容（`.harness/plans/` 下 ≥1 个任务目录含完整 10 文件） | 4 | 代码 |
| D2 | `00-overview.md` 维护活跃度（近 90 天有任务 overview 的 git 更新） | 4 | 代码+模型 |
| D3 | 小变更 TDD/回归测试要求文档化 + 模板完整性（`_template/` 含 10 文件 + TDD 在 `.harness/docs/unittest/unittest.md` 或 `AGENTS.md` 明确；旧版 `.harness/docs/testing.md` 视为待迁移，按迁移反模式提示） | 4 | 代码+模型 |
| D4 | 变更分级标准文档化：明确定义大/中/小变更的判定标准（人天阈值、影响范围）及各级对应流程 | 3 | 模型 |

#### E. 公共资料库（5 分）

| ID | 评估项 | 满分 | Grader |
|----|--------|------|--------|
| E1 | 项目内有 Skills 沉淀目录（`.codebuddy/skills/`）且 ≥3 份 SKILL.md | 2 | 代码 |
| E2 | 知识沉淀完整度（满足任一即 PASS：① `.harness/docs/` 下 ≥10 篇文档；② README/AGENTS.md 中链接外部团队 wiki/Confluence/Tapd 等知识库；③ `.harness/plans/` 下 ≥3 个已创建任务目录） | 3 | 代码+模型 |

#### F. 度量机制（15 分）

| ID | 评估项 | 满分 | Grader |
|----|--------|------|--------|
| F1 | `.harness/sop_report.md` 存在且有改进跟踪记录（F1a 报告存在+非首次 2分 / F1b 改进行动有记录 3分） | 5 | 代码+模型 |
| F2 | AI 会话/记忆/失败 case 留存（满足任一即 PASS）：① 当前项目的 CodeBuddy 记忆库（`~/.codebuddy/projects/<项目路径 slug>/memory/`，用户级）含 ≥3 份记忆文件；② `logs/ai-sessions/`、`.codebuddy/sessions/` 或 CodeBuddy 用户级会话转录（`~/.codebuddy/projects/<slug>/*.jsonl`）有近 30 天文件；③ `.harness/docs/failures.md` 已入 git 且近 90 天有提交 | 4 | 代码 |
| F3 | 文档变更可追踪：`.harness/` 目录文件最近 60 天有 git 提交记录 | 3 | 代码 |
| F4 | 改进行动闭环：历史评估中 FAIL/PARTIAL 项有 ≥1 项升级为 PASS（需 ≥2 次评估记录） | 3 | 代码+模型 |

> Eval ID 命名空间稳定，新增项追加新 ID 不复用旧 ID。

### Step 3：评分计算与成熟度等级

**评分规则**：

- ✅ PASS：满分
- ⚠️ PARTIAL：满分的 40%（如 5 分 → 2 分；6 分 → 2.4 分，四舍五入）
- ❌ FAIL：0 分

**成熟度等级**：

| 总分 | 等级 | 名称 | 一句话定位 |
|------|------|------|-----------|
| 0–19 | L0 | **无 SOP** | 项目仅有源码与零散文档，团队/AI 协作完全靠口口相传 |
| 20–39 | L1 | **基础约束** | 有 AGENTS.md/README，基本的 lint，但门禁与流程缺位 |
| 40–59 | L2 | **门禁建立** | CI + PreCommit + 设计流程开始落地，但反馈机制未闭环 |
| 60–79 | L3 | **流程闭环** | 六大支柱基本齐备，反馈机制持续运转，团队 + AI 高效协作 |
| 80–100 | L4 | **持续优化** | 度量驱动改进，文档/规约持续迭代，可作为团队范本输出 |

### Step 4：反模式检测（必做，独立于评分）

即使总分不低，也要扫描下表反模式。任何一项命中都要在报告中标红，不影响支柱评分但会在「核心结论」中突出强调。

| 反模式 | 检测方式 | 风险 |
|--------|---------|------|
| 文档与代码严重不同步（`.harness/` 内文件 >60 天无更新） | `git log --since='60 days ago' -- .harness/` | AI 用过期约束生成代码 |
| 测试过度 Mock（mock 文件 >20 且无集成测试文件） | `find . -name '*_mock*.go' \| wc -l` + `find . -path '*/integration*' -name '*_test.go' \| wc -l` | AI 拿到失真正反馈 |
| 提交了敏感文件或生成物（`*.env`、`*.key`、`vendor/`、`dist/`、`node_modules/`） | `git ls-files \| grep -E ...` | 直接违反 SOP 禁止项 |
| 重要决策只在 commit message / 对话历史，未沉淀文档 | 抽查 5 个最近大型 PR commit message 看是否引用了 spec/openspec/Tapd 单号（`--story=` / `--bug=`） | AI 无法追溯约束 |
| `failures.md` 长期为空或仅占位 | `wc -l .harness/docs/failures.md` 且最近 90 天无修改 | 反馈机制名存实亡 |
| `AGENTS.md` 浅薄（仅项目简介，无禁忌/规约索引） | 行数 + 章节关键字检查 | AI 无有效约束信号 |
| 旧版 harness 残留未迁移（新版 specs-sop 已切换到隐藏 `.harness/` + 新文档名） | `ls -d harness/` 命中非隐藏旧目录；或存在根目录 `ARCHITECTURE.md`、`.harness/docs/dependency-map.md`、`.harness/docs/testing.md`、`.harness/plan.md` 等旧版文件 | 旧布局与新 sop.init 不兼容，AI 入口索引可能指向错误路径，评估需按旧布局单独判定 |
| 使用禁用工具栈（CI 用 GitHub Actions/GitLab CI/CircleCI 作主流水线；Issue 用 Jira/Linear/GitHub Issues；依赖用 Dependabot） | `grep -rE 'jira\|linear\|github\.com/.*/issues\|dependabot' README.md AGENTS.md .harness/ .github/`；`ls .github/workflows/ .gitlab-ci.yml` 但无 `Jenkinsfile` | 违反团队工具栈约束，跨项目无法对齐 |

### Step 5：生成报告并写入 `.harness/sop_report.md`

按 `references/sop-report-template.md` 渲染，**直接覆盖写入 `.harness/sop_report.md`**（如目录不存在则创建）。

报告包含以下章节（顺序固定）：

1. 元信息（项目名、评估日期、评估人、SOP 版本）
2. 总览评分表（六支柱得分 + 总分 + 等级 + 红/黄/绿色块）
3. Capability Eval 明细（按 A-F 分组的 28 项详表）
4. 反模式检测结果
5. 熵管理评估（文档新鲜度、测试 Mock 比例、failures.md 活跃度）
6. 优先改进建议（按高/中/低优先级，每条引用 Eval ID + 给出可执行行动 + 预期收益，参考 `references/sop-improvement-examples.md`）
7. 升级路线图（从当前 L? 到 L?+1 的关键里程碑）
8. 核心结论（3-4 句概括）
9. **Todo Suggestions 表格**（紧跟核心结论，从改进建议提炼 3-7 条可直接行动项，两列：`Todo 标题` / `改进方案`，便于前端解析或直接转 TAPD 单）

---

## Step 1: 解析用户参数

从 `$ARGUMENTS` 解析以下可选标志：

- `--dry-run`：执行完整扫描和评分，但**不写入** `.harness/sop_report.md`，仅在控制台输出报告
- `--diff-from=<path>`：与历史报告对比（默认对比 `.harness/sop_report.md` 中上次评估），输出"本次比上次涨/跌了哪些项"，便于追踪改进。**Eval ID 不对称处理**：若新旧报告 eval-schema 版本不同（如旧版无某 Eval ID），对比时新增项标"新增，无历史对比"，已删除项从对比中剔除，仅对双方都有的 ID 计算升降。
- `--only=<支柱>`：仅评估指定支柱（如 `--only=A,C` 只评 AI 友好化和质量门禁），用于快速复测某次改进
- `--no-anti-patterns`：跳过反模式检测（不推荐，仅在快速试跑时使用）
- `--json`：在生成 `.harness/sop_report.md` 报告后，额外启动子 Agent 从报告中提取总分、各支柱评分和 Todo Suggestions，生成结构化 JSON 文件（含评分 + 改进任务）到临时目录，最终返回文件路径（详见 Step 6）
- `--json-only`：**不执行评估**，跳过 Step 2-5，直接从已有的 `.harness/sop_report.md` 提取数据生成 JSON。若报告文件不存在则报错退出（详见 Step 6）

**三种运行模式**：

| 模式 | 参数 | 行为 |
|------|------|------|
| 仅报告（默认） | 无 `--json` 无 `--json-only` | 执行 Step 2-5，生成/更新 `.harness/sop_report.md` |
| 报告 + JSON | `--json` | 执行 Step 2-5 生成报告，再执行 Step 6 生成 JSON |
| 仅 JSON | `--json-only` | 跳过 Step 2-5，直接执行 Step 6 从已有报告生成 JSON |

> `--json-only` 与 `--json` 互斥，同时传入时以 `--json-only` 优先（不做评估）。
> `--json-only` 与 `--dry-run`/`--only`/`--no-anti-patterns` 等评估参数互斥，同时传入时忽略评估参数并 Warning。

未识别参数原样保留并在报告头部 Warning 区提示。

---

## Step 2: 环境探测（主 Agent 前置）

> **`--json-only` 模式**：跳过 Step 2-5，直接进入 Step 6。

**前置**：确认路径已解析（Skill 启动时已执行 Step A + Step B，此处仅做防御性校验）。

```bash
# 防御性校验：确保 REPO_ROOT 和 SKILL_DIR 已解析
[ -z "$REPO_ROOT" ] && REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
[ -z "$SKILL_DIR" ] && echo "⚠️ SKILL_DIR 未解析，请检查 Skill 启动步骤" >&2
```

后续所有扫描命令均在 `$REPO_ROOT` 下执行；读 references/scripts 一律用 `$SKILL_DIR` 绝对路径。

### 2.1 基础探测

并行执行：

1. `ls` 检测 SOP 标准文件存在性（AGENTS.md / README.md / `.harness/docs/architecture.md` / `.harness/` / 软链接；注意新版 specs-sop 架构文档在 `.harness/docs/` 下，根目录 ARCHITECTURE.md 视为旧版残留）
2. 识别语言栈（按 Step 0 的信号文件表）
3. `git log -1 --format=%cI -- .harness/` 等命令拿文档新鲜度

### 2.2 构建 Evidence Cache（关键优化）

**目的**：避免 6 个子 Agent 重复执行相同命令。主 Agent 一次性收集公共证据，注入子 Agent 上下文。

**执行脚本**：`$SKILL_DIR/scripts/collect_evidence.sh`

```bash
cd "$REPO_ROOT" && bash "$SKILL_DIR/scripts/collect_evidence.sh"
```

脚本输出结构化分段文本（`=== FILE_EXISTS ===`、`=== DIR_EXISTS ===`、`=== GIT_RECENCY ===` 等）。主 Agent 将完整输出注入每个子 Agent 的 prompt（章节名：`# Evidence Cache`）。子 Agent 优先查 Cache，Cache 中无对应数据时才自行执行命令。

输出探测结果矩阵后再进入 Step 3。

---

## Step 3: 28 项 Eval 扫描（建议子 Agent 并行）

**推荐架构**：六大支柱各派一个子 Agent（共 6 个，`run_in_background: true`），每个子 Agent 负责自己支柱内的 3-7 个 Eval。

### 3.1 子 Agent Prompt 框架

```text
你是 SOP 评估子 Agent，负责支柱 <X.支柱名> 的 <N> 个 Eval（<ID 列表>）。

# 输入
- 仓库根目录（工作目录）：<主 Agent 注入 $REPO_ROOT 的实际绝对路径>（已由主 Agent cd 到位）
- 评分标准：<主 Agent 注入 $SKILL_DIR 的实际绝对路径>/references/sop-scoring-criteria.md（仅读你负责的支柱章节）
- 改进建议库：<主 Agent 注入 $SKILL_DIR 的实际绝对路径>/references/sop-improvement-examples.md（仅读你负责的支柱章节）
- 项目语言栈：<由主 Agent 注入>
- 项目类型：<由主 Agent 注入：service / library / cli / monorepo>
- **工具栈强制约束（CI / Issue Tracker / 依赖管理）**：本 SOP 框架默认工具栈为 **CI=Jenkins + 部署=Argo CD + 流水线门户=智研 + Issue=Tapd + 依赖更新=Renovate（Self-Hosted）**。改进建议中**禁止出现** GitHub Actions / GitLab CI / CircleCI / CNB / Jira / Linear / GitHub Issues / Dependabot 等平台。
  - **CI（C2/C6/C7）**：改进路径必须为 ① 仓库根入库 `Jenkinsfile`（含 stages：Build → Lint → UnitTest → Coverage → Integration / Security）；② 在 `.harness/docs/devops/development.md` 写出 Jenkins/Argo CD/智研 可点击 URL。证据扫描优先查 `Jenkinsfile` / `Jenkinsfile.*` / `jenkins/` / `.jenkins/`，不命中再查 `.github/workflows/` / `.gitlab-ci.yml` 仅作兜底信号（不作 PASS 主证据）。
  - **Issue Tracker（B3/C4/F4）**：所有"任务列表/单号引用/缺陷跟踪/需求管理"类建议必须落到 **Tapd**。MR/commit message 引用单号格式 `--story=<id>` / `--bug=<id>`。证据扫描查 `tapd.cn` / `tapd.woa.com` URL 与 `--story=` / `--bug=` commit message 痕迹。
  - **依赖管理（C6）**：推 `Renovate`（Self-Hosted），禁 `Dependabot`（GitHub 专属）。

# Evidence Cache（主 Agent 预收集，优先使用，避免重复 IO）

<主 Agent 注入 Step 2.2 的完整输出>

⚠️ 使用规则：
- Cache 中已有的数据直接使用，**不要重复执行相同命令**
- 仅当 Cache 中无对应数据、或需要更深层检测（如文件内容质量判断）时才执行新命令
- 若 Eval 项因项目类型标为 N/A，直接跳过不评估

⚠️ 路径约束（严格区分两个目录）：
- $REPO_ROOT = 项目仓库根目录 → 扫描证据只读此目录下文件
- $SKILL_DIR = Skill 安装目录 → 仅读 references/ 和 scripts/
- 禁止把任何文件写到 $SKILL_DIR / $HOME / ~/.codebuddy/
- 禁止混淆：$SKILL_DIR 下的 references/ 是评分标准，不是项目文档；$REPO_ROOT 下的文件才是评估对象

# 步骤

1. 读取评分标准中你负责的支柱章节，了解每个 Eval 的判定逻辑、命令、PARTIAL 边界

2. 对每个 Eval：
   a. 按"代码 Grader 优先"运行命令收集证据：
      - ls / cat / grep / find / wc -l / git log
      - 禁止深度遍历整个仓库；只读必要文件
   b. 根据评分标准给出 PASS / PARTIAL / FAIL
   c. 证据 ≤3 行，必须包含具体路径或命令输出片段

3. 对 FAIL/PARTIAL 项，从 sop-improvement-examples.md 中查找对应改进建议；
   若未命中，用模型生成可执行的改进动作（必须形如「在 X 文件添加 Y 章节」/「配置 Z 工具」），
   不允许出现「应加强 X」这种空话。

4. 输出结构化结果（不写盘）：
   {
     "pillar": "C",
     "score": 16.4,
     "max": 25,
     "evals": [
       {"id": "C1", "result": "PARTIAL", "evidence": "...", "grader": "代码", "improvement": "..."},
       ...
     ],
     "anti_patterns_observed": [...] // 仅记录与本支柱相关的反模式信号
   }

# 约束
- 只读，禁止任何写文件 / git add / git commit
- 不读取 .git/、node_modules/、vendor/、bin/、logs*/、dist/、build/
- 证据缺失时宁可 FAIL，不要编造路径
- 评估置信度低时（如纯主观判断）必须在 evidence 末尾加 "(置信度: 低)"
```

### 3.2 并行控制

- 一次性发起 6 个子 Agent 调用（同条消息多个 Agent tool 调用，`run_in_background: true`）
- 主 Agent 用 TaskOutput 汇集所有支柱结果
- 任一子 Agent 失败 → 该支柱标 `EVAL_FAILED`，得分计 0，不阻塞其他支柱

---

## Step 4: 主 Agent 汇总

1. 累加六支柱得分 → 总分 → 映射成熟度等级（按 Step 3 表）
2. 跨支柱合并反模式信号 + 主 Agent 自己跑一次反模式专项检测（确保不依赖子 Agent）
3. 计算熵指标：
   - `.harness/` 文件更新新鲜度：逐文件取 last commit time 计算**中位数**距今天数
     ```bash
     for f in $(find .harness -name '*.md' 2>/dev/null); do
       [ -f "$f" ] && git log -1 --format='%ct' -- "$f" 2>/dev/null
     done | sort -n | awk '{a[NR]=$1} END{print a[int(NR/2)+1]}'
     ```
     用中位数而非均值，避免单个频繁更新的文件掩盖其他文件过期
   - Mock 与集成测试健康度 = 综合判断：
     - `find . -name '*_mock*.go' -o -name '*mock*.go' | wc -l`（mock 文件数）
     - `find . -path '*/integration*' -name '*_test.go' -o -path '*/e2e*' -name '*_test.go' | wc -l`（集成测试文件数）
     - 判定标准：mock 文件 >20 且集成测试文件 =0 → 🔴 过度 Mock；集成测试存在 → 🟢
   - `failures.md` 活跃度 = `git log --since='90 days ago' -- .harness/docs/failures.md | wc -l`
4. 按优先级聚合改进建议：FAIL 项 → 高优；PARTIAL 项 → 中优；反模式 → 高优
5. 提炼 Todo Suggestions（3-7 条，从改进建议中挑可独立行动 + 1 周内能完成的）

---

## Step 5: 渲染并写入 `.harness/sop_report.md`

- 按 `$SKILL_DIR/references/sop-report-template.md` 填充
- 写入路径：`$REPO_ROOT/.harness/sop_report.md`（**直接覆盖**，由 git 留版本历史）
- 若 `$REPO_ROOT/.harness/` 目录不存在 → 创建（同时提示用户「项目尚未运行 sop.init」）
- `--dry-run` 模式：不写盘，仅控制台输出完整报告

写入后追加一行控制台提示：

```
✅ SOP 评估完成
   总分：72/100  等级：L3 流程闭环
   报告：.harness/sop_report.md
   高优改进项：3 条 / 反模式：1 条
   下次建议评估：90 天后或下次重大流程变更后
```

---

## Step 6: JSON 输出（`--json` 或 `--json-only` 模式）

当用户传入 `--json` 或 `--json-only` 参数时执行本步骤。

**前置检查（`--json-only` 模式）**：

```bash
# 确保 cwd 在项目仓库根目录（--json-only 跳过了 Step 2，依赖 Skill 启动时的 cd）
[ -z "$REPO_ROOT" ] && REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# 检查报告文件是否存在（使用绝对路径）
ls "$REPO_ROOT/.harness/sop_report.md"
```

若文件不存在，输出错误并退出：
```
❌ .harness/sop_report.md 不存在
   请先运行 sop.eval（不带 --json-only）生成评估报告，或确认报告文件路径正确。
```

**报告来源判定**：

| 模式 | 报告来源 |
|------|----------|
| `--json`（正常） | Step 5 刚写入的 `.harness/sop_report.md` |
| `--json` + `--dry-run` | 主 Agent 把报告内容写入临时文件 `$TMPDIR/sop_report.md`，子 Agent 从该临时文件读取 |
| `--json-only` | 已有的 `.harness/sop_report.md`（不做任何评估） |

### 6.1 启动子 Agent 生成 JSON

使用 Agent tool 启动一个子 Agent，负责从报告中提取评分数据和 Todo Suggestions，生成结构化 JSON 文件。

**子 Agent Prompt 框架**：

```text
你是 SOP 报告 JSON 转换 Agent。你的任务是从已生成的 SOP 评估报告中提取总分、各支柱评分和 Todo Suggestions，生成结构化 JSON 文件。

# 输入
- 报告文件路径：<主 Agent 注入 $REPO_ROOT 的实际值>/.harness/sop_report.md
- SKILL_DIR：<主 Agent 注入 $SKILL_DIR 的实际绝对路径>
- 工作目录：已切到 $REPO_ROOT（项目仓库根目录，非 Skill 安装目录）

⚠️ 路径约束：
- 读报告用 $REPO_ROOT/.harness/sop_report.md
- 读验证脚本用 $SKILL_DIR/scripts/validate_todo_json.py
- 禁止把文件写入 $SKILL_DIR / $HOME / ~/.codebuddy/

# 步骤

## Step 1：定位内容来源

**提取评分数据**：从报告中读取「总览评分」表格和「成熟度等级」章节，提取总分、各支柱得分、等级信息。

**提取 Todo（优先 HTML 标记定位，降级全文）**：

**路径 A（优先）：grep 定位 HTML 标记**

```bash
grep -n "SOP_TODOS_START\|SOP_TODOS_END" "$REPO_ROOT/.harness/sop_report.md"
```

若 grep 同时找到 `SOP_TODOS_START` 和 `SOP_TODOS_END`，提取两个标记之间的内容（Markdown 表格），作为 todos 的输入。

**路径 B（降级）：grep 标题文本**

若 HTML 标记不存在（旧版报告），退而用 `grep -n "Todo Suggestions"` 定位章节标题，读取其后内容直到下一个 `---` 或文件末尾。

**路径 C（最终降级）：读取报告全文**

若路径 A/B 均未命中，读取报告全文，进入 Step 2 进行全文语义理解。

## Step 2：提取评分 + Todo 并生成 JSON

从报告中提取总分、各支柱评分和 Todo Suggestions，生成如下格式的 JSON：

```json
{
  "schema_version": "2.0",
  "project_type": "service",
  "total_score": 72,
  "max_score": 100,
  "effective_max_score": 100,
  "level": "L3",
  "level_name": "流程闭环",
  "pillars": [
    {"id": "A", "name": "项目 AI 友好化", "score": 22, "max": 25},
    {"id": "B", "name": "开发模式 / 角色协作", "score": 11, "max": 15},
    {"id": "C", "name": "质量检查与反馈机制", "score": 17, "max": 25},
    {"id": "D", "name": "设计与变更管理", "score": 12, "max": 15},
    {"id": "E", "name": "公共资料库", "score": 3, "max": 5},
    {"id": "F", "name": "度量机制", "score": 7, "max": 15}
  ],
  "todos": [
    {
      "title": "AGENTS.md 补充 commit / push 规范",
      "solution": "在 AGENTS.md「二、SOP」补 commit message 格式、提交前 build+lint+test 检查与 push 后 MR 流程约定，关联 Eval C1"
    },
    {
      "title": "激活 failures.md 踩坑记录",
      "solution": "本周补充 3 条最近遇到的典型问题到 .harness/docs/failures.md，关联 Eval C5"
    }
  ]
}
```

**顶层字段说明**：
- `schema_version`：Eval Schema 版本号（与 SKILL.md 顶部声明一致），用于跨版本对比兼容性判断
- `project_type`：项目类型（`service` / `library` / `cli` / `monorepo`），影响豁免逻辑
- `total_score`：总分（0-100 的数值，已按 effective_max_score 折算为百分制）
- `max_score`：满分，固定为 100
- `effective_max_score`：实际有效满分（扣除 N/A 豁免项后的基数，如 library 项目可能为 94）
- `level`：成熟度等级代码（L0 / L1 / L2 / L3 / L4）
- `level_name`：等级名称（无 SOP / 基础约束 / 门禁建立 / 流程闭环 / 持续优化）
- `pillars`：六大支柱评分数组，每项含 `id`（A-F）、`name`（支柱名称）、`score`（得分）、`max`（满分）
- `todos`：改进任务列表数组

**todos 字段说明**：
- `title`：任务标题，简洁可操作（≤30 字）
- `solution`：改进方案，具体说明操作步骤（≤100 字）

**评分提取规则**：
- 从报告「总览评分」表格中提取总分和各支柱得分
- 从「成熟度等级」章节提取 level 和 level_name
- 数值必须与报告一致，不可二次计算或估算

**Todo 语义处理规则（路径 A：来自 Todo Suggestions 表格）**：
- 保留原始表格中的所有改进项，不增删
- 对内容进行适当清理（去除多余空白、Markdown 格式符号等），但不改变语义
- 如果表格中某行内容不完整（缺少标题或方案），跳过该行

**Todo 语义处理规则（路径 B：来自全文语义理解）**：
- 重点关注：评分明细中的 FAIL / PARTIAL 项、优先改进建议、反模式检测中的问题、熵管理评估中的高风险项
- 提炼 3-7 条最具价值的可执行改进项

## Step 3：格式验证（循环直到通过）

将生成的 JSON 写入临时文件，然后运行验证脚本：

```bash
# 创建临时目录
TMPDIR=$(mktemp -d)
echo '<生成的JSON内容>' > "$TMPDIR/sop_todo.json"

# 运行验证脚本（脚本位于 $SKILL_DIR，与 skill 是用户级/项目级安装无关）
python3 "$SKILL_DIR/scripts/validate_todo_json.py" "$TMPDIR/sop_todo.json"
```

**验证规则**（由脚本强制执行）：
- 顶层结构必须是 JSON 对象
- 必须包含 `total_score`（数值 0-100）、`max_score`（固定 100）、`level`（字符串 L0-L4）、`level_name`（非空字符串）、`pillars`（数组）、`todos`（数组）
- `pillars` 必须有 6 个元素，每个含 `id`（A-F）、`name`（非空字符串）、`score`（数值 ≥0）、`max`（数值 >0）且 score ≤ max
- `todos` 长度在 1-20 之间，每个元素仅含 `title` 和 `solution` 两个非空字符串字段

**如果验证失败**：根据错误信息修正 JSON，重新验证，直到通过。

## Step 4：输出结果

验证通过后，输出临时文件路径：

```
✅ JSON 生成完成
   文件路径：<TMPDIR>/sop_todo.json
   总分：<total_score>/100  等级：<level> <level_name>
   改进任务：<N> 条
```

# 约束
- 只读报告文件，不修改任何源码
- JSON 必须通过验证脚本校验
- 评分数据必须与报告一致，不可估算
- 不允许出现空字段或多余字段
```

### 6.2 主 Agent 汇报

子 Agent 完成后，主 Agent 在控制台补充输出：

```
📄 JSON 报告已生成
   路径：/tmp/xxx/sop_todo.json
   总分：72/100  等级：L3 流程闭环
   改进任务：N 条
   可直接用于前端解析或导入任务系统
```

---

## 评估护栏

- **只读审计** —— 全过程不修改任何源代码、配置、规约文件，写入仅限 `.harness/sop_report.md` 和 `--json` 模式下的临时目录
- **证据优先** —— 每项 Eval 必有文件路径或命令输出；无证据则 FAIL，不要靠"我感觉"
- **代码 Grader 优先** —— 能用 `ls`/`grep`/`git log` 确定的，绝不上模型
- **诚实评分** —— PARTIAL 是真实状态的合理表达；不为了"数字好看"虚报 PASS
- **可执行改进** —— 每条建议必须能转换成 `mkdir`/`touch`/`echo`/`配置工具`/`补章节`等具体动作
- **SOP 视角** —— 始终从「项目是否符合团队 SOP v1.0」评估，不评代码本身的好坏
- **反模式必做** —— 即便整体评分高，也要扫，并在结论中明确标记
- **绝不擅自 commit** —— 报告写入后，由用户审阅再提交；本 Skill 永不执行 `git add` / `git commit`

---

## 输出示例（精简）

```
项目：did-mgr-backend
评估日期：2026-05-18
SOP 版本：v1.0

总分：72 / 100   等级：L3 流程闭环

支柱得分：
  A. 项目 AI 友好化         22 / 25  🟢
  B. 开发模式 / 角色协作    11 / 15  🟢
  C. 质量检查与反馈机制     17 / 25  🟡
  D. 设计与变更管理          12 / 15  🟢
  E. 公共资料库              3 / 5   🟢
  F. 度量机制                7 / 15  🟡

反模式：
  🔴 .harness/docs/failures.md 60+ 天无更新（反馈机制未运转）
  🟢 其余 5 项未发现

高优改进（3 条）：
  1. C5 - failures.md 活跃化：本周补 3 条最近踩坑记录
  2. F1 - sop_report.md 定期更新：把 sop.report 加入月度评审议程
  3. C1 - 提交/push 规范记忆化：AGENTS.md 补 commit message 格式 + 提交前检查 + push 流程约定

报告：.harness/sop_report.md
```

---

## 与其他 Skill 集成

### 与 `sop.init` 的关系

- `sop.init`（新版 specs-sop）：从零搭建 `.harness/` SOP 体系（创建 AGENTS.md 四章式入口 + `.harness/docs/` 规约库 + `.harness/plans/` 任务模板 + 软链接）
- `sop.eval`（本 Skill）：评估 sop.init 的产出和后续维护质量
- 推荐顺序：先 `sop.init` 搭骨架 → 再 `sop.eval` 跑基线 → 后续每月用 `sop.eval --diff-from=...` 追踪改进

> `sop.init` 明确把 `.harness/sop_report.md` 留给本 Skill 创建。

### 与 CI 集成（可选）

> 本项目使用 **Jenkins** 作为 CI 平台。

- 在 Jenkins Pipeline 中加 stage 调用 `sop.eval --dry-run`，把评分写入构建日志/归档为 `.harness/sop_report.md` 工件
- 总分跌破阈值（如 60 分）时，用 `currentBuild.result = 'UNSTABLE'` 标记构建（避免硬门禁导致流程僵化，不用 FAILURE）
- 推荐配合 Jenkins Build Discarder + `archiveArtifacts '.harness/sop_report.md'` 保留历史评估对比

---

## 相关资料

- 评分标准详表：`references/sop-scoring-criteria.md`
- 报告模板：`references/sop-report-template.md`
- 改进建议示例库：`references/sop-improvement-examples.md`
