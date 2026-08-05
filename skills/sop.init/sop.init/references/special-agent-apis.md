# APIs 梳理子 Agent 指令

> 本文件作为 `apis` 梳理子 Agent 在通用 prompt 基础上的**补充指令**。主 Agent 调度时一并传入。
> 负责对象：`.harness/docs/apis/`（对外接口文档区）。

---

## 核心目标

基于代码真实接口，把 `.harness/docs/apis/` 充实为**调用者视角**的接口文档集：
- `apis/index.md` 总索引（与正式接口文档 1:1 对应）
- `apis/<module>/<Action>.md` 每个对外 Action 一篇（按 `_template.md` 结构）
- `apis/api-standards.md` 若有实质内容则保留，仅补充本项目协议/路径/版本规范

---

## 步骤

### 0. 相关性判定（决定是否执行）

执行以下命令判断项目是否对外暴露 API：

```bash
# HTTP / RPC 入口
find . \( -name "*.proto" -o -name "*.thrift" -o -name "*.api" \) -not -path "*/vendor/*" 2>/dev/null | head
grep -rlE "gin|echo|fiber|go-zero|kratos|grpc|gorilla/mux|net/http" go.mod 2>/dev/null
# 路由注册
find . \( -name "router*" -o -name "route*" -o -name "*handler*.go" -o -name "controller*" \) -not -path "*/vendor/*" 2>/dev/null | head
```

- **无任何对外接口证据**（无 proto / 无 HTTP-RPC 框架 / 无路由注册 / 纯库无导出接口）→ 判定为**无 API 项目**：
  1. **删除** `.harness/docs/apis/` 整个目录（`rm -rf`）。
  2. 输出 `skipped(no external API)`，结束。
- 有证据 → 进入创建/更新模式。

### 1. 扫描接口事实

从信息源抽取结构化事实（**禁止凭记忆编造**）：
- proto/thrift/OpenAPI → service / method / message
- 路由注册表 → method + path + handler
- handler 签名 → 入参 / 出参
- 错误码表 → Code / 含义
- 版本路径前缀（如 `/v1/`）

### 2. 生成接口文档

- 按 module 聚类（如 `user/`、`order/`），每 Action 一篇 `<module>/<Action>.md`，套 `apis/_template.md`。
- 必填章节：描述 / 请求（方法路径 + 入参表 + 示例）/ 响应（出参表 + 示例）/ 错误码 / 变更记录。
- 不确定的字段保留 `{{...}}` 或 `<!-- TODO(sop.init): ... -->`，不编造。
- 每篇头部写 Source + Last-verified 脚注。

### 3. 回写 index.md

把 `apis/index.md` 刷新为总索引表：模块 / Action / 一句话 / 链接。与正式文档 1:1 对应。

---

## 约束

- **无 API 项目必须删除 `apis/` 目录**，禁止保留空骨架。
- 禁止复制源码，从调用者视角写"怎么调 / 返回什么 / 错了怎么看"。
- 已存在的人工接口文档保留并修正，不整体覆盖。
- 只动 `apis/` 下文件，不动其它 docs。
