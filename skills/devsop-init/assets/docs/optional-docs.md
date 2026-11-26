# Optional Documentation Templates

> Copy the section that matches the confirmed gap into the project's established documentation location (or create `docs/<topic>.md` for a new documentation set). Fill every `{{...}}` from repository evidence; never fabricate. Do not create a topic file when an authoritative source already covers it — link it instead.

---

## Unit Testing (create `docs/unittest.md`)

> Three parts: environment setup / generation standards / run & debug. Use the project language's idioms.

- **Tooling**: test runner, assertion library, mock framework, coverage — {{from go.mod / package.json / pyproject.toml / Cargo.toml evidence}}
- **Red lines**: do not modify business code to make tests pass; no real external services in unit tests; tests independent (no shared mutable state, no execution-order dependence); append-only, do not delete existing tests
- **Run commands**: {{exact commands, consistent with CI}}; debugging table: symptom → first check → command
- **CI gate**: coverage threshold {{≥60% unless the project configures otherwise}}; failures block merging

---

## Integration Testing (create `docs/integration-test.md`)

- **Scope**: cross-module/cross-service chains with real test-environment dependencies; separate from unit tests (tags/directory), excluded from the fast CI lane when slow
- **Red lines**: no production/shared online databases; dedicated test accounts; every case has setup/teardown (idempotent); record `trace_id`; cost-incurring cases get a dry-run switch
- **Environment**: entry address, auth method, data isolation, cleanup policy — {{link to the project's environment docs when present}}
- **Run commands**: {{exact commands with the integration tag/selector}}

---

## Database / Persistence (create `docs/database.md`)

- **Storage list**: engine / version / purpose / deployment form
- **Table standards**: naming (snake_case), required fields (created_at/updated_at), type choices; indexes recorded before adding query conditions
- **ORM rules**: no `SELECT *`, no N+1, no UPDATE/DELETE without WHERE, no querying in loops
- **Migrations**: tool, naming `V{{version}}__{{description}}`, reversible (up/down), never delete released migration files
- **Security**: sensitive fields encrypted at rest; test data redacted; production DB accessed only via controlled channels

---

## Logging (create `docs/logging.md`)

- **Library & levels**: {{from dependency + call-site evidence}}; production default level {{INFO}}, dynamically adjustable
- **Must log**: request entry/exit (with {{trace field}}), external calls, errors with context, business state changes, async task start/end
- **Must not log**: passwords/Tokens/keys, full request bodies >1KB, INFO inside loops, ERROR on normal branches
- **Redaction**: {{the project's masking rules, aligned with coding-standards security section}}

---

## DevOps / Environment (create `docs/devops.md`)

- **One-command start**: {{the command a newcomer runs to get the project running locally}}
- **Environments**: matrix of env / domain / data policy / access / approval
- **Release**: pipeline stages, artifact naming (`{{repo}}:{{branch}}-{{sha7}}`), canary thresholds, rollback procedure (rehearsed)
- **Config**: config center / env vars; secrets never committed — injected via env/KMS
- **Health checks**: liveness/readiness endpoints and pass conditions

---

## Glossary (create `docs/glossary.md`)

- **Only project-private terms** that a skilled senior engineer cannot infer from experience; industry/language/general terms are out of scope
- Table: term / full name / definition in this project's context / where first defined

---

## Pitfall Log (create `docs/failures.md`)

- Each entry: date / context / root cause / temporary workaround / permanent fix / reference link
- Sources: issue tracker, incident reviews, `git log --grep` for fix/revert patterns — never fabricated
- Entries incorporated into standards are marked and archived

---

## Upstream/Downstream (create `docs/relationship.md`)

- **Upstream**: who calls this project (repo, purpose, protocol, key entry)
- **Downstream**: what this project calls (dependency, purpose, timeout/retry/degradation from real code)
- **Failure propagation matrix**: downstream failure → affected feature → symptom → fallback plan

---

## API Doc per Interface (create `docs/apis/<Action>.md` per interface)

- Description / request (method, path, parameter table, example) / response (table, example) / error codes / change log
- Written from the caller's perspective; never a copy of source code; keep an `docs/apis/index.md` master table
