---
# Do not modify the header of this file; the AI coding agent relies on it to apply this style guide as an always-on rule
type: always
---
You are a professional TypeScript/JavaScript development assistant. All code must strictly follow the coding conventions below.

**Note: unless explicitly stated otherwise, follow the Google TypeScript Style Guide (gts).**

## Conventions Overview

The requirement level of each convention is defined as:
- **Mandatory**: code must follow this; violating it is considered an error
- **Preferable**: code should follow this, but exceptions are allowed in special cases and are not considered errors
- **Optional**: can be referenced; decide whether to adopt it based on the specific situation

## Code Style Conventions

### 【Mandatory】Formatting
- Formatting is enforced by Prettier (2-space indent, single quotes, semicolons, trailing commas) — never by hand
- A single line should not exceed 100 columns (Prettier printWidth)
- ESLint (recommended + type-aware rules for TS) must pass before commit

### 【Mandatory】Imports
- Use ES module syntax (`import`/`export`); CommonJS (`require`) is forbidden in new code
- Import order (enforced by ESLint import plugin): built-ins → external packages → internal aliases → relative
- No default exports — use named exports (enables refactoring and tree-shaking)
- No `import * as` unless the module is a namespace-like utility

### 【Mandatory】Naming conventions
- Files/dirs: kebab-case; components: `PascalCase.tsx`; types: `PascalCase`; variables/functions: `camelCase`
- Constants: `UPPER_SNAKE_CASE` (only for true module-level constants)
- Booleans read as a question (`isReady`, `hasToken`); event handlers start with `handle`/`on` (`onClick`, `handleSubmit`)
- Avoid single-letter names except loop indices; no Hungarian notation

### 【Preferable】Code line count limits
- A file must not exceed 600 lines; a function must not exceed 60 lines; a component must not exceed 300 lines
- Nesting depth must not exceed 4; extract functions/components instead of nesting further

## TypeScript Type Conventions

### 【Mandatory】Type safety
- `strict: true` in tsconfig (noImplicitAny / strictNullChecks are non-negotiable)
- `any` is forbidden in committed code — use `unknown` + narrowing, generics, or `never` for unreachable branches
- Prefer type inference; annotate only public API boundaries and function signatures
- Use discriminated unions and `satisfies` over type casts; `as` is a last resort (document why)
- Prefer `interface` for object shapes; `type` for unions/intersections/mapped types

### 【Mandatory】Null handling
- Optional chaining (`a?.b`) and nullish coalescing (`??`) for null/undefined access
- Never use `!` non-null assertion in production logic paths; narrow instead

## Error Handling Conventions

### 【Mandatory】Errors
- Promises: `async/await` over raw `.then()` chains; unhandled promise rejections are forbidden
- Always rethrow or handle with context: `throw new ServiceError("...", { cause: err })`
- Never swallow errors (`catch {}`); log with context at the boundary
- Use custom error classes for business errors; never throw string literals

### 【Mandatory】Logging
- Never log secrets/tokens/PII — mask before logging
- No `console.log` in committed production code (use a logger or remove); lint rule enforced

## Comment Conventions

### 【Mandatory】Comments
- JSDoc for public APIs and complex type utilities; comments explain *why*, not *what*
- No commented-out code in committed files — use git history instead
- TODO comments must carry an owner/ticket reference: `// TODO(team#123): ...`

## React / Frontend Conventions (when applicable)

### 【Preferable】Components
- Function components + hooks only; no class components in new code
- One component per file; props typed with `interface`; no `React.FC` type wrapper
- Side effects in `useEffect` must declare dependencies correctly; mutations use immutable updates

## Unit Test Conventions

### 【Mandatory】Testing
- Vitest or Jest; test files colocated (`*.test.ts`) or under `__tests__/`
- One behavior theme per test; AAA structure (Arrange/Act/Assert)
- Mock at module boundaries only; never mock the unit under test
- Coverage target: ≥60% for the project, ≥80% for core modules (per CI threshold)

## Dependency Management Conventions

### 【Mandatory】Dependencies
- Package manager per project convention (pnpm/npm), lockfile committed; no shrinkwrap mixing
- Adding a third-party dependency requires a documented reason; prefer platform/built-ins when equivalent
- Dependency versions are pinned; upgrades go through the team's dependency-update flow (Renovate/Dependabot)

## Security Conventions

### 【Mandatory】Security
- SQL must be parameterized (ORM/prepared statements); string concatenation is forbidden
- No hardcoded keys, tokens, or passwords; read from env vars or secret management
- External input must be validated at the boundary (zod / yup / manual checks)
- XSS: never use `dangerouslySetInnerHTML` with unsanitized data; escape user content before rendering

## Recommended Tools

| Purpose | Tool |
|---------|------|
| Lint | ESLint (typescript-eslint) |
| Format | Prettier |
| Type check | `tsc --noEmit` |
| Testing | Vitest / Jest |
| CI gate | `eslint` + `prettier --check` + `tsc --noEmit` + `test` (block on failure) |
