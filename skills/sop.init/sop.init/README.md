# sop.init · 使用介绍

> **一句话**：为任意代码项目一键铺设 `.harness/` SOP 骨架 + `AGENTS.md` AI 入口（唯一真源，CODEBUDDY.md / CLAUDE.md 均为其软链），把"需求 → 澄清 → 计划 → 实现 → 单测 → 部署 → 集成测试 → 文档 → 评审 → 提交"的 9 阶段流程固化成可被 AI Agent 持续推进的产物结构。

---

## 1. 这个 skill 解决什么问题

| 痛点 | sop.init 的对策 |
|------|------------------|
| AI 协作每次重新对齐项目规范、流程不稳定 | 在仓库根生成 `AGENTS.md` 作为**唯一真源入口**（CODEBUDDY.md / CLAUDE.md 均为其软链），所有规范 / SOP / 红线显式写死 |
| 多人并行开发、全局任务总览文件冲突 | **不再生成**全局 `plan.md`，每个任务自带 `00-overview.md` 作为单一真相源 |
| 需求做完没有文档沉淀，下一次又重头讲 | 9 阶段每步都有固定产物文件（`0N-<step>.md`），任务结束即留痕 |
| 单元/集成测试规范散在各处 | `.harness/docs/unittest/` + `.harness/docs/integration_test/` 标准三段式（环境 / 用例 / 运行调试） |

---

## 2. 触发方式

下列说法都会让 AI 自动调用本 skill：

- "初始化 `.harness/`"
- "搭建 SOP / 项目脚手架"
- "bootstrap specs"
- "给当前仓库铺一份 AGENTS.md"

也可以直接手动跑脚本（见 §4）。

---

## 3. 初始化后会得到什么

执行后仓库会出现这些产物（已存在文件不覆盖；`AGENTS.md` 例外，仅刷新第二章 SOP 而保留其余章节）：

```
<repo_root>/
├── AGENTS.md                    # AI 协作唯一真源入口（四章：快速索引 / SOP / 开发准则 / 禁止红线）
├── CODEBUDDY.md                 # → AGENTS.md 的软链（CodeBuddy 识别）
├── CLAUDE.md                    # → AGENTS.md 的软链（Claude Code 识别）
├── .codebuddy/
│   └── skills/clarify/          # Stage 01 配套的对话协议 skill（自动安装）
├── scripts/                     # Git Hook 脚本副本（pre-commit / pre-push / commit-msg）
│   ├── pre_commit_check.sh
│   ├── pre_push_check.sh
│   └── commit_msg_check.sh
└── .harness/
    ├── review.md                # AI Code Review 规范
    ├── docs/                    # 长期性技术文档区（占位，由你逐步填充）
    │   ├── architecture.md
    │   ├── relationship.md
    │   ├── coding-style.md
    │   ├── code-review.md
    │   ├── glossary.md
    │   ├── failures.md
    │   ├── logging.md
    │   ├── apis/{index.md, _template.md, api-standards.md, <module>/<Action>.md}
    │   ├── sqls/{README.md, database.md}
    │   ├── unittest/unittest.md
    │   ├── integration_test/integration_test.md
    │   └── devops/{env.md, test-env-deploy.md, deployment.md, development.md}
    └── plans/
        └── _template/           # 10 文件任务模板（00-overview + 01-clarify ... 09-commit）
```

**任务发现约定**（替代旧版全局 `plan.md`）：

| 想知道 | 操作 |
|--------|------|
| 所有任务 | `ls .harness/plans/` |
| 当前分支对应的任务 | `git branch --show-current`，去各 `00-overview.md` Meta 的 `分支` 字段匹配 |
| 单个任务进度 | 只读 `.harness/plans/<任务>/00-overview.md` |

---

## 4. 用法

### 4.1 全新项目初始化

```bash
# 进入仓库根
cd /path/to/your/repo

# 直接跑脚本（也可让 AI 自动触发）
bash /path/to/skills/sop.init/scripts/init_harness.sh

# 可选 flag：无 API / 无 DB 的项目跳过对应骨架目录（缺省 true 向后兼容）
bash /path/to/skills/sop.init/scripts/init_harness.sh . --has-api=false --has-db=false
```

