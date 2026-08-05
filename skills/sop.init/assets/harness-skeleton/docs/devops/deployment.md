# Deployment and Operation Standards

> Status: Draft | Maintainer: {{name}} | Last Updated: {{YYYY-MM-DD}}

## Scope

Covers the release, configuration, and operation standards for the three environments: test, staging (pre-prod), and production.

## 1. Environment Matrix

| Environment | Purpose | Domain | Data | Access Method | Approval |
|------|------|------|------|----------|------|
| dev | Personal development | `localhost` | local/shared | local machine | None |
| test | QA testing | `{{test.xxx}}` | test database (redacted) | internal network | None |
| pre | Staging verification | `{{pre.xxx}}` | production-like (redacted) | controlled | team leader |
| prod | Production | `{{xxx.com}}` | real | strict approval | department + security |

## 2. Artifacts

- Build artifacts: {{Docker image / binary}}
- Artifact registry: `{{Harbor / artifact registry address}}`
- Naming convention: `{{repo}}:{{branch}}-{{git-sha7}}-{{timestamp}}`
- Must inject: `build_time`, `git_commit`, `version` (handled automatically via `make build`)
- Retention policy:
  - Production: ≥**1 year**
  - Staging: ≥**90 days**
  - Test: ≥**30 days**

## 3. Configuration Management

### Config Center
- Tool: {{Apollo / Nacos / etcd / in-house}}
- Config files: `etc/*.yaml`, maintained per environment (`etc-dev.yaml` / `etc-test.yaml` / `etc-prod.yaml`)

### Sensitive Configuration
- **【Forbidden】** Committing real credentials, keys, Tokens to the code repository
- **【Must】** Inject via environment variables or KMS/Vault:
  ```yaml
  jwt_secret: ${JWT_SECRET}
  mysql_dsn: ${MYSQL_DSN}
  ```
- **【Must】** JWT/session key strength: ≥**32 characters**, generated with CSPRNG
- **【Must】** Redis password not written in plaintext in yaml; inject via environment variables
- Config changes must go through the process: review → canary → full rollout → retain change records

### Environment Isolation
- Different environments use **different** keys, Tokens, third-party accounts
- **Forbidden** to connect the test environment to the production DB / real third-party accounts

## 4. Release Process

```
1. Pre-check: CI fully green + Code Review passed + linked ticket number
2. Test environment: automatic deployment (CI triggered)
3. Staging environment: manual approval + smoke test cases
4. Production environment (canary ladder):
   5% → wait {{15 minutes}} → 25% → wait {{30 minutes}} → 50% → wait {{30 minutes}} → 100%
   Monitor core metrics at each step, auto-pause on alert
5. Rollback: trigger condition + command + data compatibility confirmation
```

### Canary Ladder Thresholds
- Error rate > **1%** pause
- P99 latency > {{1s}} pause
- Core business metrics deviating from baseline > **5%** pause

### Rollback
- **Must** retain the previous stable version artifact for at least 30 days
- Rollback commands must be rehearsed (at least quarterly)
- Database migrations **forbidden** to roll back physically (use forward fix)

## 5. Health Checks

| Probe | Endpoint | Pass Condition | Interval |
|------|------|----------|------|
| Liveness | `GET /healthz` | HTTP 200 | 10s |
| Readiness | `GET /ready` | 200 + dependencies (DB/Redis/required downstream) ready | 10s |
| Startup | `GET /startup` | startup completed | 5s during startup |

- Startup time budget: ≤**60s**
- Health checks **forbidden** to call third-party slow endpoints

## 6. Monitoring and Alerting

### Metrics Platform
- Metrics: {{Prometheus + Grafana}}
- Logs: {{ELK / Loki / CLS}}
- Distributed tracing: {{Jaeger / SkyWalking}}
- APM: {{Sentry / Datadog}}

### Required Metrics
- Error rate (HTTP 5xx / business error codes)
- P50 / P95 / P99 interface latency
- QPS / call volume
- Dependency availability (DB, Redis, downstream services)
- Resource usage (CPU, memory, disk, connection count)
- Core business metrics: {{order volume, payment success rate, login success rate...}}

### Alert Thresholds (defaults, adjust per business)

| Metric | Warning | Critical |
|------|------|------|
| Error rate | > 0.5% for 5min | > 1% for 1min |
| P99 latency | > 800ms for 5min | > 1s for 1min |
| CPU usage | > 70% for 10min | > 85% for 5min |
| Memory usage | > 75% for 10min | > 85% for 5min |
| Disk usage | > 80% | > 90% |
| Connection pool saturation | > 70% | > 85% |
| Slow query count | > 10/min | > 50/min |

### Alert Channels
- {{enterprise WeChat group / SMS / phone}}
- Critical alerts must be by phone; 3 unanswered repeats escalate to the leader

## 7. Capacity Planning

- Single-instance capacity baseline: {{QPS upper limit + resource allocation}}
- Scaling policy: {{HPA / manual scaling}}
- Promotions/events: must **load test in advance** (at least N+1x traffic), scale up before going live

