# 能力探测子 Agent 指令（API / DB）

> 本文件作为 sop.init「Step 0 能力探测」子 Agent 的**完整指令**。主 Agent 调度时以 `subagent_type: Explore`（只读）派出，并把本文件内容作为 prompt 传入。
> 负责对象：目标项目仓库（**只读探测，严禁任何写操作**）。

---

## 核心目标

判断目标项目**是否对外提供 API**、**是否有数据库 / 持久化定义**，以固定格式返回两个布尔值，供主 Agent 传入 `init_harness.sh --has-api= --has-db=`。

---

## 硬性约束

1. **只读**：只使用 Read / Glob / Grep / Bash（只读命令）探测；**严禁**创建、修改、删除目标项目任何文件。
2. **证据驱动**：每个布尔值必须给出至少一条命令证据或「无证据」声明；禁止凭经验猜测。
3. **固定返回格式**：见文末「返回格式」，主 Agent 按行解析，禁止输出额外散文。

---

## 探测方法

### A. API 探测（判定 `HAS_API`）

在目标项目根目录执行（路径按实际包管理调整，排除 vendor/node_modules）：

```bash
# 1. 接口定义文件
find . \( -name "*.proto" -o -name "*.thrift" -o -name "*.api" -o -name "openapi*.yaml" -o -name "swagger*.yaml" \) -not -path "*/vendor/*" -not -path "*/node_modules/*" | head

# 2. HTTP / RPC 框架依赖
grep -rlE "gin|echo|fiber|go-zero|kratos|grpc|gorilla/mux|net/http|flask|django|fastapi|express|spring" go.mod requirements.txt package.json pom.xml 2>/dev/null

# 3. 路由注册 / handler 文件
find . \( -name "router*" -o -name "route*" -o -name "*handler*.go" -o -name "controller*" \) -not -path "*/vendor/*" -not -path "*/node_modules/*" | head
```

**判定规则**：
- 任一类有实质证据（接口定义文件 / 框架依赖 + 路由注册）→ `HAS_API=true`
- 三类均无证据（纯库、纯 CLI、纯文档仓库）→ `HAS_API=false`
- 仅 `net/http` 出现在依赖但无任何路由/handler 注册 → 倾向 `false`（可能只是客户端调用）

### B. DB 探测（判定 `HAS_DB`）

```bash
# 1. DB 驱动 / ORM 依赖
grep -rlE "database/sql|gorm|xorm|sqlx|ent|mysql|postgres|mongo|redis|sqlite|sqlalchemy|django.db|mongoose|mybatis" go.mod requirements.txt package.json pom.xml 2>/dev/null

# 2. migration / schema / SQL 文件
find . \( -name "*.sql" -o -iname "*migration*" -o -iname "*schema*" \) -not -path "*/vendor/*" -not -path "*/node_modules/*" | head

# 3. ORM model 定义（struct tag / 装饰器）
grep -rlE "gorm:\"|xorm:\"|db:\"" --include="*.go" . 2>/dev/null | head
grep -rlE "models\.Model|@Entity|@Table" --include="*.py" --include="*.java" . 2>/dev/null | head
```

**判定规则**：
- 任一类有实质证据 → `HAS_DB=true`
- 三类均无证据（纯内存 / 纯计算 / 纯文档项目）→ `HAS_DB=false`
- 仅 redis 作为缓存客户端、无任何 schema/model → 可判 `false`（在证据摘要注明理由）

---

## 返回格式

**严格按以下格式输出**（主 Agent 按行解析键值）：

```
HAS_API=true|false
HAS_DB=true|false
EVIDENCE_API=<一行证据摘要；false 时写「无 proto/框架依赖/路由注册证据」>
EVIDENCE_DB=<一行证据摘要；false 时写「无 DB 驱动/migration/model 证据」>
```

示例（无 API 无 DB 的 skill 库项目）：

```
HAS_API=false
HAS_DB=false
EVIDENCE_API=无 proto/HTTP-RPC 框架依赖/路由注册证据（仅 shell 脚本与 markdown）
EVIDENCE_DB=无 DB 驱动/migration/ORM model 证据
```

---

## 失败处理

- 目标目录不可读 / 不存在 → 输出 `HAS_API=true` `HAS_DB=true`（保守缺省，不阻断初始化）并在 EVIDENCE 行注明「探测失败，取保守缺省」。
