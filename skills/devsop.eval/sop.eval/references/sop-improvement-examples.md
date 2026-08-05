# SOP 改进建议示例库

本文档为 `sop.eval` skill 提供「FAIL/PARTIAL → 可执行改进动作」的对照库。子 Agent 在生成改进建议时优先匹配本库；未命中再用模型生成。

> **改进建议三要素**：
> 1. **可执行**：必须形如「在 X 文件添加 Y 章节」/「配置 Z 工具」/「运行 N 命令」，禁止"应加强 X"这种空话
> 2. **可验证**：完成后能直接看到 Eval 状态从 PARTIAL/FAIL 升到 PASS
> 3. **小颗粒**：单条建议预期工作量 <1 人日，超过的拆分为多条

---

## 支柱 A：项目 AI 友好化

### A1 AGENTS.md 缺失或超长

| 当前状态 | 改进动作 |
|----------|----------|
| 不存在 | 运行 `sop.init` skill 自动生成；或手动创建 AGENTS.md，至少包含：技术栈 / 目录结构 / 规约索引 / 快速启动 / 核心约定 / 禁止项 |
| 行数 >300 | 把详细章节拆到 `.harness/docs/` 子规约或 `rules/*.mdc`，AGENTS.md 仅保留索引和核心约束（参考其他成熟项目的瘦身经验） |
| 行数 <30（浅薄） | 补充以下章节：① 技术栈版本号 ② 目录结构 ③ .harness/docs/ 规约链接 ④ 一键启动命令 ⑤ 5 条以上禁止项 |
| 四章不全（快速索引/SOP/开发准则/禁止红线缺1-2章） | 补充缺失章节：① 快速索引表格（含 .harness/docs/ 文档位置映射）② 二、SOP（含 9 步 plans 流程、上下文恢复、任务隔离、规模分支）③ 三、开发准则（按项目实际情况填写）④ 四、禁止红线（≥5 条硬约束）。参考 `sop.init` skill 的 `assets/agents.md.tmpl` 模板结构 |

### A2 README.md 不完整

| 缺失章节 | 改进动作 |
|----------|----------|
| 项目背景 / 业务目标 | 在 README 顶部加「## 项目简介」，2-3 段说明业务背景和目标用户 |
| 核心功能清单 | 加「## 核心功能」，用 bullet 列出 5-10 项功能 |
| 上下游依赖 | 加「## 外部依赖」，列出依赖的服务、SDK、基础设施（DB / Redis / 外部 API） |
| 快速启动 | 加「## 快速启动」，给出 `git clone` → `make dev` 的完整命令序列 |
| 部署环境要求 | 加「## 环境要求」，列出 Go/Node/Python 版本、必需的服务依赖、最小硬件配置 |
| 注意事项 | 加「## 注意事项」，列出已知限制、不兼容场景、避坑提示 |

### A3 .harness/docs/architecture.md 不完整

| 缺失章节 | 改进动作 |
|----------|----------|
| 整体架构图 | 用 mermaid `graph TD` 画分层架构图（前端 → 网关 → 服务 → DB），嵌入 `.harness/docs/architecture.md`（新版 specs-sop 已迁入 docs/，根目录 ARCHITECTURE.md 为旧版残留应迁移） |
| 模块划分与边界 | 列出顶层目录树，每个模块用 1-2 句说明职责和不应做的事 |
| 数据流向 | 画 1-2 个核心场景的数据流序列图（如「用户登录」「核心业务接口」） |
| 技术选型理由 | 对每个关键技术（框架/中间件/存储）写「选什么 + 为什么 + 替代方案及拒绝理由」 |
| 核心设计决策 | 列出 3-5 个项目级关键决策（如「为什么选事件驱动」「为什么单体而非微服务」） |
| 已知技术债 | 加「## 已知技术债」，列出当前知道但未修的问题及计划处理时间 |

### A4 .harness/docs/ 规约库不全