脚本要点：
- `.harness/docs/` 骨架文件**已存在则不覆盖**（保护用户填写的内容）。
- `--has-api=false` / `--has-db=false` 只影响补缺复制（跳过 `docs/apis/` / `docs/sqls/`），**不删**已有文件；flag 值通常由 AI 按 `references/special-agent-detect.md` 探测得出。
- `plans/_template/` 下**全部文件**采用「有差异则直接覆盖」策略，确保 skill 升级后新建任务能拿到最新模板结构；已创建的具体任务目录（`plans/<task>/`）一律不动。
- `AGENTS.md` 已存在 → **按章节分治**：仅强制刷新「二、SOP」章节（核心 SOP 契约），保留「一、快速索引」「三、开发准则」「四、禁止红线」不改不删；仅当第二章有差异时才更新（Git 管理，无需备份）。
- `CODEBUDDY.md` / `CLAUDE.md` 已是软链 → 直接重建；是真实文件 → 直接删除后重建为软链（双 Agent 入口，Git 可找回）。
- `.harness/docs/devops/test-env-deploy.md` 按章节分治：skill 管控区强制刷新，`## 项目自定义` 章节保留不动。
- Go 项目（`go.mod` 存在）自动复制 `.golangci.yml` 到仓库根（已存在则跳过）。
- 通过 `setup_hooks.sh` 幂等安装 Git Hooks：先把 3 个 hook 脚本复制到目标仓库 `scripts/`（已存在则跳过），再在 `.git/hooks/` 下建立指向 `../../scripts/<script>` 的软链（pre-commit / pre-push / commit-msg 三个）。
- 同时将 `clarify` skill 安装到 `<repo>/.codebuddy/skills/clarify/`。

### 4.2 初始化后必须人工补齐的内容

按重要性排序：

1. `.harness/docs/architecture.md`、`.harness/docs/relationship.md`
2. `.harness/docs/apis/<module>/<Action>.md` + `apis/index.md`
3. `.harness/docs/sqls/`（DB schema / migration）
4. **`.harness/docs/unittest/unittest.md`**（三段式：环境 / 生成 / 运行调试）
5. **`.harness/docs/integration_test/integration_test.md`**（三段式：环境与依赖 / 用例设计 / 运行调试）
6. `.harness/docs/devops/env.md` + `.harness/docs/devops/test-env-deploy.md`
7. `AGENTS.md` 的「三、开发准则」与「四、禁止红线」两章

> 已有 `.codebuddy/rules/<topic>_*.md` 的项目（如 `unittest_rule.md`），docs 改为**摘录 + 链接**承接，避免双轨。

---

## 5. 9 阶段任务 SOP 概览

每个新需求都从 `cp -r .harness/plans/_template .harness/plans/YYYY-MM-DD_<short-title>` 开始，然后按下表推进：

| # | 步骤 | 产物 | 关键动作 |
|---|------|------|----------|
| 1 | Clarify | `01-clarify.md` | 调用 `clarify` skill，AI 切换 PM 视角，澄清背景/目标/待确认问题 |
| 2 | Plan | `02-plan.md` | 改动文件、调用链、**§6 UT 用例设计（TDD 先行，必填）**、IT 用例设计、风险评估 |
| 3 | Implement | `03-implement.md` | 关键实现细节、与 Plan 的差异；**遵循 Plan §6 红绿循环：先按 §6 写 UT 跑红 → 写最小实现转绿 → 在 UT 保持绿前提下重构** |
| 4 | UT | `04-ut.md` | 用例**与 Plan §6 逐条对齐**（含 Plan §6 编号列）、单测命令、覆盖率、未覆盖行；规则参考 `unittest/unittest.md` |
| 5 | Deploy | `05-deploy.md` | 部署结果（协同模式：热更新到 Meta「测试环境」指定的环境） |
| 6 | IT | `06-it.md` | 集成测试结果、关键 req_id；**协同模式同样必须执行**（覆盖本组件职责的用例，跨组件 / 端到端用例由上层编排器另行覆盖）；规则参考 `integration_test/integration_test.md` |
| 7 | Docs | `07-docs.md` | 增量回写 `.harness/docs/` |
| 8 | Review | `08-review.md` | Code Review 结果 |
| 9 | Commit | `09-commit.md` | **强制顺序**：① 询问 TAPD（无则引导创建）→ ② 释放环境（通过团队环境管理 Skill 执行环境释放命令，结果落「0.1 环境释放」表）→ ③ TAPD 状态推进到「开发中」（团队流程时；**CR 由 push 后 MR 提交自动触发，不在此步完成**）→ ④ 写好所有 md（含 `09-commit.md` §3 commit message）→ ⑤ 更新 `00-overview.md`（边界点 A）→ ⑥ 一次性 `git add` → ⑦ `git commit`（脚注**默认 `--story=<id>`**，bug fix 用 `--bug=<id>`）→ ⑧ `git push` 触发 TAPD「开发中→CR」→ ⑨（可反复直到 MR 合入）amend 累积修复**；**一个 MR 一个 commit**——任何修正一律 `git commit --amend`，**严禁**新增第二个 commit；amend 后 push 必须用 `git push --force-with-lease`（**禁止**裸 `--force`）；**禁止**绕过团队环境管理 Skill 直接调用环境释放命令；**禁止**绕过团队 TAPD Skill 直接调 TAPD MCP；**禁止**任务收尾前 TAPD 未落到 CR（团队流程时）；**禁止**环境未释放就 commit |

