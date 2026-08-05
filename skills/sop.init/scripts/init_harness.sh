#!/usr/bin/env bash
# init_harness.sh —— SOP initialization / upgrade script (idempotent).
#
# Usage:
#   bash init_harness.sh [repo_root] [--has-api=true|false] [--has-db=true|false]
#
#   --has-api   when false, skips copying the skeleton docs/apis/ (default true, backward compatible)
#   --has-db    when false, skips copying the skeleton docs/sqls/ (default true, backward compatible)
#   The two flags only affect the "gap-filling copy" phase; existing apis//sqls/ files in the target project are always kept, never deleted.
#
# Features (shared by new-project init and old-project upgrade):
#   1. Gap-fill: copy the Skill's `.harness/` skeleton and `plans/_template` into the target repo (existing files are not overwritten)
#   2. Refresh contractual files: 00-overview / 05-deploy / 06-it / test-env-deploy (overwrite directly when different)
#   3. Smart merge of CODEBUDDY.md: refresh chapters 1-2 (skill-controlled), keep chapters 3-4 (project-custom)
#   4. Ensure CODEBUDDY.md / CLAUDE.md symlinks → AGENTS.md (dual agent entry: CodeBuddy + Claude Code)
#   5. Install the clarify skill to .codebuddy/skills/clarify/ (skip if it exists)

set -euo pipefail

# ---------------------------------------------------------------------------
# Argument parsing: first positional arg = repo_root; --has-api/--has-db are optional flags (default true).
# Validation completes before any write operation; invalid input exits 2 without writing any file.
# ---------------------------------------------------------------------------
REPO_ROOT=""
HAS_API=true
HAS_DB=true
for arg in "$@"; do
    case "$arg" in
        --has-api=*) HAS_API="${arg#--has-api=}" ;;
        --has-db=*)  HAS_DB="${arg#--has-db=}" ;;
        --*)
            echo "[ERROR] Unknown argument: $arg (only --has-api= / --has-db= are supported)" >&2
            exit 2
            ;;
        *)
            if [[ -z "$REPO_ROOT" ]]; then
                REPO_ROOT="$arg"
            else
                echo "[ERROR] Extra positional argument: $arg" >&2
                exit 2
            fi
            ;;
    esac
done
REPO_ROOT="${REPO_ROOT:-$(pwd)}"

for pair in "has-api=$HAS_API" "has-db=$HAS_DB"; do
    name="${pair%%=*}"
    val="${pair#*=}"
    if [[ "$val" != "true" && "$val" != "false" ]]; then
        echo "[ERROR] --$name accepts only true/false, got: $val" >&2
        exit 2
    fi
done
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
SKELETON="$SKILL_DIR/assets/harness-skeleton"
TEMPLATE="$SKILL_DIR/assets/plans-template"
CLARIFY_SKILL_SRC="$SKILL_DIR/assets/clarify-skill"

if [[ ! -d "$SKELETON" ]]; then
    echo "[ERROR] Skeleton directory does not exist: $SKELETON" >&2
    exit 1
fi
if [[ ! -d "$TEMPLATE" ]]; then
    echo "[ERROR] Task template directory does not exist: $TEMPLATE" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Legacy harness/ migration (old sop.init → new sop.init)
