---
# Do not modify the header of this file; the AI coding agent relies on it to apply this style guide as an always-on rule
type: always
---
You are a professional Java development assistant. All code must strictly follow the coding conventions below.

**Note: unless explicitly stated otherwise, follow the Google Java Style Guide.**

## Conventions Overview

The requirement level of each convention is defined as:
- **Mandatory**: code must follow this; violating it is considered an error
- **Preferable**: code should follow this, but exceptions are allowed in special cases and are not considered errors
- **Optional**: can be referenced; decide whether to adopt it based on the specific situation

## Code Style Conventions

### 【Mandatory】Formatting
- 2-space indentation (never tabs); K&R braces (`{` on the same line)
- A single line should not exceed 100 columns (imports and long URLs may exceed)
- Formatting is enforced by a formatter in CI (Spotless with google-java-format / checkstyle), never by hand

### 【Mandatory】Import conventions
- No wildcard imports (`import java.util.*` is forbidden)
- Static imports are used only for constants/methods in tests and well-known utilities
- Imports must be ordered and grouped (google-java-format handles this)

### 【Mandatory】Naming conventions
- Classes/records/enums: `UpperCamelCase`; methods/fields: `lowerCamelCase`; constants: `UPPER_SNAKE_CASE`
- Package names: all lowercase, no underscores, reversed domain (e.g. `com.example.project`)
- Test classes end with `Test`; no Hungarian notation or prefix letters (no `mField`, `sCount`)

### 【Preferable】Code line count limits
- A file must not exceed 800 lines; a method must not exceed 80 lines; a class must not exceed 600 lines
- Nesting depth must not exceed 4; extract methods/classes instead of nesting further

## Language Feature Conventions

### 【Mandatory】Modern Java
- Target LTS releases only (Java 17/21+); use records, sealed interfaces, and `var` where they reduce boilerplate
- Avoid raw types; always use generics; prefer `List.of()` / `Map.of()` over manual construction
- `Optional` is for return types only — never for fields, parameters, or collections; never call `Optional.get()` without `isPresent()`/`orElse` checks
- Prefer streams for simple data transforms; use loops when logic needs early exit, checked exceptions, or heavy mutation
- Minimize mutability: fields are `final` by default; prefer immutable collections

### 【Preferable】Null handling
- Use `@Nullable` / `@NonNull` annotations (jspecify / checker-framework) on public APIs
- Prefer `Objects.requireNonNull` at constructor boundaries over scattered null checks

## Error Handling Conventions

### 【Mandatory】Exceptions
- Never catch and ignore (`catch (Exception e) {}`) — log with context or rethrow with cause
- Catch the most specific exception; don't use exceptions for control flow
- Wrap with cause: `throw new ServiceException("msg", e)`; never drop the original exception
- Business errors and technical errors must be distinguishable (typed exceptions / error codes), mapped at the API boundary

### 【Mandatory】Logging
- Use SLF4J facade; choose the backing implementation (Logback) per project
- Parameterized logging: `log.error("create user failed, uid={}", uid, e)` — never string concatenation in log statements
- Never log passwords/tokens/ID-card numbers — mask before logging

## Comment and Javadoc Conventions

### 【Mandatory】Comments
- Public APIs (classes and public methods of exported modules) must have Javadoc
- Comments explain *why*, not *what*; keep comments in sync with code changes
- No commented-out code in committed files — use git history instead

## Control Structure Conventions

### 【Preferable】Flow control
- Early return / guard clauses over deep nesting
- Switch expressions (`switch` with `yield`, arrow syntax) over long if-else chains for enums and sealed types
- Ternary only for trivial expressions; never nested ternaries
- Static helper methods must not mutate shared state (stateless utilities)

## Unit Test Conventions

### 【Mandatory】Testing
- JUnit 5 + AssertJ + Mockito (if mocks are needed); tests mirror the source package layout
- One behavior theme per test method (`@DisplayName` describes intent); given/when/then structure
- Mock at boundaries only; never mock the class under test
- Coverage target: ≥60% for the project, ≥80% for core modules (per CI threshold)

## Dependency and Build Conventions

### 【Mandatory】Build
- Maven or Gradle with a wrapper committed to the repo (`mvnw` / `gradlew`); one-command build (`./mvnw verify`)
- Dependency versions are pinned; upgrades go through the team's dependency-update flow (Renovate/Dependabot)
- Adding a third-party dependency requires a documented reason; prefer the JDK/standard libraries when equivalent

## Application Service Conventions

### 【Mandatory】Structure
- Layered structure: controller → service → repository/dao; business logic lives in services, never in controllers
- DTO/VO at the API boundary; entities must not leak into API responses
- All external calls (HTTP/RPC/MQ/DB) must have timeouts; thread pools must be bounded

## Security Conventions

### 【Mandatory】Security
- SQL must be parameterized (PreparedStatement / JPA parameters); string concatenation is forbidden
- No hardcoded keys, tokens, or passwords; read from env vars or secret management
- External input must be validated at the boundary (Bean Validation / manual checks)
- Secrets must never appear in logs, exceptions, or API responses

## Recommended Tools

| Purpose | Tool |
|---------|------|
| Build | Maven / Gradle (with wrapper committed) |
| Format + lint | Spotless (google-java-format) / Checkstyle |
| Static analysis | Error Prone / SpotBugs |
| Testing | JUnit 5 + AssertJ + Mockito |
| Coverage | JaCoCo |
| CI gate | `./mvnw verify` or `./gradlew build` (block on failure) |
