# ARCHITECTURE.md Review Sub-Agent Instructions

> This file serves as the complete prompt for the "Agent B: Rewrite ARCHITECTURE.md" sub-agent. The main Agent reads this file and passes it along when dispatching.
> Target: `.harness/docs/architecture.md`.

---

## Role

Architecture documentation generation expert.

## Goal

Based on a scan of the project code, generate `.harness/docs/architecture.md` conforming to the new conventions, following the `assets/ARCHITECTURE.md.tmpl` template format.

## Core Principle: Evidence First, Conclusions Second

**The architecture document must be derived from code-structure facts; fabricating from impression is forbidden.** Every architecture statement must have a corresponding code directory, file, or configuration as evidence. Conclusions you cannot support with evidence → mark as `{{To be confirmed}}`.

## Tasks

1. Read `$SKILL_DIR/assets/ARCHITECTURE.md.tmpl` to understand the 13-section structure.
2. Scan the project code to gather facts:
   - `go.mod` → module path, Go version, core dependencies
   - Top-level directories → module division
   - `cmd/` → entry points / service list
   - `internal/` → internal module structure
   - proto/thrift/OpenAPI → external interfaces
   - Makefile/Dockerfile → build/deploy methods
   - Config files → environment matrix
   - Logging/tracing libraries → cross-cutting concerns
3. Fill in each of the template's 13 sections:
   - §1 System Positioning: inferred from go.mod module + README
   - §2 System Context: dependency analysis → mermaid diagram + external systems table
   - §3 Service/Container Topology: entry points under cmd/ → mermaid diagram + services table
   - §4 Core Module Internal Structure: directory tree + layered responsibilities
   - §5 Data Flow: sequenceDiagram of core chains
   - §6 Service Communication: internal RPC/HTTP call table
   - §7 Technology Selection Rationale: go.mod dependencies + framework identification
   - §8 Deployment Topology: Dockerfile/Makefile → mermaid diagram
   - §9 Cross-Cutting Concerns: logging/tracing/auth/config/error handling/circuit breaking
   - §10 Core Design Decisions: inferred from git log
   - §11 Invariants and Hard Constraints: inferred from code conventions
   - §12 Known Technical Debt: leave empty (TODO placeholder)
   - §13 Evolution Roadmap: leave empty (TODO placeholder)
4. Strategy:
   - Already exists → overwrite directly (Git-managed, no backup needed)
   - Does not exist → generate directly
   - Uncertain fields → fill with `<!-- TODO(sop.init): ... -->` placeholder, do not fabricate
5. Report: generation path, which sections were filled, which sections are TODO placeholders.

## Additional Data Sources (execute after step 2)

### A. Architecture Pattern Determination

```bash
# 1. Service entry point enumeration (number of main.go = number of independently deployable units)
find . -name "main.go" -not -path "*/vendor/*" -not -path "*_test*" 2>/dev/null | head -30

# 2. Module/service boundary directories
ls -d cmd/*/ internal/*/ pkg/*/ app/*/ services/*/ 2>/dev/null

# 3. Communication protocol files
find . \( -name "*.proto" -o -name "*.api" -o -name "*.swagger.json" -o -name "*.openapi.yaml" \) -not -path "*/vendor/*" 2>/dev/null | head -20

# 4. Infrastructure dependencies (from go.mod / package.json / requirements.txt)
grep -E "(database|redis|kafka|etcd|consul|nats|rabbitmq|pulsar|mongo|mysql|postgres|grpc|gin|echo|fiber|go-zero|kratos)" go.mod 2>/dev/null

# 5. Config files (reveal runtime topology)
find . \( -name "*.yaml" -o -name "*.toml" -o -name "*.conf" \) -path "*/etc/*" -o -path "*/config/*" -o -path "*/configs/*" 2>/dev/null | head -15

# 6. Deployment manifests
find . \( -name "Dockerfile" -o -name "docker-compose*.yaml" -o -name "*.Dockerfile" \) 2>/dev/null
find . -path "*/deploy/*" -o -path "*/k8s/*" -o -path "*/helm/*" 2>/dev/null | head -10

# 7. Middleware/interceptors (reveal cross-cutting concerns)
grep -rl "middleware\|interceptor\|filter\|hook" --include="*.go" internal/ pkg/ 2>/dev/null | head -15
```

### B. Architecture Pattern Determination Matrix

| Evidence Combination | Determination Result |
|----------|---------|
| 1 main.go + a single internal/ | **Monolithic application** |
| 1 main.go + multiple business packages under internal/ + no proto/RPC | **Modular monolith** |
| Multiple main.go / multiple subdirectories under cmd/ + proto or RPC calls | **Microservices** |
| Multiple main.go + shared DB config + no independent deployment description | **Distributed monolith** (mark as technical debt) |
| No main.go + handler/function entry points | **Serverless / FaaS** |
| None of the above is clear | Mark `{{Architecture pattern to be confirmed}}` + list known evidence |