**单一真相源**：每步完成后只更新两处——本步骤 `0N-<step>.md` + 本任务 `00-overview.md`（Progress 勾选 + 当前步骤指针 + 时间记录）。永远不写跨任务共享文件。

**步骤时间记录**：`00-overview.md` 内置「时间记录」表，对 9 步骤逐行记录开始时间 / 结束时间 / 耗时 / 备注。
- 开始时间：用户在「开始确认」环节回复同意后、AI 动手执行**前**写入（精确到秒）
- 结束时间：步骤产物落地后、向用户发起「结束确认」**前**写入
- 仅以下两种场景允许「跳过」：① Clarify 用户预置；② 协同开发（design.md 驱动）跳过 Clarify / Plan。开始 / 结束填同一时间戳，耗时 `0s`，备注列写明跳过原因
- **小需求模式批次时间记录**：Meta `小需求模式` = ✅ 时，03-04 / 07-09 各自按批次起止共享开始/结束/耗时，备注列写「小需求模式批次：03-04」或「小需求模式批次：07-09」；05/06 仍按标准模式记录。漏估时无需回填——按批次记录的时间已能反映真实工作窗口，跨任务聚合靠备注前缀识别
- **禁止事后回填编造时间**——漏记的步骤保持空白并在备注写「漏记」

**协同开发模式**（上层编排器生成 `.harness/design.md` 时）：
- Clarify & Plan 由 design.md 一次性派生为 `01-clarify.md` / `02-plan.md`，**派生完成后立即删除 design.md**（避免双源）；测试环境名沉降到 `00-overview.md` Meta，作为后续步骤的唯一真相源
- 跳过 Step 1 / Step 2，从 Step 3 Implement 开始执行
- Deploy 步骤改用快速更新热更代码（使用 Meta「测试环境」，不创建新环境）
- IT 步骤**正常执行**（不跳过），覆盖本组件职责的用例；跨组件 / 端到端用例由上层编排器另行覆盖
- Review 完成后由上层编排器统一合流，不在本仓库执行 Commit 中的合流操作

**小需求模式**（02 Plan 估算 `预估代码改动行数 ≤ 10` → `00-overview.md` Meta `小需求模式` 设为 ✅）：

| 步骤 | 模式 | 说明 |
|------|------|------|
| 01-02 Clarify / Plan | **确认** | 决策点，必须显式确认 |
| 03-04 Implement / UT | **自动** | 开始/结束合并为单次提问；产物 + 时间记录不豁免 |
| 05 Deploy | **确认** | 环境敏感，必须显式确认 |
| 06 IT | **确认** | 真实链路核验，必须显式确认 |
| 07-09 Docs / Review / Commit | **自动** | 开始/结束合并为单次提问；环境释放仍按 `09-commit.md` 0 节执行 |

> 若实际改动 > 10 行（漏估），在汇报 03-04 结论时同步把 `小需求模式` 改回 ⬜，从 05 起按标准模式跑。

---

## 6. 常见问答

**Q：已经有 `AGENTS.md` 了，再跑会不会丢内容？**
A：不会丢。脚本按章节分治——只强制刷新第二章「SOP」（核心契约），你在一/三/四章填写的项目自定义内容（快速索引追加行、开发准则、禁止红线）全部原样保留。项目由 Git 管理，如需找回旧内容用 `git restore`，不生成 `.bk.*` 备份文件。

**Q：能否只生成 `.harness/` 不动 `AGENTS.md`？**
A：脚本是一体的。如果只想要骨架，手动 `cp -r assets/harness-skeleton/. .harness/` + `cp -r assets/plans-template .harness/plans/_template` 即可。

