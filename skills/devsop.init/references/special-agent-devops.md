# DevOps Review Sub-Agent Instructions

> This file serves as the **supplementary instructions** for the `devops` review sub-agent, on top of the common prompt. The main Agent passes it along when dispatching.
> Target: `.docs/devops/` (environment setup + test-environment deployment + release conventions area).

---

## Core Goal

Based on the project's real build / deploy / environment configuration, fill `.docs/devops/` into a set of actionable operations documentation.

---

## Steps

### 1. Scan operations facts

Extract from information sources (**forbidden to fabricate from memory**):
- `Makefile` / `package.json scripts` / `Cargo.toml` → build / test / lint commands
- `Dockerfile` / `docker-compose*.yaml` → image build, ports, volumes
- K8s / Helm / deploy directories → deployment topology, environment layering
- `.github/workflows/` / `Jenkinsfile` / `.gitlab-ci.yml` → CI flow
- Config files (env / yaml / toml) → environment variables, config layering
- Test-environment tools (e.g. team environment management CLI / team environment management Skill) → environment readiness checks + deployment sync flow

### 2. Generate documentation

Fill in per the skeleton sections:
- `devops/env.md` — local development environment setup, dependency installation, one-click run, common issues
- `devops/deployment.md` — deployment and runtime conventions (environment matrix / artifacts / config / release / rollback)
- `devops/development.md` — local development environment conventions (dependencies / one-click run / IDE / FAQ)
- `devops/test-env-deploy.md` — **process it by section**: above `## Project Customization` is the skill-controlled area (environment management CLI tool readiness checks + team environment management Skill / team test tool Skill usage instructions); below it is the project-customization area (component list / common environments / special sync rules) — **preserve user content, do not modify or delete it**.

### 3. Real-run verification (if feasible)

For the build / test / start commands in the documentation, actually run them locally once to confirm they work; if they cannot be run (no environment / requires permission), mark the document with `<!-- TODO(devsop.init): command pending real-run verification -->`.

---

## Constraints

- The project-customization area of `test-env-deploy.md` is user asset; **only refresh the skill-controlled area**; overwriting the whole file is strictly forbidden.
- Commands must come from the actual Makefile / CI / Dockerfile; fabricating is forbidden.
- Only touch files under `devops/`; do not touch other docs.
