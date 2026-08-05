# SOP 评分标准（详细判定逻辑）

本文档为 `sop.eval` skill 提供 28 项 Eval 的判定标准、证据来源、命令示例和 PARTIAL 边界。子 Agent 在执行扫描时必读对应支柱章节。

> 评判依据：团队 AI 研发工作流 SOP v1.0
> 评分映射：✅ PASS = 满分，⚠️ PARTIAL = 满分 × 40%，❌ FAIL = 0

---

## 支柱 A：项目 AI 友好化（25 分）

### A1：AGENTS.md 存在且 ≤300 行 + 四章完整（3 分）

**SOP 依据**：§1.1「AI 入口文件 根目录 AGENTS.md（≤300 行）」+ 四章结构完整性

**代码 Grader**：
```bash
[ -f AGENTS.md ] && wc -l < AGENTS.md
```

**模型 Grader**（章节检查）：
```bash
# 检查四章完整性
grep -c "^## 一、快速索引" AGENTS.md
grep -c "^## 二、SOP" AGENTS.md
grep -c "^## 三、开发准则" AGENTS.md
grep -c "^## 四、禁止红线" AGENTS.md
```

**判定**：
- ✅ PASS：文件存在 + 行数 ≤300 + 四章（一、快速索引 / 二、SOP / 三、开发准则 / 四、禁止红线）均存在且非空
- ⚠️ PARTIAL：文件存在但 300-500 行（接近超限），或文件存在但四章缺 1-2 章，或文件存在但 <30 行（过于浅薄）
- ❌ FAIL：不存在

> Grader 类型：代码（行数）+ 模型（章节检查）。

---

### A2：README.md 完整（5 分）

**SOP 依据**：§1.1「项目介绍 README.md：项目背景与业务目标、核心功能清单、上下游依赖、快速启动、部署环境要求、注意事项」

**模型 Grader**：扫描 README.md，统计是否覆盖以下 6 类信息：
1. 项目背景 / 业务目标
2. 核心功能清单
3. 上下游依赖
4. 快速启动（命令）
5. 部署环境要求
6. 注意事项 / 已知限制

**判定**：
- ✅ PASS：6 类信息至少覆盖 5 类
- ⚠️ PARTIAL：覆盖 3-4 类
- ❌ FAIL：覆盖 ≤2 类，或仅有项目名 + 一句话描述

---

### A3：.harness/docs/architecture.md 完整（5 分）

**SOP 依据**：新版 specs-sop 将架构文档迁入 `.harness/docs/architecture.md`（根目录 `ARCHITECTURE.md` 为旧版残留，按迁移反模式处理）。内容要求：整体架构图、模块划分与边界、数据流向、技术选型理由、核心设计决策、已知技术债。

**模型 Grader**：扫描 `.harness/docs/architecture.md` 是否覆盖：
1. 整体架构图（文字描述或图片引用 / Mermaid）
2. 模块划分与边界
3. 数据流向
4. 技术选型理由
5. 核心设计决策
6. 已知技术债

**判定**：
- ✅ PASS：6 项至少覆盖 5 项，且非占位模板（系统定位非 `<项目名>`、模块划分表 ≥1 行有效数据、总体视图非通用占位框图）
- ⚠️ PARTIAL：覆盖 3-4 项，或文件存在但仍是空模板/占位内容
- ❌ FAIL：文件不存在或仅占位

> 占位识别：见文末「占位模板识别规则」。

---

### A4：.harness/docs/ 规约库覆盖新版核心文档（5 分）

**SOP 依据**：新版 specs-sop 的 `.harness/docs/` 标准布局（§1.2 核心文档 + 子目录文档）。

**必选核心文档（存在且非占位即计 OK）**：
- `architecture.md`（系统定位/模块划分/视图）
- `relationship.md`（上下游关系，**替代旧版 `dependency-map.md`**）
- `coding-style.md`
- `code-review.md`
- `glossary.md`
- `failures.md`
- `logging.md`
- `unittest/unittest.md`（**替代旧版 `testing.md`**）
- `integration_test/integration_test.md`

**按需子目录文档**（无对应能力可缺省，不扣分；缺失仅报告中标注）：
- `apis/index.md` + `apis/api-standards.md` —— 无对外接口项目可缺省（注明"无接口"即可）
- `sqls/README.md` + `sqls/database.md` —— 无数据库项目可缺省（注明"无数据库"即可）
- `devops/deployment.md` / `devops/development.md` / `devops/env.md` / `devops/test-env-deploy.md` —— 库项目可部分缺省

**核心判定哲学（来自 specs-checklist）**：**「文件存在」≠「内容充实」**。每个文档必须超越初始占位模板（见文末「占位模板识别规则」），仅含标题 + 空表格 + `<填>`/`TODO` 占位符的文档视为未填充，按缺失处理。