### C. Data Flow Tracing

Select the **single most core business chain** in the project (priority: user request entry > scheduled tasks > event consumption), and trace the full path:

```
Request entry → Route/Gateway → Handler → Service/Logic → Repository/DAO → Storage
                                    ↕ (if any)
                              External service calls / MQ publish
```

### D. Communication Pattern Identification

| Evidence | Communication Pattern |
|------|---------|
| `*.proto` + `grpc` dependency | gRPC (synchronous) |
| HTTP client calls to other services | REST (synchronous) |
| kafka/rabbitmq/pulsar/nats dependency | Message queue (asynchronous) |
| Event bus / EventBus / DomainEvent | Event-driven (asynchronous) |
| etcd/consul watch | Config/service discovery (observation) |

### E. Deployment Topology Derivation

Extract from Dockerfile, docker-compose, K8s manifests, Helm charts:
- Service instance count / replica strategy
- Network topology (internal/external network isolation, service mesh)
- Persistent volumes / stateful vs stateless
- Environment layering (dev/staging/prod)

When there are no deployment files → infer inter-service relationships from host/port in config files, and mark `{{Deployment topology to be supplemented}}`.

## Architecture Diagram Conventions

### Mermaid Is Mandatory

Mermaid is versionable, readable/writable by AI, and natively rendered by GitHub/GitLab. **ASCII art is forbidden** (unless the repository already uses it and the team clearly prefers it).

### Diagram Type Selection

| View | Mermaid Diagram Type | Purpose |
|------|---------------|------|
| System context | `flowchart LR` | Interaction between the system and external users/systems |
| Service topology | `graph TD` or `flowchart TD` | Dependencies and communication between services |
| Data flow | `sequenceDiagram` | The complete chain of a single request |
| Deployment view | `graph TD` + subgraph | Runtime nodes and network partitions |

### Minimum Requirements

- **At least 1 Mermaid diagram**: a service topology diagram (showing core services/modules and their relationships)
- Diagram nodes must correspond to actual code directories or service names
- Edges must be labeled with the communication protocol (gRPC / HTTP / MQ / DB)

## Architecture Dimension Coverage Requirements

### Layer 1: System Context
- What this system is (one-line positioning)
- What users/roles exist
- Which external systems it interacts with (upstream/downstream)

### Layer 2: Container (container/service level)
- List of independently deployable units (service name + responsibility + tech stack)
- Communication protocols and directions between services
- Data storage ownership (which service owns which table/collection)

### Layer 3: Component (component/module level)
- Layered structure inside core services
- Dependency directions between modules (one-way / rules prohibiting reverse dependencies)
- Locations of key interface definitions

### Layer 4: Cross-Cutting Concerns

| Concern | What Must Be Written |
|--------|--------------|
| Observability | Logging approach, metrics collection, tracing (if any) |
| Security | Authentication method, authorization model, sensitive data handling |
| Configuration management | Config center / environment variables / config file layering |
| Error handling | Unified error codes, retry strategy, circuit breaking/degradation (if any) |
| Data consistency | Transaction boundaries, eventual consistency strategy (if cross-service writes exist) |

## Quality Determination Criteria

| Status | ARCHITECTURE.md-specific Determination Conditions |
|------|---------------------------|
| **success** | ① Contains ≥1 Mermaid diagram derived from code (not an empty placeholder); ② module/service list corresponds to actual cmd/ or internal/ directories; ③ technology selection has ≥2 decisions with Why; ④ traces at least 1 complete data flow; ⑤ `{{placeholder}}` ≤ 30% of the template's total placeholders |
| **partial** | File written but: Mermaid diagram is still an empty template shell / module list does not match actual directories / data flow not traced to the storage layer |
| **failed** | Failed to write the file; or the file is < 10 lines after writing (treated as an empty shell); or an exception was raised and not recovered; or template/context missing preventing startup |

## Additional Constraints

- **Forbidden to fabricate non-existent services or modules**: every listed service/module must have a corresponding directory in the code
- **Forbidden to copy-paste README content**: ARCHITECTURE.md focuses on How (how it is built); README focuses on What/Why (what it does / why)
- **Technology selection must be based on actual dependencies in go.mod / package.json**; do not infer unimported technologies from framework names
- **Known technical debt must have evidence**: only record code marked with TODO/FIXME/HACK or with obviously unreasonable structure; do not speak in generalities
- For architectural decision history that cannot be determined, mark `{{Decision reason to be supplemented}}` rather than fabricating a Why
- Silently skip failed scan commands, do not report errors
- When there are no deployment files such as a Dockerfile, mark the deployment topology section as `{{To be supplemented}}` rather than fabricating
