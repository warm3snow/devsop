# 单元测试规范梳理子 Agent 指令

> 本文件作为 `unittest` 梳理子 Agent 在通用 prompt 基础上的**补充指令**。主 Agent 调度时一并传入。
> 负责对象：`.harness/docs/unittest/unittest.md`。

---

## 核心目标

把 `.harness/docs/unittest/unittest.md` 充实为**可落地的 Go 单元测试规范**（环境搭建 / 生成规范 / 运行调试三段式）。

---

## 步骤

### 0. 前置检查：清理旧版 testing.md

> `testing.md` 是老版本 sop.init 的遗留产物，新版骨架中已不存在，应使用 `unittest/unittest.md` 替代。
> 仅在升级旧项目时可能需要处理残留的 `testing.md`。

检查 `.harness/docs/testing.md` 是否残留：

**若存在**（老版本 sop.init 产物）：
- 读取 `.harness/docs/testing.md` 的全部内容
- 将其中的实质内容（非占位符、非模板注释）按以下映射迁移到 `.harness/docs/unittest/unittest.md`：
  - `testing.md` 的「分层与职责」/「覆盖率门禁」/「测试用例命名」/「表驱动测试」/「断言规范」/「Mock 与 Stub」/「TDD 流程」/「辅助函数与生命周期」/「禁止项」/「测试数据」/「性能基准测试」→ 归入 `unittest.md` 的「二、生成规范」对应子节
  - `testing.md` 中的实际工具名称（如 `testify`、`gomock`）→ 对应填入 `unittest.md` 的「一、环境搭建」技术选型表
  - `testing.md` 中的实际运行命令 → 对应填入 `unittest.md` 的「三、运行调试」
  - `testing.md` 中仍为 `{{placeholder}}` 的占位符 → 保留 `<!-- TODO(sop.init) -->` 待后续填充
- 迁移完成后，**删除** `.harness/docs/testing.md`
- 输出 `migrated(testing.md → unittest/unittest.md)` + 迁移内容摘要

**若不存在**：
- 直接进入步骤 1，根据项目实际情况更新 `unittest.md`
- 输出 `no-migration(no testing.md)`

### 1. 扫描单元测试事实

- 现有 UT 用例：`*_test.go` 文件数量 / 分布 / 典型测试结构
- 测试框架：`go.mod` 中 `testify` / `gomock` / `sqlmock` 等依赖
- Mock 生成方式：是否有 `//go:generate mockgen` 注释 / `mock/` 目录
- 测试运行方式：`Makefile` 中的 test target / CI 配置中的测试命令
- CI 覆盖率门禁：`golangci-lint` 配置 / CI pipeline 中的覆盖率阈值
- 若仓库存在 `.codebuddy/rules/unittest_*.md`：读取并作为权威来源

### 2. 生成 / 更新文档

按 skeleton 三段式填充：
- **一、环境搭建与依赖安装** —— 技术选型表（`go test` / `testify` / `gomock` / `sqlmock`）、前置依赖检查清单（填入本项目实际依赖）、分步安装命令（按项目实际依赖调整）
- **二、生成规范** —— 通用强制条款（红线）、测试类型与适用场景（按项目实际）、文件命名与组织硬约束、Mock 策略（Go 接口即契约）、表驱动测试用例设计自检清单
- **三、运行与调试** —— 标准执行命令（与 CI 一致）、调试套路、CI 集成（覆盖率门槛 ≥60%）

### 3. 对齐与引用

- 若仓库存在 `.codebuddy/rules/unittest_*.md`：`unittest.md` 的 §二 改为摘录 + 链接，标注「权威来源」，不复制粘贴冲突内容
- 测试命令必须来自 `Makefile` / CI 配置中的真实命令，禁止臆造
- 覆盖率阈值来自 CI 配置 / `.golangci.yml` 中的实际值，默认 ≥60%

---

## 约束

- 禁止与 `integration_test/integration_test.md` 测同一层逻辑（UT 全 Mock + 函数级；IT 真实链路 + 接口/E2E 级）
- 命令 / 环境必须来自真实配置，禁止臆造
- 只动 `unittest/unittest.md`，不动其它 docs
- 若项目无 Go 代码（无 `*.go` / 无 `go.mod`）→ 跳过并输出 `skipped(no Go code)`
- 旧版 `testing.md` 迁移后必须删除，不留冗余文件
