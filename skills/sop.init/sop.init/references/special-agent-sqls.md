# SQLs 梳理子 Agent 指令

> 本文件作为 `sqls` 梳理子 Agent 在通用 prompt 基础上的**补充指令**。主 Agent 调度时一并传入。
> 负责对象：`.harness/docs/sqls/`（持久化结构文档区）。

---

## 核心目标

基于项目真实持久化结构，把 `.harness/docs/sqls/` 充实为 DB schema / 表设计 / 迁移规范文档。

---

## 步骤

### 0. 相关性判定（决定是否执行）

执行以下命令判断项目是否有数据库 / 持久化：

```bash
# ORM / DB 驱动依赖
grep -rlE "database/sql|gorm|xorm|sqlx|ent|mysql|postgres|mongo|redis|sqlite" go.mod 2>/dev/null
# 迁移 / schema 文件
find . \( -name "*.sql" -o -name "*migration*" -o -name "*schema*" \) -not -path "*/vendor/*" 2>/dev/null | head
# ORM model 定义
find . \( -name "*.go" \) -not -path "*/vendor/*" 2>/dev/null | xargs grep -lE "type .* struct" 2>/dev/null | head
```

- **无任何持久化证据**（无 DB 驱动依赖 / 无 migration / 无 schema / 纯内存或纯计算库）→ 判定为**无数据库项目**：
  1. **删除** `.harness/docs/sqls/` 整个目录（`rm -rf`）。
  2. 输出 `skipped(no database)`，结束。
- 有证据 → 进入创建/更新模式。

### 1. 抽取 schema 事实

- 优先从 migration 历史 / ORM model 抽取表结构（字段名 / 类型 / 约束 / 索引）。
- 无 migration 时，从 ORM struct tag（gorm / xorm）或实体定义推导，标注 `<!-- TODO(sop.init): 与线上 schema 核对 -->`。
- 抽取涉及状态机的表（如订单状态 / 任务状态），列出状态枚举与转换条件。

### 2. 生成文档

- `sqls/database.md` 按 skeleton 章节填充：表设计 / 索引规范 / 事务边界 / 迁移策略。
- 每篇头部写 Source + Last-verified 脚注。
- 不确定的字段保留 `{{...}}` 或 `<!-- TODO(sop.init): ... -->`。

---

## 约束

- **无数据库项目必须删除 `sqls/` 目录**，禁止保留空骨架。
- 禁止把 schema 当成代码字符串抄；字段必须带含义说明。
- 已存在的人工 schema 文档保留并修正，不整体覆盖。
- 只动 `sqls/` 下文件，不动其它 docs。