**代码 Grader**：
```bash
# 必选文档（9 份）—— 缺存在/缺内容直接影响评分
REQUIRED="architecture relationship coding-style code-review glossary failures logging unittest/unittest integration_test/integration_test"
req_ok=0; req_total=9; skeleton=0
for f in $REQUIRED; do
  if [ -f .harness/docs/$f.md ]; then
    lines=$(wc -l < .harness/docs/$f.md)
    # 占位判定：≤10 行 或 几乎全是占位符/空表格
    if [ "$lines" -le 10 ]; then
      skeleton=$((skeleton+1)); echo "SKELETON $f ($lines lines)"
    else
      req_ok=$((req_ok+1)); echo "OK $f"
    fi
  else
    echo "MISSING $f"
  fi
done

# 按需子目录文档（仅报告，不影响判定，按项目能力裁剪）
for f in .harness/docs/apis/index.md .harness/docs/sqls/README.md \
         .harness/docs/devops/deployment.md .harness/docs/devops/development.md \
         .harness/docs/devops/env.md .harness/docs/devops/test-env-deploy.md \
         .harness/review.md; do
  if [ -f "$f" ]; then
    lines=$(wc -l < "$f")
    [ "$lines" -gt 10 ] && echo "OPTIONAL_OK $f"
  fi
done

echo "Required(non-skeleton): $req_ok/$req_total (skeleton: $skeleton)"
```

**判定**（仅基于 9 份必选文档的内容充实度）：
- ✅ PASS：9 份必选全存在 + 每份非空（>10 行且非占位）；按需文档按项目能力裁剪不强制
- ⚠️ PARTIAL：必选存在且非占位 5-8 份（含 skeleton 算缺失），或 9 份都在但 ≥3 份为空骨架（≤10 行/纯占位）
- ❌ FAIL：必选 ≤4 份存在或非占位

> **等价识别**：若项目用 `docs/design.md` 替代 `architecture.md`、用其他命名承载等价内容，只要信息等价即同等对待，不重复扣分（遵循 specs-checklist 评估哲学）。
> 注：`sop_report.md` 不计入本项（它就是本 Skill 的产出物，由 F1 评估）。
> 注：按需文档缺失不影响 PASS/PARTIAL/FAIL 判定。

---

### A5：多工具软链接入库（2 分）

**SOP 依据**：§1.2「屏蔽工具差异（软链接方案）」

**代码 Grader**：
```bash
# 候选软链接路径（只检测对应配置目录已存在的工具）
# - CODEBUDDY.md：当 .codebuddy/ 目录存在时检测
# - CLAUDE.md（仓库根）：当 .claude/ 目录存在时检测

ok=0; total=0
check_link() {
  local dir="$1" link="$2"
  [ -d "$dir" ] || return   # 工具未使用，跳过
  total=$((total+1))
  if [ -L "$link" ] && [ "$(readlink "$link")" = "AGENTS.md" -o "$(readlink "$link")" = "../AGENTS.md" ]; then
    ok=$((ok+1)); echo "OK $link"
  else
    echo "MISSING/WRONG $link"
  fi
}
check_link ".codebuddy" "CODEBUDDY.md"
check_link ".claude"    "CLAUDE.md"

# 如果没有任何工具目录，至少检测 CODEBUDDY.md（最常见）
if [ "$total" -eq 0 ]; then
  total=1
  [ -L "CODEBUDDY.md" ] && ok=1
fi

# 检查关键文件未被 .gitignore
grep -E "AGENTS\.md|ARCHITECTURE\.md|\.harness/" .gitignore 2>/dev/null && echo "FAIL: 关键文件被 .gitignore"
```

**判定**（仅对项目实际使用的 AI 工具打分，不要求补建未使用工具的软链）：
- ✅ PASS：所有已使用工具的软链接全部正确 + 关键文件未被 ignore
- ⚠️ PARTIAL：已使用工具中有 1 个软链接缺失/错误，或软链接正确但 .gitignore 包含关键文件
- ❌ FAIL：已使用工具中 ≥2 个软链接缺失，或 AGENTS.md 被 ignore

> **重要**：不要建议项目补建其未使用的 AI 工具软链接（如团队不使用 Claude Code，不要建议建 CLAUDE.md）。只对「工具目录已存在但软链接缺失」的情况给出改进建议。

---

### A6：一键启动命令（3 分）

**SOP 依据**：§1.1「一键启动 确保项目具备 make dev 或等效命令，一条跑通」

**代码 Grader**：
```bash
# Go 项目
grep -E '^(dev|run|start):' Makefile 2>/dev/null

# JS/TS 项目
node -e "console.log(JSON.stringify(require('./package.json').scripts))" 2>/dev/null | grep -iE '"(dev|start)"'

# Python 项目
grep -E '(dev|start)' Makefile pyproject.toml 2>/dev/null
```

**判定**：
- ✅ PASS：存在 `make dev` / `npm run dev` / `make run` 或等效目标，且 README 提及
- ⚠️ PARTIAL：命令存在但未文档化，或文档提及但实际命令不通
- ❌ FAIL：无任何一键启动入口

---

### A7：环境配置模板（2 分）

**SOP 依据**：§1.1「AI/新人 30 分钟内跑通项目」的隐含前提

**代码 Grader**：
```bash
ls .env.example .env.template .env.sample env.example 2>/dev/null
grep -l "环境变量\|ENV\|配置" README.md .harness/docs/devops/development.md 2>/dev/null
ls docker-compose.yml docker-compose.yaml 2>/dev/null
```

**判定**：
- ✅ PASS：`.env.example` 或等效配置模板存在，或 `README`/`development.md` 中明确列出所需环境变量清单
- ⚠️ PARTIAL：仅在 `docker-compose.yml` 中隐含环境变量配置，无独立说明文档
- ❌ FAIL：无任何环境配置模板或说明，新开发者需要猜测配置

