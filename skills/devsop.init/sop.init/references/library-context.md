# 库项目补充指令（Library Context）

> 本文件由主 Agent 在检测到 `project.type == library` 时读取，按章节提取后注入各子 Agent prompt。
> 子 Agent 不直接读取本文件。

---

## § 通用指令

本项目是 **{{library_lang}} library**（纯库，被其他项目依赖使用，无独立运行入口）。

### 必须删除的内容

- 所有与「部署」「运行时服务」「数据库」「上下游服务调用」「健康检查」「监控告警」「灰度发布」「回滚策略」相关的段落
- Docker / docker-compose / K8s 相关内容
- 环境矩阵（dev/test/pre/prod）
- 服务启动命令
- 模拟上下游服务段落

### 库应关注的内容（所有语言通用）

- **导出 API surface**：公开函数/类型/接口的设计
- **向后兼容性**：遵循 semver，breaking change 需主版本号升级
- **最小依赖**：尽量 zero-dependency 或 minimal-dependency
- **消费者文档**：API 文档注释、使用示例
- **版本兼容**：支持的语言/运行时版本范围
- **线程安全**：并发使用说明

---

## § 语言特化指令

### Go library 特化

- 包管理：`go get` 安装，`go.mod` 管理依赖
- 文档：godoc 注释规范，`go doc` 可生成
- 版本：Go module semver（v0/v1 无 /vN 路径，v2+ 需路径后缀）
- 兼容：声明支持的最低 Go 版本（go.mod 中的 `go` 指令）
- 测试：`go test ./...`，benchmark 用 `testing.B`
- 零值可用：公开类型尽量零值即可使用
- internal/：内部包禁止外部导入，用于实现细节隔离

### Rust library 特化

- 包管理：`cargo add` 安装，`Cargo.toml` 声明依赖
- 文档：`///` doc comments + `cargo doc`，发布到 docs.rs
- 版本：Cargo semver（0.x 允许 breaking，1.0+ 严格）
- Feature flags：用 Cargo features 控制可选功能，默认 feature 最小化
- `#[no_std]` 支持：如适用，提供 no_std 兼容
- 安全：标注 `unsafe` 使用范围，提供 safe wrapper
- MSRV：声明 Minimum Supported Rust Version
- 测试：`cargo test`，doc tests 视为一等公民

### Java SDK 特化

- 包管理：Maven Central 发布，pom.xml 声明坐标（groupId:artifactId:version）
- 文档：Javadoc 注释，`@param` / `@return` / `@throws` 完整
- 版本：Maven semver，SNAPSHOT 用于开发版
- API 稳定性标注：`@Deprecated`（弃用）、`@Beta` / `@Experimental`（不稳定）
- 最低 JDK 版本：明确声明 source/target compatibility
- 依赖管理：shade/relocate 冲突依赖，避免传递依赖污染消费者
- 测试：JUnit 5 + Mockito，`mvn test`
- 线程安全：明确类/方法的线程安全保证（`@ThreadSafe` / `@NotThreadSafe`）

---

## § README 专用

库的 README 应包含以下结构（替代服务项目的上下游/部署/docker 等段落）：

1. **项目简介**：一句话说明库做什么
2. **安装方式**：
   - Go: `go get {{module_path}}`
   - Rust: `cargo add {{crate_name}}` 或 Cargo.toml 依赖声明
   - Java: Maven/Gradle 坐标片段
3. **快速示例**：最小可运行代码片段
4. **API 概览**：核心导出函数/类型列表（或链接到在线文档）
5. **版本兼容矩阵**：支持的语言/运行时版本
6. **贡献指南**：如何提 PR、运行测试

删除：部署环境要求、docker-compose 启动、上下游依赖（服务层面）

---

## § ARCHITECTURE 专用

库的架构文档应侧重：

1. **模块/包结构**：顶层模块划分及职责
   - Go: package 划分
   - Rust: module tree（lib.rs → mod.rs）
   - Java: package hierarchy
2. **导出 API 设计**：公开接口的设计哲学
3. **内部分层**：模块间依赖关系（用 mermaid 包/模块依赖图）
4. **扩展点**：接口/trait/回调/选项模式
5. **性能特征**：时间/空间复杂度、内存分配策略

删除：服务拓扑图、网关层、系统上下文图（外部系统交互）、容器图
用「模块依赖图」替代「服务拓扑图」

---

## § AGENTS.md 专用

当前 `AGENTS.md` 模板（`assets/agents.md.tmpl`）为四章式：一、快速索引 / 二、SOP / 三、开发准则 / 四、禁止红线。库项目按以下差异化处理（由 Agent A 在批次一执行，参考 `special-agent-agents.md`）：

### 一、快速索引（删行）
- 删除「数据库 / 持久化 schema」行（`.harness/docs/sqls/`）
- 删除「测试环境部署 / 代码同步」行（`.harness/docs/devops/test-env-deploy.md`）
- 删除「集成测试规范」行（`.harness/docs/integration_test/integration_test.md`）——库项目无独立运行环境
- 保留「单元测试规范」行（`.harness/docs/unittest/unittest.md`，库仍需单测）

### 二、SOP
- 9 阶段流程保留，但 Step 5 Deploy / Step 6 IT 在库项目下可跳过（无独立运行环境、无对外服务接口）
- 跳过需在 `00-overview.md` Progress 标注原因 + 时间记录填同一时间戳、备注列写「跳过：library 项目无此阶段」

### 三、开发准则
- 增加导出 API 稳定性规则（如：公开接口变更必须走 deprecation 流程；breaking change 主版本号升级）
- 增加最小依赖原则（zero-dependency / minimal-dependency 优先）
- 增加向后兼容性约束（semver，库项目的核心契约）
- 删除 DB 交互准则、部署环境要求

### 四、禁止红线
- 增加红线：导出 API breaking change 必须主版本号升级
- 增加红线：公开类型签名变更必须同步更新消费者文档
- 删除「数据库 schema 变更」「外部 API 协议变更」相关红线（库项目无独立 DB / 对外服务）
