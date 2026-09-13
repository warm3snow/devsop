# Local Development Environment Standards

> Status: Draft | Maintainer: {{name}} | Last Updated: {{YYYY-MM-DD}}

## Scope

The minimum requirements for a newcomer to get this service running within 30 minutes. All commands must be verified.

## System Requirements

| Item | Requirement |
|------|------|
| Operating system | {{macOS / Linux / Windows + WSL2}} |
| Memory | ≥{{8GB}} |
| Disk | ≥{{20GB}} free |

## Required Dependencies

```bash
# 1. Language runtime
{{install command, including specific version, e.g. go1.24.12 required}}

# 2. Database / middleware (Docker recommended)
{{docker-compose up -d or brew install ...}}

# 3. Development tools
{{make tools or install commands one by one}}
```

**Version consistency**: this repository pins {{language version}}, other versions are disabled (CI and local must match, otherwise build/test results may not be reproducible).

## Repository Initialization

```bash
git clone {{repo-url}}
cd {{repo-name}}
{{init commands: dependency installation, code generation, database initialization}}
```

## One-Command Run

```bash
{{make dev / make run / equivalent command}}
```

Expected output: {{listening port, key startup log lines}}

## Common make Targets

| Command | Purpose |
|------|------|
| `make build` | Compile artifacts |
| `make lint` | Static checks |
| `make ut` | Unit tests |
| `make integration-test` | Integration tests |
| `make gen` | Generate code from IDL |
| `make mock` | Regenerate mocks |
| `make tools` | Install development tools |
| `make init-db` | Initialize the database |

Full list: `make help` or the `Makefile`.

## Recommended IDE Configuration

- {{IDE name}}
- Plugins: {{Go / ESLint / Prettier etc.}}
- Configuration: {{`.editorconfig` / recommended settings}}

## Parallel Tasks with Git Worktrees (optional)

> The DEVSOP default model is "one branch ↔ one task directory" (see `AGENTS.md` §2). When you need multiple tasks in parallel with separate working trees (e.g. one task is blocked on review while another starts), `git worktree` is the complementary tool — each worktree is a full checkout on its own branch, and each has its own `.docs/plans/<task>/` artifacts. Task isolation still applies: **never read other tasks' md artifacts** even inside the same worktree.

```bash
# Create a worktree for a new task
git worktree add -b feature/<task-b> ../<repo>-<task-b> origin/master
cd ../<repo>-<task-b>

# List worktrees
git worktree list

# Clean up after the task is merged (prune after merge)
git worktree remove ../<repo>-<task-b>
```

Conventions:
- Worktree path lives **outside** the main clone (sibling directory), never inside it.
- One worktree = one branch = one `.docs/plans/<task>/` directory; do not run two tasks in one worktree.
- After the branch is merged, remove the worktree; stale worktrees accumulate disk and confusion.

## Debugging

- Startup: {{IDE Run/Debug configuration or dlv command}}
- Remote debug port: {{2345}}
- Log location: {{logs/ path}}

## FAQ

- **Q: `make build` reports a version error?** A: Check `go version`, must be {{version}}
- **Q: Port already in use?** A: {{solution}}
- **Q: Cannot connect to the database?** A: {{solution}}

More troubleshooting notes see [failures.md](failures.md).

## CI/CD and Delivery

### CI/CD Pipeline

> If the project does not use CI/CD, this section can be deleted.

- Platform: {{Jenkins / GitLab CI / GitHub Actions / other}}
- Pipeline config file: `{{.gitlab-ci.yml / .github/workflows/ci.yaml / Jenkinsfile}}`
- Trigger method: {{push / MR / tag / manual}}

Pipeline flow:

```mermaid
graph LR
    A[{{trigger condition}}] --> B[{{stage 1}}]
    B --> C[{{stage 2}}]
    C --> D[{{stage 3}}]
    D --> E[{{stage N...extend according to the actual pipeline}}]
```

> Modify the diagram above per the actual pipeline, keep the mermaid format for rendering.

### Helm Package

> If the project does not use Helm, this section can be deleted.

| Item | Description |
|------|------|
| Helm Chart repository | `{{repository address}}` |
| Chart path | `{{deploy/helm/chart-name/}}` |

Chart directory structure:

```
{{chart-path}}/
├── Chart.yaml      # Chart metadata (name / version / appVersion)
├── values.yaml     # default values
├── templates/      # K8s resource templates
│   └── ...
└── {{other files per the actual project}}
```

> Supplement the directory structure and key values field descriptions according to the project's actual Chart content.

## References

- Project introduction: [../README.md](../README.md)
- AI collaboration entry: [../AGENTS.md](../AGENTS.md)
