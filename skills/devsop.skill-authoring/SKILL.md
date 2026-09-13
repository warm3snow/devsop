---
name: devsop.skill-authoring
description: Writing, reviewing, and publishing new DEVSOP skills. Use when creating a new skill, modifying an existing skill's structure, or reviewing skill quality before release.
---

# devsop.skill-authoring

**Purpose**: The self-bootstrapping skill of the DEVSOP skills library. It encodes how to write a high-quality SKILL.md, how to verify it, and how to publish it — so every skill in the library follows the same anatomy and quality bar.

---

## When to Use

| Trigger | Action |
|---------|--------|
| Creating a new skill for the library | Follow the full anatomy below |
| Modifying an existing SKILL.md | Check the anatomy + verification sections |
| Reviewing a skill before merge | Use the review checklist as the gate |

---

## SKILL.md Anatomy (required sections)

Every SKILL.md must contain, in order:

1. **Frontmatter**: `name` (lowercase-hyphen, unique) + `description` (what it does + when to use; this is what agents read for trigger decisions — make it specific).
2. **Purpose**: one paragraph, what the skill accomplishes and why it exists.
3. **When to Use**: a table of triggers → actions, or explicit triggering conditions.
4. **Process**: step-by-step workflow with checkpoints and exit criteria. Steps must be actionable (commands, file paths, decision rules), not prose.
5. **Rationalizations** (anti-rationalization table): a table of common excuses an agent might use to skip steps, each with a rebuttal. At least 4 rows.
6. **Red Flags / Red Lines**: signs something is wrong + absolute prohibitions.
7. **Verification**: evidence requirements — what must be true for the task to be "done" (output files, command results, counts). "Seems right" is never sufficient.

Optional but recommended:
- **Progressive disclosure**: heavy details sink into `references/` files, loaded on demand; SKILL.md stays lean (≤300 lines).
- **Scripts**: deterministic work goes into `scripts/` (bash/python), invoked with `$SKILL_DIR`-relative paths.

## Path Conventions (agent-agnostic, mandatory)

| Concept | Location |
|---------|----------|
| User-level skills | `~/.agents/skills/<skill-name>/` |
| Repo-level skills | `<repo>/.agents/skills/<skill-name>/` |
| Project rules | `rules/` (repo root) |
| Project memory | `.agents/memory/` |
| Skill data (references/scripts) | read via `$SKILL_DIR`, never hardcoded absolute paths |

**Forbidden**:
- Hardcoding any specific AI coding tool's config dir (e.g. tool-vendor-specific dot-directories) in skill logic or docs; only the `~/.agents/` standard locations are allowed.
- `$SKILL_DIR` / `$REPO_ROOT` conflation: skills read `$SKILL_DIR`, write only to the target project (`$REPO_ROOT`), never to `$HOME` or the library repo.

---

## Process

### Step 1: Draft the SKILL.md

1. Write the frontmatter + the 7 anatomy sections above.
2. Keep the main file lean; move heavy reference material into `references/`.
3. Every workflow step must have an exit criterion (what output proves the step is done).

### Step 2: Self-check with the rationalization test

Run through this table and make sure the skill would rebut each excuse:

| Excuse an agent might use | Required rebuttal in the skill |
|---------------------------|--------------------------------|
| "This is a simple case, I'll skip the formal flow" | A trigger rule that forces the flow regardless of apparent simplicity |
| "I already know this skill, no need to re-read" | A "read the current version every time" rule |
| "I'll verify later" | Verification is the last mandatory step; no completion message before evidence |
| "The user didn't ask for X explicitly" | User instructions say WHAT, not HOW; conventions still apply |
| "This skill doesn't fit my situation exactly" | An adaptation rule: rigid parts (never skip) vs flexible parts (adapt to context) |

### Step 3: Validate

```bash
# syntax check any scripts shipped with the skill
bash -n scripts/*.sh 2>/dev/null || true
python3 -m py_compile scripts/*.py 2>/dev/null || true
# skill install check
bash install.sh --check
```

### Step 4: Publish

1. Add a Quick Index row in this repo's `AGENTS.md` (install.sh auto-discovers `skills/*/SKILL.md`, no manual list update needed).
2. Verify with the repo's own validation:
   ```bash
   bash scripts/validate_skills.sh --strict   # warnings also fail; -v for details, --json for CI
   bash install.sh --check
   ```
3. Run the repo's git hooks checks before commit:
   ```bash
   bash scripts/pre_commit_check.sh
   bash scripts/commit_msg_check.sh
   ```
4. One MR one commit (repo red line): accumulate fixes with `git commit --amend`, push with `--force-with-lease`.

---

## Review Checklist (gate for accepting a skill)

- [ ] Frontmatter `name` unique and lowercase-hyphen; `description` mentions triggering conditions
- [ ] All 7 anatomy sections present, with at least 4 rationalization rows
- [ ] Steps are actionable (commands / paths / decision rules), not vague advice
- [ ] Verification section lists concrete evidence requirements
- [ ] No hardcoded tool-specific paths; `$SKILL_DIR` used for all skill-internal reads
- [ ] Skills write only to `$REPO_ROOT` of the target project; no writes to `$HOME` / library repo
- [ ] No auto-commit in skill instructions; changes left for user review
- [ ] Listed in the repo `AGENTS.md` Quick Index (install.sh auto-discovers skills)
- [ ] Shell/Python scripts pass syntax checks

---

## Red Lines

1. **Never write to the library repo or `$HOME` from a skill**: `$SKILL_DIR` (read) and target `$REPO_ROOT` (write) are strictly separated.
2. **No auto-commit**: skills never run `git add` / `git commit`; the user reviews and commits.
3. **No tool lock-in**: skills must work with any AI coding agent that can read SKILL.md files; no agent-specific config dirs or dispatch parameters.
4. **One MR one commit** in the library repo: amend + `--force-with-lease`, never a second commit.

---

## Verification

A skill-writing task is complete only when:
- The SKILL.md passes the review checklist above (all boxes checked).
- Scripts shipped with the skill pass `bash -n` / `py_compile`.
- `bash install.sh --check` reports the skill as linked correctly.
- The generated/updated docs follow the ≤300-line convention where applicable (run `devsop.init --update-only` if templates changed).
