# logging.md 特殊子 Agent 指令

> 本文件作为 `logging.md` 子 Agent 在通用 prompt 基础上的**补充指令**。主 Agent 调度时一并传入。
> 负责对象：`.harness/docs/logging.md`。

---

## 核心目标

把 `.harness/docs/logging.md` 从通用模板落实为本项目真实日志体系的规范——日志库、级别映射、链路追踪字段、脱敏规则均来自代码证据。

---

## 相关性判定（前置）

- 项目无任何日志输出证据（纯库项目只返回 error 不打日志、无日志库依赖、grep 不到日志调用）→ 判定为**无日志项目**，删除 `.harness/docs/logging.md` 后输出 `skipped(no logging)`
- 有证据 → 进入下方步骤

---

## 步骤

### 1. 采集日志事实

- 日志库识别（以依赖文件 + import 证据为准）：
  - Go：`go.mod` 中 `zap` / `logrus` / `logx`（go-zero）/ `slog` / 自研封装（grep `log.` / `logger.` 调用点确认实际封装包）
  - Python：`logging` 标准库 / `loguru` / `structlog`
  - Java：`slf4j` + `logback` / `log4j2`
- 级别体系：项目实际使用的级别集合（如 logx 只有 Info/Error/Slow 等）→ 映射到模板等级表，不存在的级别删除或标注 N/A
- 链路追踪字段：grep 代码中真实的 trace 字段名（`traceId` / `trace_id` / `TraceId` / `spanId`），替换模板中的「traceId」为项目实际字段
- 日志格式：是否 JSON 结构化（看初始化代码 / 配置文件），有无统一字段（time / level / caller / msg）
- 脱敏现状：代码中已有的脱敏工具函数（grep `mask` / `desensit` / `***`），有则在「禁止打印」节引用实际函数名
- 动态调级：是否有运行时调整日志级别的机制（配置中心 / admin API / 信号），有则填实「原则」段
- 日志输出位置：`devops/env.md` 或部署配置中的日志路径 / 采集方式（stdout → ELK / 文件 → Fluent Bit），在文档末尾补充一节「日志采集与查询」（无证据则 `<!-- TODO(sop.init) -->`）

### 2. 生成 / 更新文档

- 「范围」段：填实际日志库与适用模块
- 「日志等级定义」表：按项目实际级别裁剪；保留级别语义列，删除项目没有的级别行
- 「必须打印日志的场景」表：保留通用结构；「必须包含信息」列中的 traceId 替换为实际字段名
- 「禁止 / 减少打印的场景」表：保留；敏感字段清单结合 `coding-style.md` §10 密钥与敏感信息条款，用 `@` 引用不复制
- 「Code Review 检查清单」：保留；若项目有自定义检查项（如自研日志封装的必传参数）补充之
- 「参考」段：修正失效链接（`deployment.md` → `devops/deployment.md`；`api-standards.md` → `apis/api-standards.md`，无 API 项目删除该行）

---

## 约束

- 只动 `.harness/docs/logging.md`，不动其它 docs
- 日志库 / 字段名 / 级别必须来自代码证据，禁止臆造；无证据字段保留 `<!-- TODO(sop.init) -->`
- 敏感信息脱敏条款与 `coding-style.md` §10 对齐，用引用而非复制，避免双轨漂移
- 无日志项目删除文件后，需同步检查 AGENTS.md 索引中是否引用了 `logging.md`——若有引用，在主 Agent 汇总报告中标注「需移除 logging.md 索引行」（本 Agent 不动 AGENTS.md，由 Agent A 产物或主 Agent 收尾处理）