| 缺失文件 | 改进动作 |
|----------|----------|
| 任意新版核心文档缺失 | 运行 `sop.init` skill 自动补建；或手动按新版 SOP 要求创建 `.harness/docs/` 下的文件（relationship.md 替代旧 dependency-map.md；unittest/unittest.md 替代旧 testing.md） |
| 文件存在但 ≤10 行（骨架） | 按文件主题填充：architecture → 架构图/模块/技术债；relationship → 上下游依赖图/故障传播；coding-style → 命名/格式/安全规则；unittest → 测试策略/覆盖率/执行命令；integration_test → 集成测试范围/运行方式；code-review → Review 清单；glossary → 业务术语表；failures → 踩坑记录（≥3 条）；logging → 日志级别/格式/脱敏。每份至少 30 行实质内容，避免占位符 |

### A5 软链接缺失或被 .gitignore

> **原则**：只为项目**已实际使用**的 AI 工具补建软链接。判断依据：对应工具的配置目录（`.codebuddy/`、`.claude/`）是否已存在于仓库中。**禁止建议项目补建未使用工具的软链接**（如团队不用 Claude Code 则不建 `.claude/`）。

| 当前状态 | 改进动作 |
|----------|----------|
| `.codebuddy/` 存在但 `CODEBUDDY.md` 缺失 | `ln -sf AGENTS.md CODEBUDDY.md` |
| `.claude/` 存在但根 `CLAUDE.md` 缺失 | `ln -s AGENTS.md CLAUDE.md` |
| 软链接是普通文件而非符号链接 | 备份原文件后重建：`mv CODEBUDDY.md CODEBUDDY.md.bak && ln -sf AGENTS.md CODEBUDDY.md` |
| 关键文件被 .gitignore | 从 .gitignore 中删除 `AGENTS.md` / `.harness/` 条目；若根目录仍有旧版 `ARCHITECTURE.md`，建议迁移到 `.harness/docs/architecture.md` 后删除（旧版残留暂需排除 ignore） |

### A6 缺一键启动

| 当前状态 | 改进动作 |
|----------|----------|
| 无 Makefile 或 scripts | 创建 Makefile 加 `dev:` 目标，封装本地启动所需命令；或在 package.json 加 `scripts.dev` |
| 命令存在但未文档化 | 在 README 「## 快速启动」章节明确写出 `make dev` 一行命令 + 期望输出 |
| 命令存在但实际跑不通 | 用一台干净机器走一遍，把缺失的依赖（DB 启动、环境变量）补到命令链或 README 中 |

### A7 环境配置模板缺失

| 当前状态 | 改进动作 |
|----------|----------|
| 无 .env.example | 从当前运行环境导出必需的环境变量，创建 `.env.example`：`env | grep -E "^(DB_|REDIS_|APP_|PORT)" > .env.example`，然后手动清理敏感值替换为占位符 |
| 环境变量散落在多处 | 统一在 `.harness/docs/devops/development.md` 加「## 环境变量」章节，列出所有必需变量（名称 + 说明 + 示例值 + 是否必填） |
| docker-compose.yml 有但无说明 | 在 `README.md` 快速启动章节加一行：「如需配置环境变量，参考 `.env.example` 或 `docker-compose.yml` 中的 environment 段」 |

---

## 支柱 B：开发模式 / 角色协作

### B1 研发流程 9 步未文档化

**改进动作**：在 `AGENTS.md`「二、SOP」章节中补充 9 步 plans 流程描述，每步说明：
- 对应产物文件（`.harness/plans/<任务>/0N-xxx.md`）
- 输入/输出
- 确认点（开始确认 + 结束确认）
- 时间记录要求

参考 `sop.init` skill 的 `assets/agents.md.tmpl` 模板中的「SOP 启动前置」和「步骤执行规则」章节。

### B2 角色职责未约定

**改进动作**：在 `AGENTS.md` 顶部加「## 角色职责」章节，按 SOP「角色职责划分」表格列出 PM / QA / RD 各 4-6 条职责。如团队规模小，可简化为「在小团队中由 X 角色兼任 Y 职责」。

