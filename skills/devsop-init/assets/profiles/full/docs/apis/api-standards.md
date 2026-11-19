# API Design Standards

> Status: Draft | Maintainer: {{name}} | Last Updated: {{YYYY-MM-DD}}

## Scope

Applies to all APIs exposed by this service (HTTP/REST, gRPC, internal RPC). When adding/modifying an interface, you must first update the standards, then generate the code.

## 1. Protocol and Style

- Protocol: {{HTTP/JSON | gRPC | GraphQL}}
- Style: {{RESTful / RPC-style}}
- IDL tool: {{.api / .proto / OpenAPI}}, stored in `{{template/ or idl/}}`
- Code generation: `{{make gen or equivalent command}}`
- HTTP method semantics: GET (read, idempotent), POST (create/action), PUT (full update, idempotent), PATCH (incremental update), DELETE (delete, idempotent)

## 2. Path and Naming

- URL style: `/api/v{N}/{resource}/{id}/{sub-action}`
- Resource name: {{choose plural / singular, consistent across the project}}
- Action naming: `kebab-case` (URL) / `camelCase` (parameters)
- Version prefix: `/v1`, `/v2`; deprecation process see §7
- Routes grouped by business module (avoid a single route file exceeding 200 lines)

## 3. IDL / Type Definitions

### Required Field Tags
- Request/Response fields must include complete tags: `json` / `form` / `path` / `validate`
- Required fields must have constraints such as `validate:"required"`
- Field naming: use `camelCase` or `snake_case` in JSON, consistent across the project

### Field Conventions
- **Time**: unified format ({{ISO 8601 string / Unix millisecond timestamp}}, choose one, consistent across the project)
- **Large integers** (snowflake IDs, order numbers ≥2^53): serialize as **strings** to avoid JS precision loss
- **Money**: `DECIMAL` string, unit explicit (e.g. "12.3400" means yuan)
- **Enums**: defined in IDL, use strings rather than bare numbers
- **Pagination**: {{cursor / page+size, choose one}}, default value and upper limit explicit (page_size ≤100)
- **Boolean**: use `true/false`, not 0/1

### Compatibility
- Adding fields: backward compatible, clients must tolerate unknown fields
- Removing fields / semantic changes: must **bump version** + canary release
- Fields marked `deprecated` must be kept for at least 2 versions before being removed

## 4. Unified Response Format

```json
{
  "code": 0,
  "message": "ok",
  "data": { /* business data */ },
  "trace_id": "{{request id}}"
}
```

- `code = 0` means business success; non-zero see the error code definitions
- HTTP status codes: 4xx client errors, 5xx server errors, business errors uniformly use 200 + code
- `message` is for developers to debug, **forbidden** to display directly to end users (frontend maps localized text by code)
- `trace_id` must be propagated, to facilitate cross-service troubleshooting

## 5. Error Codes

- Error code format: {{unified length, e.g. 6-digit integer / string}}
- Error codes must be **categorized + unique + documented**, centrally defined in `{{internal/errorcode/}}`
- **Forbidden** to distinguish errors by message string (use code)
- Error messages **must not** leak: stack traces, SQL, internal paths, third-party tokens

## 6. Authentication and Security (Interface Layer)

> Language-level security (input validation, encryption, key management) see [coding-style.md](coding-style.md) §Security Coding.

### Authentication
- Authentication method: {{JWT / OAuth2 / internal ticket}}
- Header conventions: `Authorization: Bearer <token>` / `X-Trace-Id` / `X-Request-Id`
- **【Must】** Authentication by default, public resources via whitelist; new interfaces require authentication by default
- **【Must】** Authentication → operation permission → data permission → account consistency, validated in four layers in order
- **【Must】** Regenerate session/token after successful login; clean up session on logout
- Cookie: must set `HttpOnly` + `Secure` + `SameSite`, and configure expiration time

### CORS
- **【Must】** `AllowedOrigins` lists concrete domains; **forbidden** to use `*`
- **【Must】** When `AllowCredentials` is enabled, `AllowedOrigins` cannot be `*`, only whitelisted domains
- **Must** restrict `AllowedMethods` and `AllowedHeaders`

### SSRF Protection
- **【Must】** Server-side outbound requests: only HTTP/HTTPS protocols allowed
- **【Must】** Resolve the target HOST to get IPs, **forbidden** to access internal networks (10/8, 172.16/12, 192.168/16, 127.0.0.1, 169.254/16)
- **【Must】** Forbidden to follow redirects to internal networks; re-validate after following
- **【Must】** Set a timeout (typically 3 seconds)

### XXE / Deserialization
- **【Must】** XML parsing disables DTD and external entities
- **【Forbidden】** Deserializing untrusted data as arbitrary types (Java: disable ObjectInputStream / Python: disable pickle)

### Rate Limiting
- **【Must】** Public-facing entry interfaces set rate limits: granularity (IP/User/Token) + threshold
- **【Must】** Critical operations (login, registration, password change, payment) have independent rate-limiting policies

### Response Headers
- **【Must】** Set:
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY` or `SAMEORIGIN`
  - `Strict-Transport-Security` (HTTPS sites)
  - `Content-Security-Policy` (HTML sites)

## 7. Versioning and Deprecation

- Version number: URL prefix (`/v1`) or Header (`Accept: application/vnd.xxx.v1+json`), choose one, consistent across the project
- Deprecation process: mark `Deprecated` → broadcast via docs → monitor call volume → remove after N versions
- Announcement of old version removal at least {{30 days}} in advance

## 8. Documentation and Contract Testing

- Interface documentation: {{Swagger / Apifox / auto-generated website}}, published in sync with code
- Contract testing: {{solution, e.g. Pact / record and replay}}, to ensure client/server protocol consistency
- Examples: every interface must have complete request/response examples (including error cases)

## 9. Performance and Timeout

- Default interface timeout: {{3 seconds}}; batch interfaces {{10 seconds}}
- Batch interfaces must have a count upper limit (default ≤100)
- P99 latency target: {{< 500ms}}
- High-traffic interfaces must support pagination/cursor, **forbidden** to return ≥1000 rows at once

## 10. {{Framework-specific}} (e.g. go-zero)

> Delete this section if not applicable.

- API files (`.api`): clear route grouping, correct HTTP methods, standardized path parameters
- JWT config (`Auth` field) takes effect for interfaces requiring authentication
- Logic obtains dependencies via `svcCtx` (dependency injection), **forbidden** to directly instantiate dependencies
- Logic must accept and propagate `context.Context` to all external calls
- Errors uniformly handled with `errorx` (or the project's corresponding error code package)

## References

- IDL workflow: [development.md](development.md)
- Error code definitions: `{{internal/errorcode/}}`
- Coding and security: [coding-style.md](../coding-style.md)
- Testing standards: [unittest/unittest.md](../unittest/unittest.md)
