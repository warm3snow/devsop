# references/docs-generation.md

> `.harness/docs/` 生成方法论。**通用版**——不绑定任何语言、框架、领域。
>
> 加载时机：
> 1. **Scenario A 之后**：项目刚初始化完，需要给空骨架填实
> 2. **存量项目反向补齐**：项目已经存在但 `docs/` 还是空的
> 3. **阶段 07 Docs**：任务执行到文档同步步骤时，作为决策参考

---

## 〇、读这份方法论之前

下文给出的目录结构、章节模板、抽取脚本都是**示意**，不是模板硬约束。
真正不变的，只有以下五件事：

1. **Why**：docs 存在的目的（§ 一 核心理念）
2. **What 的分层维度**：Orientation / Contract / Internals / Operability（§ 二 四层模型）
3. **How 的方法学**：从信息源到产物的提取-抽样-修订循环（§ 三 通用生成法）
4. **When**：触发时机与对应动作（§ 四）
5. **不变的反模式**（§ 五）

具体到某个项目落到哪些文件、用什么工具抽取，由 §六「项目形态自适应」决定。

---

## 一、核心理念

`.harness/docs/` 不是"项目介绍 / README 增强版"，而是 **让一个全新的人（或 AI Agent）在不读源码的前提下，能理解、修改、运维这个项目** 所需的最小知识集。

四条原则，与项目类型无关：

| # | 原则 | 含义 |
|---|------|------|
| 1 | **代码是真相，docs 是地图** | 文档过期不可怕，文档与代码不一致才致命；写文档时把"如何与代码同步"写进去（每篇文档脚注源码路径 + 同步时间） |
| 2 | **按读者写，不按作者写** | 契约文档站在调用者视角；架构文档站在新接手者视角；ADR 站在未来维护者视角 |
| 3 | **半自动 > 全自动 > 全手动** | 全自动 AI 会编造细节；全手动没人坚持；**AI 起草 → 人 review → 入库**才能跑长期 |
| 4 | **分层、按需、增量** | 不要一次性产 100 个文件；按重要性分批产、产完一批让人看，再产下一批 |

---

## 二、What —— docs 的四层模型（与项目类型解耦）

不论项目是后端服务、前端 SPA、CLI 工具、SDK / 库、移动端、数据管线，docs 都要回答以下四类问题：

| 层 | 名称 | 回答的问题 | 失去后的代价 |
|---|------|-----------|-------------|
| L1 | **Orientation 定位层** | 这是什么？跑起来长啥样？模块怎么切？数据怎么流？ | 新人 / AI 无法形成心智模型，所有下层文档都看不懂 |
| L2 | **Contract 契约层** | 别人怎么用它？有哪些接口 / API / 命令 / 事件 / props / CLI flags？ | 集成方踩坑、版本升级破坏性变更不可控 |
| L3 | **Internals 内核层** | 为什么这么实现？关键算法、状态机、数据模型、持久化结构是怎样的？ | 维护者只能逆向工程，重构如盲人摸象 |
| L4 | **Operability 运维层** | 怎么本地跑？怎么测？怎么发布？怎么观测？怎么回滚？ | 项目交接 = 重新踩坑 |

**层间生成顺序硬要求**：L1 → L2/L3 并行 → L4。**严禁**先写契约文档而不写定位层（没有上下文，契约文档没人能看懂）。

> 各层在不同项目类型里**落到什么文件**，见 §六。

---

## 三、How —— 通用生成法（每层共享同一个循环）

不论生成哪一层文档，都遵循同一个 5 步循环：

```
Scan        →  Extract     →  Draft      →  Verify     →  Commit
扫描信息源     抽取结构化事实    生成 Markdown   抽样对照源码    用户 review 后入库
```

### Step 1: Scan —— 找到信息源

每层都有"权威信息源"，AI **必须**先列出来再开抽取。常见信息源类型：

| 信息源类型 | 示例 |
|-----------|------|
| **入口文件** | `main.*` / `index.*` / `server.*` / `cli.*` / `App.*` / `__main__.py` |
| **路由 / 调度 / 入口注册表** | `router.*` / `routes/` / `*.routing.ts` / `urls.py` / `mod.rs` 的 `pub` 列表 |
| **类型 / 接口定义** | `*.proto` / `*.thrift` / `openapi.yaml` / `*.d.ts` / `schema.graphql` / IDL |
| **构建 / 运行配置** | `Makefile` / `package.json` / `Cargo.toml` / `pyproject.toml` / `pom.xml` / `Dockerfile` |
| **测试入口** | `tests/` / `__tests__/` / `*_test.go` / `spec/` |
| **持久化 schema** | DB 的 `SHOW CREATE TABLE` / migrations / ORM model / `*.proto` for storage |
| **CI / CD 配置** | `.github/workflows/` / `.gitlab-ci.yml` / Jenkinsfile |
| **依赖图** | lockfile / `go mod graph` / `npm ls` / `cargo tree` |