---

## 支柱 B：开发模式 / 角色协作（15 分）

### B1：研发流程 9 步明确（5 分）

**SOP 依据**：§2.1「整体流程：Clarify → Plan → Implement → UT → Deploy → IT → Docs → Review → Commit」

**模型 Grader**：检查 AGENTS.md「二、SOP」中是否描述了完整的 9 步 plans 流程。

**代码 Grader**：
```bash
grep -cE "Clarify|Plan|Implement|UT|Deploy|IT|Docs|Review|Commit" AGENTS.md
```

**判定**：
- ✅ PASS：明确文档化 9 步流程（或合理裁剪后的 ≥7 步），且每步说明产出物或工具
- ⚠️ PARTIAL：流程提及但只有 3-6 步，或只有步骤名无产出物说明
- ❌ FAIL：无任何流程描述

---

### B2：角色职责约定（4 分）

**SOP 依据**：§（角色职责划分）产品/测试/研发各 4-6 条职责

**模型 Grader**：搜索 "角色职责"、"产品经理"、"测试"、"研发" 等关键词，在 AGENTS.md / README.md / docs/ 中定位。

**判定**：
- ✅ PASS：三个角色（PM/QA/RD）职责均有 ≥3 条具体说明
- ⚠️ PARTIAL：只覆盖 1-2 个角色，或职责浅泛（"做好需求"这种）
- ❌ FAIL：完全无角色定义

---

### B3：阶段产出物有归属位置（4 分）

**SOP 依据**：§2.1 各阶段（设计、子任务、单测）需有明确产出位置

**代码 Grader + 模型**：
- 检查 `.harness/plans/` 目录是否存在
- 检查 `.harness/plans/_template/` 模板目录是否存在（含 10 文件）
- 检查是否有已创建的任务目录（含 `00-overview.md`）

```bash
ls -d .harness/plans/ 2>/dev/null
ls -d .harness/plans/_template/ 2>/dev/null
find .harness/plans -maxdepth 2 -name 00-overview.md 2>/dev/null | wc -l
```

**判定**：
- ✅ PASS：`.harness/plans/_template/` 存在 + ≥1 个已创建任务目录（含 00-overview.md）
- ⚠️ PARTIAL：`_template/` 存在但无历史任务目录
- ❌ FAIL：`.harness/plans/` 不存在或空

---

### B4：分支命名规范 + Commit Message 规范（2 分）

**SOP 依据**：§2 流程约定 + §3.2 禁止项（commit message 不规范）

**代码 Grader + 模型**：
```bash
# 检查 commitlint / conventional commit 配置
ls commitlint.config.* .commitlintrc* .czrc 2>/dev/null
grep -l "commit" lefthook.yml .husky/commit-msg 2>/dev/null

# 检查分支命名规范文档
grep -iE "分支|branch|feat/|fix/|hotfix/|命名" .harness/docs/devops/development.md .harness/docs/code-review.md AGENTS.md 2>/dev/null
```

**判定**：
- ✅ PASS：Commit 规范文档化（Conventional Commits 或等效）+ 分支命名规范有文档承载
- ⚠️ PARTIAL：仅文档提及但无强制工具（commitlint/hook），或仅有分支规范无 commit 规范
- ❌ FAIL：完全无分支/commit 规范文档

---

## 支柱 C：质量检查与反馈机制（25 分）

### C1：提交 / Push 规范记忆化（AGENTS.md / .codebuddy/rules 定义 commit + push 规范）（5 分）

**SOP 依据**：§3.1「提交前/commit：build + lint + 单测 + 禁止项检查 → 阻断提交」

> **架构说明**：本 Skill 运行在服务器上（拉取仓库代码执行评估），`.git/hooks/` 不随代码分发，无法作为证据。改为评估等效目标：**commit / push 的行为规范是否写进 AI 可读的项目记忆文件**（`AGENTS.md` 与 `.codebuddy/rules/` 下的规则文件）。规则入记忆文件后，AI 与人协作时才有可遵循的门禁约定。

**代码 Grader**：
```bash
# 记忆文件存在性
ls AGENTS.md 2>/dev/null
ls .codebuddy/rules/ 2>/dev/null

# commit 规范信号：message 格式 / 提交前检查 / 单号关联 / amend 约束
grep -inE 'commit|提交' AGENTS.md .codebuddy/rules/*.md 2>/dev/null | head -15

# push 规范信号：push 前检查 / MR 流程 / force push 约束 / 禁止直推
grep -inE 'push|推送|force-with-lease|MR|合并' AGENTS.md .codebuddy/rules/*.md 2>/dev/null | head -15
```

**模型 Grader**：阅读命中段落，判断规则是否具体可执行（含明确命令 / 格式 / 禁止项），而非「注意提交规范」式空话。

**判定**：
- ✅ PASS：记忆文件中**同时**定义了 commit 规范（如 message 格式、提交前必跑 build/lint/test、单号关联 `--story=` / `--bug=`、一个 MR 一个 commit / amend 约束）**和** push 规范（如 push 前检查、push 后 MR 流程、`--force-with-lease` 约束、禁止直推受保护分支），且规则具体可执行
- ⚠️ PARTIAL：仅定义了其中一类（有 commit 规范无 push 规范，或反之），或两类均有提及但仅为泛泛一句话、无可执行细节
- ❌ FAIL：`AGENTS.md` 与 `.codebuddy/rules/` 中均无提交 / push 相关规范（含两者都不存在的情况）

