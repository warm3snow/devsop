# SQLs Review Sub-Agent Instructions

> This file serves as the **supplementary instructions** for the `sqls` review sub-agent, on top of the common prompt. The main Agent passes it along when dispatching.
> Target: `.harness/docs/sqls/` (persistence structure documentation area).

---

## Core Goal

Based on the project's real persistence structures, fill `.harness/docs/sqls/` into documentation for DB schema / table design / migration conventions.

---

## Steps

### 0. Relevance determination (decides whether to execute)

Run the following commands to determine whether the project has a database / persistence:

```bash
# ORM / DB driver dependencies
grep -rlE "database/sql|gorm|xorm|sqlx|ent|mysql|postgres|mongo|redis|sqlite" go.mod 2>/dev/null
# Migration / schema files
find . \( -name "*.sql" -o -name "*migration*" -o -name "*schema*" \) -not -path "*/vendor/*" 2>/dev/null | head
# ORM model definitions
find . \( -name "*.go" \) -not -path "*/vendor/*" 2>/dev/null | xargs grep -lE "type .* struct" 2>/dev/null | head
```

- **No evidence of any persistence** (no DB driver dependency / no migration / no schema / pure in-memory or pure computation library) → judged a **project without a database**:
  1. **Delete** the entire `.harness/docs/sqls/` directory (`rm -rf`).
  2. Output `skipped(no database)` and end.
- Evidence exists → enter create/update mode.

### 1. Extract schema facts

- Prefer extracting table structures from migration history / ORM models (field names / types / constraints / indexes).
- Without migrations, derive from ORM struct tags (gorm / xorm) or entity definitions, marking `<!-- TODO(devsop.init): verify against the live schema -->`.
- For tables involving state machines (e.g. order status / task status), list the state enumerations and transition conditions.

### 2. Generate documentation

- `sqls/database.md` filled in per the skeleton sections: table design / index conventions / transaction boundaries / migration strategy.
- Write a Source + Last-verified footnote at the top of each doc.
- For uncertain fields, keep `{{...}}` or `<!-- TODO(devsop.init): ... -->`.

---

## Constraints

- **Projects without a database must delete the `sqls/` directory**; keeping an empty skeleton is forbidden.
- Forbidden to copy schema as code strings; fields must carry meaning explanations.
- Keep and fix existing manually-written schema docs; do not overwrite wholesale.
- Only touch files under `sqls/`; do not touch other docs.
