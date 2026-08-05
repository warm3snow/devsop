# 上下游 / 集成关系梳理子 Agent 指令

> 本文件作为 `relationship` 梳理子 Agent 在通用 prompt 基础上的**补充指令**。主 Agent 调度时一并传入。
> 负责对象：`.harness/docs/relationship.md`。

---

## 核心目标

把 `.harness/docs/relationship.md` 充实为**可落地的上下游 / 集成关系文档**（上游调用方 / 下游依赖 / 调用关系说明 / 拓扑图 / 故障传播矩阵）。

---

## 步骤

### 0. 前置检查：清理旧版 dependency-map.md

> 老版本 `sop.init` 初始化的是 `dependency-map.md`（旧版格式：mermaid 调用关系图 + 故障传播分析）；新版本骨架已改为单一的 `relationship.md`（新格式，内部调用关系为主）。
> 升级旧项目时可能残留老版本 `dependency-map.md`，需将其中的实质内容迁移进 `relationship.md` 并按新格式落地，遗留文件随后删除。新版本骨架中已不存在 `dependency-map.md`，无需保留。

检查以下残留旧文件（按优先级）：
- `.harness/docs/dependency-map.md` 中是否含有**非占位符、非模板注释**的实质内容（即已迁移前由老版本填充的字段：上游调用方、下游数据存储/第三方服务/中间件、调用关系图、故障传播分析等）。
- 若存在老版本 `harness/` 顶层残留（`.harness/dependency-map.md` 或 `harness/dependency-map.md`），同样视为旧版产物参与迁移。

**若存在旧版 `dependency-map.md` 实质内容**（老版本 sop.init 产物）：
- 读取残留 `dependency-map.md` 的全部内容
- 将其中的实质内容按以下映射迁移到 `.harness/docs/relationship.md`：
  - 「上游调用方（谁会调我）」表（调用方 / 入口 / 频率 / 失败影响）→ 归入 `relationship.md` 的「## 上游（谁在用本项目）」表（调用方 / 代码仓库 / 用途 / 协议集成方式 / 关键入口 / 联系人）
  - 「下游依赖」的「数据存储」「第三方/内部服务」「中间件」三表 → 合并归入 `relationship.md` 的「## 下游（本项目用了谁）」表（被调方 / 代码仓库 / 用途 / 协议集成方式 / 关键入口 / SLA 版本约束 / 失败处理 / 集成代码位置）
  - 「调用关系图（mermaid）」→ 转化为 `relationship.md` 的「## 拓扑图」（ASCII 或 mermaid，覆盖所有强依赖）
  - 「故障传播分析」→ 归入 `relationship.md` 的「## 故障传播矩阵」（下游外部条件 / 受影响功能 / 失败表现 / 是否可降级 / 降级兜底方案）
- 迁移完成后，**删除**残留的旧版 `dependency-map.md`（`.harness/docs/dependency-map.md`、`.harness/dependency-map.md`、`harness/dependency-map.md` 任一落点）
- 输出 `migrated(dependency-map.md → relationship.md)` + 迁移内容摘要

**若不存在旧版残留**（无实质内容）：
- 直接进入步骤 1，根据项目实际情况分析代码并更新 `relationship.md`
- 输出 `no-migration(no legacy dependency-map.md)`

### 1. 扫描上下游 / 集成关系事实

- **上游调用方**：谁在调用本项目 —— 路由注册、`main` 包暴露的 HTTP/gRPC 服务、被其它仓库 `import` 的 package、订阅的 WebHook / Topic
- **下游依赖**：本项目调用了谁 —— `go.mod` 依赖、`import` 的外部 SDK/客户端、adapter / client 目录、配置文件中的地址与凭证、消息生产/消费
- **集成方式**：HTTP / RPC(gRPC/Thrift) / 包依赖 / CLI 嵌入 / SDK 引入 / WebHook 订阅 / 消息消费
- **调用拓扑**：从入口到下游的关键调用链，跨模块、跨服务的实际路径
- **故障处理**：超时、重试、降级的真实代码实现（如 `circuit breaker`、fallback 函数、配置开关）
- 来源必须来自真实代码 / 配置 / 依赖文件，**禁止臆造**

### 2. 生成 / 更新文档

按 skeleton 五段式填充 `relationship.md`：
- **上游（谁在用本项目）** —— 调用方 / 代码仓库 / 用途 / 协议集成方式 / 关键入口 / 联系人
- **下游（本项目用了谁）** —— 被调方 / 代码仓库 / 用途 / 协议集成方式 / 关键入口 / SLA 版本约束 / 失败处理（超时重试降级）/ 集成代码位置
- **调用关系说明** —— 按业务场景/功能模块组织的关键调用链（触发场景 / 调用拓扑 / 传输数据 / 关键代码 / 失败影响 / 相关文档）
- **拓扑图** —— ASCII 或 mermaid，覆盖所有强依赖；纯库项目可省略
- **故障传播矩阵** —— 下游失败 → 受影响功能 → 失败表现 → 是否可降级 → 降级兜底方案

### 3. 对齐与引用

- 填写文件头 `> Source:` 与 `> Last-verified:`（来源与扫描日期）
- 调用链「相关文档」链接到对应的 `apis/<module>/<Action>.md` 或下游仓库文档
- 依赖关系与 `architecture.md`、`devops/` 保持一致，用 `@` 引用不复制
- 故障传播矩阵中的降级方案必须来自真实代码（如重试配置、fallback 分支），禁止编造

---

## 约束

- 命令 / 依赖 / 调用方 / 失败处理必须来自真实代码、配置、`go.mod`、CI 配置，禁止臆造
- 旧版 `dependency-map.md` 迁移后必须删除，不留冗余文件
- 只动 `relationship.md` 与需删除的遗留 `dependency-map.md`，不动其它 docs
- 纯库项目（无对外接口、无下游服务）可只填上游（被 import 方）与下游（第三方依赖），拓扑图可省略
- 若项目无任何外部依赖与调用方（孤立工具）→ 保留模板结构并注明「暂无上下游关系」