### B3 阶段产出物归属位置不清

**改进动作**：
- 任务目录：统一在 `.harness/plans/<YYYY-MM-DD_任务标题>/` 下，每个任务含 10 文件（00-overview 至 09-commit）
- 设计文档：在 `.harness/docs/architecture.md` + `.harness/docs/apis/` 中沉淀
- 单测约定：在 `.harness/docs/unittest/unittest.md` 写明「与源码同目录 / `tests/` 独立目录」
- 任务发现：`ls .harness/plans/` 或 `find .harness/plans -maxdepth 2 -name 00-overview.md`

### B4 分支/Commit 规范未文档化

**改进动作**：

1. **Commit 规范文档化**：在 `.harness/docs/devops/development.md` 或 `.harness/docs/code-review.md` 加「## Commit 规范」章节：
   ```markdown
   ## Commit 规范

   采用 Conventional Commits：
   - `feat: 新功能`
   - `fix: 修复 Bug`
   - `refactor: 重构（非新功能/非修复）`
   - `docs: 文档变更`
   - `test: 测试相关`
   - `chore: 构建/工具变更`

   每条 commit message 必须关联任务单号（如 `feat: 新增用户鉴权 #123`）
   ```

2. **分支命名规范文档化**：
   ```markdown
   ## 分支规范

   - 功能分支：`feat/<单号>-<简述>`（如 `feat/123-user-auth`）
   - 修复分支：`fix/<单号>-<简述>`
   - 热修复：`hotfix/<单号>-<简述>`
   - 禁止直接在 main/master 上开发
   ```

3. **可选：添加 commitlint 强制检查**：
   ```bash
   # lefthook.yml
   commit-msg:
     commands:
       conventional:
         run: 'echo "$1" | grep -E "^(feat|fix|refactor|docs|test|chore|style|perf|ci|build|revert)(\(.+\))?: .+"'
   ```

---

## 支柱 C：质量检查与反馈机制

### C1 提交 / Push 规范未记忆化

**改进动作**：把 commit / push 的行为规范写进 AI 可读的项目记忆文件（`AGENTS.md` 或 `.codebuddy/rules/*.md`），AI 与人协作时才有可遵循的门禁约定。

1. **commit 规范**（写入 `AGENTS.md`「二、SOP」章节或 `.codebuddy/rules/commit.md`）：
   ```markdown
   ## Commit 规范
   - message 格式：`type(scope): 简述 --story=<id>`（type ∈ feat / fix / refactor / docs / test / chore；缺陷用 `--bug=<id>`）
   - 提交前必跑：`make build && make lint && make ut`，全绿才允许 commit
   - 一个 MR 一个 commit，修正一律 `git commit --amend` 累积，禁止新增第二个 commit
   ```

2. **push 规范**（同一文件追加）：
   ```markdown
   ## Push 规范
   - push 前确认本地 build + lint + 单测全绿
   - amend 后必须 `git push --force-with-lease`，禁止裸 `--force`
   - 禁止直推 main / master，必须特性分支 + MR
   ```

### C2 无 CI 流水线

> 本项目 CI 平台：**Jenkins** / **Argo CD** / **智研**。判定二选一即认定有 CI：① 仓库内 `Jenkinsfile` 入库；② README/deployment.md 明确写出 CI 平台 URL。

| 当前状态 | 改进动作 |
|----------|----------|
| 路径 ①：Jenkinsfile 入库 | 仓库根创建 `Jenkinsfile`，stages：Checkout → Build → Lint → UnitTest → Coverage → IntegrationTest。骨架见下方 |
| 路径 ②：流水线配置在 Jenkins Master / Argo CD / 智研，不入库 | `README.md` 或 `.harness/docs/devops/deployment.md` 加「## CI 流水线」章节，必须含：CI 平台名 + **可点击 URL**（http(s)://）+ 触发条件 + stages 列表 + 失败联系人。光写平台名无 URL 不算 |
| 仅提平台名无 URL | 补 URL：Jenkins Job 页面、Argo CD App 详情页、智研流水线详情页，任选其一贴进 deployment.md |
| 无覆盖率门禁 | Makefile 加 `COVERAGE_THRESHOLD := 60`；Jenkinsfile 中 `sh 'go test -coverprofile=coverage.out ./...'` 后用 `cobertura` 插件或 shell `awk` 校验，未达标 `currentBuild.result = 'UNSTABLE'`；Argo CD/智研 同理在对应平台配阈值 |

**Jenkinsfile 参考骨架（Go 项目）**：
```groovy
pipeline {
  agent any
  options { timeout(time: 30, unit: 'MINUTES') }
  stages {
    stage('Build')    { steps { sh 'make build' } }
    stage('Lint')     { steps { sh 'make lint' } }
    stage('UnitTest') {
      steps { sh 'go test -coverprofile=coverage.out ./...' }
      post { always { archiveArtifacts 'coverage.out' } }
    }
    stage('Coverage Gate') {
      steps {
        sh '''
          pct=$(go tool cover -func=coverage.out | tail -1 | awk '{print $3}' | tr -d '%')
          awk -v p=$pct -v t=60 'BEGIN{exit !(p>=t)}' || { echo "coverage $pct% < 60%"; exit 1; }
        '''
      }
    }
    stage('Integration') { steps { sh 'make integration-test' } }
  }
  post {
    failure { /* TAPD 单/企业微信告警 */ }
  }
}
```

**deployment.md 章节模板（路径 ②）**：
```markdown
## CI 流水线

