# API Standards

> Status: Draft | Maintainer: {{name}} | Last Updated: {{YYYY-MM-DD}}

## Scope

Applies to all APIs exposed by this project ({{HTTP/REST / gRPC / GraphQL — pick what applies}}).

## 1. Protocol and Paths

- Protocol/style: {{RESTful / RPC-style}}; IDL: {{OpenAPI / .proto / none}}
- URL style: `/api/v{N}/{resource}/{id}`; resource naming {{plural/singular}} consistent project-wide
- HTTP method semantics: GET read / POST create / PUT full update / PATCH partial / DELETE remove
- Version prefix `/v1`; breaking changes bump the version

## 2. Request / Response Conventions

- Field naming: {{camelCase / snake_case}} consistent project-wide
- Time: {{ISO 8601 / Unix timestamp}}; large integers (≥2^53) as strings; money as decimal string with explicit unit
- Pagination: {{cursor / page+size}}, default and upper limit explicit (page_size ≤100)
- Adding fields is backward compatible; removing fields or changing semantics bumps the version
- Every interface has complete request/response examples, including error cases

## 3. Errors

- Unified response format: `{{{"code": 0, "message": "ok", "data": {...}}}}` (code = 0 means success)
- Error codes: {{format}}, categorized + unique + documented in one central place
- Error messages must not leak stack traces, SQL, internal paths, or credentials
- Do not distinguish errors by message string — use the code

## 4. Authentication and Security

- Auth: {{JWT / OAuth2 / internal ticket}}; new interfaces require auth by default
- CORS: explicit origin whitelist; `AllowCredentials` forbids `*`
- Rate limiting on public-facing and critical interfaces (login, payment, password change)
- Response headers: `X-Content-Type-Options: nosniff`, `X-Frame-Options`, HSTS for HTTPS

## 5. Performance

- Default timeout: {{3s}}; batch interfaces: {{10s}} and count-capped (≤100)
- High-traffic interfaces support pagination/cursor; never return ≥1000 rows at once

## References

- Coding standards: {{link when present}}
- Interface docs: {{link to the project's API doc source when present}}
