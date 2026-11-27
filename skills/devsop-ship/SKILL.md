---
name: devsop-ship
description: Deploys the verified work to the development environment with explicit human confirmation before any deploy action. Use after devsop-test reports the plan verified; deploy is always opt-in and confirmed.
---

# devsop-ship

Move verified work to the development environment. This stage is **optional and requires explicit human confirmation** before anything is deployed.

Core discipline: verify first, present the options, execute only the user's choice.

## Preconditions — check all, stop on any miss

1. **Verification evidence exists:** `docs/plans/<plan-dir>/test-report.md` (when written) shows no FAIL, and every scenario outside the report is covered by `devsop-code`'s completion-gate evidence; anything else needs an explicit user waiver (record it). NEEDS-HUMAN scenarios acknowledged by the user count as acknowledged, not passed — list them.
2. **Working tree state known:** run `git status`. Uncommitted changes are reported; deploying with uncommitted work requires the user's explicit say-so. Never commit or push unless asked.
3. **Deploy method known:** the project's documented deploy procedure — from `docs/` (devops docs, Makefile targets, scripts, `docker compose` files, CI pipelines) or the user's instruction. If none is documented, ask; do not discover a deploy path by trial and error against a shared environment.

## Confirmation gate

Present exactly, then wait:

```
Ready to ship to the development environment.

- Plan: <plan dir>
- Test evidence: <N> pass, <M> needs-human (acknowledged: yes/no)
- Changes: <branch / uncommitted summary>
- Deploy method: <command/target from project docs>
- Target: <env name, and any state it will overwrite>

Deploy now? [yes/no]
```

Ship only on an explicit "yes" to this message. Anything else — silence, a topic change, "maybe later" — means do not deploy. Re-confirm again if the plan, target, or method changed since the last "yes".

## Execute

1. Run the documented deploy method, exactly as documented. Capture output.
2. Verify the deployment: run the documented health check, or hit a documented endpoint / run the smoke command and read the result. "Deploy command exited 0" is necessary, not sufficient.
3. Record the outcome in `docs/plans/<plan-dir>/ship.md`: date, target, method, deploy output summary, verification evidence.

## Rollback

Before deploying, note the documented rollback procedure (previous image tag, previous migration, `git revert` point). If verification fails after deploy: report the failure with evidence, ask whether to roll back using the documented method — do not improvise fixes against a shared environment.

## Red flags

| Thought | Reality |
|---|---|
| "Tests mostly passed, ship it" | The gate is evidence, not majority. Waivers come from the user, explicitly. |
| "It's just the dev environment" | It is shared, and the confirmation gate still applies. |
| "The deploy script exited 0, done" | Verify the running thing, not the exit code. |
| "The user said ship earlier, I'll skip the gate" | Earlier approval covered an earlier state. Re-confirm when anything changed. |
