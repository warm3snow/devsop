# 集成测试规范（环境 / 用例 / 运行调试）

> 让任意成员（或 AI Agent）能在**真实或近真实环境**把集成测试**搭起来、写得对、跑得通、出错查得到**。
> 三段式结构：① 环境与依赖 / ② 用例设计与组织 / ③ 运行与调试。
>
> **与单元测试的边界**：
> - 单元测试（`.harness/docs/unittest/unittest.md`）：函数 / 模块级，**禁止**真实外部调用，全部 Mock。
> - 集成测试（本文）：跨模块 / 跨服务 / 跨进程链路，**允许**调用真实测试环境的依赖（DB / MQ / 上下游服务 / 第三方 SDK 测试桩）。
>
> **若仓库存在 `.codebuddy/rules/integration_test_*.md` 或同义命名（如 `it_rule.md`、`api_test_rule.md`），那是权威来源**：本文以摘录 + 链接形式承接，不另起冲突；调整本文必须同步 rules。

> Source: <信息源：带 `//go:build integration` 的 `*_integration_test.go` + CI 集成测试 job（带 `-tags=integration`）+ .codebuddy/rules/integration_test_*.md + 测试环境部署文档>
> Last-verified: <YYYY-MM-DD>

---

## 一、环境与依赖

### 1. 集成测试形态判定

> 不同项目的"集成测试"含义不同，先明确本项目落在哪一种（可多选），再决定如何搭环境。

| 形态 | 典型场景 | 依赖准备方式 |
|------|---------|-------------|
| **接口级 IT**（API 黑盒）| 调用 HTTP/RPC 接口验证业务流程 | 需要可用的测试环境地址 + 鉴权 |
| **链路级 IT**（多服务联动）| 验证 A→B→C 的端到端链路 | 全链路测试环境 + 数据隔离方案 |
| **数据库 IT** | 验证 DAO / migration / 事务行为 | 独立测试库（容器或共享库 + 隔离 schema） |
| **消息 / 异步 IT** | 验证 MQ 消费 / 定时任务 / 回调 | 独立 topic / queue + 消费组隔离 |
| **前端 IT**（E2E） | 验证页面交互、跨页流程 | Playwright / Cypress + 后端 mock 或测试环境 |

> 在下方填写**本项目实际形态**，并标注权重（哪些为主、哪些为辅）：
>
> <!-- TODO: 例如「本项目以 接口级 IT 为主、数据库 IT 为辅；前端无 E2E。」 -->

### 2. 测试环境信息

> **强依赖** `.harness/docs/devops/test-env-deploy.md`：环境的"如何创建/部署/同步"在 devops 文档中，本节只记录"集成测试需要的环境形态与连通信息"。

| 项 | 说明 | 示例 / 实际值 |
|----|------|--------------|
| 环境名称 / 类型 | 持久共享环境 还是 临时按需环境 | <填> |
| 接入地址 | 入口域名 / IP / 端口 | <填> |
| 鉴权方式 | Token / 证书 / IAM / 临时 AKSK | <填> |
| 数据隔离策略 | 独立账号 / 独立 schema / 独立 namespace / tag 隔离 | <填> |
| 清理策略 | 自动清理（TTL / 标签删除）/ 手动清理 / 不清理 | <填> |
| 上下游依赖 | 见 `.harness/docs/relationship.md`，列出 IT 必须可达的依赖 | <填> |

### 3. 前置依赖检查清单（先查再装）

> 任何一项已满足就跳过对应安装步骤，不要无脑重置环境。

```bash
# (1) 测试环境可达性
<填：curl -sS --max-time 5 <env-endpoint>/healthz && echo "env OK" || echo "env unreachable">

# (2) 鉴权凭证就绪（不打印明文）
<填：test -n "$<APP>_IT_TOKEN" && echo "token OK" || echo "缺少 token">

# (3) 集成测试依赖就绪（Go：依赖通过 testcontainers / docker-compose 起的真实服务，或 CI 注入的测试 endpoint）
<填：docker ps --format '{{.Names}}' | grep -q <svc> && echo "deps OK" || echo "缺依赖">
<填：curl -sS --max-time 5 <mysql/redis/kafka 测试地址>/healthz && echo "deps OK" || echo "缺依赖">

# (4) 测试数据 fixture / 种子数据
<填：test -f testdata/it/<seed>.sql && echo "fixture OK" || echo "需要导入 fixture">

# (5) 隔离资源（独立 topic / namespace 等）
<填：项目特有检查命令>
```

判断逻辑：5 项全过 → 直接执行 IT；某项失败 → **只修复失败项**，不要全量重建。

### 4. 环境变量与配置

| 变量 | 用途 | 示例 |
|------|------|------|
| <例：`<APP>_IT_ENDPOINT`> | 测试环境入口地址 | `https://test-api.example.com` |
| <例：`<APP>_IT_TOKEN`> | 鉴权 token（**严禁硬编码**） | 从 vault / 环境变量注入 |
| <例：`<APP>_IT_NAMESPACE`> | 资源隔离命名空间 | `it-<branch>-<run-id>` |
| <例：`IT_DRY_RUN`> | 仅打印请求不真实下发 | `1` / `0` |

