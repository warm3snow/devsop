#!/usr/bin/env bash
# init_docs.sh —— DEVSOP initialization / upgrade script (idempotent).
#
# Usage:
#   bash init_docs.sh [repo_root] [--has-api=true|false] [--has-db=true|false]
#
#   --has-api   when false, skips copying the skeleton apis/ (default true, backward compatible)
#   --has-db    when false, skips copying the skeleton sqls/ (default true, backward compatible)
#   The two flags only affect the "gap-filling copy" phase; existing apis//sqls/ files in the target project are always kept, never deleted.
#
# Features (shared by new-project init and old-project upgrade):
#   1. Gap-fill: copy the Skill's `.docs/` skeleton and `plans/_template` into the target repo (existing files are not overwritten)
#   2. Refresh contractual files: 00-overview / 05-deploy / 06-it / test-env-deploy (overwrite directly when different)
#   3. Smart merge of AGENTS.md: refresh §2 (DEVSOP) only, keep §1 / §3 / §4 (project-custom)
#   4. AGENTS.md is the single generic AI entry; no tool-specific entry files are created
#   5. Install the clarify skill into `.agents/skills/clarify/` (the agent-agnostic standard dir; skip if it exists)

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
SKELETON="$SKILL_DIR/assets/docs-skeleton"
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

