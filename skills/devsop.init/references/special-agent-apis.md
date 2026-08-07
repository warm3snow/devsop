# APIs Review Sub-Agent Instructions

> This file serves as the **supplementary instructions** for the `apis` review sub-agent, on top of the common prompt. The main Agent passes it along when dispatching.
> Target: `.docs/apis/` (the external API documentation area).

---

## Core Goal

Based on the real interfaces in the code, fill `.docs/apis/` into an interface documentation set written from the **caller's perspective**:
- `apis/index.md` master index (1:1 correspondence with the official API docs)
- `apis/<module>/<Action>.md` one doc per exposed Action (following the `_template.md` structure)
- `apis/api-standards.md` keep it if it has substantive content; only supplement this project's protocol/path/version conventions

---

## Steps

### 0. Relevance determination (decides whether to execute)

Run the following commands to determine whether the project exposes APIs externally:

```bash
# HTTP / RPC entry points
find . \( -name "*.proto" -o -name "*.thrift" -o -name "*.api" \) -not -path "*/vendor/*" 2>/dev/null | head
grep -rlE "gin|echo|fiber|go-zero|kratos|grpc|gorilla/mux|net/http" go.mod 2>/dev/null
# Route registration
find . \( -name "router*" -o -name "route*" -o -name "*handler*.go" -o -name "controller*" \) -not -path "*/vendor/*" 2>/dev/null | head
```

- **No evidence of any external interface** (no proto / no HTTP-RPC framework / no route registration / pure library without exported interfaces) → judged a **project without APIs**:
  1. **Delete** the entire `.docs/apis/` directory (`rm -rf`).
  2. Output `skipped(no external API)` and end.
- Evidence exists → enter create/update mode.

### 1. Scan interface facts

Extract structured facts from information sources (**forbidden to fabricate from memory**):
- proto/thrift/OpenAPI → service / method / message
- Route registration tables → method + path + handler
- handler signatures → inputs / outputs
- Error code tables → Code / meaning
- Version path prefixes (e.g. `/v1/`)

### 2. Generate API documentation

- Cluster by module (e.g. `user/`, `order/`), one `<module>/<Action>.md` per Action, using `apis/_template.md`.
- Required sections: description / request (method + path + input table + example) / response (output table + example) / error codes / changelog.
- For uncertain fields, keep `{{...}}` or `<!-- TODO(devsop.init): ... -->`, do not fabricate.
- Write a Source + Last-verified footnote at the top of each doc.

### 3. Update index.md

Refresh `apis/index.md` as a master index table: module / Action / one-liner / link. Keep 1:1 correspondence with the official docs.

---

## Constraints

- **Projects without APIs must delete the `apis/` directory**; keeping an empty skeleton is forbidden.
- Forbidden to copy source code; write "how to call / what is returned / how to read errors" from the caller's perspective.
- Keep and fix existing manually-written API docs; do not overwrite wholesale.
- Only touch files under `apis/`; do not touch other docs.