## 8. Logging Standards

- Production log level: **info** (debug only temporarily enabled for troubleshooting)
- **【Forbidden】** Log output of: passwords, Tokens, keys, full ID card numbers, bank cards, pointer values
- **【Must】** Key path logs: request entry (including trace_id), external calls (success/failure), error stack traces
- Log format: JSON structured, for easy searching
- Log retention: ≥**30 days** (extend as required for compliance scenarios)
- Log volume: single instance daily average ≤{{10GB}} (consider sampling or offloading beyond that)

## 9. Emergency Plans

| Failure Type | Symptoms | Response Actions |
|----------|------|----------|
| Dependency X unavailable | alert + error rate rising | feature-flag degradation + contact upstream + switch to backup |
| Traffic surge | CPU/QPS spiking | rate limit + scale out + investigate abnormal callers |
| Single-node anomaly | node alert | remove traffic + restart + retrospective |
| DB slow / table lock | slow queries surge | kill slow queries + switch to read-only / primary-standby switch |
| Cache avalanche | DB pressure spikes | rate limit + cache rebuild + review hot keys |

Each plan must be **rehearsed** (quarterly) and recorded in [failures.md](failures.md).

## 10. Simulating Upstream/Downstream Services

> In local development and test environments, upstream/downstream dependency services may be unavailable or unstable. This section defines how to mock (Mock/Stub) these dependencies so the service can start and be debugged independently.

### Dependency Service List

| # | Dependency Service | Protocol | Mock Method | Port | Description |
|---|----------|------|----------|------|------|
| 1 | {{service name}} | {{HTTP / gRPC / TCP}} | {{Docker / Mock Server / embedded}} | {{port}} | {{purpose description}} |

> Fill in according to the actual project dependencies, refer to [relationship.md](../relationship.md).

### Startup Methods

#### Method 1: Bring Up Mock Services (full integration)

- **Unified orchestration**: use `{{docker-compose / Makefile / script}}` to bring up all mock services with one command
- **Start command**: `{{make mock-up / docker compose -f xxx.yaml up -d}}`
- **Stop command**: `{{make mock-down / docker compose -f xxx.yaml down}}`
- **Readiness check**: `{{make check-mocks / port probe script}}`

#### Method 2: No Services Started, Inject Mock Responses (lightweight development)

When there is no need to actually bring up upstream/downstream services, use the following methods to avoid call errors:

| # | Method | Adopted in This Project | Applicable Scenarios |
|---|------|-----------|----------|
| 1 | Environment variable switch (skip/stub logic) | {{yes/no}} | {{description}} |
| 2 | Interface-layer Stub implementation (DI injects empty implementation) | {{yes/no}} | {{description}} |
| 3 | Config degradation (return default value on call failure) | {{yes/no}} | {{description}} |
| 4 | Local request interception (middleware/proxy returns preset responses) | {{yes/no}} | {{description}} |
| 5 | hosts / DNS mapping (point to a shared Mock platform) | {{yes/no}} | {{description}} |
| N | {{custom method}} | {{yes/no}} | {{description}} |

> **Principle**: the service must be able to start normally when upstream/downstream are missing. Core dependencies go through Mock, non-core dependencies go through degradation.

### Mock Data Management

- Directory: `{{mocks/}}`, with subdirectories per service name
- Data format: {{JSON / YAML / Proto}}
- **【Recommended】** Mock data under version control, shared by the team

### Call Conventions

| # | Standard | Description |
|---|------|------|
| 1 | **【Must】** Switch real/mock addresses via configuration | Forbidden to hardcode mock addresses in business code |
| 2 | **【Must】** Mock service addresses use environment variables | e.g. `{{SERVICE_NAME}}_ADDR=localhost:{{port}}` |
| 3 | **【Must】** Mock data covers normal + error scenarios | At least include: success, parameter error, timeout, service unavailable |
| 4 | **【Forbidden】** Exposing Mock services to the public internet | Only for local/internal network use |
| 5 | **【Forbidden】** Production config pointing to Mock services | Add a check in CI to prevent misconfiguration |

### Local Development Startup Flow

```
1. Pull the code and install dependencies
2. Start mock services: {{start command}}
3. Confirm mock services are ready: {{readiness check command}}
4. Start this service (using dev config): {{run command}}
5. Verify calls: confirm the interfaces correctly return Mock data
```

## 11. Prohibited Items

- ❌ Logging into production servers directly to manually modify files / run scripts
- ❌ Releasing directly without going through the approval process
- ❌ Running unrehearsed SQL (DDL / DML) in production
- ❌ Using real production data in the test environment (must be redacted)
- ❌ Turning off production monitoring / alerting (except during maintenance windows)
- ❌ Releasing to production outside the release window (unless emergency hotfix, with the process completed afterward)

## References

- Upstream/downstream dependencies: [dependency-map.md](dependency-map.md)
- Failure cases: [failures.md](failures.md)
- Coding and security: [coding-style.md](coding-style.md)
