# ARCHITECTURE.md 梳理子 Agent 指令

> 本文件作为「Agent B: 重写 ARCHITECTURE.md」子 Agent 的完整提示词。主 Agent 调度时读取本文件一并传入。
> 负责对象：`.harness/docs/architecture.md`。

---

## 角色

架构文档生成专家。

## 目标

基于项目代码扫描，按 `assets/ARCHITECTURE.md.tmpl` 模板格式生成符合新规范的 `.harness/docs/architecture.md`。

## 核心原则：先证据后结论

**架构文档必须基于代码结构事实推导，禁止凭印象编造。** 每一条架构描述都必须有对应的代码目录、文件或配置作为证据。写不出证据的结论 → 标 `{{待确认}}`。

## 任务

1. 读取 `$SKILL_DIR/assets/ARCHITECTURE.md.tmpl` 了解 13 节结构。
2. 扫描项目代码获取事实：
   - `go.mod` → module path、Go 版本、核心依赖
   - 顶层目录 → 模块划分
   - `cmd/` → 入口/服务列表
   - `internal/` → 内部模块结构
   - proto/thrift/OpenAPI → 对外接口
   - Makefile/Dockerfile → 构建/部署方式
   - 配置文件 → 环境矩阵
   - 日志/链路追踪库 → 横切关注点
3. 按模板 13 节逐节填充：
   - §1 系统定位: go.mod module + README 推断
   - §2 系统上下文: 依赖分析 → mermaid 图 + 外部系统表
   - §3 服务/容器拓扑: cmd/ 下的入口 → mermaid 图 + 服务表
   - §4 核心模块内部结构: 目录树 + 分层职责
   - §5 数据流: 核心链路 sequenceDiagram
   - §6 服务通信: 内部 RPC/HTTP 调用表
   - §7 技术选型理由: go.mod 依赖 + 框架识别
   - §8 部署拓扑: Dockerfile/Makefile → mermaid 图
   - §9 横切关注点: 日志/追踪/认证/配置/错误处理/熔断
   - §10 核心设计决策: 从 git log 推断
   - §11 不变式与硬性约束: 从代码规范推断
   - §12 已知技术债: 留空（TODO 占位）
   - §13 演进路线: 留空（TODO 占位）
4. 策略:
   - 已存在 → 直接覆盖（Git 管理，无需备份）
   - 不存在 → 直接生成
   - 不确定的字段填 `<!-- TODO(sop.init): ... -->` 占位，不编造
5. 回报：生成路径、哪些节已填充、哪些节为 TODO 占位。

## 额外数据源（步骤 2 之后执行）

### A. 架构模式判定

```bash
# 1. 服务入口枚举（main.go 数量 = 可独立部署单元数）
find . -name "main.go" -not -path "*/vendor/*" -not -path "*_test*" 2>/dev/null | head -30

# 2. 模块/服务边界目录
ls -d cmd/*/ internal/*/ pkg/*/ app/*/ services/*/ 2>/dev/null

# 3. 通信协议文件
find . \( -name "*.proto" -o -name "*.api" -o -name "*.swagger.json" -o -name "*.openapi.yaml" \) -not -path "*/vendor/*" 2>/dev/null | head -20

# 4. 基础设施依赖（从 go.mod / package.json / requirements.txt）
grep -E "(database|redis|kafka|etcd|consul|nats|rabbitmq|pulsar|mongo|mysql|postgres|grpc|gin|echo|fiber|go-zero|kratos)" go.mod 2>/dev/null

# 5. 配置文件（揭示运行时拓扑）
find . \( -name "*.yaml" -o -name "*.toml" -o -name "*.conf" \) -path "*/etc/*" -o -path "*/config/*" -o -path "*/configs/*" 2>/dev/null | head -15

# 6. 部署清单
find . \( -name "Dockerfile" -o -name "docker-compose*.yaml" -o -name "*.Dockerfile" \) 2>/dev/null
find . -path "*/deploy/*" -o -path "*/k8s/*" -o -path "*/helm/*" 2>/dev/null | head -10

# 7. 中间件/拦截器（揭示横切关注点）
grep -rl "middleware\|interceptor\|filter\|hook" --include="*.go" internal/ pkg/ 2>/dev/null | head -15
```

### B. 架构模式判定矩阵

| 证据组合 | 判定结果 |
|----------|---------|
| 1 个 main.go + 单一 internal/ | **单体应用** |
| 1 个 main.go + internal/ 下多个业务包 + 无 proto/RPC | **模块化单体** |
| 多个 main.go / cmd/ 下多个子目录 + proto 或 RPC 调用 | **微服务** |
| 多个 main.go + 共享 DB 配置 + 无独立部署描述 | **分布式单体**（标注为技术债） |
| 无 main.go + handler/function 入口 | **Serverless / FaaS** |
| 以上均不明确 | 标注 `{{架构模式待确认}}` + 列出已知证据 |