> ⚠️ **与相邻 Eval 的边界**：B4 评「分支命名 + Commit Message 格式约定」；C4 评「分支保护与 Review 流程文档」；C1 评「**提交与推送行为的规则约束是否进入 AI 记忆文件**」——同一段文字可同时支撑多项，不重复扣分也不互相豁免。
>
> ⚠️ **防误命中**：不要把「9 步流程里有 Commit 步骤名」当作 commit 规范——必须有对 commit / push 行为本身的约束条款（格式、前置检查、禁止项）才算。

---

### C2：CI 流水线全量单测 + 覆盖率门禁（5 分）

**SOP 依据**：§3.1「CI（提交后/MR前）：全量单测（覆盖率）+ 接口测试（全量）+ 集成测试 + code review → 阻断合并」

**代码 Grader**：
```bash
# 路径 ①：仓库内 Jenkinsfile 入库（最强证据）
ls Jenkinsfile Jenkinsfile.* jenkins/ .jenkins/ 2>/dev/null

# 路径 ②：README.md 或 .harness/docs/devops/development.md 明确写出 CI/CD 平台 URL
#   认可平台：Jenkins / ArgoCD / Argo CD / 智研
#   匹配方式：同一行中既提到平台名又包含 http(s):// 链接（URL 可以是 IP 地址）
grep -iE '(jenkins|argocd|argo.?cd|zhiyan|智研).*https?://|https?://.*(jenkins|argocd|argo.?cd|zhiyan|智研)' \
  README.md .harness/docs/devops/development.md AGENTS.md 2>/dev/null | head -5

# 覆盖率门禁（Jenkinsfile/Makefile 中通常用 cobertura/jacoco 或 shell 校验）
grep -rE 'coverage|COVERAGE_THRESHOLD|cover|cobertura|jacoco' \
  Makefile Jenkinsfile jenkins/ 2>/dev/null
```

**判定**（路径 ① 或 ② 任一命中即认定有 CI）：
- ✅ PASS：满足任一路径 + 跑单测 + 有覆盖率阈值
  - 路径 ①：Jenkinsfile 入库 + stages 含单测 + 含覆盖率门禁逻辑
  - 路径 ②：README/development.md 写出 Jenkins/Argo CD/智研 URL + 文档说明流水线包含单测与覆盖率门禁
- ⚠️ PARTIAL：
  - 路径 ① 命中但 Jenkinsfile 只跑 build/lint 无单测，或有单测无覆盖率门禁
  - 路径 ② 命中但文档未说明 stages 内容/无覆盖率门禁说明
  - 仅提平台名（如「用 Jenkins 跑 CI」）但无 URL
- ❌ FAIL：仓库内无 Jenkinsfile，且 README/development.md 中找不到 Jenkins/Argo CD/智研 URL

> **核心规则**：URL 必须是可点击的 http(s):// 链接，光写「我们用 Jenkins」不算 PASS（AI/新人仍无法直达流水线）。

---

### C3：禁止项防护（4 分）

**SOP 依据**：§3.2 禁止项清单

**代码 Grader + 模型**：
```bash
# 1. .gitignore 是否覆盖敏感文件和生成物
grep -E '\.env|\.pem|\.key|vendor/|node_modules/|dist/|\.exe' .gitignore

# 2. 当前是否有违规已提交文件
git ls-files | grep -E '\.env$|\.pem$|\.key$|^vendor/|^node_modules/'

# 3. 是否在 .harness/docs/code-review.md 或 PreCommit Hook 中明确禁止项
grep -iE '禁止|不允许|不能' .harness/docs/code-review.md .harness/docs/coding-style.md 2>/dev/null
```

**判定**：
- ✅ PASS：.gitignore 完整 + 无违规文件已提交 + 文档明确列出禁止项
- ⚠️ PARTIAL：.gitignore 完整但禁止项未文档化，或文档化但 .gitignore 缺漏
- ❌ FAIL：.gitignore 严重缺失或已提交敏感文件

---

### C4：分支保护与 Review 流程（3 分）

**SOP 依据**：§3.2 流程约定（绕过 Review、直推 main、PR 超 500 行、未关联单号 等禁止项）

**模型 Grader**：在 `.harness/docs/code-review.md` 或 README/AGENTS 中查找：
- 禁止直推 main / master
- PR 必须关联需求单号
- PR 行数限制
- Review 通过才能合并

**判定**：
- ✅ PASS：≥3 条流程约束有文档
- ⚠️ PARTIAL：1-2 条
- ❌ FAIL：完全无文档（即便平台已配，也算 FAIL）

---

### C5：反馈机制 / failures.md 活跃（3 分）

**SOP 依据**：§3.3 反馈机制 + §3.4 「每两周回顾 failures.md」

**代码 Grader**：
```bash
# 文件存在 + 行数
wc -l .harness/docs/failures.md 2>/dev/null

# 90 天内是否有提交
git log --since='90 days ago' --oneline -- .harness/docs/failures.md | wc -l
```

