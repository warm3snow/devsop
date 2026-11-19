# Database Documentation Guide

> Use this guide when the project has persistent storage. The main agent can follow it directly or delegate the task when supported.
> Target: `.docs/sqls/` (persistence structure documentation area).

---

## Core Goal

Based on the project's real persistence structures, fill `.docs/sqls/` into documentation for DB schema / table design / migration conventions.

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

- **No evidence of persistence** → do not create database docs; leave any existing files untouched.
- Evidence exists → enter create/update mode.

### 1. Extract schema facts

- Prefer extracting table structures from migration history / ORM models (field names / types / constraints / indexes).
- Without migrations, derive from ORM struct tags (gorm / xorm) or entity definitions, marking `<!-- TODO(devsop-init): verify against the live schema -->`.
- For tables involving state machines (e.g. order status / task status), list the state enumerations and transition conditions.

### 2. Generate documentation

- `sqls/database.md` filled in per the skeleton sections: table design / index conventions / transaction boundaries / migration strategy.
- Write a Source + Last-verified footnote at the top of each doc.
- For uncertain fields, keep `{{...}}` or `<!-- TODO(devsop-init): ... -->`.

---

## Constraints

- **Projects without a database should not create database docs**. Never delete existing project files as part of this check.
- Forbidden to copy schema as code strings; fields must carry meaning explanations.
- Keep and fix existing manually-written schema docs; do not overwrite wholesale.
- Only touch files under `sqls/`; do not touch other docs.
