# Database / Persistence Structure

> Central location for database table structure / Schema definition files, as the authoritative reference for development and review.
> DDL changes must be synced here.

---

## Directory Conventions

```
sqls/
├── README.md                # this file
└── <db_name>/<table>.sql    # or <db_name>_FINAL_SCHEMA.md (per actual project)
```

## Maintenance Principles

- DDL in sync with production; table changes must be synced to this directory
- Indexes must be recorded; before adding new query conditions, confirm index coverage
- Fields must have COMMENT, enum fields list all possible values
- Task templates `02-plan.md` / `07-docs.md` already mandate DB changes synced to this directory

---

## Database List

| DB | Purpose | Main Tables | Document Path |
|----|------|-------|---------|
|  |  |  |  |
