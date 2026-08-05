# 集成测试 梳理子 Agent 指令

> 本文件作为 `integration_test` 梳理子 Agent 在通用 prompt 基础上的**补充指令**。主 Agent 调度时一并传入。
> 负责对象：`.harness/docs/integration_test/integration_test.md`。

---

## 核心目标

把 `.harness/docs/integration_test/integration_test.md` 充实为**真实链路、接口 / E2E 级**的集成测试规范，与 `relationship.md`、`devops/test-env-deploy.md` 对齐。

---

## 步骤

### 1. 扫描集成测试事实

- 现有 IT 用例：`*_test.go` 中走真实链路的测试 / `integration_test/` 目录 / e2e 脚本
- 外部依赖：数据库 / MQ / 第三方服务（来自 `relationship.md`）
- 测试环境：部署方式（来自 `devops/test-env-deploy.md`）
- 框架：testify / ginkgo / 自带测试 runner

### 2. 生成 / 更新文档

按 skeleton 三段式填充：
- **环境与依赖** —— 集成测试需要的中间件 / 服务 / 数据准备，依赖项对齐 `relationship.md`
- **用例设计** —— 核心链路 E2E 用例清单（场景 / 前置 / 步骤 / 断言），与 UT 分层不重叠（IT 真实链路 + 接口/E2E 级；UT 全 Mock + 函数级）
- **运行调试** —— 启动命令 / 环境变量 / 如何本地跑单条 IT / 常见失败排查

### 3. 对齐与引用

- 依赖来自 `relationship.md`，环境部署来自 `devops/test-env-deploy.md` —— 用 `@` 引用，不复制粘贴。
- 若仓库存在 `.codebuddy/rules/integration_test_*.md` / `it_*.md`，摘录 + 链接并标明权威关系。

---

## 约束

- 禁止与 `unittest/unittest.md` 测同一层逻辑（UT 函数级 Mock；IT 真实链路）。
- 命令 / 环境必须来自真实配置，禁止臆造。
- 只动 `integration_test/` 下文件，不动其它 docs。
