# Service Registry

> Hand-maintained registry of every service and external platform this system touches.
> This table is the ONLY hand-edited input to the derived capability view in
> `service-dependencies.md` — keep it current; that view regenerates from it.
>
> `source` meanings:
> - `dev` — devsop-managed repo: AGENTS.md / architecture.md exist there; capabilities
>   and dependencies are derived automatically from that repo during plan sync.
> - `manual` — external platform / legacy system with no devsop repo: record its
>   metadata (protocol, version, change-notification channel, degradation policy)
>   in the Notes column or link a contract doc under `docs/apis/`.

| Service | Source | Repo | Notes |
|------|------|------|------|
| example-svc | dev | https://github.com/org/example-svc | devsop-managed; capabilities derived from repo |
| platform-payment | manual | — (external) | Integration: REST v2; change notifications: platform release channel; degradation: local queue buffering |

<!-- When a `manual` row has a contract worth documenting, create
     `docs/apis/<contract>.md` from the per-API template (optional-docs catalog)
     and link it here instead of inlining the full contract. -->