**判定**：
- ✅ PASS：存在 + ≥30 行 + 90 天内有提交
- ⚠️ PARTIAL：存在但 <30 行，或 90 天无提交但内容丰富
- ❌ FAIL：不存在或仅占位（<10 行）

---

### C6：安全扫描 / 依赖漏洞检测（2 分）

**SOP 依据**：§3.2 禁止项「提交含漏洞的依赖」+ 行业安全基线

> **工具口径**：团队 Go 项目不再单独使用 `gosec` 二进制，统一通过 `golangci-lint` 承载（sop.init 注入的 `.golangci.yml` 默认在 `linters.enable` 中启用 `gosec`）。Go 项目的主证据是 **`.golangci.yml` 中 `gosec` 处于启用状态**。

**代码 Grader**：
```bash
# 1. Go 项目主路径：.golangci.yml 启用 gosec
ls .golangci.yml .golangci.yaml 2>/dev/null
# gosec 出现在 enable 列表（PASS 信号）
grep -A30 'enable:' .golangci.yml .golangci.yaml 2>/dev/null | grep -E '^\s*-\s*gosec'
# gosec 出现在 disable 列表（否定信号，命中则不算启用）
grep -A30 'disable:' .golangci.yml .golangci.yaml 2>/dev/null | grep -E '^\s*-\s*gosec'

# 2. 其它安全扫描工具配置 / CI 集成（trivy / snyk / govulncheck / sonar 等）
ls .trivyignore .snyk 2>/dev/null
grep -rE "trivy|snyk|renovate|npm.audit|safety|govulncheck|sonar" \
  Jenkinsfile jenkins/ Makefile lefthook.yml .github/ .gitlab-ci.yml 2>/dev/null

# 3. 检查 .harness/docs 文档中是否声明了外部 CI 仓库集成的安全扫描
#   （安全扫描配置可能在独立的 CI/Argo Workflow 仓库中，需在 development.md 声明仓库地址和工具）
grep -iE 'gosec|golangci|trivy|snyk|sonar|govulncheck|安全扫描|漏洞|security' \
  .harness/docs/devops/development.md .harness/docs/devops/deployment.md 2>/dev/null
# 确认是否声明了外部 CI 仓库地址（含 URL 即可追溯）
grep -E 'https?://' .harness/docs/devops/development.md .harness/docs/devops/deployment.md 2>/dev/null | \
  grep -iE 'ci|workflow|pipeline|argo|安全|scan'

# 4. Renovate（项目不用 Dependabot）
ls renovate.json renovate.json5 .renovaterc 2>/dev/null
```

**判定**：
- ✅ PASS：满足任一：① Go 项目 `.golangci.yml` / `.golangci.yaml` 存在且 `gosec` 在 `linters.enable` 中（未出现在 disable 列表）；② 本地有其它安全扫描工具配置文件；③ 本地 CI 配置（Jenkinsfile/Makefile）含安全扫描；④ Argo Workflow 或外部 CI yaml 中集成安全扫描；⑤ .harness/docs 文档中明确声明安全扫描集成在外部 CI 流水线中（含工具名和位置说明）；⑥ Renovate 配置存在
- ⚠️ PARTIAL：`.golangci.yml` 存在但未启用 `gosec`（lint 体系在、缺安全 linter）；或仅有 Renovate 但无主动漏洞扫描；或 .harness/docs 文档提及安全扫描但未说明具体工具/位置；或配置存在但规则为空
- ❌ FAIL：无 `.golangci.yml` 或启用列表为空，且无任何其它安全扫描配置，.harness/docs 文档中也未声明外部 CI 集成安全扫描

---

### C7：E2E / 集成测试存在性（3 分）

**SOP 依据**：§3.1「接口测试（全量）+ 集成测试 → 阻断合并」

**代码 Grader**：
```bash
# 检查 E2E/集成测试目录
ls -d tests/e2e/ tests/integration/ test/e2e/ e2e/ integration/ 2>/dev/null

# 检查集成测试文件（Go / JS / Python）
find . -name '*integration*test*' -o -name '*e2e*test*' -o -name '*_integration_test.go' 2>/dev/null | head -5

# 检查 CI 中是否有 E2E/集成测试 stage
# 检查 CI 中是否有 E2E/集成测试 stage（项目使用 Jenkins）
grep -iE "e2e|integration.test|接口测试" Jenkinsfile jenkins/ Makefile .harness/docs/devops/deployment.md 2>/dev/null
# 兼容其他平台
grep -iE "e2e|integration.test|接口测试" .github/workflows/*.yml .gitlab-ci.yml 2>/dev/null
```

**判定**：
- ✅ PASS：有独立的 E2E/集成测试目录 + 文件非空 + CI 中有对应步骤
- ⚠️ PARTIAL：有集成测试文件但无 CI 集成，或 CI 有步骤但测试目录为空
- ❌ FAIL：完全无 E2E/集成测试痕迹

---

## 支柱 D：设计与变更管理（15 分）

> 统一采用 `.harness/plans/` 体系管理所有变更（Clarify → Plan → Implement → UT → Deploy → IT → Docs → Review → Commit）。

---

### D1：任务目录存在且有实质内容（4 分）

**SOP 依据**：§4「设计先于编码」— 通过 `.harness/plans/` 体系管理变更

