# Library project supplementary instructions (Library Context)

> This file is read by the main agent when it detects `project.type == library`; content is extracted by section and injected into each sub-agent's prompt.
> Sub-agents do not read this file directly.

---

## § General instructions

This project is a **{{library_lang}} library** (a pure library, depended on and used by other projects, with no standalone runnable entry point).

### Content that must be deleted

- All sections related to "deployment", "runtime services", "databases", "upstream/downstream service calls", "health checks", "monitoring & alerting", "canary releases", and "rollback strategies"
- Docker / docker-compose / K8s related content
- The environment matrix (dev/test/pre/prod)
- Service startup commands
- The section simulating upstream/downstream services

### Content a library should focus on (common to all languages)

- **Exported API surface**: design of public functions/types/interfaces
- **Backward compatibility**: follow semver; breaking changes require a major version bump
- **Minimal dependencies**: prefer zero-dependency or minimal-dependency
- **Consumer documentation**: API doc comments, usage examples
- **Version compatibility**: supported language/runtime version ranges
- **Thread safety**: concurrency usage notes

---

## § Language-specific instructions

### Go library specialization

- Package management: installed via `go get`, dependencies managed by `go.mod`
- Documentation: godoc comment conventions, generatable via `go doc`
- Versioning: Go module semver (v0/v1 have no /vN path, v2+ requires a path suffix)
- Compatibility: declare the minimum supported Go version (the `go` directive in `go.mod`)
- Testing: `go test ./...`; benchmarks use `testing.B`
- Zero-value usability: public types should be usable at their zero value where possible
- internal/: internal packages must not be imported externally, used to isolate implementation details

### Rust library specialization

- Package management: installed via `cargo add`, dependencies declared in `Cargo.toml`
- Documentation: `///` doc comments + `cargo doc`, published to docs.rs
- Versioning: Cargo semver (0.x allows breaking changes, 1.0+ is strict)
- Feature flags: use Cargo features to control optional functionality, keep default features minimal
- `#[no_std]` support: if applicable, provide no_std compatibility
- Safety: annotate the scope of `unsafe` usage, provide safe wrappers
- MSRV: declare the Minimum Supported Rust Version
- Testing: `cargo test`; doc tests are first-class citizens

### Java SDK specialization

- Package management: published to Maven Central, coordinates declared in pom.xml (groupId:artifactId:version)
- Documentation: Javadoc comments, complete `@param` / `@return` / `@throws`
- Versioning: Maven semver, SNAPSHOT for development versions
- API stability annotations: `@Deprecated` (deprecated), `@Beta` / `@Experimental` (unstable)
- Minimum JDK version: explicitly declare source/target compatibility
- Dependency management: shade/relocate conflicting dependencies, avoid transitive dependency pollution of consumers
- Testing: JUnit 5 + Mockito, `mvn test`
- Thread safety: explicitly state thread-safety guarantees for classes/methods (`@ThreadSafe` / `@NotThreadSafe`)

---

## § README-specific

A library's README should contain the following structure (replacing a service project's upstream/downstream/deployment/docker sections):

1. **Project introduction**: one sentence explaining what the library does
2. **Installation**:
   - Go: `go get {{module_path}}`
   - Rust: `cargo add {{crate_name}}` or a Cargo.toml dependency declaration
   - Java: a Maven/Gradle coordinate snippet
3. **Quick example**: a minimal runnable code snippet
4. **API overview**: a list of core exported functions/types (or a link to online docs)
5. **Version compatibility matrix**: supported language/runtime versions
6. **Contribution guide**: how to submit PRs, run tests

Delete: deployment environment requirements, docker-compose startup, upstream/downstream dependencies (at the service level)

---

## § ARCHITECTURE-specific

A library's architecture doc should focus on:

1. **Module/package structure**: top-level module breakdown and responsibilities
   - Go: package divisions
   - Rust: module tree (lib.rs → mod.rs)
   - Java: package hierarchy
2. **Exported API design**: the design philosophy of the public interfaces
3. **Internal layering**: dependency relationships between modules (using a mermaid package/module dependency graph)
4. **Extension points**: interfaces/traits/callbacks/option patterns
5. **Performance characteristics**: time/space complexity, memory allocation strategy

Delete: service topology diagrams, gateway layer, system context diagrams (external system interactions), container diagrams
Replace "service topology diagram" with "module dependency graph"

---

## § AGENTS.md-specific

The current `AGENTS.md` template (`assets/agents.md.tmpl`) has four sections: 1. Quick index / 2. DEVSOP / 3. Development conventions / 4. Forbidden red lines. Library projects are differentiated as follows (executed by Agent A in batch one, see `special-agent-agents.md`):

### Section 1. Quick index (delete lines)
- Delete the "Database / persistence schema" line (`.harness/docs/sqls/`)
- Delete the "Test environment deployment / code sync" line (`.harness/docs/devops/test-env-deploy.md`)
- Delete the "Integration testing standards" line (`.harness/docs/integration_test/integration_test.md`) — library projects have no standalone runtime environment
- Keep the "Unit testing standards" line (`.harness/docs/unittest/unittest.md`; libraries still need unit tests)

### Section 2. DEVSOP
- The 9-stage process is kept, but Step 5 Deploy / Step 6 IT can be skipped for library projects (no standalone runtime environment, no external service interfaces)
- Skipping must be noted with a reason in the `00-overview.md` Progress, with the time log filled with the same timestamp and the remark column reading "skipped: library project has no such stage"

### Section 3. Development conventions
- Add exported API stability rules (e.g.: public interface changes must go through the deprecation process; breaking changes bump the major version)
- Add the minimal dependency principle (zero-dependency / minimal-dependency preferred)
- Add backward compatibility constraints (semver, the core contract of a library project)
- Delete DB interaction conventions and deployment environment requirements

### Section 4. Forbidden red lines
- Add a red line: exported API breaking changes must bump the major version
- Add a red line: public type signature changes must be accompanied by updates to consumer docs
- Delete red lines related to "database schema changes" and "external API protocol changes" (library projects have no standalone DB / external services)