- 平台：Jenkins（或 Argo CD / 智研）
- URL：https://jenkins.example.com/job/xxx
- 触发：push to main / MR
- Stages：Build → Lint → UnitTest → Coverage(≥60%) → Integration
- 失败联系人：@xxx
```

### C3 禁止项防护不足

**改进动作**：
1. **.gitignore 补全**：添加 `.env*`, `*.pem`, `*.key`, `vendor/`, `node_modules/`, `dist/`, `build/`, `*.exe`, `bin/`
2. **PreCommit 加敏感文件检查**：
   ```yaml
   # lefthook.yml
   pre-commit:
     commands:
       no-secrets:
         run: |
           git diff --cached --name-only | grep -E '\.(env|pem|key)$' && exit 1 || exit 0
   ```
3. **`.harness/docs/code-review.md` 列出禁止项清单**：照搬 SOP §3.2 的 12 条禁止项

### C4 分支保护与 Review 流程未文档化

**改进动作**：在 `.harness/docs/code-review.md` 加章节，列明：
- 禁止直推 main / master（必须特性分支 + MR）
- MR 必须关联 TAPD 单号（MR title 含 `--story=<id>` 或 `--bug=<id>`）
- MR 行数 ≤500 行，超过必须拆分
- 至少 1 名 Reviewer 通过才能合并
- AI 生成代码必须经人工 Review 后提交（含「我理解这段代码」确认）

如使用工蜂等支持 Branch Protection 的代码平台，同步配置仓库保护规则。

### C5 failures.md 长期为空

**改进动作**：
1. **本周补 3 条最近踩坑记录**：在 `.harness/docs/failures.md` 用以下模板：
   ```markdown
   ## 2026-05-18 — 短标题
   **现象**：...
   **根因**：...
   **修复**：...
   **预防**：（更新到哪个规约 / 加什么测试）
   ```
2. **建立机制**：在 `AGENTS.md` 加约定「踩坑后 24 小时内补 failures.md」
3. **每两周回顾**：把 failures.md 加入团队周会议程，过去两周新增条目转化为规约更新

### C6 无安全扫描机制

**改进动作（按语言栈选择）**：

| 语言 | 推荐工具 | 安装与配置 |
|------|---------|-----------|
| Go | `golangci-lint`（启用 `gosec`）+ `govulncheck` | 在 `.golangci.yml` 的 `linters.enable` 列表加 `- gosec`（gosec 随 `golangci-lint run` 一并执行，无需单独安装）；`go install golang.org/x/vuln/cmd/govulncheck@latest`，Makefile 加 `security: govulncheck ./...` |
| JS/TS | `npm audit` + Snyk | CI 中加 `npm audit --production`；或 `npx snyk test` |
| Python | `safety` + `bandit` | `pip install safety bandit && safety check && bandit -r src/` |
| 通用 | Renovate | 配置 `renovate.json` 自动检测依赖更新（Jenkins 项目推荐 Renovate Self-Hosted 或 Mend Renovate） |

**Go 项目 `.golangci.yml` 配置示例**：
```yaml
linters:
  enable:
    - gosec    # 安全编码检查
    - govet
    - staticcheck