> AI 起手第一件事：用 `list_dir` 看仓库根，再用 `codebase_search` 定位上述类型的文件，**不要**凭记忆假设它们一定存在。

### Step 2: Extract —— 抽取结构化事实

把代码里的事实抽成"结构化条目"再渲染成 Markdown，**不要**让 LLM 自由文字描述（容易编造）。

| 待抽事实 | 抽取手段（择一即可） |
|---------|--------------------|
| 模块清单 | 顶层目录树 + 每个目录的 README / 第一行 docstring |
| 入口与启动方式 | 入口文件名 + 启动命令（从 `package.json scripts` / `Makefile` / `Dockerfile CMD` 中提取） |
| 对外契约 | IDL 优先；其次注解/装饰器；最后回退到 handler / exported function 签名 |
| 错误码 / 异常 | grep `raise` / `throw` / `return Err` / `Error(...)` 语句 + 集中错误码表 |
| 依赖图 | 包管理器命令输出 |
| DB schema | 直接连测试库 `SHOW CREATE TABLE` / 读 migration 历史 |

**铁律**：抽取脚本的输出应当是**确定性的**——相同代码两次跑，产出 byte-by-byte 一致；这样才能放进 CI 做"docs 漂移"检测。

### Step 3: Draft —— 生成草稿

- 草稿默认写到 `*.draft.md`，**不要**直接写正式文件，避免覆盖人工修订。
- 模板里**保留 `<!-- TODO: ... -->` 占位**，标记 AI 拿不准的字段，等人填。
- 文档头部固定脚注：
  ```markdown
  > Source: <抽取来源文件 / 命令>
  > Generated: <date>  by <skill / script name>
  ```

### Step 4: Verify —— 抽样对照

每生成 N 篇同类文档（N=10 是经验值），**随机挑 2 篇**对照源码：
- 名字（接口名 / 字段名 / 命令名）是否与代码一致？
- 默认值、必填、可选关系是否对？
- 错误处理 / 失败语义是否齐全？

发现不一致：**改抽取脚本**，重生成全部，**禁止**手工补丁（手工补丁下次再生成又会被覆盖）。

### Step 5: Commit —— 人工 review 后入库

- diff `*.draft.md` 与已有正式文件，由用户决定合入策略。
- 入库的同时更新对应 `index.md` / 导航表。

---

## 四、When —— 触发时机与对应动作

| 触发场景 | 对应动作 | 输出位置 |
|---------|---------|---------|
| **项目刚初始化（Scenario A）** | 按 L1 → L2/L3 → L4 顺序，逐层生成草稿 + 用户 review | `.harness/docs/` 全部 |
| **存量项目首次补齐** | 同上，**按模块分批**：先补核心模块；契约层每批 N 篇 stop 一次 | 同上 |
| **任务执行到 Stage 07 Docs** | 按本次代码 diff 反推**增量**更新；只动这次任务影响到的文档 | 仅本次涉及的文档 |
| **季度 / 版本健康检查** | 抽样对照（名字 / 默认值 / 错误码），不一致开 chore 任务 | 暴露问题 → 任务 → 修复 |
| **大重构 / 架构演进后** | 强制触发完整 Stage 07；必要时新增 ADR 记录决策 | `.harness/docs/` + `.harness/adr/` |
| **依赖大版本升级** | 重生成 L4 的环境 / 部署文档，对照新版命令 / 配置 | `.harness/docs/<L4 文件>` |

---

## 五、反模式（与项目类型无关，全部必须避免）

