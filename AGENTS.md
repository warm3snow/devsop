# devsop — Team R&D DEVSOP Skills Library

> This file is the **single source of truth** for AI collaboration (AGENTS.md). CODEBUDDY.md / CLAUDE.md are symlinks pointing to this file, so all AI tools read the same content through the symlinks.
> This file is only an index + recovery protocol + project-specific red lines. The DEVSOP conventions themselves are provided by the skills in this repository.

---

## §1 Quick Index

| Topic | Location |
|-------|----------|
| Project background, features, installation | `README.md` |
| AI collaboration entry | `AGENTS.md` (this file; `CODEBUDDY.md` / `CLAUDE.md` are symlinks) |
| DEVSOP scaffolding skill (create `.harness/` skeleton in target projects) | `skills/devsop.init/SKILL.md` |
| DEVSOP maturity audit skill | `skills/devsop.eval/SKILL.md` |
| Go code quality scoring skill | `skills/go-quality-scorer/SKILL.md` |
| Go secret-leak review skill | `skills/go-secret-leak-review/SKILL.md` |
| Requirement clarification skill | `.codebuddy/skills/clarify/SKILL.md` |
| Go official coding standards | `rules/go-style-guide.md` |
| Skill installation script | `install.sh` |

### Common Commands

```bash
# Install skills to ~/.codebuddy/skills/
bash install.sh

# Initialize the DEVSOP structure in a target project
devsop.init
devsop.init --dry-run          # preview the changes
devsop.init --update-only      # only update templates

# Audit a target project's DEVSOP compliance
devsop.eval
devsop.eval --json             # JSON format output
devsop.eval --diff-from HEAD~3 # incremental audit

# Go code quality scoring
python3 skills/go-quality-scorer/scripts/go-quality-scorer-v1.1.py /path/to/go/project

# Git Hooks checks (this repo)
bash scripts/pre_commit_check.sh
bash scripts/commit_msg_check.sh
bash scripts/pre_push_check.sh
```

---

## §2 Dev Guidelines

### Skill Development Conventions

- **`$SKILL_DIR` and `$REPO_ROOT` are strictly separated**: Skills only read the install directory and write only to the target project directory; never write to this repo or `$HOME`.
- **No auto-commit**: `devsop.init` / `devsop.eval` do not run `git add` / `git commit`; changes are left for the user to review.
- **Template changes**: after modifying templates under `devsop.init/assets/`, run `devsop.init --update-only` to verify the generated `AGENTS.md` is ≤300 lines (≤200 is excellent).
- **Go code** (`go-quality-scorer` / `go-secret-leak-review`): follow `rules/go-style-guide.md`.

### Git Hooks (this repo's CI)

```bash
bash scripts/pre_commit_check.sh   # before commit: file headers, trailing whitespace, large files
bash scripts/commit_msg_check.sh   # commit message format check (--story= / --bug= footers)
bash scripts/pre_push_check.sh     # full check before push
```

### Language / Framework Versions

| Component | Version constraint |
|-----------|-------------------|
| Go (go-quality-scorer / go-secret-leak-review) | see the `go.mod` in each skill subdirectory |
| Python (go-quality-scorer scoring script) | Python 3.8+ |
| Markdown (all Skill docs) | CommonMark |

### Security Baseline

Key points: no hardcoded credentials, input validation, parameterized queries, standard-library crypto. Dedicated secret-leak detection for incremental code is provided by the `go-secret-leak-review` skill.

---

## §3 Forbidden Red Lines

| # | Red line | Consequence |
|---|----------|-------------|
| 1 | **Skills must never write to this repo or `$HOME`**: `$SKILL_DIR` and `$REPO_ROOT` are strictly separated; Skills only write to the target project directory. | repo pollution; broken install state |
| 2 | **No auto-commit**: `devsop.init` / `devsop.eval` do not run git operations; changes must be reviewed and committed manually by the user. | accidentally committing unreviewed content |
| 3 | **One MR one commit**: an MR in this repo may only contain one commit; fixes are always accumulated via `git commit --amend`, and pushes must use `--force-with-lease`. | messy commit history; difficult Code Review |