> 集成测试环境变量**必须从 vault / CI secret / 本地 `.env.local`（已 gitignore）注入**，禁止写入仓库。

---

## 二、用例设计与组织

### 1. 通用强制条款（红线）

| # | 红线 |
|---|------|
| 1 | **禁止**指向生产环境 / 共享线上库；只跑测试或 staging 环境 |
| 2 | **禁止**在 IT 中使用真实用户的真实凭证；用专用测试账号 |
| 3 | **禁止**测试遗留脏数据：每个用例自带 setup / teardown，或全局清理钩子保证幂等 |
| 4 | **禁止**用例间共享可变状态 / 依赖执行顺序（除非显式声明 `@order` 并文档化） |
| 5 | **禁止**硬编码环境信息（域名 / 路径 / 凭证 / 资源 ID） |
| 6 | **必须**记录 `req_id` / `trace_id` 到日志或报告，便于事后追溯 |
| 7 | **必须**为可能产生费用 / 不可逆操作的用例加保护开关（`IT_DRY_RUN` / 显式 confirm） |

### 2. 用例类型与适用场景

| 类型 | 适用 | 文件命名 / 位置 | 示例风格 |
|------|------|----------------|---------|
| 接口正向用例 | 验证主流程 happy path | `<package>/<module>_integration_test.go`（`//go:build integration`） | `TestXxx_Normal` |
| 接口逆向用例 | 参数错误 / 鉴权失败 / 资源不存在 | 同上，独立 `TestXxx_Negative` 函数 | `TestXxx_Negative` |
| 端到端链路用例 | 跨服务 / 跨模块流程 | `it/scenarios/<scenario>_integration_test.go` | `TestScenarioXxx` |
| 数据一致性用例 | DB / 缓存 / 副本数据校验 | `<package>/<module>_integration_test.go` 内 `TestXxx_DataConsistency` | `TestXxx_DataConsistency` |
| 异步 / 时序用例 | MQ 消费 / 回调 / 定时任务 | `<package>/<module>_integration_test.go` 内 `TestXxx_Async` | `TestXxx_Async` |

### 3. 文件命名硬约束

- 集成测试文件**用 `//go:build integration` build tag 隔离**，普通 `go test ./...` 不编译、不运行，避免污染 UT 与拖慢 CI
- 集成测试文件与被测代码**同 package 同目录**（`<module>_integration_test.go`），或集中放 `it/` 包；不要与 UT 混在同一文件
- 每个被测接口 / 场景**独立 `TestXxx` 函数**，命名直观体现"测什么 + 正向/逆向"
- go-zero 项目：通过 `svc.ServiceContext` 注入测试用真实依赖（testcontainer 起的 mysql/redis），复用 `TestMain` 统一启停

### 4. 用例设计自检清单（四维度）

> 每个用例必须明确以下四个维度的设定，避免"测了个寂寞"。

| 维度 | 检查点 |
|------|-------|
| **输入** | 必填 / 选填 / 边界值 / 非法输入是否覆盖 |
| **状态** | 前置状态准备（DB 行 / 资源已创建 / 上游已 mock）是否清晰 |
| **依赖** | 上下游依赖（见 `relationship.md`）哪些需要真实、哪些可桩 |
| **断言** | 不仅断言响应码，还要断言核心字段、副作用（DB 写入 / 消息发送 / 日志输出） |

### 5. Mock / 桩策略

> 集成测试默认**真实调用**，但仍有需要桩的场景，避免连不上 / 不可控的依赖把 IT 变红。

| 类别 | 默认策略 |
|------|---------|
| 本项目核心接口 | **真实调用** |
| 同测试环境内的下游服务 | **真实调用** |
| 跨域 / 第三方 SDK（短信 / 支付 / 邮件） | 接入第三方提供的 sandbox / 测试模式；无 sandbox 时使用本地桩 |
| 不可控外部（如运营商 / 真实物理设备） | 必须桩；用例标注 `@requires_real` 显式排除 |
| 时间 / 随机 | 谨慎使用；如必要，用专用 fixture 隔离 |

### 6. 与项目 rules 承接

- 若仓库存在 `.codebuddy/rules/integration_test_*.md` / `it_*.md`：本文 §二 改为指向该 rules 锚点，不重复写
- 否则使用本文规范作为最低基线
- 与 `.harness/plans/_template/06-it.md`（IT 阶段产物模板）配套使用：本文写"规则"，06-it.md 写"本次任务的执行结果"

---

## 三、运行与调试

### 1. 标准执行命令

