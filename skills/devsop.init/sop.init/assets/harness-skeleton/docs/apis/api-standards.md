# API 设计规范

> 状态：草稿 | 维护者：{{姓名}} | 最后更新：{{YYYY-MM-DD}}

## 范围

适用于本服务对外暴露的所有 API（HTTP/REST、gRPC、内部 RPC）。新增/修改接口必须先更新规范，再生成代码。

## 1. 协议与风格

- 协议：{{HTTP/JSON | gRPC | GraphQL}}
- 风格：{{RESTful / RPC-style}}
- IDL 工具：{{.api / .proto / OpenAPI}}，存放于 `{{template/ 或 idl/}}`
- 代码生成：`{{make gen 或等效命令}}`
- HTTP 方法语义：GET（读，幂等）、POST（创建/动作）、PUT（全量更新，幂等）、PATCH（增量更新）、DELETE（删除，幂等）

## 2. 路径与命名

- URL 风格：`/api/v{N}/{resource}/{id}/{sub-action}`
- 资源名：{{选 复数 / 单数 之一全项目一致}}
- 动作命名：`kebab-case`（URL）/ `camelCase`（参数）
- 版本前缀：`/v1`、`/v2`；弃用流程见 §7
- 路由按业务模块分组（避免单一路由文件超 200 行）

## 3. IDL / 类型定义

### 字段标签必备
- Request/Response 字段必须含完整标签：`json` / `form` / `path` / `validate`
- 必填字段必须有 `validate:"required"` 等约束
- 字段命名：JSON 用 `camelCase` 或 `snake_case`，全项目一致

### 字段约定
- **时间**：统一格式（{{ISO 8601 字符串 / Unix 毫秒时间戳}} 二选一全项目一致）
- **大整数**（雪花 ID、订单号 ≥2^53）：序列化为**字符串**，避免 JS 精度丢失
- **金额**：`DECIMAL` 字符串，单位明确（如 "12.3400" 表示元）
- **枚举**：定义在 IDL，使用字符串而非裸数字
- **分页**：{{cursor / page+size 二选一}}，默认值 + 上限明确（page_size ≤100）
- **布尔**：用 `true/false`，不用 0/1

### 兼容性
- 字段新增：向后兼容，client 必须容忍未知字段
- 字段删除/语义变更：必须**升版本** + 灰度
- 字段标记 `deprecated` 至少保留 2 个版本再下线

## 4. 统一响应格式

```json
{
  "code": 0,
  "message": "ok",
  "data": { /* 业务数据 */ },
  "trace_id": "{{request id}}"
}
```

- `code = 0` 表示业务成功；非 0 见错误码定义
- HTTP 状态码：4xx 客户端错误，5xx 服务端错误，业务错误统一用 200 + code
- `message` 面向开发者排查，**禁止**直接展示给终端用户（前端按 code 映射本地化文案）
- `trace_id` 必须透传，便于跨服务排查

## 5. 错误码

- 错误码格式：{{统一长度，如 6 位整数 / 字符串}}
- 错误码必须**分类 + 唯一 + 文档化**，集中定义在 `{{internal/errorcode/}}`
- **禁止**用 message 字符串区分错误（用 code）
- 错误信息**禁止**泄露：堆栈、SQL、内部路径、第三方 token

## 6. 鉴权与安全（接口层）

> 语言层安全（输入校验、加密、密钥管理）见 [coding-style.md](coding-style.md) §安全编码。

### 鉴权
- 鉴权方式：{{JWT / OAuth2 / 内部 ticket}}
- Header 约定：`Authorization: Bearer <token>` / `X-Trace-Id` / `X-Request-Id`
- **【必须】** 默认鉴权，公开资源走白名单；新增接口默认需要鉴权
- **【必须】** 鉴权 → 操作权限 → 数据权限 → 账户一致性，四层依次校验
- **【必须】** 登录成功重新生成 session/token；退出清理 session
- Cookie：必须设置 `HttpOnly` + `Secure` + `SameSite`，并配置过期时间

### CORS
- **【必须】** `AllowedOrigins` 列具体域名；**禁止** `*`
- **【必须】** 启用 `AllowCredentials` 时，`AllowedOrigins` 不能为 `*`，且仅放白名单域名
- **必须**限制 `AllowedMethods` 与 `AllowedHeaders`

### SSRF 防护
- **【必须】** 服务端发起外部请求：仅允许 HTTP/HTTPS 协议
- **【必须】** 解析目标 HOST 获取 IP，**禁止**访问内网（10/8、172.16/12、192.168/16、127.0.0.1、169.254/16）
- **【必须】** 禁止跟随重定向到内网；跟随后重新校验
- **【必须】** 设超时（典型 3 秒）

### XXE / 反序列化
- **【必须】** XML 解析禁用 DTD 与外部实体
- **【禁止】** 反序列化不可信数据为任意类型（Java：禁用 ObjectInputStream / Python：禁用 pickle）

### 限流
- **【必须】** 公网入口接口设速率限制：粒度（IP/User/Token）+ 阈值
- **【必须】** 关键操作（登录、注册、改密、支付）独立限流策略

### 响应头
- **【必须】** 设置：
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY` 或 `SAMEORIGIN`
  - `Strict-Transport-Security`（HTTPS 站点）
  - `Content-Security-Policy`（HTML 站点）

## 7. 版本与弃用

- 版本号：URL 前缀（`/v1`）或 Header（`Accept: application/vnd.xxx.v1+json`）二选一全项目一致
- 弃用流程：标注 `Deprecated` → 文档广播 → 监控调用量 → N 个版本后下线
- 旧版本下线公告至少提前 {{30 天}}

## 8. 文档与契约测试

- 接口文档：{{Swagger / Apifox / 自动生成网站}}，与代码同步发布
- 契约测试：{{方案，如 Pact / 录制回放}}，确保 client/server 协议一致
- 示例：每个接口必须有完整 request/response 示例（含错误情况）

## 9. 性能与超时

- 接口默认超时：{{3 秒}}；批量接口 {{10 秒}}
- 批量接口必须有数量上限（默认 ≤100）
- P99 延迟目标：{{< 500ms}}
- 大流量接口必须支持分页/游标，**禁止**一次返回 ≥1000 行

## 10. {{框架特定}}（如 go-zero）

> 删除本节如不适用。

- API 文件（`.api`）：路由分组清晰，HTTP 方法正确，路径参数规范
- JWT 配置（`Auth` 字段）对需要认证的接口生效
- Logic 通过 `svcCtx` 获取依赖（依赖注入），**禁止**直接 new 依赖
- Logic 必须接收并传递 `context.Context` 到所有外部调用
- 错误使用 `errorx`（或项目对应错误码包）统一处理

## 参考

- IDL 工作流：[development.md](development.md)
- 错误码定义：`{{internal/errorcode/}}`
- 编码与安全：[coding-style.md](../coding-style.md)
- 测试规范：[unittest/unittest.md](../unittest/unittest.md)