#
# The old sop.init produced `harness/` (non-hidden),
# the new one uses `.harness/` (hidden directory); the paths are incompatible.
# When a legacy harness/ is detected:
#   1. move doc-type files/dirs from the old harness/ top level into .harness/docs/
#   2. keep top-level files like plans/, review.md under .harness/
#   3. the subsequent upgrade flow gap-fills on the new skeleton, never deleting old files
# ---------------------------------------------------------------------------
if [[ -d "$REPO_ROOT/harness" ]]; then
    echo "[MIGRATE] Legacy harness/ directory detected, preparing migration to .harness/"

    # create .harness/ and the docs/ subdirectory
    mkdir -p "$REPO_ROOT/.harness/docs"

    # move doc-type files/dirs from the legacy harness/ top level into .harness/docs/
    # doc types: *.md (except top-level kept files like review.md / plan.md), apis/, sqls/,
    #            unittest/, integration_test/, devops/
    # top-level kept: non-doc-type dirs such as review.md, plans/
    for item in "$REPO_ROOT/harness"/*; do
        if [[ ! -e "$item" ]]; then
            continue
        fi
        item_name="$(basename "$item")"
        case "$item_name" in
            review.md|plans)
                # top-level kept file/dir → move to .harness/ top level
                mv "$item" "$REPO_ROOT/.harness/"
                echo "[MIGRATE] Kept at top level: $item_name → .harness/$item_name"
                ;;
            plan.md|README.md)
                # legacy deprecated files (no home in the new skeleton, no sub-agent consumes them) → delete directly
                rm -f "$item"
                echo "[MIGRATE] Deleted legacy deprecated file: $item_name"
                ;;
            development.md|env.md|deployment.md|test-env-deploy.md)
                # devops-type docs → move into .harness/docs/devops/
                mkdir -p "$REPO_ROOT/.harness/docs/devops"
                mv "$item" "$REPO_ROOT/.harness/docs/devops/"
                echo "[MIGRATE] devops doc migrated: $item_name → .harness/docs/devops/$item_name"
                ;;
            api-standards.md)
                # API standards → move into .harness/docs/apis/
                mkdir -p "$REPO_ROOT/.harness/docs/apis"
                mv "$item" "$REPO_ROOT/.harness/docs/apis/"
                echo "[MIGRATE] apis doc migrated: $item_name → .harness/docs/apis/$item_name"
                ;;
            database.md)
                # data/Schema standards → move into .harness/docs/sqls/
                mkdir -p "$REPO_ROOT/.harness/docs/sqls"
                mv "$item" "$REPO_ROOT/.harness/docs/sqls/"
                echo "[MIGRATE] sqls doc migrated: $item_name → .harness/docs/sqls/$item_name"
                ;;
            *)
                # doc type → move into .harness/docs/
                mv "$item" "$REPO_ROOT/.harness/docs/"
                echo "[MIGRATE] Doc migrated: $item_name → .harness/docs/$item_name"
                ;;
        esac
    done

    # delete the now-empty legacy harness/ directory
    rmdir "$REPO_ROOT/harness" 2>/dev/null || true
    echo "[MIGRATE] harness/ → .harness/ migration complete"
    echo "         legacy docs moved into .harness/docs/, top-level kept files moved to the .harness/ top level"
else
    echo "[MIGRATE] No legacy harness/, skipping migration"
fi

# ---------------------------------------------------------------------------
# Root-level legacy ARCHITECTURE.md migration
#
# The old sop.init generated ARCHITECTURE.md at the repo root; the new one requires it under .harness/docs/.
# When a root ARCHITECTURE.md is detected, move it to .harness/docs/architecture.md.
# ---------------------------------------------------------------------------
mkdir -p "$REPO_ROOT/.harness/docs"
if [[ -f "$REPO_ROOT/ARCHITECTURE.md" ]]; then
    if [[ ! -e "$REPO_ROOT/.harness/docs/architecture.md" ]]; then
        mv "$REPO_ROOT/ARCHITECTURE.md" "$REPO_ROOT/.harness/docs/architecture.md"
        echo "[MIGRATE] Root ARCHITECTURE.md → .harness/docs/architecture.md"
    else
        # .harness/docs/architecture.md already exists: keep the existing version, delete the legacy root file
        rm -f "$REPO_ROOT/ARCHITECTURE.md"
        echo "[MIGRATE] .harness/docs/architecture.md already has a new version, deleting the legacy root file"
    fi
else
    echo "[MIGRATE] No root ARCHITECTURE.md, skipping migration"
fi

SPECS_DIR="$REPO_ROOT/.harness"
PLANS_TEMPLATE_DIR="$SPECS_DIR/plans/_template"

# determine whether this is a fresh init or an upgrade of an existing project
IS_UPGRADE=0
if [[ -d "$SPECS_DIR" ]]; then
    IS_UPGRADE=1
fi

mkdir -p "$SPECS_DIR"
mkdir -p "$SPECS_DIR/plans"

# ---------------------------------------------------------------------------
# Copy the skeleton (existing files are not overwritten; newly added files are reported one by one)
#
# --has-api=false → skip docs/apis/; --has-db=false → skip docs/sqls/.
# Only affects the gap-filling copy: same-named files already present in the target project are "not overwritten" anyway and never deleted.
# ---------------------------------------------------------------------------
(cd "$SKELETON" && find . -type f -print0) | while IFS= read -r -d '' rel; do
    case "$rel" in
        ./docs/apis/*) [[ "$HAS_API" == "false" ]] && continue ;;
        ./docs/sqls/*) [[ "$HAS_DB" == "false" ]] && continue ;;
    esac
    src="$SKELETON/$rel"
    dst="$SPECS_DIR/$rel"
    mkdir -p "$(dirname "$dst")"
    if [[ ! -e "$dst" ]]; then
        cp "$src" "$dst"
        echo "[ADD] Added skeleton file: .harness/${rel#./}"
    fi
done
[[ "$HAS_API" == "false" ]] && echo "[SKIP] --has-api=false, skipping skeleton docs/apis/"
[[ "$HAS_DB" == "false" ]] && echo "[SKIP] --has-db=false, skipping skeleton docs/sqls/"

# Copy plans/_template (file-level no-overwrite; newly added files reported one by one)
mkdir -p "$PLANS_TEMPLATE_DIR"
(cd "$TEMPLATE" && find . -type f -print0) | while IFS= read -r -d '' rel; do
    src="$TEMPLATE/$rel"
    dst="$PLANS_TEMPLATE_DIR/$rel"
    mkdir -p "$(dirname "$dst")"
    if [[ ! -e "$dst" ]]; then
        cp "$src" "$dst"
        echo "[ADD] Added template file: .harness/plans/_template/${rel#./}"
    fi
done

if [[ $IS_UPGRADE -eq 1 ]]; then
    echo ""
    echo "[Upgrade mode] Existing .harness/ directory detected, running upgrade checks..."
    echo "               - missing skeleton/template files auto-added (see [ADD] above)"
    echo "               - will now check whether contractual files need refreshing..."
else
    echo "[OK] .harness initialized at: $SPECS_DIR"
    echo "     - top level: review.md"
    docs_list="architecture.md, relationship.md"
    [[ "$HAS_API" == "true" ]] && docs_list="$docs_list, apis/"
    [[ "$HAS_DB" == "true" ]] && docs_list="$docs_list, sqls/"
    docs_list="$docs_list, unittest/, integration_test/, devops/"
    echo "     - docs/: $docs_list"
    echo "     - plans/: _template/ (10-file task template)"
fi

# ---------------------------------------------------------------------------
# Force-refresh all template files under plans/_template/
#
# All files under plans/_template/ are SOP contractual templates. When the skill
# upgrades, the latest structure must be synced to old projects, otherwise tasks
# created by old projects keep using the old templates.
#
# Strategy: for each file under _template/, overwrite directly when different.
#
# Note: only the `_template/` directory itself is refreshed here; user-created task
# directories (plans/<task>/) are never touched, protecting in-progress tasks.
# ---------------------------------------------------------------------------
(cd "$TEMPLATE" && find . -type f -print0) | while IFS= read -r -d '' rel; do
    SRC="$TEMPLATE/$rel"
    DST="$PLANS_TEMPLATE_DIR/$rel"
    if [[ ! -f "$SRC" ]]; then
        continue
    fi
    if [[ -f "$DST" ]]; then
        if ! cmp -s "$SRC" "$DST"; then
            cp "$SRC" "$DST"
            echo "[REFRESH] Refreshed plans/_template/${rel#./}"
        fi
    fi
done

# ---------------------------------------------------------------------------
# Force-refresh docs/devops/test-env-deploy.md (chapter-divided)
#
# This file contains the env-management CLI tool readiness checks + install guidance,
# plus the team env-management Skill / team test-tool Skill usage instructions; it is part of the toolchain conventions.
#
# Update strategy (consistent with CODEBUDDY.md):
#   - use "## Project Customization" as the divider:
#     skill-controlled area (start ~ before "## Project Customization") → force-refresh to the latest
#     project-custom area ("## Project Customization" and after ~ end of file) → keep as-is, no change/no delete
#   - only update when the skill-controlled area differs
# ---------------------------------------------------------------------------
TEST_ENV_DEPLOY_SRC="$SKELETON/docs/devops/test-env-deploy.md"
TEST_ENV_DEPLOY_DST="$SPECS_DIR/docs/devops/test-env-deploy.md"
if [[ -f "$TEST_ENV_DEPLOY_SRC" ]]; then
    if [[ ! -f "$TEST_ENV_DEPLOY_DST" ]]; then
        # file does not exist → full write
        mkdir -p "$(dirname "$TEST_ENV_DEPLOY_DST")"
        cp "$TEST_ENV_DEPLOY_SRC" "$TEST_ENV_DEPLOY_DST"
        echo "[OK] Wrote docs/devops/test-env-deploy.md"
    else
        # file exists → chapter-divided refresh
        # extract the skill-controlled area of the source file (start ~ before "## Project Customization")
        SRC_SKILL_PART="$(mktemp)"
        awk '/^## Project Customization/{exit} {print}' "$TEST_ENV_DEPLOY_SRC" > "$SRC_SKILL_PART"

        # extract the skill-controlled area of the existing file (for comparison)
        DST_SKILL_PART="$(mktemp)"
        awk '/^## Project Customization/{exit} {print}' "$TEST_ENV_DEPLOY_DST" > "$DST_SKILL_PART"

        if cmp -s "$SRC_SKILL_PART" "$DST_SKILL_PART"; then
            echo "[SKIP] docs/devops/test-env-deploy.md skill-controlled area is already up to date, no update needed"
        else
            # extract the project-custom area of the existing file
            DST_CUSTOM_PART="$(mktemp)"
            if grep -q '^## Project Customization' "$TEST_ENV_DEPLOY_DST"; then
                awk '/^## Project Customization/{p=1} p{print}' "$TEST_ENV_DEPLOY_DST" > "$DST_CUSTOM_PART"
            else
                # no project-custom area → fill the default from the source file
                awk '/^## Project Customization/{p=1} p{print}' "$TEST_ENV_DEPLOY_SRC" > "$DST_CUSTOM_PART"
                echo "[INFO] test-env-deploy.md has no \"## Project Customization\" section; default filled from the template"
            fi

            # concat: latest skill-controlled area + existing project-custom area
            cat "$SRC_SKILL_PART" "$DST_CUSTOM_PART" > "$TEST_ENV_DEPLOY_DST"
            echo "[REFRESH] Refreshed docs/devops/test-env-deploy.md (skill-controlled area updated; project-custom area kept unchanged)"

            rm -f "$DST_CUSTOM_PART"
        fi

        rm -f "$SRC_SKILL_PART" "$DST_SKILL_PART"
    fi
fi

# ---------------------------------------------------------------------------
# Install the clarify skill into the target repo's .codebuddy/skills/clarify/
#
# clarify is a strongly recommended dialogue-protocol skill for Stage 01. Install it into the target repo
# so the target repo's AI can directly use_skill clarify during SOP execution, without depending on an external skill.
#
# Note: source files end with .tmpl (e.g. SKILL.md.tmpl) to avoid conflicting with this repo root's
# .codebuddy/skills/clarify/SKILL.md and being double-recognized by the skill system.
# On install, iterate source files; for files with the .tmpl suffix, strip the .tmpl and write to the target; other files are copied with their original names.
# Existing files are always skipped, protecting user changes.
# ---------------------------------------------------------------------------
CLARIFY_DST="$REPO_ROOT/.codebuddy/skills/clarify"
if [[ -d "$CLARIFY_SKILL_SRC" ]]; then
    if [[ -e "$CLARIFY_DST/SKILL.md" ]]; then
        echo "[SKIP] $CLARIFY_DST/SKILL.md already exists, keeping as-is"
    else
        mkdir -p "$CLARIFY_DST"
        installed_any=0
        (cd "$CLARIFY_SKILL_SRC" && find . -type f -print0) | while IFS= read -r -d '' rel; do
            src="$CLARIFY_SKILL_SRC/$rel"
            # strip the .tmpl suffix (only a trailing .tmpl is treated as a template marker; preserve the path structure)
            dst_rel="${rel%.tmpl}"
            dst="$CLARIFY_DST/$dst_rel"
            mkdir -p "$(dirname "$dst")"
            if [[ ! -e "$dst" ]]; then
                cp "$src" "$dst"
            fi
        done
        echo "[OK] Installed the clarify skill to: $CLARIFY_DST"
    fi
else
    echo "[WARN] clarify skill template does not exist: $CLARIFY_SKILL_SRC, skipping install" >&2
fi

# ---------------------------------------------------------------------------
# Git Hooks installation (idempotent)
#
# Installs pre-commit / pre-push / commit-msg hook symlinks into .git/hooks/ via setup_hooks.sh;
# the script is copied to the scripts/ directory.
# Non-git repos skip silently; existing hooks are not overwritten; missing ones are created.
# ---------------------------------------------------------------------------
HOOKS_SETUP="$SKILL_DIR/scripts/setup_hooks.sh"
if [[ -f "$HOOKS_SETUP" ]]; then
    # setup_hooks.sh internally re-confirms the project root with git rev-parse --show-toplevel
    bash "$HOOKS_SETUP" "$REPO_ROOT"
    echo "[HOOKS] Git Hooks installed"
else
    echo "[WARN] setup_hooks.sh does not exist: $HOOKS_SETUP, skipping hooks install" >&2
fi

# ---------------------------------------------------------------------------
# Go project lint config injection
#
# Only when the project is Go (go.mod exists) and .golangci.yml does not exist,
# copy one from the Skill template.
# ---------------------------------------------------------------------------
if [[ -f "$REPO_ROOT/go.mod" ]]; then
    GOLANGCI_SRC="$SKILL_DIR/assets/.golangci.yml"
    GOLANGCI_DST="$REPO_ROOT/.golangci.yml"
    if [[ -f "$GOLANGCI_SRC" ]]; then
        if [[ ! -f "$GOLANGCI_DST" ]]; then
            cp "$GOLANGCI_SRC" "$GOLANGCI_DST"
            echo "[LINT] Copied .golangci.yml (from the SOP template)"
        else
            echo "[LINT] .golangci.yml already exists, skipping"
        fi
    else
        echo "[WARN] .golangci.yml template does not exist: $GOLANGCI_SRC" >&2
    fi
else
    echo "[LINT] Not a Go project, skipping .golangci.yml"
fi

# ---------------------------------------------------------------------------
# Repo-root AI entry docs: AGENTS.md (single source of truth) + CODEBUDDY.md / CLAUDE.md dual symlinks
#
# Goal: give CodeBuddy / Claude Code / Codex CLI / Cursor and other agents a unified entry.
# Generated from the template $SKILL_DIR/assets/agents.md.tmpl, replacing only {{PROJECT_NAME}}.
# AGENTS.md is the single source of truth; CODEBUDDY.md / CLAUDE.md are both symlinks to AGENTS.md.
#
# Update strategy (chapter-divided):
#   - AGENTS.md does not exist  → generate fully from the template
#   - AGENTS.md exists  → split into three segments by "## §2 SOP" and "## §3 Development Guidelines":
#       segment A (header + §1 quick index)   → keep existing (the project may have appended custom index lines)
#       segment B (§2 SOP)                    → force-refresh to the latest template version (core SOP contract)
#       segment C (§3 dev guidelines + §4 forbidden red lines) → keep existing (project-custom; no change/no delete)
#     update only when segment B differs.
#   - CODEBUDDY.md / CLAUDE.md if symlinks    → delete and rebuild directly
#   - CODEBUDDY.md / CLAUDE.md if real files  → delete then rebuild as symlinks
# ---------------------------------------------------------------------------
AGENTS_TMPL="$SKILL_DIR/assets/agents.md.tmpl"
AGENTS_MD="$REPO_ROOT/AGENTS.md"
if [[ ! -f "$AGENTS_TMPL" ]]; then
    echo "[WARN] Template does not exist: $AGENTS_TMPL, skipping AGENTS.md generation" >&2
else
    PROJECT_NAME="$(basename "$REPO_ROOT")"

    if [[ ! -e "$AGENTS_MD" && ! -L "$AGENTS_MD" ]]; then
        # ---- fresh generation ----
        awk -v name="$PROJECT_NAME" '{ gsub(/\{\{PROJECT_NAME\}\}/, name); print }' \
            "$AGENTS_TMPL" > "$AGENTS_MD"
        echo "[OK] Generated $AGENTS_MD from the template"
    else
        # ---- smart merge: only refresh chapter 2 (SOP), keep the rest ----
        #
        # split the file into three segments at the two dividers:
        #   segment A = file start ~ before "## §2 SOP" (header + §1 quick index)
        #   segment B = "## §2 SOP" (inclusive) ~ before "## §3 Development Guidelines" (§2 SOP)
        #   segment C = "## §3 Development Guidelines" (inclusive) ~ end of file (§3 dev guidelines + §4 forbidden red lines)
        #
        # update rule: segment A keep existing | segment B refresh from template | segment C keep existing

        # 1) generate the full version from the template to a temp file
        TMPL_FULL="$(mktemp)"
        awk -v name="$PROJECT_NAME" '{ gsub(/\{\{PROJECT_NAME\}\}/, name); print }' \
            "$AGENTS_TMPL" > "$TMPL_FULL"

        # 2) extract segment B of the template (§2 SOP chapter)
        TMPL_SOP="$(mktemp)"
        awk '/^## §2 SOP/{p=1} p && /^## §3 Development Guidelines/{exit} p{print}' "$TMPL_FULL" > "$TMPL_SOP"

        # 3) extract segment B of the existing file (for comparison)
        EXISTING_SOP="$(mktemp)"
        awk '/^## §2 SOP/{p=1} p && /^## §3 Development Guidelines/{exit} p{print}' "$AGENTS_MD" > "$EXISTING_SOP"

        # 4) compare whether segment B differs
        if cmp -s "$TMPL_SOP" "$EXISTING_SOP"; then
            echo "[SKIP] AGENTS.md chapter 2 (SOP) is already up to date, no update needed"
        else
            # 5) extract segment A of the existing file (header + §1 quick index)
            EXISTING_HEAD="$(mktemp)"
            awk '/^## §2 SOP/{exit} {print}' "$AGENTS_MD" > "$EXISTING_HEAD"

            # 6) extract segment C of the existing file (§3 dev guidelines + §4 forbidden red lines)
            EXISTING_TAIL="$(mktemp)"
            if grep -q '^## §3 Development Guidelines' "$AGENTS_MD"; then
                awk '/^## §3 Development Guidelines/{p=1} p{print}' "$AGENTS_MD" > "$EXISTING_TAIL"
            else
                # no chapters 3-4 → fill the defaults from the template
                awk '/^## §3 Development Guidelines/{p=1} p{print}' "$TMPL_FULL" > "$EXISTING_TAIL"
                echo "[INFO] Chapters 3-4 not detected, default chapters filled from the template"
            fi

            # 7) concat: existing segment A + template segment B + existing segment C
            cat "$EXISTING_HEAD" "$TMPL_SOP" "$EXISTING_TAIL" > "$AGENTS_MD"
            echo "[REFRESH] Updated AGENTS.md (chapter 2 SOP refreshed to the latest; chapters 1/3/4 kept unchanged)"

            rm -f "$EXISTING_HEAD" "$EXISTING_TAIL"
        fi

        rm -f "$TMPL_FULL" "$TMPL_SOP" "$EXISTING_SOP"
    fi
fi

# CODEBUDDY.md / CLAUDE.md: always rebuild as symlinks to AGENTS.md, ensuring consistent multi-agent entries.
#   - CODEBUDDY.md → recognized by CodeBuddy
#   - CLAUDE.md    → recognized by Claude Code
ensure_ai_agent_symlink() {
    local link_name="$1"   # symlink name (e.g. CODEBUDDY.md / CLAUDE.md)
    local link_path="$REPO_ROOT/$link_name"
    if [[ -L "$link_path" ]]; then
        # already a symlink: delete directly (skill-owned resource, no backup needed)
        rm -f "$link_path"
    elif [[ -e "$link_path" ]]; then
        # a real file: delete directly (recoverable via git, no backup needed)
        rm -f "$link_path"
        echo "[OK] Removed original real file $link_name (rebuilt as a symlink)"
    fi
    # use a relative symlink to keep the repo portable.
    ln -s AGENTS.md "$link_path"
    echo "[OK] $link_name → AGENTS.md symlink ready"
}

for AGENT_LINK in CODEBUDDY.md CLAUDE.md; do
    ensure_ai_agent_symlink "$AGENT_LINK"
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
if [[ $IS_UPGRADE -eq 1 ]]; then
    echo "  ✅ SOP upgrade complete"
    echo ""
    echo "  This upgrade automatically handled the following:"
    echo "    • Missing skeleton/template files → auto-added (see [ADD] above)"
    echo "    • Contractual templates (00-overview / 05-deploy / 06-it) → overwritten directly when different"
    echo "    • test-env-deploy.md → chapter-divided: skill-controlled area refreshed, \"## Project Customization\" kept"
    echo "    • AGENTS.md → only chapter 2 (SOP) refreshed; chapters 1/3/4 kept (see [REFRESH] or [SKIP] above)"
    echo "    • CODEBUDDY.md / CLAUDE.md → symlinks to AGENTS.md ensured (dual agent entry)"
    echo "    • clarify skill → installed if missing"
else
    echo "  ✅ SOP initialization complete"
    echo ""
    echo "  Next steps:"
    echo "    1. Fill in .harness/docs/architecture.md and .harness/docs/relationship.md"
    echo "    2. Create interface docs under .harness/docs/apis/<module>/ as needed; sync apis/index.md"
    echo "    3. Add DB schema / migration docs under .harness/docs/sqls/ as needed"
    echo "    4. [required] Fill in .harness/docs/unittest/unittest.md (three sections: environment / generation / run & debug)"
    echo "    5. [required] Fill in .harness/docs/integration_test/integration_test.md (three sections)"
    echo "    6. Fill in .harness/docs/devops/env.md + test-env-deploy.md"
    echo "    7. Edit AGENTS.md: \"§3 Development Guidelines\" + \"§4 Forbidden Red Lines\""
fi
echo "═══════════════════════════════════════════════════════════════"
