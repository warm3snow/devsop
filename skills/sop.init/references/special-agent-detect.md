# Capability Detection Sub-Agent Instructions (API / DB)

> This file serves as the **complete instructions** for the sop.init "Step 0 Capability Detection" sub-agent. The main Agent dispatches it with `subagent_type: Explore` (read-only) and passes this file's content as the prompt.
> Target: the target project repository (**read-only detection; any write operation is strictly forbidden**).

---

## Core Goal

Determine whether the target project **exposes APIs externally** and **has database / persistence definitions**, and return two boolean values in a fixed format for the main Agent to pass to `init_harness.sh --has-api= --has-db=`.

---

## Hard Constraints

1. **Read-only**: use only Read / Glob / Grep / Bash (read-only commands) for detection; **strictly forbidden** to create, modify, or delete any file in the target project.
2. **Evidence-driven**: each boolean value must have at least one command-based piece of evidence or a "no evidence" statement; guessing from experience is forbidden.
3. **Fixed return format**: see the "Return Format" at the end; the main Agent parses it line by line; extra prose output is forbidden.

---

## Detection Methods

### A. API Detection (determines `HAS_API`)

Run in the target project root (adjust paths per the actual package manager; exclude vendor/node_modules):

```bash
# 1. Interface definition files
find . \( -name "*.proto" -o -name "*.thrift" -o -name "*.api" -o -name "openapi*.yaml" -o -name "swagger*.yaml" \) -not -path "*/vendor/*" -not -path "*/node_modules/*" | head

# 2. HTTP / RPC framework dependencies
grep -rlE "gin|echo|fiber|go-zero|kratos|grpc|gorilla/mux|net/http|flask|django|fastapi|express|spring" go.mod requirements.txt package.json pom.xml 2>/dev/null

# 3. Route registration / handler files
find . \( -name "router*" -o -name "route*" -o -name "*handler*.go" -o -name "controller*" \) -not -path "*/vendor/*" -not -path "*/node_modules/*" | head
```

**Determination rules**:
- Substantive evidence in any category (interface definition files / framework dependency + route registration) → `HAS_API=true`
- No evidence in all three categories (pure library, pure CLI, pure documentation repository) → `HAS_API=false`
- Only `net/http` appears in dependencies but no route/handler registration exists → lean toward `false` (may only be a client call)

### B. DB Detection (determines `HAS_DB`)

```bash
# 1. DB driver / ORM dependencies
grep -rlE "database/sql|gorm|xorm|sqlx|ent|mysql|postgres|mongo|redis|sqlite|sqlalchemy|django.db|mongoose|mybatis" go.mod requirements.txt package.json pom.xml 2>/dev/null

# 2. migration / schema / SQL files
find . \( -name "*.sql" -o -iname "*migration*" -o -iname "*schema*" \) -not -path "*/vendor/*" -not -path "*/node_modules/*" | head

# 3. ORM model definitions (struct tags / decorators)
grep -rlE "gorm:\"|xorm:\"|db:\"" --include="*.go" . 2>/dev/null | head
grep -rlE "models\.Model|@Entity|@Table" --include="*.py" --include="*.java" . 2>/dev/null | head
```

**Determination rules**:
- Substantive evidence in any category → `HAS_DB=true`
- No evidence in all three categories (pure in-memory / pure computation / pure documentation project) → `HAS_DB=false`
- Only redis as a cache client, with no schema/model at all → can be judged `false` (note the reason in the evidence summary)

---

## Return Format

**Output strictly in the following format** (the main Agent parses the key-values line by line):

```
HAS_API=true|false
HAS_DB=true|false
EVIDENCE_API=<one-line evidence summary; write "no proto/framework dependency/route registration evidence" when false>
EVIDENCE_DB=<one-line evidence summary; write "no DB driver/migration/model evidence" when false>
```

Example (a skill-library project with no API and no DB):

```
HAS_API=false
HAS_DB=false
EVIDENCE_API=no proto/HTTP-RPC framework dependency/route registration evidence (only shell scripts and markdown)
EVIDENCE_DB=no DB driver/migration/ORM model evidence
```

---

## Failure Handling

- Target directory unreadable / non-existent → output `HAS_API=true` `HAS_DB=true` (conservative default, does not block initialization) and note "detection failed, taking conservative default" in the EVIDENCE lines.