**代码 Grader**：
```bash
# 检查 plans/ 下任务目录数（排除 _template）
task_dirs=$(find .harness/plans -mindepth 1 -maxdepth 1 -type d -not -name '_template' 2>/dev/null | wc -l)

# 检查每个任务目录的 10 文件完整性
find .harness/plans -mindepth 1 -maxdepth 1 -type d -not -name '_template' 2>/dev/null | while read d; do
  files=$(ls "$d"/*.md 2>/dev/null | wc -l)
  echo "$d: $files step files"
done
```

**判定**：
- ✅ PASS：≥1 个任务目录，且至少 1 个包含 ≥8 个步骤文件（00-overview.md + 01-09）
- ⚠️ PARTIAL：有任务目录但文件不全（1-7 个步骤文件）
- ❌ FAIL：无任务目录或仅有 `_template/`

---

### D2：00-overview.md 维护活跃度（4 分）

**SOP 依据**：§4「设计先于编码」— 任务总览文件持续维护

**代码 Grader**：
```bash
# 检查 plans/ 下 00-overview.md 的最近更新
find .harness/plans -name 00-overview.md -not -path '*/_template/*' -exec git log -1 --format='%cI' {} \; 2>/dev/null | sort -r | head -1
```

**判定**：
- ✅ PASS：近 90 天内有任务 `00-overview.md` 的 git 更新
- ⚠️ PARTIAL：有任务目录但 90 天内无更新
- ❌ FAIL：无任务 `00-overview.md`

---

### D3：小变更 TDD/回归测试 + 模板完整性（4 分）

**SOP 依据**：§4.2「Bug 修复必须附带回归测试」+ §3.1「单测门禁」

**代码 Grader + 模型**：
```bash
# 检查 plans/_template/ 下 10 文件完整性
ls .harness/plans/_template/ 2>/dev/null | wc -l

# TDD 要求（新版在 unittest/unittest.md；旧版 testing.md 视为待迁移）
grep -iE 'TDD|先写测试|回归测试' .harness/docs/unittest/unittest.md AGENTS.md 2>/dev/null
```

**判定**：
- ✅ PASS：`_template/` 含 10 个文件 + TDD 在 `unittest/unittest.md` 或 `AGENTS.md` 中明确
- ⚠️ PARTIAL：模板存在但 <10 文件，或 TDD 仅口头约定，或仅在旧版 `testing.md` 中（待迁移）
- ❌ FAIL：模板不存在且无 TDD 要求

---

### D4：变更分级标准文档化（3 分）

**SOP 依据**：§4.1 变更分级规则

**模型 Grader**：
```bash
grep -iE "分级|大型|中型|小型|人天|变更规模|影响范围" \
  .harness/docs/devops/development.md AGENTS.md .harness/docs/code-review.md 2>/dev/null
```

在 `.harness/docs/devops/development.md`、`AGENTS.md` 或 `.harness/docs/code-review.md` 中查找变更分级定义。

**判定**：
- ✅ PASS：文档中明确定义了大/中/小变更的判定标准（如人天阈值、影响模块数、代码行数等），并指出各级对应的流程
- ⚠️ PARTIAL：仅提到「大中小变更」概念但无明确判定标准，或标准模糊
- ❌ FAIL：无变更分级说明

---

## 支柱 E：公共资料库（5 分）

### E1：项目内 Skills 沉淀目录（2 分）

**SOP 依据**：§5.1「Skills & Hooks：好用的 skill 文件」

**代码 Grader**：
```bash
ls -d .codebuddy/skills/ 2>/dev/null
ls .codebuddy/skills/*/SKILL.md 2>/dev/null | wc -l
```

**判定**：
- ✅ PASS：`skills/` 存在 + ≥3 份 SKILL.md（含本 Skill 自身）
- ⚠️ PARTIAL：仅 1-2 份 Skill
- ❌ FAIL：无任何沉淀目录

---

### E2：知识沉淀完整度（3 分）

**SOP 依据**：§5「公共资料库：建设共享知识沉淀空间」——SOP 不限制沉淀位置，本地仓库内的 `.harness/docs/` 与远程 wiki 同等价值，本地沉淀甚至更利于 AI 直接消费。

**判据**：满足以下任一路径即 PASS（三选一）。

**路径 ① `.harness/docs/` 文档数量（代码 Grader）**：
```bash
# .harness/docs/ 下 Markdown 文档数
find .harness/docs/ -name '*.md' 2>/dev/null | wc -l
```
- `.harness/docs/` 下 ≥10 篇 Markdown 文档 → PASS

**路径 ② 远程团队知识库引用（代码 Grader + 模型 Grader）**：
```bash
# 检查 README/AGENTS 中是否有外部知识库链接
# 认可关键字：wiki、confluence、tapd（含 markdown_wikis）、notion、语雀、飞书、共享仓库等
grep -iE '(wiki|confluence|tapd|notion|yuque|语雀|feishu|飞书|knowledge|文档中心)' \
  README.md AGENTS.md 2>/dev/null | grep -E 'https?://'
```
- 同一行或同一文件中既有知识平台关键字又有 http(s):// 链接 → 代码 Grader 命中
- 模型 Grader 辅助确认：链接指向有效的团队知识库且有用途说明 → PASS

**路径 ③ `.harness/plans/` 任务数（代码 Grader）**：
```bash
# .harness/plans/ 下任务目录数（排除 _template）
find .harness/plans -mindepth 1 -maxdepth 1 -type d -not -name '_template' 2>/dev/null | wc -l
```
- ≥3 个已创建任务目录 → PASS