**Q：每个任务必须把 9 步全走完吗？**
A：不强制。但 `00-overview.md` Progress 必须诚实反映实际进度（已跳过的步骤标注原因），便于上下文恢复。

**Q：`master`/`main` 分支可以做 SOP 吗？**
A：禁止。`AGENTS.md` 已写死红线：所有 SOP 步骤必须在 `feature/<task>` 分支上。

**Q：我能不能在 `.harness/` 顶层加 `apis/` / `sqls/` / `architecture.md`？**
A：禁止。这些必须放 `.harness/docs/` 之下。详见 SKILL.md「红线」节。

**Q：commit 后发现 plans 产物写漏了一行 / 还要修个 typo 怎么办？**
A：如果是**代码**问题 → 直接 `git commit --amend` 累积到原 commit，再 `git push --force-with-lease`（**一个 MR 只能有一个 commit**）。如果是**写漏 md** → 不要再回去改 md！`00-overview.md` / `09-commit.md` 在 `git add` 之后就冻结了（边界点 A）——任何 post-commit 的 md 编辑都会破坏一个 MR 一个 commit 原则，**唯一例外**是 amend 改代码时也不写 md。MR 链接 / commit hash / CR 状态在 GitLab / `git log` / TAPD 系统查即可，不重复记到 md。详见 `09-commit.md`「2. amend 流程」节。

**Q：amend 后用 `git push --force` 还是 `--force-with-lease`？**
A：**必须** `--force-with-lease`（拒绝覆盖远端新进 commit，比裸 `--force` 安全）。若用裸 `--force` 会触发 SKILL.md 红线 4。

**Q：commit message 脚注 `kind` 字段怎么选？**
A：**默认 `--story=<id>`**——只要不是明确的 bug fix（`fix` type），就用 `--story`；bug fix 用 `--bug=<id>`；其他按需 `task` / `test` / `other`。一次 commit 内 `--kind` 必须唯一。commit-msg hook 默认强制校验该脚注存在，缺脚注会 BLOCK。

**Q：commit message 格式不合规会被 hook 拦吗？**
A：会。`commit_msg_check.sh` 默认强制两条：① 标题符合 Conventional Commits（`<type>(<scope>): <subject>`，type 必须是 `feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|other` 之一）；② body 含 TAPD 脚注 `--<kind>=<id>`。遗留项目过渡可设 `DISABLE_CONV_COMMITS=1` / `DISABLE_TAPD_FOOTER=1` 临时跳过（不推荐长期使用）。

**Q：commit 阶段 TAPD 没填怎么办？**
A：AI 会**主动询问**你"是否需要根据本次需求创建 TAPD 需求单"（默认推荐：是）。选是的话，AI 会调团队 TAPD skill 基于 `02-plan.md` 的方案设计 + `04-ut.md` / `06-it.md` 的测试结果创建，并推进到「开发中」（commit 前强制）；**CR 由 push 后 MR 提交自动触发**（不在 commit 前完成）。选否的话记原因到 `00-overview.md` 关键决策备忘后跳过 0.2 节。**任务收尾前**必须确认全链路已落到 CR。

**Q：非本团队项目也要走 TAPD 衔接吗？**
A：不需要。团队 TAPD skill 适用于本团队 TAPD 空间（ChainWeaver）。非本团队项目在 `00-overview.md` 关键决策备忘写"本次任务跳过 TAPD：<原因>"，跳过整个 0.2 节；commit 时可设 `DISABLE_TAPD_FOOTER=1` 临时绕过脚注校验。

---

## 7. 目录速览

