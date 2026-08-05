# Database Standards

> Status: Draft | Maintainer: {{name}} | Last Updated: {{YYYY-MM-DD}}

## Scope

Covers all persistent storage for this service: {{MySQL / PostgreSQL / MongoDB / Redis}} etc.

## 1. Selection and Versions

| Storage | Purpose | Version | Deployment Form |
|------|------|------|----------|
| {{MySQL}} | {{primary business data}} | {{8.0}} | {{cloud RDS}} |
| {{Redis}} | {{cache/lock/queue}} | {{6.x / 7.x}} | {{Cluster / Sentinel}} |

## 2. Table Design Standards

### Naming
- Table names: `snake_case`, {{plural / singular}} consistent across the project
- Field names: `snake_case`
- Index names:
  - Normal index `idx_{{field}}` or `idx_{{table}}_{{field}}`
  - Unique index `uk_{{field}}`
  - Foreign key `fk_{{from}}_{{to}}`

### Required Fields
Every business table must include:

```sql
id          BIGINT UNSIGNED  PRIMARY KEY AUTO_INCREMENT,
created_at  DATETIME(3)      NOT NULL,
updated_at  DATETIME(3)      NOT NULL,
is_deleted  TINYINT(1)       NOT NULL DEFAULT 0,  -- soft delete (if used)
```

> Choose one of the soft delete field names `is_deleted` or `deleted_at`, consistent across the project.

### Type Selection
- Primary key: `BIGINT UNSIGNED` (business database) or `UUID` (distributed)
- Time: `DATETIME(3)` or `TIMESTAMP`, **forbidden** to store time as `INT`
- Money: `DECIMAL(N, 4)`, **forbidden** `FLOAT` / `DOUBLE` (precision loss)
- Enums: `TINYINT` + code constants or `VARCHAR(32)`
- JSON: only for attribute config that does not need indexing/aggregation; **forbidden** to use JSON for relational data
- Strings: explicit length upper bound (`VARCHAR(N)`), **avoid** `TEXT` / `BLOB` (unless truly needed)

### Indexes
- Index count per table: ≤**5** (including primary key)
- Composite index field count: ≤**3**
- Must create composite indexes for high-frequency queries (leftmost prefix principle)
- **Forbidden** to build standalone indexes on fields with poor selectivity (gender, status booleans)
- Foreign key fields must have indexes
- Must analyze EXPLAIN to confirm index usage

### Charset and Collation
- Charset: `utf8mb4`
- Collation: `utf8mb4_0900_ai_ci` (MySQL 8) or `utf8mb4_unicode_ci`

## 3. ORM and Queries

- ORM: `{{GORM / Prisma / SQLAlchemy / MyBatis}}`
- Code generation: `{{make gen-dao or equivalent command}}`

### ORM Prohibitions

| # | Forbidden | Reason | Alternative |
|---|------|------|------|
| 1 | `SELECT *` | irrelevant fields waste IO, field changes easily cause problems | explicit column names |
| 2 | `.Save()` for updates (GORM) | ambiguous semantics, triggers unnecessary UPDATEs | `.Updates(...)` or `.Update(...)` |
| 3 | N+1 queries | very poor performance | `Preload` / `JOIN` |
| 4 | `UPDATE` / `DELETE` without `WHERE` | full-table disaster | must include primary key or unique condition |
| 5 | String-concatenated SQL | SQL injection | parameterized queries |
| 6 | Querying the DB in loops | N round trips | batch queries + in-memory merge |

### Transactions
- Use `TransactCtx()` / `db.Transaction(...)` to wrap multi-write operations
- Must **check the return value of the transaction function**; the framework rolls back automatically on error
- **Forbidden** to call external interfaces inside transactions (easily causes long transactions and table locks)
- Transaction timeout: default {{3 seconds}}

### Caching
- Cache key namespace: `{{module}}:{{entity}}:{{id}}`, e.g. `user:profile:123`
- **Forbidden** to use business object memory addresses or Go type strings as keys
- Cache empty values (short TTL, e.g. 60s) to prevent penetration
- Large hot keys use local + distributed two-level caching
- Must set expiration time, **forbidden** permanent caching (unless explicitly confirmed)

## 4. Performance and Capacity

| Item | Threshold |
|------|------|
| Single-table row count warning | 5 million (consider sharding/archiving beyond that) |
| Slow query threshold | ≥**500ms** must be optimized (200ms alert in production) |
| Connection pool upper limit | ≤**100** (adjust per instance spec) |
| Query timeout | 3 seconds by default, must be set for external interfaces |
| Batch operation sharding | ≤1000 rows/batch |

## 5. Migrations

- Tool: `{{Liquibase / Flyway / GORM AutoMigrate / in-house scripts}}`
- File naming: `V{{version}}__{{description}}.sql`, e.g. `V20240518_001__add_user_email_index.sql`
- Must be reversible: each up script has a matching down script
- **Forbidden** to execute business logic data transformations in migrations (data fixes go in separate scripts with independent approval)
- Destructive changes (drop/rename/type changes) must be reviewed + canary
- Keep the complete migration history, **forbidden** to delete already-released migration files