**判定**：
- ✅ PASS：满足 ①/②/③ 任一
- ⚠️ PARTIAL：`.harness/docs/` 有 1-9 篇，或仅提及外部资料但无链接，或 `.harness/plans/` 有 1-2 个任务目录
- ❌ FAIL：完全无沉淀痕迹

---

## 支柱 F：度量机制（15 分）

### F1：sop_report.md 存在并定期更新 + 改进行动有记录（5 分）

**SOP 依据**：§6.1「SOP 度量 Skill，度量各项目的建设情况，并输出评分」

本项拆为两个子维度，解决"跑 eval 即 PASS"的自指悖论：

#### F1a：报告存在且非首次（2 分）

**代码 Grader**：
```bash
[ -f .harness/sop_report.md ] && \
  git log --oneline -- .harness/sop_report.md 2>/dev/null | wc -l
```

**判定**：
- ✅ PASS：文件存在 + git 历史有 ≥2 次提交（说明不是第一次评估）
- ⚠️ PARTIAL：文件存在但仅 0-1 次提交（首次评估或刚入库）
- ❌ FAIL：文件不存在

> **首次评估特殊处理**：本次执行即创建该文件，自动计为 ⚠️ PARTIAL（不惩罚新项目）。

#### F1b：报告中有明确的改进跟踪记录（3 分）

**代码 Grader + 模型**：
```bash
# 检查报告中是否有"与上次评估对比"章节且非空
grep -A5 "与上次评估对比" .harness/sop_report.md 2>/dev/null | grep -E "↑|↓|PASS|PARTIAL|FAIL"

# 或检查 .harness/ 中是否有改进跟踪文件
ls .harness/sop_improvements.md .harness/sop_changelog.md 2>/dev/null
```

**判定**：
- ✅ PASS：报告中有非空的"与上次评估对比"章节（含具体的升降记录），或存在独立的改进跟踪文件记录了 FAIL→PASS 的行动
- ⚠️ PARTIAL：报告存在但无对比章节（仅首次评估，或历次评估未对比），或对比章节仅占位无实质内容
- ❌ FAIL：无法证明团队 acted upon 评估结果（报告不存在，或存在但从未有对比/改进记录）

> **核心逻辑**：F1 度量的不是"有人记得跑命令"，而是"团队根据评估结果采取了行动"。

---

### F2：AI 会话/记忆/失败 case 留存（4 分）

**SOP 依据**：§6.2「关键 AI 会话保留日志（Prompt + 输出）/ 失败 case 沉淀」——SOP 关心的是"AI 协作过程是否可追溯"，具体载体随工具演进，不绑定 `logs/ai-sessions/` 路径。CodeBuddy 的持久化记忆机制（用户级 `~/.codebuddy/projects/<项目路径 slug>/memory/`，含 MEMORY.md 索引）是同等有效的留存形式。

**判据**：满足以下任一路径即 PASS。

**路径 ① AI 记忆库（代码 Grader · 推荐）**：
```bash
# CodeBuddy 持久化记忆（用户级，单数 memory/；目录名为项目绝对路径 slug：/ 转 -，去前导 -）
slug=$(pwd | sed 's|/|-|g; s/^-//')
ls "$HOME/.codebuddy/projects/$slug/memory/" 2>/dev/null
find "$HOME/.codebuddy/projects/$slug/memory/" -name '*.md' 2>/dev/null | wc -l
# slug 匹配不上时兜底扫描
find "$HOME/.codebuddy/projects" -maxdepth 2 -name MEMORY.md 2>/dev/null | head -5
```
- 当前项目对应 `memory/` 目录存在 + 记忆文件 ≥3 份 → PASS（记忆已是结构化的 AI 上下文沉淀）
- 注：记忆在**用户级**目录（仓库外），属合理证据来源；只读扫描 `$HOME/.codebuddy/projects/`，不涉及写操作

**路径 ② 会话日志（代码 Grader）**：
```bash
# 仓库内会话目录
ls -d logs/ai-sessions/ logs/ ai-sessions/ .codebuddy/sessions/ 2>/dev/null
find logs/ai-sessions/ .codebuddy/sessions/ -name '*.md' -o -name '*.jsonl' 2>/dev/null | head -5
# CodeBuddy 用户级会话转录（自动产生，无需配置）
slug=$(pwd | sed 's|/|-|g; s/^-//')
find "$HOME/.codebuddy/projects/$slug" -maxdepth 1 -name '*.jsonl' -mtime -30 2>/dev/null | wc -l
```
- 仓库内任一会话目录存在 + 近 30 天有文件，或用户级项目目录近 30 天有 `.jsonl` 会话转录 → PASS

**路径 ③ 失败 case 入 git（代码 Grader）**：
```bash
git ls-files .harness/docs/failures.md >/dev/null 2>&1 && \
  git log --since='90 days ago' --format='%cI' -- .harness/docs/failures.md | head -1
```
- failures.md 已追踪 + 近 90 天有提交记录 → PASS

**判定**：
- ✅ PASS：满足 ①/②/③ 任一
- ⚠️ PARTIAL：仅有 failures.md 但未入 git，或记忆库存在但 <3 份，或会话目录存在但 30+ 天无新文件
- ❌ FAIL：完全无会话/记忆/失败留存