| # | 反模式 | 后果 | 正确做法 |
|---|--------|------|---------|
| 1 | **一次性批量生成全部文档** | 量大质低，没人 review，写完即烂 | 按模块 / 按层分批，每批人工 review |
| 2 | **AI 生成完直接合入** | AI 会编造参数 / 默认值 / 错误码 | 抽样 ≥3 处与代码对照 |
| 3 | **docs 与代码分两次 PR** | docs PR 永远不合并 | 同 Stage 07 内完成，与代码同 PR |
| 4 | **只记"是什么"不记"为什么"** | 半年后无人理解决策 | ADR 记"为什么"，契约层 / 内核层记"是什么" |
| 5 | **契约文档复制源码** | 失去调用者视角，变成"代码翻译" | 从调用者视角写：怎么调 / 返回什么 / 错了怎么看 |
| 6 | **跳过定位层直接写契约 / 内核** | 契约堆砌、内核孤立，无上下文 | 必须先 L1 通过 review，再做 L2/L3 |
| 7 | **持久化 schema 抄代码字符串** | 与线上不一致 | 直接从测试库 / migration 真实状态导出 |
| 8 | **覆盖已有人工修改** | 用户修订丢失 | 默认输出 `*.draft.md`，由用户 diff 后合入 |
| 9 | **AI 用记忆代替扫描** | 文件路径 / 命令名臆想 | 起手必须 `list_dir` / `codebase_search` 验证 |
| 10 | **文档无源码脚注** | 不知道何时与谁同步 | 头部固定 `Source` + `Generated` 脚注 |

---

## 六、本骨架的物理布局

> 本 skill 的 skeleton 与团队当前 `.harness/` 完全一致。所有 docs 落到以下固定物理路径：

| 用途 | 物理路径 |
|------|---------|
| 系统架构 | `.harness/docs/architecture.md` |
| 上下游 / 集成 | `.harness/docs/relationship.md` |
| 编码规范（行长/复杂度/命名/安全） | `.harness/docs/coding-style.md` |
| 团队人工 Code Review 流程 | `.harness/docs/code-review.md` |
| 业务术语表 | `.harness/docs/glossary.md` |
| 踩坑记录 | `.harness/docs/failures.md` |
| 日志规范 | `.harness/docs/logging.md` |
| 对外接口 | `.harness/docs/apis/<module>/<Action>.md` + `apis/index.md` + `apis/_template.md` + `apis/api-standards.md` |
| 数据 / Schema | `.harness/docs/sqls/README.md` + `sqls/database.md` |
| 单元测试规范 | `.harness/docs/unittest/unittest.md` |
| 集成测试规范 | `.harness/docs/integration_test/integration_test.md` |
| 环境搭建 | `.harness/docs/devops/env.md` |
| 测试环境部署 | `.harness/docs/devops/test-env-deploy.md` |
| 部署与运行规范 | `.harness/docs/devops/deployment.md` |
| 本地开发环境规范 | `.harness/docs/devops/development.md` |
| AI Code Review 指导规范 | `.harness/review.md`（顶层，非 docs/） |

> "L1 Orientation / L2 Contract / L3 Internals / L4 Operability"是辅助 AI 思考"应当写什么"的方法论标签——
> **物理目录命名固定为 `architecture.md / relationship.md / apis/ / sqls/ / unittest/ / integration_test/ / devops/`，不要为了"贴标签"再造 `contracts/internals/operability` 一套**。

### 信息源映射示例（按形态）

| 待抽事实 | 后端服务 | CLI | 库/SDK | 前端 |
|---------|---------|-----|-------|------|
| 入口 | `main.py` / `server.go` / `app.js` | `cmd/root.go` / `bin/<name>.js` | `__init__.py` / `lib.rs` / `index.ts` | `main.tsx` / `App.vue` |
| 契约 | router 注册 + handler 签名 | `argparse` / `cobra` / `clap` 子命令 | `__all__` / `pub` 导出 / `export` | 路由表 + 组件 props |
| 错误码 | `raise <Exc>` 集中表 | exit code 表 | 自定义 Error 类 | 错误边界 + toast 文案 |
| 持久化 | DB schema | 配置文件 / 缓存目录 | 无（或 file format spec） | localStorage / IndexedDB schema |

---

## 七、按需加载与目录约定

`.harness/docs/` 是按需增长的，不要一次性把所有占位文件都建出来。但是必须遵守的约定：

1. **每篇文档头 5 行**包含：
   - 一句话摘要
   - 目标读者
   - Source（信息源路径）
   - Generated / Last-verified 时间
   - 链接到相关上层 / 下层文档
2. **`apis/` 列表型目录**强制有 `index.md` 总表，能 1:1 对应正式文档列表。
3. **项目专属 rules 优先**：若仓库根存在 `.codebuddy/rules/<topic>_*.md`（如 `unittest_rule.md`、`cls_mcp_rule.md`），它们是该 topic 的**权威来源**——
   - `docs/<topic>/` 等同名文档应**摘录 + 链接**，不复制粘贴；
   - 二者冲突时以 `.codebuddy/rules/` 为准；
   - 修订 rules 必须同步修订 docs，反之亦然；任务模板 04-ut.md / 05-deploy.md 等阶段会强制要求两者都读。
4. **不要为了"看起来完整"预生成 `README.md` / `conventions.md` / `glossary.md` / `risks.md` / `adr/` / `PROFILES.md`** 等占位——按需在用到时再加。

