# Logging Standards

> Status: Draft | Maintainer: {{name}} | Last Updated: {{YYYY-MM-DD}}

## Scope

Applies to the runtime log output of all services in this project, including application logs, access logs, and audit logs.

## Log Level Definitions

| Level | Semantics | Usage Scenarios | Enabled by Default in Production |
|------|------|----------|----------------------|
| `FATAL` | unrecoverable error, process about to exit | startup failure, critical dependencies unreachable | ✅ |
| `ERROR` | business error, requires human attention | database write failure, external interface anomalies | ✅ |
| `WARN` | potential issue, does not yet affect the main flow | retry succeeded, degradation triggered, missing config using default value | ✅ |
| `INFO` | key business nodes, used for production troubleshooting | request entry/exit, status changes, scheduled task execution | ✅ |
| `DEBUG` | development debugging details | intermediate variables, branch paths, SQL parameters | ❌ (dynamically enabled on demand) |
| `TRACE` | extremely fine-grained tracing | each iteration inside loops, byte-level data | ❌ (local development only) |

> **Principle**: the default log level in production is `INFO`, with support for dynamic adjustment to `DEBUG` via config/API without restart.

## Scenarios That Must Print Logs

The following scenarios **must** have log output, otherwise production issues cannot be troubleshooted:

| # | Scenario | Minimum Level | Required Information |
|---|------|----------|--------------|
| 1 | Request entry (API/RPC/message consumption) | `INFO` | traceId, method name, key input parameter summary |
| 2 | Request exit (response/ACK) | `INFO` | traceId, latency, response status code |
| 3 | External call initiation and return (HTTP/RPC/DB/cache) | `INFO` / `WARN` | target address, latency, status code/error |
| 4 | Error and exception capture | `ERROR` | error message, stack trace (first occurrence), context parameters |
| 5 | Business status changes | `INFO` | entity ID, status before and after the change |
| 6 | Scheduled/async task start and end | `INFO` | task name, processed count, latency, success/failure counts |
| 7 | Service startup and shutdown | `INFO` | version number, config summary, listening address |
| 8 | Rate limit / circuit breaker / degradation triggered | `WARN` | trigger rule name, current metric value |
| 9 | Authentication failure / permission denied | `WARN` | user identifier, target resource, denial reason |
| 10 | Retry operations | `WARN` | retry count, interval, original error |

## Forbidden / Reduced Logging Scenarios

| # | Forbidden/Restricted | Reason | Alternative |
|---|-----------|------|----------|
| 1 | **Forbidden** to print `INFO` level logs inside loops | log volume explodes under high concurrency | use `DEBUG` / `TRACE`; or print a summary only after the loop ends |
| 2 | **Forbidden** to print the full request/response body (over 1KB) | high storage cost, may leak sensitive data | print a summary (first 200 characters) or only at `DEBUG` level |
| 3 | **Forbidden** to print sensitive fields such as passwords, Tokens, keys | security compliance | output redacted (e.g. `***`) or do not print |
| 4 | **Restricted** health check / heartbeat logs | high-frequency worthless logs | disable or lower to `TRACE` |
| 5 | **Restricted** information already covered by existing monitoring metrics | duplicate information wastes resources | rely on metrics; logs keep only error branches |
| 6 | **Forbidden** to print `ERROR` on normal branches | misleads alerting, lowers signal-to-noise ratio | use `INFO`/`DEBUG` for normal; only real errors use `ERROR` |
| 7 | **Restricted** repeatedly printing the same error | log storm during failures | sampling/rate limiting (e.g. at most N identical logs per minute) |

## 4. Code Review Checklist

When reviewing logging-related code, confirm:

- [ ] Whether key business paths (scenarios listed in §2) have sufficient `INFO` logs
- [ ] Whether error branches have `ERROR` logs containing context information (error cause, key parameters)
- [ ] Whether log levels are accurate (normal flows should not be `ERROR`)
- [ ] Whether there is abuse of `INFO` / `WARN` inside loops
- [ ] Whether sensitive information (passwords, Tokens, keys) is redacted or not printed
- [ ] Whether large data volumes (request/response body >1KB) avoid full output at `INFO` level
- [ ] Whether identical errors have rate limiting/sampling, avoiding log storms during failures

## References

- Coding standards: [coding-style.md](coding-style.md)
- API standards: [api-standards.md](api-standards.md)
- Deployment standards: [deployment.md](deployment.md)
- Failure retrospectives: [failures.md](failures.md)