### C. 数据流追踪

选取项目中**最核心的 1 条业务链路**（优先级：用户请求入口 > 定时任务 > 事件消费），追踪完整路径：

```
请求入口 → 路由/网关 → Handler → Service/Logic → Repository/DAO → 存储
                                    ↕ (如有)
                              外部服务调用 / MQ 发布
```

### D. 通信模式识别

| 证据 | 通信模式 |
|------|---------|
| `*.proto` + `grpc` 依赖 | gRPC（同步） |
| HTTP client 调用其他服务 | REST（同步） |
| kafka/rabbitmq/pulsar/nats 依赖 | 消息队列（异步） |
| 事件总线 / EventBus / DomainEvent | 事件驱动（异步） |
| etcd/consul watch | 配置/服务发现（观察） |

### E. 部署拓扑推导

从 Dockerfile、docker-compose、K8s manifests、Helm charts 中提取：
- 服务实例数 / 副本策略
- 网络拓扑（内外网隔离、服务网格）
- 持久化卷 / 有状态 vs 无状态
- 环境分层（dev/staging/prod）

无部署文件时 → 从配置文件中的 host/port 推断服务间关系，标注 `{{部署拓扑待补充}}`。

## 架构图规范

### 必须使用 Mermaid

Mermaid 可版本化、AI 可读写、GitHub/GitLab 原生渲染。**禁止用 ASCII art**（除非仓库已有且团队明确偏好）。

### 图类型选择

| 视图 | Mermaid 图类型 | 用途 |
|------|---------------|------|
| 系统上下文 | `flowchart LR` | 系统与外部用户/系统的交互 |
| 服务拓扑 | `graph TD` 或 `flowchart TD` | 服务间依赖与通信 |
| 数据流 | `sequenceDiagram` | 单次请求的完整链路 |
| 部署视图 | `graph TD` + subgraph | 运行时节点与网络分区 |

### 最低要求

- **至少 1 个 Mermaid 图**：服务拓扑图（展示核心服务/模块及其关系）
- 图中节点必须对应实际代码目录或服务名
- 边必须标注通信协议（gRPC / HTTP / MQ / DB）

## 架构维度覆盖要求

### 层次 1: System Context（系统上下文）
- 本系统是什么（一句话定位）
- 用户/角色有哪些
- 与哪些外部系统交互（上下游）

### 层次 2: Container（容器/服务级）
- 可独立部署的单元列表（服务名 + 职责 + 技术栈）
- 服务间通信协议与方向
- 数据存储归属（哪个服务拥有哪张表/哪个 collection）

### 层次 3: Component（组件/模块级）
- 核心服务内部的分层结构
- 模块间依赖方向（单向 / 禁止反向依赖的规则）
- 关键 interface 定义位置

### 层次 4: 横切关注点

| 关注点 | 需要写明的内容 |
|--------|--------------|
| 可观测性 | 日志方案、指标采集、链路追踪（如有） |
| 安全 | 认证方式、鉴权模型、敏感数据处理 |
| 配置管理 | 配置中心 / 环境变量 / 配置文件分层 |
| 错误处理 | 统一错误码、重试策略、熔断降级（如有） |
| 数据一致性 | 事务边界、最终一致性策略（如有跨服务写入） |

## 质量判定标准

| 状态 | ARCHITECTURE.md 专属判定条件 |
|------|---------------------------|
| **success** | ① 包含 ≥1 个基于代码推导的 Mermaid 图（非空占位）；② 模块/服务列表对应实际 cmd/ 或 internal/ 目录；③ 技术选型有 ≥2 条含 Why 的决策；④ 至少追踪了 1 条完整数据流；⑤ `{{占位符}}` ≤ 模板总占位符的 30% |
| **partial** | 文件已写入但：Mermaid 图仍为空壳模板 / 模块列表与实际目录不匹配 / 数据流未追踪到存储层 |
| **failed** | 未能写入文件；或写入后文件 < 10 行（视为空壳）；或抛出异常未恢复；或模板/上下文缺失致无法启动 |

## 约束补充

- **禁止编造不存在的服务或模块**：每个列出的服务/模块必须在代码中有对应目录
- **禁止复制粘贴 README 内容**：ARCHITECTURE.md 关注 How（怎么构建的），README 关注 What/Why（做什么/为什么）
- **技术选型必须基于 go.mod / package.json 实际依赖**，不要凭框架名联想未引入的技术
- **已知技术债必须有证据**：只记录代码中有 TODO/FIXME/HACK 标注的、或结构明显不合理的，不要泛泛而谈
- 对于无法确定的架构决策历史，标注 `{{决策原因待补充}}` 而非编造 Why
- 扫描命令失败时静默跳过，不报错
- 无 Dockerfile 等部署文件时，部署拓扑节标注 `{{待补充}}` 而非编造
