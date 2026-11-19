# devsop — Team R&D DEVSOP Skills Library

> This file is the **single source of truth** for AI collaboration (AGENTS.md), the generic entry shared by all AI coding agents.
> This file is only an index + recovery protocol + project-specific red lines. The DEVSOP conventions themselves are provided by the skills in this repository.

---

## §1 Quick Index

| Topic | Location |
|-------|----------|
| Project background, features, installation | `README.md` |
| AI collaboration entry | `AGENTS.md` (this file; the generic entry shared by all AI coding agents) |
| DEVSOP scaffolding skill (create `.docs/` skeleton in target projects) | `skills/devsop-init/SKILL.md` |
| DEVSOP maturity audit skill | `skills/devsop-eval/SKILL.md` |
| Requirement clarification skill | `skills/devsop-init/assets/clarify-skill/SKILL.md.tmpl` |
| Language coding standards | `rules/` — Go / Python / Java / TypeScript / Rust style guides |
| Skill installation script | `install.sh` |

### Common Commands

```bash
# Install skills into ~/.agents/skills/ (the agent-agnostic standard dir)
bash install.sh
bash install.sh --check        # verify existing symlinks

# Initialize the DEVSOP structure in a target project
devsop-init
devsop-init --dry-run          # preview the changes
devsop-init --update-only      # only update templates

# Audit a target project's DEVSOP compliance
devsop-eval
devsop-eval --json             # JSON format output
devsop-eval --diff-from HEAD~3 # incremental audit

# Git Hooks checks (this repo)
bash scripts/pre_commit_check.sh
bash scripts/commit_msg_check.sh
```

---

## §2 Dev Guidelines

### Skill Development Conventions

- **Skills live under `~/.agents/skills/` (user-level) or `<repo>/.agents/skills/` (project-level)** — the agent-agnostic standard locations; never depend on any specific AI coding tool's config dir.
- **`$SKILL_DIR` and `$REPO_ROOT` are strictly separated**: Skills only read the install directory and write only to the target project directory; never write to this repo or `$HOME`.
- **No auto-commit**: `devsop-init` / `devsop-eval` do not run `git add` / `git commit`; changes are left for the user to review.
- **Keep the shipped skill set focused**: maintain `devsop-init` and `devsop-eval` as the two standalone skills; companion templates remain inside the skill that uses them.
- **Template changes**: after modifying templates under `devsop-init/assets/`, run `devsop-init --update-only` to verify the generated `AGENTS.md` is ≤300 lines (≤200 is excellent).
- **Skill scripts**: follow the matching `rules/*-style-guide.md` (Go / Python / Java / TypeScript / Rust). Shell scripts must pass `bash -n`; Python must pass `ast.parse`.

### Git Hooks (this repo's CI)

```bash
bash scripts/pre_commit_check.sh   # check staged whitespace and conflict markers
bash scripts/commit_msg_check.sh   # check Conventional Commit title
```

### Language / Framework Versions

| Component | Version constraint |
|-----------|-------------------|
| Python (skill scripts) | Python 3.8+ |
| Bash (skill scripts) | Bash 3.2+ (macOS default) |
| Markdown (all Skill docs) | CommonMark |

### Security Baseline

Key points: no hardcoded credentials, input validation, parameterized queries, and standard-library crypto.

---

## §3 Three-Tier Boundaries

| Tier | Meaning | This repo's rules |
|------|---------|-------------------|
| ✅ Always do | Non-negotiable defaults | Keep the standalone skill set to `devsop-init` and `devsop-eval`; run `bash scripts/validate_skills.sh --strict` and the Git Hook checks before commit; keep SKILL.md ≤300 lines (≤500 hard limit) |
| ⚠️ Ask first | Higher-risk or preference-dependent | Restructuring `install.sh` targets; adding new tool dependencies to skills |
| 🚫 Never do | Hard prohibitions | Skills writing to this repo or `$HOME`; auto-commit (`git add`/`git commit` inside skills); a second commit in one MR; `git push --force` (use `--force-with-lease`) |

---

## §4 Forbidden Red Lines

| # | Red line | Consequence |
|---|----------|-------------|
| 1 | **Skills must never write to this repo or `$HOME`**: `$SKILL_DIR` and `$REPO_ROOT` are strictly separated; Skills only write to the target project directory. | repo pollution; broken install state |
| 2 | **No auto-commit**: `devsop-init` / `devsop-eval` do not run git operations; changes must be reviewed and committed manually by the user. | accidentally committing unreviewed content |
| 3 | **One MR one commit**: an MR in this repo may only contain one commit; fixes are always accumulated via `git commit --amend`, and pushes must use `--force-with-lease`. | messy commit history; difficult Code Review |
