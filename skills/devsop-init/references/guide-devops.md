# DevOps Documentation Guide

> Use this guide when the project needs environment, deployment, or release documentation. The main agent can follow it directly or delegate the task when supported.
> Adapt any output to the project's existing operations-documentation location and naming convention.

---

## Core Goal

Based on the project's real build / deploy / environment configuration, document actionable operations guidance only when an authoritative source is missing or incomplete.

---

## Steps

### 1. Scan operations facts

Extract from information sources (**forbidden to fabricate from memory**):
- `Makefile` / `package.json scripts` / `Cargo.toml` → build / test / lint commands
- `Dockerfile` / `docker-compose*.yaml` → image build, ports, volumes
- K8s / Helm / deploy directories → deployment topology, environment layering
- `.github/workflows/` / `Jenkinsfile` / `.gitlab-ci.yml` → CI flow
- Config files (env / yaml / toml) → environment variables, config layering
- Project-owned deployment scripts and environment configuration → setup, readiness, deployment, and release procedures

### 2. Generate documentation

- Add only the missing local setup, deployment, runtime, release, or rollback guidance in the established source.
- Document test-environment setup in `devops/env.md` or `devops/deployment.md` when relevant; do not assume a particular CLI, AI Skill, or environment-management service.

### 3. Real-run verification (if feasible)

For the build / test / start commands in the documentation, actually run them locally once to confirm they work; if they cannot be run (no environment / requires permission), mark the document with `<!-- TODO(devsop-init): command pending real-run verification -->`.

---

## Constraints

- Commands must come from the actual Makefile / CI / Dockerfile; fabricating is forbidden.
- Only create or update the selected authoritative operations source when a gap is confirmed; preserve unrelated docs.
