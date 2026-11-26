# scripts/ — Repository Tooling

This directory holds the devsop repository's own tooling and Git Hook entry points.

| Script | Purpose | When it runs | Used by |
|------|------|----------|--------|
| `validate_skills.sh` | Validate the skills library (frontmatter / naming / line count / reference depth / script syntax) | manually or CI (`--json`) | skills library maintainers (**this repo only**, not distributed to target projects) |
| `pre_commit_check.sh` | Check staged whitespace errors and conflict markers (`git diff --cached --check`) | git pre-commit hook | this repo + all projects initialized by devsop-init |
| `commit_msg_check.sh` | Check the `<type>(<module-or-service>): <subject>` title (only `feat` / `fix` / `docs` / `refactor`) | git commit-msg hook | same as above |

> The two hook scripts are symlinks to `skills/devsop-init/scripts/` (single source). Initialization copies only those two scripts into the target project's `scripts/` directory; no pre-push hook is installed, and existing scripts or hooks are never overwritten. `validate_skills.sh` serves this skills library only and is never copied.

## Common commands

```bash
bash scripts/validate_skills.sh

# Per-skill detail / strict mode (warnings also fail) / CI machine-readable
bash scripts/validate_skills.sh -v
bash scripts/validate_skills.sh --strict
bash scripts/validate_skills.sh --json

# Full pre-commit checks for this repo (including hook scripts)
bash scripts/validate_skills.sh --strict
bash scripts/pre_commit_check.sh
bash scripts/commit_msg_check.sh
```
