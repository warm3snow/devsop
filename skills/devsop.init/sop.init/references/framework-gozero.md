# go-zero 框架特化指令

> 当 `$FRAMEWORK = go-zero` 时，以下文件的子 Agent 必须在通用 prompt 基础上额外遵循本文件中对应段落的要求。

---

## coding-style.md 子 Agent 额外要求

- 目录分层规范：必须遵循 go-zero 标准分层 `handler → logic → svc → model`
- 命名规范：handler 文件以 `xxxHandler` 命名；logic 文件以 `xxxLogic` 命名
- ServiceContext 使用规范：所有依赖通过 `svc.ServiceContext` 注入，禁止在 logic 中直接实例化外部依赖
- 配置管理：配置结构体在 `internal/config/` 定义，通过 `etc/*.yaml` 加载
- 中间件定义位置与注册方式
- error 处理：使用 `errorx` 统一错误码，禁止裸 `error` 返回给前端

## api-standards.md 子 Agent 额外要求

- API 定义方式：必须通过 `.api` 文件定义，使用 `goctl api go` 生成代码
- 路由分组：`@server` 注解的 `group`、`prefix`、`middleware` 使用规范
- 请求/响应结构体：在 `.api` 文件中定义 `type`，禁止手写 handler 层结构体
- JWT 鉴权：通过 `.api` 文件的 `jwt: Auth` 声明，不要手写 JWT 中间件
- 版本管理：API 版本通过 `prefix: /api/v1` 控制
- 错误码规范：统一使用 `httpx.ErrorCtx` + 自定义错误结构
- RPC 服务调用：通过 `zrpc.MustNewClient` 连接，在 ServiceContext 中初始化

## unittest.md 子 Agent 额外要求

- 单元测试重点：logic 层是核心测试目标，handler 层通常不单独测
- mock 策略：对 `svc.ServiceContext` 中的依赖做 interface 抽象后 mock
- 集成测试：使用 `testcontainers` 或本地 docker-compose 起依赖
- API 测试：可用 `httptest` 测试完整 handler 链路
- 测试文件位置：与被测文件同目录，`xxx_test.go`
- goctl 生成代码不写测试（生成代码不测），只测 logic 中的业务逻辑

## development.md 子 Agent 额外要求

- goctl 工具版本要求与安装方式
- 开发流程：`.api` 文件定义 → `goctl api go` 生成 → 在 logic 中填写业务逻辑
- RPC 开发流程：`.proto` 定义 → `goctl rpc protoc` 生成 → 在 logic 中填写
- 本地运行依赖：etcd（服务发现）、Redis（缓存）、MySQL/PostgreSQL 等
- 配置文件：`etc/xxx-api.yaml` 本地开发配置说明
- 多服务联调：服务注册发现机制、本地 hosts 配置

---

## 识别特征

主 Agent 通过以下特征确认项目使用 go-zero：

- `go.mod` 包含 `github.com/zeromicro/go-zero`
- 存在 `.api` 或 `.proto` 定义文件
- 目录包含 `internal/{handler,logic,svc,types}`

## 其他框架

当 `$FRAMEWORK` 为其他值或未识别时，按通用模板处理，不注入本文件内容。

> 扩展新框架：创建 `references/framework-<name>.md`，主 Agent 会自动按 `$FRAMEWORK` 值匹配加载。