```bash
# 全量集成测试（CI 主入口；必须带 integration build tag）
<填：go test -tags=integration -race ./... >
<填：make it   # 若项目提供 make it 封装（内部即 go test -tags=integration）>

# 指定 package
<填：go test -tags=integration ./internal/logic/...>

# 指定单个用例
<填：go test -tags=integration -run 'TestXxx_Normal' ./internal/logic/>

# Dry-run（不真实下发，仅校验拼接的请求）
<填：IT_DRY_RUN=1 go test -tags=integration -run 'TestXxx' ./...>

# 仅重跑失败用例
<填：go test -tags=integration -run 'TestXxx' ./... -count=1>

# 带 trace / 详细日志
<填：go test -tags=integration -v -run 'TestXxx' ./... 2>&1 | grep -E "PASS|FAIL|req_id|trace_id">
```

> **必须**与 CI 中跑的命令一致；本地能过、CI 失败的多半是环境变量 / 网络访问 / 权限差异。

### 2. 测试 runner 通常做了什么（如有 wrapper 脚本）

> 例：`run_it.sh` 通常负责：
> 1. 检查测试环境可达性（healthz / readiness）
> 2. 注入测试 token / endpoint 环境变量
> 3. 创建本次运行的隔离命名空间（`it-<run-id>`）
> 4. 调用 runner 执行用例
> 5. 失败时自动收集：失败用例的 `req_id` 列表、关键日志片段、环境快照
> 6. 结束时按隔离策略清理资源（即使失败也清理；保留产物到 artifacts/）

### 3. 调试套路

| 现象 | 优先排查 | 排查命令 |
|------|---------|---------|
| 全量失败 | 环境可达性 / 鉴权 / 配置 | 走 § 一的 5 项检查清单 |
| 全量超时 | 网络 / DNS / 测试环境过载 | `curl -v <endpoint>/healthz`；查测试环境监控 |
| 偶发失败（flaky） | 异步时序 / 资源竞争 / 依赖抖动 | 多次 `--lf` 重跑；检查是否依赖固定时序 |
| 单接口失败 | 抓取 req_id 查上下游链路日志 | 见 § 4 故障定位流程 |
| 用例间互相影响 | 数据隔离失效 / 全局状态 | 检查 setup/teardown / 命名空间隔离 |
| 鉴权失败 | token 过期 / 权限不足 | 重新签发 token；核对账号权限 |

### 4. 故障定位流程（接口级 IT 通用）

```
失败用例 → 取 req_id / trace_id
    → 查本服务日志（按 req_id 过滤）
    → 看上下游调用链（trace_id 串联）
    → 定位故障点（本服务 / 下游 / 数据问题）
    → 修复 / 跟进 owner
    → 重跑该用例确认
```

> 失败处理原则与 `_template/06-it.md` 一致：环境问题 → 修复后重跑；代码问题 → 回 03-implement；设计问题 → 回 02-plan。

### 5. 不要 / 慎用

| 项 | 原因 |
|----|------|
| 在 IT 中使用 `time.sleep` 等死等 | 改用 `wait_until(condition, timeout)` 显式轮询 |
| 共用同一份测试数据不清理 | 数据污染会让后续用例不可重复 |
| 用例依赖前一个用例创建的资源 | 用例必须独立；如需链路，用单一用例覆盖完整链路 |
| 关闭某些用例（`@skip` / `xfail`）以"让 CI 过" | 必须在 `06-it.md` 备注原因 + 跟踪修复 |
| 把 IT 和 UT 混到同一个 runner | 跑得慢、失败原因混杂、报告难读 |

### 6. 测试产物

| 产物 | 路径 | 用途 |
|------|------|------|
| JSON 测试报告 | <填：`it_report.json`（`go test -json`）> | CI 摄取（流水线展示） |
| JUnit XML | <填：`junit-it.xml`（`go test -json | gotestfmt`）> | CI 摄取（流水线展示） |
| 失败用例 trace 包 | <填：`artifacts/failed/<run-id>/`> | 包含日志、req_id、环境快照 |
| 终端摘要 | stdout | 通过 / 失败 / 跳过统计 |

### 7. CI 集成

- IT 在 CI 中**应与 UT 分离**为独立 stage / job：UT 快、阻塞 PR；IT 慢，可选阻塞或定时跑
- IT 失败必须**强制阻塞合入主干**（feature 分支可放宽，但需评审豁免）
- IT 失败后 CI 必须自动归档：`req_id` 列表、关键日志、环境快照（保留 ≥ 7 天）
- 测试环境部署 / 同步流程见 `.harness/docs/devops/test-env-deploy.md`

---

## 四、与 SOP 阶段的关系

| 阶段 | 引用本文的方式 |
|------|---------------|
| **02 Plan** | 设计 IT 用例清单时，按 § 二的"四维度自检"框架列用例；命名遵循 § 二规则 |
| **05 Deploy** | 部署完成后须确认 § 一 §2「测试环境信息」可达，才能进入 06 IT |
| **06 IT** | 按 § 三的标准命令执行；失败定位走 § 三 §4；产物按 § 三 §6 收集到 `06-it.md` |
| **07 Docs** | 若本次任务新增 / 修改了 IT 用例约定 / 环境配置，同步本文档 |
