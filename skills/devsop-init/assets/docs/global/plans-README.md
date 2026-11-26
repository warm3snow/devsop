# Global Plans

> Global plan artifacts (user stories, acceptance criteria, test cases, task list)
> live here and are the **single authoritative version**. This repo is an
> orchestration repo: plans here span multiple service repos.

Rules:

1. `devsop-plan` / `devsop-design` write global artifacts to `YYYY-MM-DD-<topic>/`
   inside this directory. Stories are business-level — never split by service.
2. `tasks.md` tasks carry a **Component** that matches a service name from
   `docs/services.md`. The orchestrator dispatches by that field.
3. Each service repo receives a **projection** at `docs/plans/<same-dir-id>/`
   containing only its tasks, the relevant acceptance criteria / test cases, and the
   cross-service interface contract summary. Projections are generated, never
   hand-edited; changes go back to the global plan here.
4. Every projection header must carry a back-link:
   `<!-- Projection of: <this repo path>/docs/plans/<dir-id> @ <commit hash> -->`.
   The dir id + hub commit hash is the consistency key for verifying projections.
5. Integration-level verification (`devsop-test` on the original acceptance criteria)
   and cross-service deployment ordering happen at this repo, not in service repos.