```
skills/sop.init/
├── SKILL.md                     # 给 AI 读的入口（含触发词、流程、红线）
├── README.md                    # 本文件，给人读的使用介绍
├── scripts/
│   ├── init_harness.sh          # 全新项目初始化 / 老项目升级（幂等）
│   ├── setup_hooks.sh           # Git Hooks 安装（幂等，复制脚本 + 建软链）
│   ├── pre_commit_check.sh      # pre-commit hook
│   ├── pre_push_check.sh        # pre-push hook
│   └── commit_msg_check.sh      # commit-msg hook（校验 Conventional Commits + TAPD 脚注）
├── references/                  # 子 Agent 指令 + 方法论（只读）
│   ├── docs-generation.md       # `.harness/docs/` 生成方法论（初始化后引导填充时加载）
│   ├── merge-agent-prompt.md    # 归一化合并子 Agent 指令
│   ├── library-context.md       # 库项目补充指令
│   ├── framework-gozero.md      # go-zero 框架特化指令
│   └── special-agent-*.md       # 13 个子 Agent（A–M）专用指令
└── assets/                      # 复制到目标仓库使用，AI 不读入上下文
    ├── harness-skeleton/        # `.harness/` 骨架（review.md + docs/ 20 文件 + plans/）
    ├── plans-template/          # 10 文件任务模板
    ├── agents.md.tmpl           # AGENTS.md 模板（四章式，CODEBUDDY.md/CLAUDE.md 均为其软链）
    ├── ARCHITECTURE.md.tmpl     # 项目架构文档模板（13 节）
    ├── README.md.tmpl           # 项目 README 模板（按需手动复制，不自动生成）
    ├── clarify-skill/           # Stage 01 配套 clarify skill 模板
    └── .golangci.yml             # Go 项目 lint 配置模板（go.mod 存在时自动复制到仓库根）
```

---

## 8. 配套 skill

| skill | 作用 |
|-------|------|
| `clarify`（自动安装到目标仓库 `.codebuddy/skills/clarify/`） | Step 1 Clarify 阶段的对话协议，AI 切换为 PM 视角做 Discovery + Challenge |
| `sop.eval`（独立 skill） | 对 `.harness/` 体系做只读审计——六大支柱 28 项 Eval（PASS / PARTIAL / FAIL）+ 反模式检测，报告写入 `.harness/sop_report.md`。`sop.init` 与 `sop.eval` 是一对：init 搭骨架 → eval 跑基线 → 周期性 `sop.eval --diff-from=...` 追踪改进 |

---

## 9. 红线速记

1. ❌ `apis/` / `sqls/` / `unittest/` / `integration_test/` / `architecture.md` 放 `.harness/` 顶层 → 必须在 `docs/` 下。
2. ❌ 重新引入全局 `.harness/plan.md` → 一切总览能力下沉到 `plans/<任务>/00-overview.md`。
3. ❌ 预生成 `README.md` / `conventions.md` / `glossary.md` / `risks.md` / `adr/` 等占位 → 按需创建。
4. ❌ 绕过团队环境管理 Skill 直接调用环境释放命令；❌ commit 之前跳过「0.1 环境释放」节（必须通过团队环境管理 Skill 执行环境释放命令，并把结果填到「0.1 环境释放」表）；❌ 绕过团队 TAPD Skill 直接调 TAPD MCP；❌ 任务收尾前 TAPD 未落到 CR（团队流程强制；CR 由 push 后 MR 提交自动触发，不在 commit 前置条件里）；❌ 同一个 MR 出现第二个 commit——一个 MR 一个 commit 原则，任何修正（含 push 元信息、follow-up 修复，可反复直到 MR 合入）一律 `git commit --amend` 累积到原 commit；❌ amend 后用裸 `git push --force`（必须 `--force-with-lease`）。
5. ❌ 违反 TDD 红绿循环 → `02-plan.md` 必须含 `§6 UT 用例设计`，Implement 必须按 Plan §6 先写测试跑红，`04-ut.md` 必须与 Plan §6 逐条对齐；禁止「先写实现再补测试」、禁止 UT 与 IT 重复测同一层逻辑。
6. ❌ 漏记 / 事后回填编造 `00-overview.md`「时间记录」表的开始 / 结束时间 → 开始时间必须在用户确认开始的当下写入；结束时间必须在向用户发起结束确认之前写入；漏记的步骤备注列写「漏记」并保持空白。
7. ❌ AI 主动读取/参考其他 `.harness/plans/<任务>/` 下的 md 产物 → 任务之间物理隔离、互为独立真相源；只有用户**显式**说「参考任务 X」时才能读，且参考内容禁止自动写回当前任务。详见 `AGENTS.md` 二、SOP「任务隔离原则（强制）」。

---

## 10. 反馈与扩展

- 模板需要项目化定制：直接改 `assets/agents.md.tmpl` 与 `assets/plans-template/`，下次跑 `init_harness.sh` 即生效。
- 新增 SOP 阶段：编辑 `assets/agents.md.tmpl` 步骤表 + 在 `assets/plans-template/` 加 `0N-<step>.md`，并同步 `assets/harness-skeleton/plans/_template/` 入口。
- 评分规则同步更新：见 `skills/sop.eval/`。