---

## 八、推荐工作流（Scenario A 之后）

按顺序、严格分批，每一步都等用户确认：

```
Step 1  生成 architecture.md / relationship.md 草稿（架构图 / 模块表 / 数据流 / 上下游）→ 用户 review
Step 2  生成 sqls/ 草稿（持久化 schema、关键状态机）→ DBA / 维护者 review
Step 3  生成 apis/ 草稿，按模块分批，每批 N=10 → 抽样 2 篇对照代码
Step 4  生成 unittest/unittest.md + integration_test/integration_test.md + devops/{env.md, test-env-deploy.md}（含运行命令）→ 实跑一遍验证命令可用
Step 5  按需补齐其它 docs/<topic>/ 文件
```

---

## 九、质量自检清单（与形态解耦）

文档"完成"的最低标准：

### Orientation
- [ ] 有一张 ASCII / mermaid 图，从外部触发到核心组件再到出口完整画完
- [ ] 模块表覆盖全部顶层目录（每行：模块 / 职责 / 入口文件 / 主要依赖）
- [ ] 至少 1 个端到端典型流程被画完整

### Contract
- [ ] 对外接口 / 命令 / 公共 API ≥ 80% 有独立文档
- [ ] 每篇有：用法、参数表、返回 / 输出、错误 / 失败模式、示例、变更记录
- [ ] `index.md` 与文件 1:1 对应
- [ ] 抽样 3 篇与源码核对一致

### Internals
- [ ] 每个持久化结构有对应文件，字段全部带含义说明
- [ ] 每个关键状态机有图 + 转换条件
- [ ] 与外部依赖的契约（如第三方 API、协议版本）单独成节

### Operability
- [ ] 新人按文档能在 30 分钟内本地跑起来
- [ ] 测试 / 构建 / 部署 / 回滚命令都可一键执行
- [ ] 关键观测指标 / 报警阈值有列表
- [ ] `unittest/unittest.md` 三段式齐全（环境搭建 / 生成规范 / 运行调试），且 § 一的"前置依赖检查清单"按本项目实际填好
- [ ] 若仓库存在 `.codebuddy/rules/unittest_*.md`，`unittest/unittest.md` 已链接并标明权威关系（不复制粘贴冲突内容）
- [ ] `integration_test/integration_test.md` 三段式齐全（环境与依赖 / 用例设计 / 运行调试），并已与 `relationship.md`、`devops/test-env-deploy.md` 对齐（依赖来自 relationship、环境部署来自 devops）
- [ ] 若仓库存在 `.codebuddy/rules/integration_test_*.md` / `it_*.md`，`integration_test/integration_test.md` 已链接并标明权威关系
- [ ] `devops/env.md` 列出本地启动方式
- [ ] `devops/test-env-deploy.md` 列出测试环境部署 / 同步流程

---

## 十、与其他 SOP 阶段的关系

```
Stage 02 Plan        → 必须先读 docs/ 的 L1 / L2 后再设计方案
Stage 03 Implement   → 与 docs/ 的 L3（schema / state machine）对照实现
Stage 04 UT          → 按 docs/ 的 L4（unittest 规范）写测试
Stage 05 Deploy      → 按 docs/ 的 L4（部署 / 回滚）执行
Stage 06 IT          → 按 docs/ 的 L4（integration_test 规范）执行集成测试
Stage 07 Docs        → 增量更新 docs/，与本次代码改动一一对应
```

`.harness/docs/` 不是写一次就完事的，**它是 SOP 的供血系统**——每个阶段都在读它，Stage 07 在补它，越来越准。

---

## 附 A：最小可工作产出（MVP docs）

如果项目刚启动，时间紧只来得及做最小集，**不能砍**的只有这 3 件：

1. `.harness/docs/architecture.md` —— 一图一段话讲清楚"这是什么"（至少 1 个 Mermaid 图 + 系统定位）
2. `.harness/docs/relationship.md` —— 上下游 / 集成关系（上游调用方 + 下游依赖表，哪怕每行只填名字）
3. `.harness/docs/apis/index.md` —— 至少把对外暴露面列全（可只列名字，详情后补；无 API 项目由 Agent C 删除 `apis/` 目录，此件可省）

剩下的允许暂缺，但每份暂缺文档都应在对应文件保留 `<!-- TODO(sop.init): ... -->` 占位，避免漏。**严禁**预生成 `.harness/docs/README.md` / `conventions.md` / `glossary.md` / `risks.md` / `adr/` 等占位（红线 3）——按需创建。