SPECS_DIR="$REPO_ROOT/.docs"
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
# --has-api=false → skip apis/; --has-db=false → skip sqls/.
# Only affects the gap-filling copy: same-named files already present in the target project are "not overwritten" anyway and never deleted.
# ---------------------------------------------------------------------------
(cd "$SKELETON" && find . -type f -print0) | while IFS= read -r -d '' rel; do
    case "$rel" in
        ./apis/*) [[ "$HAS_API" == "false" ]] && continue ;;
        ./sqls/*) [[ "$HAS_DB" == "false" ]] && continue ;;
    esac
    src="$SKELETON/$rel"
    dst="$SPECS_DIR/$rel"
    mkdir -p "$(dirname "$dst")"
    if [[ ! -e "$dst" ]]; then
        cp "$src" "$dst"
        echo "[ADD] Added skeleton file: .docs/${rel#./}"
    fi
done
[[ "$HAS_API" == "false" ]] && echo "[SKIP] --has-api=false, skipping skeleton apis/"
[[ "$HAS_DB" == "false" ]] && echo "[SKIP] --has-db=false, skipping skeleton sqls/"

# Copy plans/_template (file-level no-overwrite; newly added files reported one by one)
mkdir -p "$PLANS_TEMPLATE_DIR"
(cd "$TEMPLATE" && find . -type f -print0) | while IFS= read -r -d '' rel; do
    src="$TEMPLATE/$rel"
    dst="$PLANS_TEMPLATE_DIR/$rel"
    mkdir -p "$(dirname "$dst")"
    if [[ ! -e "$dst" ]]; then
        cp "$src" "$dst"
        echo "[ADD] Added template file: .docs/plans/_template/${rel#./}"
    fi
done

if [[ $IS_UPGRADE -eq 1 ]]; then
    echo ""
    echo "[Upgrade mode] Existing .docs/ directory detected, running upgrade checks..."
    echo "               - missing skeleton/template files auto-added (see [ADD] above)"
    echo "               - will now check whether contractual files need refreshing..."
else
    echo "[OK] .docs initialized at: $SPECS_DIR"
    echo "     - top level: review.md"
    docs_list="architecture.md, relationship.md"
    [[ "$HAS_API" == "true" ]] && docs_list="$docs_list, apis/"
    [[ "$HAS_DB" == "true" ]] && docs_list="$docs_list, sqls/"
    docs_list="$docs_list, unittest/, integration_test/, devops/"
    echo "     - docs: $docs_list"
    echo "     - plans/: _template/ (10-file task template)"
fi

# ---------------------------------------------------------------------------
# Force-refresh all template files under plans/_template/
#
# All files under plans/_template/ are DEVSOP contractual templates. When the skill
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
# Force-refresh devops/test-env-deploy.md (chapter-divided)
#
# This file contains the env-management CLI tool readiness checks + install guidance,
# plus the team env-management Skill / team test-tool Skill usage instructions; it is part of the toolchain conventions.
#
# Update strategy (consistent with the AGENTS.md chapter-divided merge):
#   - use "## Project Customization" as the divider:
#     skill-controlled area (start ~ before "## Project Customization") → force-refresh to the latest
#     project-custom area ("## Project Customization" and after ~ end of file) → keep as-is, no change/no delete
#   - only update when the skill-controlled area differs
# ---------------------------------------------------------------------------
TEST_ENV_DEPLOY_SRC="$SKELETON/devops/test-env-deploy.md"
TEST_ENV_DEPLOY_DST="$SPECS_DIR/devops/test-env-deploy.md"
if [[ -f "$TEST_ENV_DEPLOY_SRC" ]]; then
    if [[ ! -f "$TEST_ENV_DEPLOY_DST" ]]; then
        # file does not exist → full write
        mkdir -p "$(dirname "$TEST_ENV_DEPLOY_DST")"
        cp "$TEST_ENV_DEPLOY_SRC" "$TEST_ENV_DEPLOY_DST"
        echo "[OK] Wrote devops/test-env-deploy.md"
    else
        # file exists → chapter-divided refresh
        # extract the skill-controlled area of the source file (start ~ before "## Project Customization")
        SRC_SKILL_PART="$(mktemp)"
        awk '/^## Project Customization/{exit} {print}' "$TEST_ENV_DEPLOY_SRC" > "$SRC_SKILL_PART"

        # extract the skill-controlled area of the existing file (for comparison)
        DST_SKILL_PART="$(mktemp)"
        awk '/^## Project Customization/{exit} {print}' "$TEST_ENV_DEPLOY_DST" > "$DST_SKILL_PART"

        if cmp -s "$SRC_SKILL_PART" "$DST_SKILL_PART"; then
            echo "[SKIP] devops/test-env-deploy.md skill-controlled area is already up to date, no update needed"
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
            echo "[REFRESH] Refreshed devops/test-env-deploy.md (skill-controlled area updated; project-custom area kept unchanged)"

            rm -f "$DST_CUSTOM_PART"
        fi

        rm -f "$SRC_SKILL_PART" "$DST_SKILL_PART"
    fi
fi

# ---------------------------------------------------------------------------
# Install the clarify skill (see install_clarify.sh for details)
# ---------------------------------------------------------------------------
bash "$SKILL_DIR/scripts/install_clarify.sh" "$CLARIFY_SKILL_SRC" "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Git Hooks installation (idempotent)
#
# Installs lightweight pre-commit / commit-msg hooks via setup_hooks.sh.
# Non-git repos skip silently; existing hooks and scripts are not overwritten.
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
            echo "[LINT] Copied .golangci.yml (from the DEVSOP template)"
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
# Repo-root AI entry: AGENTS.md (see generate_agents_md.sh for the
# chapter-divided fresh-generation / smart-merge strategy)
# ---------------------------------------------------------------------------
bash "$SKILL_DIR/scripts/generate_agents_md.sh" "$SKILL_DIR/assets/agents.md.tmpl" "$REPO_ROOT"

echo ""
echo "═══════════════════════════════════════════════════════════════"
if [[ $IS_UPGRADE -eq 1 ]]; then
    echo "  ✅ DEVSOP upgrade complete"
    echo ""
    echo "  This upgrade automatically handled the following:"
    echo "    • Missing skeleton/template files → auto-added (see [ADD] above)"
    echo "    • Contractual templates (00-overview / 05-deploy / 06-it) → overwritten directly when different"
    echo "    • test-env-deploy.md → chapter-divided: skill-controlled area refreshed, \"## Project Customization\" kept"
    echo "    • AGENTS.md → only chapter 2 (DEVSOP) refreshed; chapters 1/3/4 kept (see [REFRESH] or [SKIP] above)"
    echo "    • AGENTS.md → single generic AI entry ensured (no tool-specific entry files)"
    echo "    • clarify skill → installed into .agents/skills/ if missing"
else
    echo "  ✅ DEVSOP initialization complete"
    echo ""
    echo "  Next steps:"
    echo "    1. Fill in .docs/architecture.md and .docs/relationship.md"
    echo "    2. Create interface docs under .docs/apis/<module>/ as needed; sync apis/index.md"
    echo "    3. Add DB schema / migration docs under .docs/sqls/ as needed"
    echo "    4. [required] Fill in .docs/unittest/unittest.md (three sections: environment / generation / run & debug)"
    echo "    5. [required] Fill in .docs/integration_test/integration_test.md (three sections)"
    echo "    6. Fill in .docs/devops/env.md + test-env-deploy.md"
    echo "    7. Edit AGENTS.md: \"§3 Development Guidelines\" + \"§4 Forbidden Red Lines\""
fi
echo "═══════════════════════════════════════════════════════════════"
