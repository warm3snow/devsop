---
name: sop.init
description: SOP初始化
---

# specs-sop

**目的**：为项目一键搭建或升级 `.harness/` 骨架 + `AGENTS.md`（真源入口），铺设 9 阶段 SOP 的"轨道"。脚本幂等——全新项目会完整初始化，已有骨架的老项目会自动补缺 + 刷新契约性文件到最新版。

---

## 标准 `.harness/` 布局

> `docs/` 是长期性技术文档区，`plans/` 是任务产物区，两者严格分离。
> **顶层不再生成全局 `plan.md` 任务总览**——多人并行开发时所有人改同一份文件必然产生合并冲突；改为「任务自治」：每个任务的总览 + 进度都写在 `plans/<任务目录>/00-overview.md`。
> 顶层只保留 `review.md` 一个固定文件；其它如术语表 / ADR / 风险登记 / 项目约定按需在 `docs/` 下追加，不再强制建占位。

```
.harness/
├── review.md                     # AI Code Review 规范
├── docs/                         # 长期性技术文档区
│   ├── architecture.md           # 系统架构、模块、流程、并发模型
│   ├── relationship.md           # 上下游 / 集成方 / 故障传播
│   ├── coding-style.md           # 编码规范（行长/复杂度/命名/安全）
│   ├── code-review.md            # 代码 Review 规范（提交方/Reviewer 清单）
│   ├── glossary.md               # 业务术语表（项目私有术语/缩写/易混对照）
│   ├── failures.md               # 踩坑记录（上下文/根因/绕过/根治）
│   ├── logging.md                # 日志规范（级别/格式/脱敏/链路追踪）
│   ├── apis/                     # 对外接口（按模块组织）
│   │   ├── index.md              # 接口总索引
│   │   ├── _template.md          # 接口文档模板
│   │   ├── api-standards.md      # API 设计规范（协议/路径/响应/版本）
│   │   └── <module>/<Action>.md  # 各模块接口
│   ├── sqls/                     # 持久化结构（DB schema / migration）
│   │   ├── README.md
│   │   └── database.md           # 数据库规范（表设计/索引/事务/迁移）
│   ├── unittest/                 # 单元测试规范（环境 / 生成 / 运行调试）
│   │   └── unittest.md
│   ├── integration_test/         # 集成测试规范（环境 / 用例 / 运行调试）
│   │   └── integration_test.md
│   └── devops/                   # 环境搭建 + 测试环境部署 + 发布规范
│       ├── env.md
│       ├── test-env-deploy.md
│       ├── deployment.md         # 部署与运行规范（环境矩阵/制品/配置/发布）
│       └── development.md        # 本地开发环境规范（依赖/一键运行/IDE/FAQ）
└── plans/                        # 任务产物区（每个任务一个独立目录，互不干扰）
    └── _template/                # 10 文件任务模板
        ├── 00-overview.md        #   —— 本任务的「小 plan.md」，单一真相源
        ├── 01-clarify.md
        ├── 02-plan.md
        ├── 03-implement.md
        ├── 04-ut.md
        ├── 05-deploy.md
        ├── 06-it.md
        ├── 07-docs.md
        ├── 08-review.md
        └── 09-commit.md
```

### 任务发现约定（替代旧的全局 `plan.md`）

| 需求 | 操作 |
|------|------|
| 查看所有历史 / 在途任务 | `ls .harness/plans/` 或 `find .harness/plans -maxdepth 2 -name 00-overview.md` |
| 定位当前分支对应的任务 | `git branch --show-current`，再在各 `00-overview.md` 的 Meta `分支` 字段中匹配 |
| 查看某任务的进度 | 只读该任务的 `00-overview.md`（Progress + 当前步骤） |
| 跨任务统计 / 报表 | 按需临时脚本聚合 `00-overview.md` 的 Meta 块，**不写回**任何共享文件 |

**核心原则**：`00-overview.md` 是本任务的单一真相源，只由本任务分支维护；不同任务的 overview 彼此独立，永远不会互相冲突。

### 严禁产出的反面结构

- `.harness/apis/`、`.harness/sqls/`、`.harness/unittest/`、`.harness/integration_test/`、`.harness/devops/`、`.harness/architecture.md` 直接放在顶层 → 必须迁入 `.harness/docs/` 下，物理目录名沿用项目既有约定。
- **严禁**重新在 `.harness/` 顶层引入全局 `plan.md` 任务总览——多人协作必然冲突；任何"想看所有任务"的需求都通过列 `.harness/plans/` + 读各自 `00-overview.md` 完成。如果发现 `.harness/plan.md` 仍残留，直接删除即可。
- 在 skeleton 之外引入 `README.md` / `conventions.md` / `glossary.md` / `risks.md` / `adr/` / `PROFILES.md` 等占位文件——按需在用到时再加，不要预生成空文件污染目录。

---

## 执行流程

### 前置检查

