---
# Do not modify the header of this file; the AI coding agent relies on it to apply this style guide as an always-on rule
type: always
---
You are a professional Rust development assistant. All code must strictly follow the coding conventions below.

**Note: unless explicitly stated otherwise, follow the Rust Style Guidelines (rustfmt defaults), the Rust API Guidelines, and clippy defaults.**

## Conventions Overview

The requirement level of each convention is defined as:
- **Mandatory**: code must follow this; violating it is considered an error
- **Preferable**: code should follow this, but exceptions are allowed in special cases and are not considered errors
- **Optional**: can be referenced; decide whether to adopt it based on the specific situation

## Code Style Conventions

### 【Mandatory】Formatting
- All code must be formatted with `rustfmt` (default settings); formatting is enforced in CI
- A single line should not exceed 100 columns (rustfmt default)
- `cargo clippy` must pass with zero warnings before commit

### 【Mandatory】Imports and modules
- One `use` item per source (unless using `use ...::{a, b}` for the same crate/module)
- Import order: std → external crates → crate-local; separate groups with a blank line
- Prefer `use crate::...` absolute paths over `super::` relative paths

### 【Mandatory】Naming conventions
- Modules/files: `snake_case`; types (structs/enums/traits): `UpperCamelCase`; functions/methods/variables: `snake_case`
- Constants/statics: `UPPER_SNAKE_CASE`; type parameters: single `UpperCamelCase` letter (`T`, `K`)
- Booleans read as a question (`is_ready`, `has_token`); conversions named `as_*` (fallible: `try_into`)

### 【Preferable】Code line count limits
- A file must not exceed 800 lines; a function must not exceed 80 lines
- Nesting depth must not exceed 4; extract functions instead of nesting further

## Language Feature Conventions

### 【Mandatory】Correctness
- Never use `unwrap()` / `expect()` on values that can fail in production paths — use `?`, `match`, or proper error types (allow only for invariants with a comment)
- `panic!` is for unrecoverable invariants only; fallible operations return `Result`
- Use `let Some(x) = ... else { return ... }` for early-return guards instead of nested `match`

### 【Mandatory】Ownership and types
- Prefer borrowing over cloning; avoid `clone()` in hot paths and library code
- Prefer `&str` over `&String` in parameters; return owned types only when necessary
- Use `Option<T>` for absence, `Result<T, E>` for fallibility; never sentinel values (`-1`, empty string) to encode errors

### 【Preferable】Modern constructs
- Prefer iterator chains (`map`/`filter`/`collect`) over manual loops for data transforms
- Prefer `derive` over hand-written `impl` for `Debug/Clone/PartialEq/Hash/Default`
- Use `thiserror` for library error enums; `anyhow` only in application/CLI top levels
- Derive `Debug` for every public type (Rust API Guidelines)

## Error Handling Conventions

### 【Mandatory】Errors
- Library crates must define typed errors (`thiserror`-based enum); applications may use `anyhow`
- Never discard errors (`let _ = ...` or `unwrap_or_default()` on `Result`) without a comment explaining why
- Log errors with context at the boundary (`map_err(|e| ...context)` / `with_context`)

### 【Mandatory】Logging
- Use `tracing` (or `log` facade); structured fields: `tracing::info!(uid = %user.id, "created")`
- Never log secrets/tokens/PII — mask before logging

## Comment Conventions

### 【Mandatory】Comments
- Every public item must have a doc comment (`///`) with `# Examples` where valuable (`cargo doc` is part of CI)
- Comments explain *why*, not *what*; keep comments in sync with code changes
- No commented-out code in committed files — use git history instead

## Concurrency Conventions

### 【Mandatory】Concurrency
- Prefer `std::sync` / `tokio` primitives per project runtime; never mix blocking code into async contexts
- Shared state: prefer message passing (`mpsc`) over shared mutable state; if shared, use `Mutex`/`RwLock`/atomics with the minimal lock scope
- Do not `block_on` inside async functions; blocking IO belongs in `spawn_blocking`

## Unit Test Conventions

### 【Mandatory】Testing
- Unit tests live in the same file under `mod tests`; integration tests under `tests/`
- One behavior theme per test; assert with meaningful messages
- Test public behavior, not internal implementation details; use `proptest` for property-based tests where valuable
- Coverage target: ≥60% for the project, ≥80% for core modules (per CI threshold)

## Dependency Management Conventions

### 【Mandatory】Dependencies
- Declare dependencies in `Cargo.toml`; `Cargo.lock` committed for binaries, omitted for libraries
- Adding a third-party dependency requires a documented reason; prefer std/well-established crates
- Dependency versions are pinned; upgrades go through the team's dependency-update flow (Renovate/Dependabot)

## Security Conventions

### 【Mandatory】Security
- SQL must be parameterized (query bindings); string concatenation is forbidden
- No hardcoded keys, tokens, or passwords; read from env vars or secret management
- External input must be validated at the boundary (typed deserialization with serde + explicit validation)
- Use constant-time comparison for secrets; never compare tokens with `==`

## Recommended Tools

| Purpose | Tool |
|---------|------|
| Format | `rustfmt` |
| Lint | `clippy -- -D warnings` |
| Static analysis | `cargo audit` (dependency vulnerabilities) |
| Testing | `cargo test` |
| Coverage | `cargo llvm-cov` / tarpaulin |
| CI gate | `cargo fmt --check` + `clippy -D warnings` + `cargo test` + `cargo audit` (block on failure) |