```

**Jenkins 集成示例**（Makefile target 方式，便于 Jenkinsfile 直接 `sh 'make security'`）：
```makefile
# Makefile（gosec 已随 make lint 中的 golangci-lint 执行，此处补依赖漏洞扫描）
security:
	govulncheck ./...
```

在 CI（Jenkins Pipeline 优先）中调用 `make security` 即可。Jenkinsfile 示例：
```groovy
stage('Security') {
  steps { sh 'make lint && make security' }
  post { unstable { /* 告警但不阻断 */ } }
}
```

### C7 无 E2E/集成测试

**改进动作**：

1. **创建集成测试目录**：
   ```bash
   mkdir -p tests/integration
   # 或 Go 项目
   mkdir -p tests/e2e
   ```

2. **编写首个集成测试**（以 Go 为例）：
   - 选择核心业务流程（如「创建用户→查询用户」）
   - 使用 `testcontainers-go` 或 `docker-compose` 起真实依赖
   - 文件命名：`tests/integration/user_flow_test.go`

3. **CI 集成（Jenkinsfile）**：
   ```groovy
   stage('Integration') {
     steps {
       sh '''
         docker-compose -f docker-compose.test.yml up -d
         go test ./tests/integration/ -v -tags=integration
       '''
     }
     post {
       always { sh 'docker-compose -f docker-compose.test.yml down' }
     }
   }
   ```

4. **在 `.harness/docs/unittest/unittest.md`（单测）与 `.harness/docs/integration_test/integration_test.md`（集成测试）补充规约**：说明集成测试的范围、运行方式、与单测的区别

---

## 支柱 D：设计与变更管理

> 新版 sop.init 统一使用 `.harness/plans/<任务>/` 的 10 文件 SOP 体系。评估基于任务目录存在性、模板完整性、和 TDD 文档化程度。

### D1 无任务目录或产物不全

| 当前状态 | 改进动作 |
|----------|----------|
| 无 `.harness/plans/` 目录 | 运行 `sop.init` skill 初始化 SOP 体系 |
| 有 `_template/` 但无历史任务 | 选择一个当前进行中的功能，执行：`cp -r .harness/plans/_template .harness/plans/YYYY-MM-DD_<任务标题>`，然后按 SOP 流程填写 00-overview.md 的 Meta 信息 |
| 任务目录存在但文件不全（<8 个步骤文件） | 从 `_template/` 补建缺失的步骤文件，确保 00-09 共 10 个文件齐全 |

### D2 00-overview.md 维护不活跃

| 当前状态 | 改进动作 |
|----------|----------|
| 有任务目录但 90 天内无 git 更新 | 回顾当前进行中的任务，更新 `00-overview.md` 的 Progress 勾选状态和时间记录 |
| 任务已完成但未归档 | 在 `00-overview.md` 中标记完成时间，关键决策备忘补充最终 commit info |

### D3 小型变更 TDD 未文档化或模板不完整

| 当前状态 | 改进动作 |
|----------|----------|
| `_template/` 文件数 <10 | 重新运行 `sop.init` skill 刷新 `_template/`（幂等，会补缺） |
| TDD 要求未文档化 | 在 `.harness/docs/unittest/unittest.md` 加 TDD 原则章节（参考 A1 改进建议中的 TDD 内容） |

### D4 变更分级标准未文档化

**改进动作**：在 `AGENTS.md`「三、开发准则」或 `.harness/docs/devops/development.md` 加「## 变更分级标准」章节：

```markdown
## 变更分级标准