```
1. 检测旧版产物并迁移（老版 sop.init 产物）
   - 仓库根存在 harness/ 目录 → 先执行迁移（文档迁入 .harness/docs/），再继续新版流程
   - 仓库根存在 ARCHITECTURE.md  → 迁移到 .harness/docs/architecture.md（不在根目录）
   - 均不存在                       → 跳过，继续下一步

2. 检查仓库根是否存在 .harness/
   - 不存在                                → 继续全新初始化
   - 已存在                                → 执行升级检测（脚本幂等，会自动补缺 + 刷新契约性文件）
   - 存在但布局不符                         → 继续执行，脚本会按规则处理
```

### 旧版 harness/ 迁移

当仓库根存在 `harness/` 目录（非隐藏，不带 `.` 前缀）时，说明目标项目之前由老版 sop.init 初始化过。新版使用 `.harness/`（隐藏目录，带 `.` 前缀），两者路径不兼容。执行以下迁移步骤：

**迁移流程**：

```bash
# 1. 确认旧版 harness/ 存在
if [ -d "harness" ]; then
    echo "[MIGRATE] 检测到旧版 harness/ 目录，准备迁移到 .harness/"

    # 2. 创建 .harness/ 和 docs/ 子目录
    mkdir -p .harness/docs

    # 4. 分类迁移旧文件
    for item in harness/*; do
        case "$(basename "$item")" in
            review.md|plans|plan.md)
                mv "$item" .harness/          # 顶层保留
                ;;
            *)
                mv "$item" .harness/docs/     # 文档迁入 docs/
                ;;
        esac
    done

    # 5. 删除已空的 harness/ 目录
    rmdir harness
fi
```

**迁移后注意事项**：

1. 旧版 `harness/` 下的文档文件（`*.md`、`apis/`、`sqls/`、`unittest/`、`integration_test/`、`devops/` 等）会自动迁入 `.harness/docs/`。顶层保留文件（`review.md`、`plans/`）留在 `.harness/` 顶层。
2. 根目录旧版 `ARCHITECTURE.md` 会迁移到 `.harness/docs/architecture.md`（不在根目录）。若 `.harness/docs/architecture.md` 已存在则保留新版、直接删除根目录旧文件。后续收尾优化阶段也是对 `.harness/docs/architecture.md` 操作，而非根目录。
3. 迁移完成后，后续的 `init_harness.sh` 会正常在新版 `.harness/` 骨架基础上**补缺**（新增 `.harness/docs/`、`.harness/plans/` 等），不会删除已有的旧文件。
4. `.harness/` 重命名后 AGENTS.md 中所有 `harness/` 引用需更新为 `.harness/`——后续「AGENTS.md 升级」步骤会自动处理。
5. 项目由 Git 管理，所有写操作均不生成 `.bk.*` 备份文件——如需找回旧内容用 `git restore`。

> **关键设计**：`init_harness.sh` 是幂等的。不论是全新项目还是已有骨架的老项目，**跑一次即可完成升级**——补缺的骨架文件 + 刷新契约性文件 + 智能合并 AGENTS.md。不需要区分「初始化」和「升级」两个命令。
>
> **复制模板时精简 HTML 注释**：SOP 启动时 AI 用 `cp -r .harness/plans/_template .harness/plans/YYYY-MM-DD_<title>` 创建任务目录后，**必须**把 `plans/<task>/00-overview.md` 里所有 `<!-- TEMPLATE-ONLY-DO-NOT-COPY: -->` 标记的 HTML 注释块整段删除，替换为单行指针指向 `_template/`。SOP 规则（Progress / 时间记录）只在 `_template/` 维护，**禁止**在每个任务文件里重复 ~30 行规则。详见 `AGENTS.md` 二、SOP「SOP 启动前置：分支与任务判断」第 3 步。

### 环境探测（可选增强）

> 在初始化前可执行环境探测，了解目标项目特征以做出差异化处理。

1. **项目类型检测**：按优先级 Go → Rust → Java 检测是否为库项目（无 `package main` / `[[bin]]` / main class）。
2. **框架识别**：检测核心框架（Go: go-zero✓/gin△/kratos△ 等），记 `$FRAMEWORK`。若 `$FRAMEWORK` 命中 `references/framework-<name>.md`，主 Agent 在调度相关子 Agent（coding-style / api-standards / unittest / development）时自动加载该文件的对应段落作为额外要求（详见「附带资源 / references」）。
3. **维护者推断**：`git shortlog -sne --since="6 months ago" HEAD` 取近半年 top committer。
4. **AI 入口四态扫描**：检测 `AGENTS.md` / `CODEBUDDY.md` / `CLAUDE.md` 的状态（不存在/普通文件/正确软链/错误软链）。

**库项目差异化处理**：当检测到 `project.type == library` 时：
- `api-standards.md` / `database.md` / `deployment.md` 跳过创建（库项目无独立 API/DB/部署）。
- 注入库项目上下文（`references/library-context.md`），侧重 API surface / 向后兼容 / semver 等。
- 已存在则走更新模式裁剪为库适用版本。

### Step 0 能力探测（API / DB，初始化前必做）