## 6. Backup and Disaster Recovery

- Backup frequency: {{daily full + hourly incremental}}
- Retention period: {{30 days}} (90 days for core databases)
- Drill frequency: {{quarterly recovery testing}}
- Cross-AZ/cross-region: {{enabled or not}}

## 7. Data Security

- **【Must】** Sensitive fields encrypted at rest: ID card numbers, phone numbers, bank cards, passwords, etc.
- **【Must】** Encryption algorithms see [coding-style.md §Security Coding](coding-style.md)
- **【Must】** Data access audit logs: change-type operations (INSERT/UPDATE/DELETE) must be traceable
- **【Must】** Production databases **forbidden** to be accessed directly, must go through bastion host or controlled channel
- **【Must】** Test/development environment data redacted, **forbidden** to copy real production data

## 8. Database Type Compatibility

### Supported Database List

This project supports the following database engines; all ORM model definitions and migration scripts **must** be verified to pass on the databases listed:

| # | Database | Version | Purpose | Notes |
|---|--------|------|------|------|
| 1 | {{MySQL}} | {{8.0+}} | {{primary business data}} | |
| 2 | {{Kingbase}} | {{10.0+}} | {{primary business data}} | |
| 3 | {{TiDB}} | {{11.0+}} | {{primary business data}} | |
| 4 | {{PostgreSQL}} | {{14+}} | {{analytics/GIS}} | enabled on demand |
| 5 | {{SQLite}} | {{3.x}} | {{local/unit tests}} | development environment only |

> Fill in according to the actual project, remove unused rows. If the project uses only a single database, keep just one row.

### Field Type Compatibility Constraints

When creating or modifying ORM models, **forbidden** to use field types unsupported by the target database. Developers must follow these rules:

1. **【Must】** Only use field types supported by all target databases of the project; do not rely on database-specific types
2. **【Must】** Before adding a field, consult the compatible type mapping table below to confirm all target databases can map it
3. **【Forbidden】** Use database-specific types in ORM models (e.g. MySQL `ENUM`, PostgreSQL `ARRAY` / `HSTORE` / `JSONB`), unless the project explicitly supports only that single database
4. **【Forbidden】** Use custom types or extension types not reviewed by the team

### Common Field Type Mapping (recommended)

| Semantic Type | MySQL | PostgreSQL | Kingbase | TiDB | SQLite | Recommended ORM Declaration |
|----------|-------|------------|----------|------|--------|--------------|
| Integer primary key | `BIGINT UNSIGNED` | `BIGINT` | `BIGINT` | `BIGINT` | `INTEGER` | auto-adapted by the framework |
| String | `VARCHAR(N)` | `VARCHAR(N)` | `VARCHAR(N)` | `VARCHAR(N)` | `TEXT` | `string` / `CharField(max_length=N)` |
| Long text | `TEXT` | `TEXT` | `TEXT` | `TEXT` | `TEXT` | `text` |
| Boolean | `TINYINT(1)` | `BOOLEAN` | `BOOLEAN` | `TINYINT(1)` | `INTEGER` | `bool` |
| Timestamp | `DATETIME(3)` | `TIMESTAMP(3)` | `TIMESTAMP(3)` | `DATETIME(3)` | `TEXT` (ISO8601) | `datetime` |
| Exact decimal | `DECIMAL(M,N)` | `NUMERIC(M,N)` | `NUMERIC(M,N)` | `DECIMAL(M,N)` | `REAL` | `decimal` |
| JSON data | `JSON` | `JSONB` | `JSONB` | `JSON` | `TEXT` | framework JSON serialization |
| UUID | `CHAR(36)` / `BINARY(16)` | `UUID` | `UUID` | `CHAR(36)` / `BINARY(16)` | `TEXT` | choose per framework support |
| Binary | `BLOB` | `BYTEA` | `BYTEA` | `BLOB` | `BLOB` | `bytes` / `binary` |

> If the project supports only a single database, database-specific types may be used, but must be noted in the table header.

### ORM Model Review Points

During code review (CR), confirm:

- [ ] Whether model field types are within the compatible mapping table above
- [ ] Whether there are default value expressions depending on specific database behavior (e.g. MySQL `NOW(3)` vs PostgreSQL `now()`)
- [ ] Whether migration scripts can run successfully on all target databases
- [ ] If database-specific types are truly needed, whether the reason is annotated in the model comment and approved by review

## References

### Project Documents

- Coding and security: [coding-style.md](coding-style.md)
- Upstream/downstream dependencies: [relationship.md](../relationship.md)
- API standards: [api-standards.md](api-standards.md)
- Deployment standards: [deployment.md](deployment.md)

### Official Database Documentation

- MySQL: <https://dev.mysql.com/doc/refman/8.0/en/data-types.html>
- PostgreSQL: <https://www.postgresql.org/docs/current/datatype.html>
- Kingbase: <https://help.kingbase.com.cn/v8/index.html>
- TiDB: <https://docs.pingcap.com/tidb/stable/data-type-overview>
- SQLite: <https://www.sqlite.org/datatype3.html>