---

### F3：.harness/ 文档变更可追踪（3 分）

**SOP 依据**：§6.1 阶段 2「扫描 SOP 规约文档的变更情况，确保反馈机制有效运作」

**代码 Grader**：
```bash
git log --since='60 days ago' --format='%cI %s' -- .harness/ | wc -l
git log --since='60 days ago' --format='%cI' -- .harness/ | head -1
```

**判定**：
- ✅ PASS：60 天内 ≥3 次提交
- ⚠️ PARTIAL：60 天内 1-2 次提交
- ❌ FAIL：60 天内无任何提交（或目录刚建立可豁免，但需在报告中标注）

---

### F4：改进行动闭环验证（3 分）

**SOP 依据**：§6 持续改进「度量驱动改进」

**代码 Grader + 模型**：
```bash
# 检查是否存在多次历史评估记录
git log --oneline -- .harness/sop_report.md 2>/dev/null | wc -l
```

若存在 ≥2 次 git 提交记录，读取当前报告和之前版本对比 FAIL/PARTIAL 项的变化。

**判定**：
- ✅ PASS：存在 ≥2 次历史评估记录（git 提交），且最近一次相比之前有 ≥1 项 FAIL→PASS 或 PARTIAL→PASS 的改进证据
- ⚠️ PARTIAL：存在历史评估但无明显改进（各项保持原状），或仅有 1 次历史评估（含本次首次创建）
- ❌ FAIL：无法验证改进闭环（sop_report.md 无 git 历史或不存在）

> **首次评估特殊处理**：若为首次评估（sop_report.md 的 git log 仅 0-1 次提交），本项自动计为 ⚠️ PARTIAL（不惩罚新项目，但标注「首次评估，闭环待后续验证」）。

---

## 占位模板识别规则（内容充实度判定依据）

> 源自 specs-checklist 评估哲学：**「文件存在」≠「内容充实」**。A4/D1/D3 等文档类 Eval 必须据此判定内容是否超越初始占位模板。

**通用占位特征（任一命中 = 占位/未填充）**：
1. 占位变量：文件含 `<项目名>`、`<填>`、`<示例>`、`<module>`、`<ActionName>`、`<X.Y.Z>`、`<APP>`、`<pkg1>`、`{{PROJECT_NAME}}` 等尖括号/双花括号占位符且无对应实际值
2. 空表格行：Markdown 数据行全部为 `|  |  |  |` / `| | | |`（仅分隔符无数据）
3. 纯 TODO 内容：正文仅 `<!-- TODO -->` / `# TODO:` 注释无实际描述
4. 零有效内容：去除标题行、引用块、HTML 注释、空行、表格表头+分隔行后，剩余非空行 < 3 行

**各文件专项判定**：
| 文件 | 仍是占位的标志 |
|------|--------------|
| `architecture.md` | 「系统定位」仍为 `<!-- 一句话... -->`；模块划分表无有效行；总体视图仍是通用占位框图 `[外部触发方] → [入口 / 调度层] → ...` |
| `relationship.md` | 上游/下游表均无有效行；拓扑图仍是 `[外部调用方] → [本项目] → [下游 A]` 通用占位 |
| `apis/index.md` | 模块/接口清单表无有效行 |
| `sqls/README.md` | 数据库清单表无有效行 |
| `unittest/unittest.md` | 技术选型表测试框架仍为 `<填...>`；执行命令仍为 `<填：sh run_test.sh ...>` |
| `integration_test/integration_test.md` | §一 形态判定全占位、未标本项目实际形态；§三 执行命令仍为 `<填：sh run_it.sh ...>`；占位符超 8 处 |
| `devops/env.md` | 运行环境表无有效行；快速启动仍为 `# TODO:` |
| `devops/test-env-deploy.md` | 工具就绪检查表无有效行；同步命令仍为 `# TODO:` |
| `review.md` | 通用模板，不要求项目定制，存在即可 ✅ |

**等价识别**：用 `design.md` 替代 `architecture.md`、用 GitHub Issues 替代任务登记等——只要信息等价即同等对待，不因文件名不同而扣分。

---

## PARTIAL 通用判定原则

当 PASS / FAIL 边界模糊时，使用以下决策树：

1. **完整性**：达到要求的核心条件吗？没有 → FAIL
2. **充分性**：达到核心条件但是浅薄 / 不完整 → PARTIAL
3. **可用性**：内容存在但 AI / 团队成员无法据此工作 → PARTIAL
4. **新鲜度**：内容存在但严重过期（与代码不匹配）→ PARTIAL（特别严重才 FAIL）

**评估置信度标记**：

- 🟢 高：纯代码 Grader，证据明确
- 🟡 中：模型判断为主，但有客观锚点（章节关键字、行数等）
- 🔴 低：纯主观判断，建议人工复核

---

## 子 Agent 使用本文档的注意事项

- 每个支柱子 Agent 只需读对应章节，不要全文加载
- 命令示例优先用 `Bash` / `Grep` / `Glob` 工具执行，避免依赖外部命令
- 命令在该项目语言栈不适用时（如 Go 项目跑 npm 命令），直接跳过该命令而非报错
- 证据保留命令输出片段（前 3 行），不保留完整 stderr