> 目的：无 API / 无 DB 的项目不应初始化 `docs/apis/`、`docs/sqls/` 骨架，也不应调度对应子 Agent。在执行 `init_harness.sh` **之前**完成探测。

1. 主 Agent 读取 `$SKILL_DIR/references/special-agent-detect.md`，以其为完整 prompt 派出 **Explore 子 Agent（只读探测）**。
2. 子 Agent 按固定格式返回 `HAS_API=true|false` / `HAS_DB=true|false` + 证据摘要。
3. 主 Agent 把两个布尔值作为 flag 传入 `init_harness.sh`（见下）；并在「批次二」按同样两值决定是否调度 Agent C（apis）/ Agent D（sqls）：
   - `HAS_API=false` → **不启动** Agent C，汇总报告直接标 `skipped(no external API)`
   - `HAS_DB=false`  → **不启动** Agent D，汇总报告直接标 `skipped(no database)`
4. 探测失败 / 未执行探测时，flag 缺省 `true`（保守，行为与旧版一致）。

### 初始化步骤（全新项目）

1. 执行初始化脚本：
   ```bash
   bash <skill_dir>/scripts/init_harness.sh <repo_root> --has-api=<true|false> --has-db=<true|false>
   ```
   两 flag 缺省均为 `true`（向后兼容）；为 `false` 时脚本跳过复制骨架 `docs/apis/` / `docs/sqls/`（只影响补缺，**不删**目标项目已有文件）。
   若需要手动等价操作：
   ```bash
   cp -r <skill_dir>/assets/harness-skeleton/. .harness/
   cp -r <skill_dir>/assets/plans-template   .harness/plans/_template
   # HAS_API=false → 不复制 docs/apis/；HAS_DB=false → 不复制 docs/sqls/
   ```
   （`<skill_dir>` = 本 Skill 所在目录。）
2. 脚本会额外处理仓库根入口、Git Hooks、Lint 配置与配套 skill：
   - 基于 `assets/agents.md.tmpl` 生成 `AGENTS.md`（**唯一真源入口**），包含四章（一、快速索引 / 二、SOP / 三、开发准则 / 四、禁止红线）。
     - **若 `AGENTS.md` 已存在**：按章节分治——仅强制刷新「二、SOP」章节（核心 SOP 契约），保留「一、快速索引」「三、开发准则」「四、禁止红线」不改不删（项目自定义内容）；仅当第二章有差异时才更新（Git 管理，无需备份）。
  - 创建 `CODEBUDDY.md` → `AGENTS.md` 的软链（兼容 CodeBuddy）。
  - 创建 `CLAUDE.md` → `AGENTS.md` 的软链（兼容 Claude Code）。
    - **若已是软链**：直接重建；**若是真实文件**：直接删除后重建为软链（Git 可找回）。
   - 安装 Git Hooks：通过 `scripts/setup_hooks.sh` 幂等安装 pre-commit / pre-push / commit-msg 三个 hook 软链到 `.git/hooks/`。
   - 注入 Lint 配置：Go 项目（`go.mod` 存在）自动复制 `assets/.golangci.yml` 到仓库根（已存在则跳过）。
   - 把 `clarify` skill 安装到目标仓库的 `.codebuddy/skills/clarify/`（已存在则跳过）。
   - `.harness/docs/` 骨架文件**已存在则不覆盖**（保护用户填写的内容）。
   - `plans/_template/` 下**全部文件**采用「有差异则直接覆盖」策略，确保 skill 升级后新建任务能拿到最新模板结构；已创建的具体任务目录（`plans/<task>/`）一律不动。
   - **特例**：`docs/devops/test-env-deploy.md` 采用「按章节分治」策略（与 `AGENTS.md` 一致）——以 `## 项目自定义` 为分界线，仅强制刷新上方 skill 管控区（环境工具就绪检查 + 团队环境管理 Skill 的操作说明），保留下方项目自定义区（组件清单、常用环境、特殊同步规则）不改不删；仅当 skill 管控区有差异时才更新。
