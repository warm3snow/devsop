# Test Environment Deployment and Code Sync

> This document explains how to call the Skills for test-environment operations.
> All environment operations are handled uniformly through the **team environment management Skill**; no need to run CLI commands manually.
>
> This document is maintained by the `specs-devsop` skill; it is **force-refreshed** when the skill is initialized or upgraded (project-customized areas are preserved; Git-managed, no backup needed).
> Project-specific customizations such as the "component list" and "environment naming" should be filled into the `## Project Customization` section below to avoid being overwritten by the refresh.

---

## Skill Overview

| Skill | Purpose | Trigger Method |
|-------|------|---------|
| `team environment management Skill` | environment create / query, code hot update, remote command execution | say "create environment", "sync code", "view logs" etc. to the AI |
| `team testing tools Skill` | create/query/destroy instances, database queries, API calls | say "create instance", "database query", "run interface test" etc. to the AI |

---

## Environment Operations (team environment management Skill)

> The following operations are all done through the team environment management Skill; the AI will automatically call the corresponding environment management capability.

| Operation | Say to the AI | Description |
|------|---------|------|
| Create test environment | `create environment` / `create environment <env-name>` | triggers the creation pipeline, about 10–20 minutes |
| Query environment status | `query environment <env-name>` | check whether the environment is READY |
| Query pipeline progress | `query pipeline` | view the create/update pipeline status |
| Hot-update code to the environment | `hot-update code to <env-name>` | bypasses the pipeline, takes effect in seconds |
| Update a specific component | `update component <env-name> <comp>` | triggers component-level redeployment |
| Run commands in a remote container | `run <command> on <comp> in <env-name>` | view logs, troubleshoot, etc. |
| **Release the test environment** | `release environment <env-name>` / `<env management CLI> release -e <env-name>` | **mandatory pre-action of the DEVSOP Commit stage**; must be executed at the end of this task, performed by the team environment management Skill (completing both environment pool release marking and platform Session release). See `plans/_template/09-commit.md` section 0 |

**Environment Status Description**

| Status | Meaning |
|------|------|
| `READY` | ready, code can be synced |
| `RUNNING` / `CREATING` | creating/deploying, wait then query again |
| `ERROR` / `FAILED` | failed, check the pipeline logs to troubleshoot |

---

## Integration Test Operations (team testing tools Skill)

> The following operations are done through the team testing tools Skill.

| Operation | Say to the AI | Description |
|------|---------|------|
| Create test instance | `create instance` | creates a test instance for IT |
| Query instance | `query instance <instance-id>` | view instance status |
| Destroy instance | `destroy instance <instance-id>` | clean up the test instance |
| Database query | `database query <env-name> <sql>` | query the test environment database |
| Call business API | `<api-name> <Action>` | directly call the project's business interface |

---

## Tool Readiness Check

Before using the above Skills, first confirm that the environment management CLI is installed (dependency of the team environment management Skill).

### Check Whether the Environment Management CLI Is Ready

```bash
<env management CLI> --version
```

| Output | Status | Handling |
|------|------|----------|
| prints a version number (e.g. `x.y.z`) | ✅ ready | can be used directly |
| `command not found` | ❌ not installed | see the team environment management Skill installation guide |

### Install the Environment Management CLI

> The installation method is provided by the team environment management Skill; follow the Skill's guidance to initialize (e.g. `git clone` the team installation repository, run the install script, and complete `init`).

After installation, run `<env management CLI> --version` again to confirm readiness.

### Tool Checklist

| Tool | Check Command | Handling When Missing |
|------|---------|---------|
| Environment management CLI | `<env management CLI> --version` | see the team environment management Skill installation guide |
| `git` | `git --version` | install via system package manager |

---

## Project Customization

> Content in this section will **not** be overwritten by the skill refresh; fill it in according to the project's actual situation.

### Component List

| Component Name | Repository / Path | Main Branch | Notes |
|--------|------------|--------|------|
|  |  |  |  |

### Common Environments

| Environment Name | Purpose | Owner | Notes |
|--------|------|--------|------|
|  |  |  |  |

### Project-Specific Sync Rules / Pitfalls

<!-- e.g. a component needs to stop serving before syncing, a directory needs chown, a config needs manual reload, etc. -->
