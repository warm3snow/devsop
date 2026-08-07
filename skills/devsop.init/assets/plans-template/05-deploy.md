# 05. Deploy

> **Purpose**: Sync the code changed in this task to the test environment, preparing for integration testing.
> **Input**: code that passed UT
> **Output**: a test environment where the code is live

---

## Development Mode Decision

<!-- Decide the deployment method based on the "Development Mode" field in 00-overview.md -->

- [ ] Independent development mode: use your own test environment
- [ ] Collaborative development mode: use the environment specified by the Meta "Test Environment" field in `00-overview.md`

---

## 1. Deployment Environment

| Item | Value |
|----|----|
| Environment name |  |
| Deployed by |  |
| Deployment time |  |
| Version / commit |  |

## 2. Deployment Scope

| Component | Remarks |
|------|------|
|  |  |

## 3. Environment Readiness Decision → Choose an Action

> **Complete all environment operations through the team environment management Skill; just describe your intent to the AI directly.**

```
Is there a usable test environment (READY status)?
├─ Yes → say to the AI "hot-deploy code to <env-name>"
└─ No → say to the AI "create environment <env-name>", and hot-deploy after it becomes READY
```

**How to confirm**: check the Meta "Test Environment" field in `00-overview.md`, or say to the AI "query environment `<env-name>`".

---

### 3.1 [No environment] Create a test environment

Say to the AI:
```
create environment <environment name>
```

> Creation takes about 10–20 minutes; say to the AI "query the pipeline" to check progress, and continue with 3.2 after `READY`.

---

### 3.2 [Has environment] Hot-deploy code to the environment

Say to the AI:
```
hot-deploy code to <environment name>
```

> For detailed usage (specify components / full deployment / force, etc.), see `.docs/devops/test-env-deploy.md`.

## 4. Deployment Result Checks

- [ ] Code sync command executed successfully
- [ ] Remote service reloaded / key processes restarted
- [ ] No ERROR in key logs (say to the AI "run tail -200 /data/log/app.log on the `<component>` of `<env-name>`" to check)

## 5. Rollback Plan (required)

> Confirm it is executable before deployment; if problems occur, it can be rolled back within 5 minutes.

| Scenario | Rollback Method | Estimated Time |
|------|---------|---------|
| Code problem |  |  |
| Config problem |  |  |

## 6. Effectiveness Verification

> After syncing, do a minimal closed-loop verification to confirm the code is actually live.

| Verification Item | Method | Result |
|-------|------|------|
|  |  |  |

---

## Completion Criteria

- [ ] Code synced successfully
- [ ] All deployment result checks pass
- [ ] Effectiveness verification passes
- [ ] Rollback plan confirmed executable
- [ ] Checked off 05 in `00-overview.md` Progress
- [ ] End confirmation completed with the user