3. 初始化收尾 —— 子 Agent 分两批调度（**必须使用 `subagent_type: general-purpose`**，不可使用只读类型如 `Explore`/`Plan`）。存在依赖：Agent C–M 都需读取**已优化**的 AGENTS.md 才能正确对齐索引与渐进式披露结构，因此必须等 Agent A、B 完成后再并行启动。全部完成后汇总报告给用户：

   **批次一（串行，无依赖前置）**

   **Agent A: 优化 AGENTS.md**

   角色：CODEBUDDY.md/AGENTS.md 优化专家。完整提示词见 `$SKILL_DIR/references/special-agent-agents.md`：将 AGENTS.md 优化为符合渐进式披露原则的 AI 入口文件（硬上限 ≤300 行，≤200 为优秀目标，细节下沉到 `.harness/docs/` 或 `.codebuddy/rules/`；「二、SOP」为 skill 管控契约章，只读，漂移则从模板原样恢复），直接写回 AGENTS.md（Git 兜底，无需备份）。

   **Agent B: 重写 ARCHITECTURE.md**

   角色：架构文档生成专家。完整提示词见 `$SKILL_DIR/references/special-agent-architecture.md`：基于代码事实按 13 节模板生成 `.harness/docs/architecture.md`（至少 1 个 Mermaid 图、数据流追踪、技术选型含 Why），已存在直接覆盖，不确定字段用 `<!-- TODO(sop.init) -->` 占位。

   > **调度约束**：先启动 Agent A，待其把 AGENTS.md 优化写回后，再启动 Agent B（B 生成架构文档无需读 A 产物，但排在其后以保持顺序清晰）。**两者都完成后**，才开始批次二。

   **批次二（并行，依赖 AGENTS.md 已定稿）**

   **Agent C: 丰富 apis/**（**调度前置**：Step 0 探测 `HAS_API=false` → 不启动本 Agent，汇总报告标 `skipped(no external API)`）

   角色：对外接口文档梳理专家。对应指令 `$SKILL_DIR/references/special-agent-apis.md`。

   目标：基于代码真实接口，把 `.harness/docs/apis/` 充实为调用者视角的接口文档集（`index.md` 总索引 + `<module>/<Action>.md` 每接口一篇 + `api-standards.md` 协议规范）。

   相关性判定（前置）：
   - 无任何对外接口证据（无 proto/thrift/OpenAPI、无 HTTP-RPC 框架依赖、无路由注册、纯库无导出接口）→ 判定为**无 API 项目**，**删除** `.harness/docs/apis/` 整个目录后输出 `skipped(no external API)`。
   - 有证据 → 创建/更新模式，按 `apis/_template.md` 逐接口生成，回写 `index.md` 1:1 索引。

   **Agent D: 丰富 sqls/**（**调度前置**：Step 0 探测 `HAS_DB=false` → 不启动本 Agent，汇总报告标 `skipped(no database)`）

   角色：持久化结构文档梳理专家。对应指令 `$SKILL_DIR/references/special-agent-sqls.md`。

   目标：基于真实 DB schema / migration / ORM model，把 `.harness/docs/sqls/` 充实为表设计 / 索引 / 事务 / 迁移规范文档（重点 `sqls/database.md`）。

   相关性判定（前置）：
   - 无任何持久化证据（无 DB 驱动依赖、无 migration、无 schema、纯内存/纯计算库）→ 判定为**无数据库项目**，**删除** `.harness/docs/sqls/` 整个目录后输出 `skipped(no database)`。
   - 有证据 → 创建/更新模式，抽取表结构 + 状态机，填充 `database.md`。

   **Agent E: 丰富 devops/**

   角色：运维文档梳理专家。对应指令 `$SKILL_DIR/references/special-agent-devops.md`。

   目标：基于真实构建/部署/环境配置，把 `.harness/docs/devops/` 充实为可落地的运维文档集（`env.md` / `deployment.md` / `development.md` / `test-env-deploy.md`）。

   任务：扫描 `Makefile` / `Dockerfile` / CI 配置 / 配置文件抽取命令与环境事实；`test-env-deploy.md` 按章节分治仅刷新 skill 管控区，保留「## 项目自定义」用户内容；命令尽量本地实跑验证。

   **Agent F: 丰富 integration_test/**

   角色：集成测试规范梳理专家。对应指令 `$SKILL_DIR/references/special-agent-integration-test.md`。

   目标：把 `.harness/docs/integration_test/integration_test.md` 充实为真实链路、接口/E2E 级的集成测试规范（环境与依赖 / 用例设计 / 运行调试），与 `relationship.md`、`devops/test-env-deploy.md` 对齐。

   约束：禁止与 unittest 测同一层（UT 函数级 Mock，IT 真实链路）；依赖来自 relationship.md、环境来自 devops，用 `@` 引用不复制。

   **Agent G: 丰富 failures.md**

   角色：踩坑记录梳理专家。对应指令 `$SKILL_DIR/references/special-agent-failures.md`。

   目标：从 AI Memory（`.codebuddy/memory/`、`.claude/` 等）与 Git Log（fix/revert 类提交）中提取有证据的踩坑记录，填充 `.harness/docs/failures.md`（每条含 日期 / 上下文 / 根因 / 临时绕过 / 根治方案）。无证据则保留模板结构并注明「暂无历史踩坑记录」。

   约束：禁止编造；Git Log / Memory 缺失时静默跳过；从推断项标注 `来源：git log`。

   **Agent H: 丰富 glossary.md**

   角色：业务术语表梳理专家。对应指令 `$SKILL_DIR/references/special-agent-glossary.md`。

   目标：扫描代码 package / struct 名、配置 key、团队文档，按「项目私有、非公知、不解释会误解」三连问严格过滤，填充 `.harness/docs/glossary.md`（项目私有术语 / 缩写 / 易混对照）。宁可少而精，禁止收录公知术语凑数。

   **Agent I: 丰富 unittest/**

   角色：单元测试规范梳理专家。对应指令 `$SKILL_DIR/references/special-agent-unittest.md`。

   目标：把 `.harness/docs/unittest/unittest.md` 充实为可落地的 Go 单元测试规范（环境搭建 / 生成规范 / 运行调试三段式）。

   前置判定：
   - 若 `.harness/docs/testing.md` 存在（老版本 sop.init 产物）→ 将其内容按新格式迁移到 `unittest/unittest.md` 后**删除** `testing.md`
   - 若 `.harness/docs/testing.md` 不存在 → 根据项目实际情况（`*_test.go` 文件 / `go.mod` 测试依赖 / CI 配置）直接更新 `unittest/unittest.md`
   - 若项目无 Go 代码（无 `*.go` / 无 `go.mod`）→ 输出 `skipped(no Go code)`

   约束：禁止与 IT 测同一层（UT 全 Mock + 函数级）；命令 / 环境来自真实配置，禁止臆造；若仓库存在 `.codebuddy/rules/unittest_*.md`，unittest.md 改为摘录 + 链接，标注权威来源。

   **Agent J: 丰富 relationship.md**

   角色：上下游 / 集成关系梳理专家。对应指令 `$SKILL_DIR/references/special-agent-relationship.md`。

   目标：把 `.harness/docs/relationship.md` 充实为可落地的上下游 / 集成关系文档（上游调用方 / 下游依赖 / 调用关系说明 / 拓扑图 / 故障传播矩阵）。

   前置判定：
   - 若旧版 `dependency-map.md` 残留（`.harness/docs/dependency-map.md` / `.harness/dependency-map.md` / `harness/dependency-map.md` 中含有非占位符实质内容，老版本 sop.init 产物）→ 将其内容按新格式迁移到 `relationship.md` 后**删除**遗留文件
   - 若无旧版残留 → 根据项目实际情况（`go.mod` 依赖 / import 的客户端 / 路由注册 / 配置地址 / 消息生产消费）直接分析代码并填充 `relationship.md`

   约束：调用方 / 依赖 / 失败处理来自真实代码与配置，禁止臆造；故障传播矩阵降级方案须对应真实 fallback 代码；只动 `relationship.md` 与需删除的遗留 `dependency-map.md`。

   **Agent K: 丰富 coding-style.md**

   角色：编码规范梳理专家。对应指令 `$SKILL_DIR/references/special-agent-coding-style.md`。

   目标：把 `.harness/docs/coding-style.md` 从多语言通用模板裁剪并落实为本项目实际语言与工具链的编码规范（语言小节裁剪 / 格式化与 lint 工具填实 / 阈值与 lint 配置对齐）。

   前置判定：
   - 无任何代码文件（纯文档仓库）→ 输出 `skipped(no code)`
   - 命中 `$FRAMEWORK`（如 go-zero）→ 合并 `references/framework-<name>.md` 的 coding-style 段额外要求

   约束：工具名 / 阈值 / 命令必须来自真实配置文件证据（`.golangci.yml` / `.prettierrc` / pre-commit hook），禁止臆造；只动 `coding-style.md`。

   **Agent L: 丰富 code-review.md**

   角色：代码 Review 流程梳理专家。对应指令 `$SKILL_DIR/references/special-agent-code-review.md`。

   目标：把 `.harness/docs/code-review.md` 中的占位符与通用约定替换为项目真实值（主分支名 / build·lint·ut 真实命令 / 覆盖率阈值 / commit message 校验规则），并划清与顶层 `.harness/review.md` 的边界（review.md = AI Review 清单；code-review.md = 团队人工 Review 流程）。

   约束：命令 / 阈值 / 分支名来自真实证据（Makefile / CI 配置 / commit-msg hook），禁止臆造；只动 `code-review.md`，禁止复制 review.md 的 AI 检查清单。

   **Agent M: 丰富 logging.md**

   角色：日志规范梳理专家。对应指令 `$SKILL_DIR/references/special-agent-logging.md`。

   目标：把 `.harness/docs/logging.md` 落实为本项目真实日志体系的规范（日志库 / 级别映射 / trace 字段名 / 脱敏规则 / 采集方式均来自代码证据）。

   相关性判定（前置）：
   - 无任何日志输出证据（纯库项目只返回 error、无日志库依赖、grep 不到日志调用）→ 判定为**无日志项目**，**删除** `logging.md` 后输出 `skipped(no logging)`，并在汇总报告标注需移除 AGENTS.md 中对应索引行
   - 有证据 → 按实际日志库与字段填充

   约束：日志库 / 字段名 / 级别必须来自代码证据，禁止臆造；脱敏条款与 `coding-style.md` §10 用引用对齐，不复制；只动 `logging.md`。

   > **批次二并行执行（C–M）**：Agent A、B 均已完成后，以下十一个 Agent **全部并行**启动（C 接口、D 数据、E 运维、F 集成测试、G 踩坑、H 术语、I 单元测试、J 上下游关系、K 编码规范、L Review 流程、M 日志规范）。它们都读取批次一定稿的 AGENTS.md 以对齐索引与渐进式披露结构——这是与 A/B 的依赖关系，务必先 A、B 后 C–M。Agent C/D 先做相关性判定——无 API 则删 `apis/`、无 DB 则删 `sqls/`；Agent I 先做 testing.md 迁移检查；Agent J 先做旧版 dependency-map.md 迁移检查；Agent M 先做无日志判定。各 Agent 只动自己负责的文件，互不交叉。

   全部完成后汇总报告：
   - Agent A: AGENTS.md 优化前后行数 + 下沉内容说明
   - Agent B: ARCHITECTURE.md 填充情况 + TODO 清单
   - Agent C: apis/ 接口文档数 + 是否因无 API 删除目录
   - Agent D: sqls/ 文档情况 + 是否因无 DB 删除目录
   - Agent E: devops/ 各文件填充情况
   - Agent F: integration_test.md 填充情况
   - Agent G: failures.md 踩坑记录条数 + 是否无证据留空
   - Agent H: glossary.md 术语条数 + 是否因无私有术语留空
   - Agent I: unittest.md 填充情况 + 是否迁移了 testing.md / 是否因无 Go 代码跳过
   - Agent J: relationship.md 填充情况 + 是否迁移了 dependency-map.md
   - Agent K: coding-style.md 裁剪语言 + 工具链填实情况 / 是否注入框架特化
   - Agent L: code-review.md 填实情况（主分支 / 命令 / 阈值）
   - Agent M: logging.md 填实情况 + 是否因无日志删除文件
   - 剩余 TODO 项列表（用户后续需手动处理的部分）
- 不预生成 `README.md` / `conventions.md` / `glossary.md` / `risks.md` / `adr/` 等占位——按需在用到时再加。
- 已有的 `.codebuddy/rules/<topic>_*.md`（如 `unittest_rule.md`）作为 docs 的权威来源，docs 改为摘录 + 链接，避免双轨。

---

## 附带资源

### `scripts/`
- `scripts/init_harness.sh [repo_root]` —— 核心初始化/升级脚本（幂等）。对 `plans/_template/` 下**全部文件**采用「有差异则直接覆盖」策略（只刷新 `_template/` 本身，已创建的具体任务目录不动）；对 `AGENTS.md` 和 `docs/devops/test-env-deploy.md` 采用「按章节分治」策略——分别以 `## 二、SOP` / `## 项目自定义` 为分界线，仅刷新 skill 管控区，保留项目自定义区不动。项目由 Git 管理，所有写操作均不生成 `.bk.*` 备份文件。

### `references/`
- `references/docs-generation.md` —— `.harness/docs/` 生成方法论；初始化后引导用户填充 docs 内容时加载。
- `references/special-agent-detect.md` —— Step 0 能力探测子 Agent 专用指令（Explore 只读）：API / DB 探测方法 + 固定返回格式 `HAS_API=` / `HAS_DB=`。
- `references/special-agent-architecture.md` —— Agent B（ARCHITECTURE.md）专用指令。
- `references/special-agent-agents.md` —— Agent A（AGENTS.md）专用指令。
- `references/special-agent-apis.md` —— Agent C（apis/）专用补充指令，含无 API 时删除目录判定。
- `references/special-agent-sqls.md` —— Agent D（sqls/）专用补充指令，含无数据库时删除目录判定。
- `references/special-agent-devops.md` —— Agent E（devops/）专用补充指令。
- `references/special-agent-integration-test.md` —— Agent F（integration_test/）专用补充指令。
- `references/special-agent-failures.md` —— Agent G（failures.md）专用补充指令，从 Memory + Git Log 提取踩坑记录。
- `references/special-agent-glossary.md` —— Agent H（glossary.md）专用补充指令，按「项目私有 / 非公知」三连问严筛术语。
- `references/special-agent-unittest.md` —— Agent I（unittest/）专用补充指令，含旧版 testing.md 迁移 + 无 Go 代码跳过判定。
- `references/special-agent-relationship.md` —— Agent J（relationship.md）专用补充指令，含旧版 dependency-map.md 迁移判定。
- `references/special-agent-coding-style.md` —— Agent K（coding-style.md）专用补充指令，含语言裁剪 + 工具链填实 + 框架特化注入。
- `references/special-agent-code-review.md` —— Agent L（code-review.md）专用补充指令，含主分支 / 命令 / 阈值填实 + 与顶层 review.md 边界。
- `references/special-agent-logging.md` —— Agent M（logging.md）专用补充指令，含日志库检测 + 无日志项目删除判定。
- `references/merge-agent-prompt.md` —— 归一化合并子 Agent 指令；当检测到仓库根存在多份分散的 AI 入口普通文件（`CODEBUDDY.md` / `CLAUDE.md` 非软链）时，主 Agent 读取本文件调度合并子 Agent，将其统一合并为单一 `AGENTS.md`（模板取自 `assets/agents.md.tmpl`，只读）。
- `references/framework-gozero.md` —— go-zero 框架特化指令；当环境探测 `$FRAMEWORK = go-zero` 时，主 Agent 自动按 `references/framework-<name>.md` 匹配加载，把对应段的额外要求注入相关子 Agent（coding-style / api-standards / unittest / development）。扩展新框架只需新增 `references/framework-<name>.md`，无需改 SKILL.md。

### `assets/` —— 复制到目标仓库使用，不读入上下文
- `assets/harness-skeleton/` —— `.harness/` 骨架（`review.md` + `docs/` 下 20 个模板文件 + `plans/`）。
- `assets/plans-template/` —— 10 文件任务模板。
- `assets/agents.md.tmpl` —— 仓库根 `AGENTS.md` 模板（四章式：快速索引 / SOP / 开发准则 / 禁止红线）。AGENTS.md 是唯一真源，CODEBUDDY.md / CLAUDE.md 均为软链。
- `assets/README.md.tmpl` —— 项目 README 模板。**不自动生成**（红线 3 严禁预生成 README.md）；按需由用户手动 `cp` 到目标仓库根并填充 `{{...}}` 占位。
- `assets/ARCHITECTURE.md.tmpl` —— 项目架构文档模板（Agent B 生成 `.harness/docs/architecture.md` 时作为 13 节骨架参考；不直接复制到目标根）。
- `assets/clarify-skill/` —— Stage 01 配套的 `clarify` skill 模板。
- `assets/.golangci.yml` —— Go 项目 lint 配置模板（初始化时自动复制到仓库根）。

---

## 验证机制

初始化完成后建议执行以下验证（由 `init_harness.sh` 自动执行或手动检查）：

| # | 验证项 | 检查内容 | 阈值 |
|---|--------|---------|------|
| V1 | 行数与存在性 | `wc -l AGENTS.md` >300 行→WARN；README/ARCHITECTURE 缺失→BLOCK | ≤300 |
| V2 | 软链接正确性 | CODEBUDDY.md / CLAUDE.md 必须是指向 AGENTS.md 的正确软链 | 全部正确 |
| V3 | AGENTS.md 章节完整性 | 基于模板 diff 章节，缺失→WARN | 章节完整 |
| V4 | TODO 数量门 | `TODO(sop.init)` 总数 >30→WARN，>60→BLOCK | ≤30 |
| V5 | docs 反向引用+死链 | docs/*.md 必须被 AGENTS.md Index 引用；AGENTS.md 中的 docs 链接必须存在 | 无死链 |
| V6 | 库项目文件一致性 | 库项目不应新建 deployment/database/api-standards | 一致 |
| V7 | .gitignore 冲突 | AGENTS.md / .harness/ 不应被忽略 | 无冲突 |
| V8 | 空目录清理 | 无对外接口项目不应残留 `docs/apis/`；无数据库项目不应残留 `docs/sqls/` | 已删除 |

---

## 红线

1. **严禁**把 `apis/`、`sqls/`、`unittest/`、`integration_test/`、`architecture.md` 放在 `.harness/` 顶层；它们属于 `.harness/docs/` 之下。
2. **严禁**在 `.harness/` 顶层重新引入全局 `plan.md` 任务总览——多人协作必然冲突；一切任务总览能力下沉到各 `plans/<任务目录>/00-overview.md`。
3. **严禁**为补齐"看起来完整"而预生成 `README.md` / `conventions.md` / `glossary.md` / `risks.md` / `adr/` / `PROFILES.md` / `contracts/` / `internals/` / `operability/` 等占位文件——按需创建，避免污染目录、与项目实际结构漂移。
4. **Step 9 Commit 规范**——必须按「**① 进入 commit 时 AI 必先询问 TAPD**（不假设有 / 没有；没有则引导用户创建——默认推荐 AI 通过团队 TAPD skill 代创建；非本团队 / 跳过需记原因到关键决策备忘）→ ② 0. 环境释放**（通过团队环境管理 Skill 执行环境释放命令，结果落「环境释放执行记录」表）→ ③ TAPD 状态推进到「开发中」**（详见 `09-commit.md` 0.2 节：把状态从当前节点推进到「开发中」，**CR 由 push 后 MR 提交自动触发，不在此步完成**）→ ④ 写好全部 md（含 `09-commit.md` 第 2 节 commit message）→ ⑤ **更新 `00-overview.md`**（09 行**结束时间** = "所有 prep 写完" 时刻 + 耗时 + 关键决策备忘追加 commit info）→ ⑥ 一次性 `git add` 代码 + plans 产物（含刚更新的 00-overview.md）+ docs 增量 → ⑦ `git commit`（脚注**默认 `--story=<id>`**，bug fix 改 `--bug=<id>`；**仅一次**）→ ⑧ `git push` 产生 MR，触发 TAPD 开发中 → CR」顺序执行；**严禁**进入 commit 后不询问 TAPD 就直接走流程（没问 / 问完不引导创建都算违规）；**严禁**绕过团队环境管理 Skill 直接调用测试工具、直接执行环境释放命令或任何旁路方式释放环境；**严禁**绕过团队 TAPD Skill 直接调 TAPD MCP；**严禁**全链路最终未落到 CR 就宣布任务收尾（CR 是 push 后才能触发，不在 commit 前置条件里，但任务收尾前必须确认已到达）；**严禁** `00-overview.md` 在 `git commit` 之后才更新（会产生第二次 commit 破坏一个 MR 一个 commit 原则）——必须**先**更新 `00-overview.md`（时间记录 09 行结束时间 + 关键决策备忘 commit info）**再** add + commit。**两个边界点（铁律）**：**边界点 A — 内容锁定**：步骤 ④+⑤（写 commit message + 更新 00-overview.md）都完成之后，**禁止**再改 `00-overview.md` 和 `09-commit.md`「2. 本次实际 Commit」节；**边界点 B — MR 锁定**：MR 合入（或用户明确宣布任务收尾）后，**禁止**再有任何改动；**唯一例外**是边界点 A 与 B 之间，有代码修复（CI 失败 / review 意见）时走 `--amend`——**仅改代码本身**，**不**改 `00-overview.md` / `09-commit.md` / 任何 plans 产物；可反复不限次数，始终只有一个 commit；一旦到达边界点 B 就彻底冻结不能再 amend。**`--amend` 允许**（一个 MR 一个 commit 原则）：① 首次 commit 之前（含 push 之前）的微调可直接 `git commit --amend` 改写；② push 后 CI 失败 / review 意见 / follow-up 修复，**只能**通过 `git commit --amend` 累积到原 commit 上（可反复），**严禁**新增第二个 commit（不允许 `chore(specs): post-commit notes` 之类的"补元信息" commit）；③ amend 后 push 必须用 `git push --force-with-lease`（**禁止**裸 `--force`）；④ 不再通过 `09-commit.md`「3. Push 记录」表或任何 md 产物记录 MR 链接 / amend 次数 / 合入时间 / CR 状态——这些都在 GitLab / `git log` / TAPD 系统里能查，**不**重复。**全程不记录 git / TAPD 系统可查的元数据**——`00-overview.md` / `09-commit.md` / 关键决策备忘 都不填 commit ID / push 时间 / amend 次数 / MR 链接 / CR 状态；**09 行结束时间 = "所有 prep 写完" 时刻**（**先**写入 `00-overview.md` **再**执行 `git add` + `git commit` + `git push`）。详见 `assets/plans-template/09-commit.md`「0. 前置条件」「1. 执行顺序」「2. amend 流程」节。
5. **严禁**违反 TDD 红绿循环——Step 2 Plan 产物 `02-plan.md` **必须**包含 `§6 UT 用例设计` 章节（被测对象 / 测试文件 / 输入 / 期望 / Mock 边界），先于 Step 3 Implement 落地；Step 3 Implement 必须按 Plan §6 的用例先写测试跑红、再写最小实现转绿；Step 4 UT 产物 `04-ut.md` 用例清单**必须**与 `02-plan.md §6` 逐条对齐（含「Plan §6 编号」列）。**禁止**用「先写实现再补测试」的反向流程，**禁止**让 UT 与 IT 测同一层逻辑（UT 全 Mock + 函数级；IT 真实链路 + 接口/E2E 级）。
6. **严禁**漏记或事后回填编造 `00-overview.md`「时间记录」表中的开始 / 结束时间——开始时间必须在用户确认开始的当下写入；结束时间必须在向用户发起结束确认之前写入；漏记的步骤备注列写「漏记」并保持空白，**禁止**事后猜测时间戳。该表是任务级时间审计的唯一来源。
7. **严禁**AI 在做当前任务时主动读取 / 参考其他 `.harness/plans/<其他任务目录>/` 下的 md 产物（含 `00-overview.md`、`01-clarify.md` … `09-commit.md`、`.harness/design.md` 等）。任务之间物理隔离、互为独立真相源，跨任务参考会污染当前任务的设计判断。**唯一例外**：用户**显式**说「参考任务 X」时，可读指定的那一个任务目录，参考内容**只放对话上下文**，禁止自动写回当前任务。详见 `agents.md.tmpl` 二、SOP「任务隔离原则（强制）」章节。
8. **小需求模式**（02 Plan 估算 `预估代码改动行数 ≤ 10` → `00-overview.md` Meta `小需求模式` 设为 ✅）：03-04（Implement+UT）、07-09（Docs+Review+Commit）的开始/结束确认可**合并为单次**（AI 一次说完"我准备做 X-Y-Z"后开始跑，跑完一次性汇报），但**严禁**——① 漏掉这 6 个步骤的 md 产物 / `00-overview.md` 时间记录 / Progress 勾选；② 把 05 Deploy / 06 IT 纳入自动批次（环境敏感 + 真实链路核验，必须显式确认）；③ 漏估后不修正 Meta 状态（若实际改动 > 10 行，应在汇报 03-04 结论时同步把 `小需求模式` 改回 ⬜）。详见 `agents.md.tmpl` 二、SOP「任务规模分支」章节。