| 级别 | 判定标准 | 对应流程 | 产出物 |
|------|---------|---------|--------|
| **大型** | ≥5 人天，或涉及 ≥3 个模块 | 完整 9 步 SOP（01-09） | `.harness/plans/<任务>/` 全量产物 |
| **中型** | 1-5 人天，涉及 1-2 个模块 | 标准 SOP（可合并部分步骤确认） | `.harness/plans/<任务>/` |
| **小型** | <1 人天，Bug 修复、配置变更 | 小需求模式（≤10 行改动可合并 03-04、07-09 确认） | 回归测试 + MR |
```

---

## 支柱 E：公共资料库

### E1 无 Skills 沉淀目录

**改进动作**：
```bash
mkdir -p .codebuddy/skills
# 把项目里反复使用的命令封装为 Skill
# 至少创建 3 个常用 Skill（如 fix-bug / commit / code-review）
```

### E2 知识沉淀完整度不足

**改进动作**（三选一即可 PASS，本地优先）：

**路径 ① 加强本地 Spec 沉淀（推荐，AI 直接消费）**：
- `specs/` 至少覆盖 5 个核心模块，每模块含设计文档 + 接口定义
- `openspec/changes/` 持续记录中型变更，归档到 `archive/`
- 让 AI 通过本地文件读取规范，比远程 wiki 检索更可靠

**路径 ② 引用团队远程知识库**：在 `AGENTS.md` 或 `README.md` 加「## 团队公共资料」章节，列出：
- 团队 Wiki 链接（如 Confluence 空间）
- 公共 Skill / Hook 仓库链接
- 业务规范范本仓库

**路径 ③ 自建项目内知识库**：`docs/` 或 `knowledge/` 目录沉淀 ≥10 篇业务/技术文档，AGENTS.md Index 章节索引。

如三者都缺，先从路径 ① 入手——本地 spec 沉淀是 AI 协作时代最高效的知识形态。

---

## 支柱 F：度量机制

### F1 sop_report.md 久未更新

**改进动作**：
1. **本次执行 sop.eval 即更新文件**（创建即满足）
2. **建立月度评估机制**：在团队周会议程中加「每月第一周跑一次 sop.eval」
3. **配 Jenkins 定时任务**（可选）：新建 Jenkins Job，`triggers { cron('H 9 1 * *') }` 每月 1 号触发，跑 `sop.eval --dry-run`，归档 `.harness/sop_report.md`，总分跌破阈值用 `currentBuild.result = 'UNSTABLE'` 告警但不阻断

### F2 无 AI 会话/记忆/失败 case 留存

**改进动作**（三选一即可 PASS）：

**路径 ① 启用 AI 记忆库（推荐 · CodeBuddy 用户）**：
```bash
# CodeBuddy 自动把记忆写入用户级 ~/.codebuddy/projects/<项目路径 slug>/memory/
# 无需手工建目录；持续用 CodeBuddy 协作，让 AI 主动沉淀用户偏好/项目事实/反馈
# 至少积累 3 份记忆文件 + MEMORY.md 索引
```
记忆文件本身就是结构化的 AI 会话沉淀，比原始日志更易复用。在 `AGENTS.md` 提示 AI 主动维护记忆。

**路径 ② 配置会话日志目录**：
```bash
mkdir -p logs/ai-sessions
echo "logs/ai-sessions/" >> .gitignore  # 会话可能含敏感内容
```
约定：每次重要功能开发后，把 AI 会话存为 `logs/ai-sessions/{YYYY-MM-DD}-{topic}.md`，30 天后归档到外部存储。

> 注：用 CodeBuddy 协作的项目，其用户级会话转录（`~/.codebuddy/projects/<slug>/*.jsonl`）近 30 天有文件即自动满足本路径，无需手工建目录。

**路径 ③ failures.md 入 git 持续维护**：
```bash
git add .harness/docs/failures.md && git commit -m "docs: track failures log"
```
约定每次踩坑修复后追加，让历史问题在 git history 可追溯。

### F3 .harness/docs/ 文档变更停滞

**改进动作**：
1. 检查 60 天内是否真的没有规约变更需求（如果项目稳定无变化，是正常的）
2. 如有变化但未沉淀：把最近的代码评审反馈、踩坑教训整理进 `.harness/docs/` 对应规约
3. 建立机制：每月底回顾，识别 ≥1 项规约更新点

### F4 改进行动未闭环

**改进动作**：
1. **回顾上次 sop_report.md**：找出所有 FAIL 和 PARTIAL 项，逐条确认是否已改进
2. **选择 1-2 条高优 FAIL 项立即修复**：参考本文档对应 Eval 的改进建议
3. **建立闭环机制**：在团队月度会议中增加「SOP 改进跟踪」议程：
   - 上次 FAIL/PARTIAL 的项是否已修复？
   - 修复后重跑 `sop.eval` 验证是否升级为 PASS
4. **在 `.harness/sop_report.md` 中标注改进轨迹**：每次评估后对比上次结果，在报告「与上次评估对比」章节记录变化

---

## 反模式专项改进

### 文档与代码严重不同步

**改进动作**：
1. 抽样验证 5 条 `.harness/docs/` 中的规则，确认与当前代码是否一致
2. 不一致的：要么更新文档，要么修代码使之符合规约
3. 长期不维护的规约文件：标 `<!-- TODO: 已过期，待 2026-Qx 更新 -->` 注释或直接删除

### 测试过度 Mock

**改进动作**：
1. 识别项目中 Mock 比例过高的目录（如 `*_mock.go` 占 `*_test.go` 数量 >70%）
2. 为每个核心业务流程补 1 个真实集成测试（用 SQLite 内存 DB / testcontainers）
3. 在 `.harness/docs/unittest/unittest.md` 明确：DAL/Repository 层禁止 Mock DB，必须用真实测试 DB

### 提交了敏感文件或生成物

**改进动作（紧急）**：
```bash
# 1. 立即从 git 历史中移除敏感文件
git rm --cached <敏感文件路径>
git commit -m "chore: remove leaked sensitive files"

# 2. 如已推到远端，需 git filter-repo 重写历史（注意通知所有协作者）
# 3. 立即轮换泄露的密钥 / 凭证
# 4. 把对应文件加到 .gitignore
```

### 重要决策未沉淀文档

**改进动作**：
1. 抽查最近 5 个大型 PR，把 PR description 中的设计决策同步到 `.harness/docs/architecture.md` 「核心设计决策」章节
2. 在 `.harness/docs/code-review.md` 加 PR Review checklist：「设计决策是否已沉淀到 architecture.md 或 spec」

### AGENTS.md 浅薄

**改进动作**：参考 A1 改进动作，补足核心 7 个章节（技术栈 / 目录 / 规约索引 / 快速启动 / 核心约定 / 禁止项 / 子文档路由表）

---

## 通用建议生成规则

当本库未命中具体场景时，子 Agent 按以下原则生成：

1. **Anchor on Eval ID**：所有建议必须明确关联 1 个 Eval ID
2. **可执行三要素**：在哪改（文件路径）+ 改什么（具体内容）+ 怎么改（命令或修改示例）
3. **预期收益量化**：完成后预期把 Eval 从 X 升到 Y（如「PARTIAL → PASS」）
4. **工作量小颗粒**：单条 <1 人日，超过的拆分
5. **禁止空话**：不要"加强 X"、"提升 Y"、"完善 Z"，必须指明具体动作
