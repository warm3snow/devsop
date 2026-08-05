# Environment Setup and Startup

> Let a newcomer get things running locally within 30 minutes; artifacts fully consistent with CI / deployment.
> Pairs with `test-env-deploy.md` (test environment deployment) and other ops docs in this directory.

> Source: <information source: Makefile / package.json / pyproject.toml / Dockerfile / CI config>
> Last-verified: <YYYY-MM-DD>

---

## §1 Runtime Environment

| Environment | Interpreter / Runtime | Dependency Directory | Build Tool | Deployment Scenario |
|------|----------------|---------|---------|---------|
|  |  |  |  |  |

> e.g. dev machines use Python 3.x, containers use venv, CI uses Docker images, etc.

---

## §2 Quick Start

### Local Development

```bash
# TODO: actual project startup method
# 1) Install dependencies
# 2) Prepare config / .env
# 3) Start / enter REPL
```

### Local Debugging

```bash
# TODO: debug mode startup command (including console log / step-by-step debugging entry, etc.)
```

---

## §3 Configuration System

### 3.1 Config File Structure

```
etc/
├── common.<ext>              # global common config
├── <region>.<ext>            # multi-region config
└── <runtime>.ini             # runtime parameters
```

### 3.2 Key Config Items

| Config Path | Description |
|---------|------|
|  |  |

---

## §4 Common Problems

| Symptom | Cause | Solution |
|------|------|------|
|  |  |  |
