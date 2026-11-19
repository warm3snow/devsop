#!/usr/bin/env bash
# init_docs.sh — create the DEVSOP project skeleton.
#
# Usage:
#   bash init_docs.sh [repo_root] [--full]
#
# The default creates a compact core. --full also creates optional API, database,
# integration-test, DevOps, relationship, glossary, failure, and logging docs.

set -euo pipefail

# ---------------------------------------------------------------------------
# Validate arguments before writing any files.
# ---------------------------------------------------------------------------
REPO_ROOT=""
PROFILE="core"
for arg in "$@"; do
    case "$arg" in
        --full) PROFILE="full" ;;
        --*)
            echo "[ERROR] Unknown argument: $arg (supported: --full)" >&2
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
SKELETON="$SKILL_DIR/assets/docs-skeleton"
TEMPLATE="$SKILL_DIR/assets/plans-template"
CORE_TEMPLATE="$SKILL_DIR/assets/plans-template-core"

if [[ ! -d "$SKELETON" ]]; then
    echo "[ERROR] Skeleton directory does not exist: $SKELETON" >&2
    exit 1
fi
if [[ ! -d "$CORE_TEMPLATE" ]]; then
    echo "[ERROR] Core task template directory does not exist: $CORE_TEMPLATE" >&2
    exit 1
fi
if [[ "$PROFILE" == "full" && ! -d "$TEMPLATE" ]]; then
    echo "[ERROR] Task template directory does not exist: $TEMPLATE" >&2
    exit 1
fi

SPECS_DIR="$REPO_ROOT/.docs"
PLANS_TEMPLATE_DIR="$SPECS_DIR/plans/_template"

mkdir -p "$SPECS_DIR"
mkdir -p "$SPECS_DIR/plans"

# ---------------------------------------------------------------------------
# Copy the selected documentation profile. Existing files are never overwritten.
# ---------------------------------------------------------------------------
(cd "$SKELETON" && find . -type f -print0) | while IFS= read -r -d '' rel; do
    if [[ "$PROFILE" == "core" ]]; then
        case "$rel" in
            ./review.md|./architecture.md|./coding-style.md|./code-review.md|./unittest/unittest.md) ;;
            *) continue ;;
        esac
    fi
    src="$SKELETON/$rel"
    dst="$SPECS_DIR/$rel"
    mkdir -p "$(dirname "$dst")"
    if [[ ! -e "$dst" ]]; then
        cp "$src" "$dst"
        echo "[ADD] Added skeleton file: .docs/${rel#./}"
    fi
done

# Copy the selected task template. Existing files are never overwritten.
mkdir -p "$PLANS_TEMPLATE_DIR"
if [[ "$PROFILE" == "core" ]]; then
    src="$CORE_TEMPLATE/00-overview.md"
    dst="$PLANS_TEMPLATE_DIR/00-overview.md"
    if [[ ! -e "$dst" ]]; then
        cp "$src" "$dst"
        echo "[ADD] Added core task template: .docs/plans/_template/00-overview.md"
    fi
else
    (cd "$TEMPLATE" && find . -type f -print0) | while IFS= read -r -d '' rel; do
        src="$TEMPLATE/$rel"
        dst="$PLANS_TEMPLATE_DIR/$rel"
        mkdir -p "$(dirname "$dst")"
        if [[ ! -e "$dst" ]]; then
            cp "$src" "$dst"
            echo "[ADD] Added template file: .docs/plans/_template/${rel#./}"
        fi
    done
fi

echo "[OK] .docs initialized at: $SPECS_DIR"
echo "     - profile: $PROFILE"
echo "     - core docs: review.md, architecture.md, coding-style.md, code-review.md, unittest/unittest.md"
[[ "$PROFILE" == "core" ]] && echo "     - plans/: _template/00-overview.md"
[[ "$PROFILE" == "full" ]] && echo "     - plans/: _template/ (detailed task workflow)"
[[ "$PROFILE" == "core" ]] && echo "     - optional docs: run with --full to create the full documentation set"

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
# Repo-root AI entry: generate it only when the project has no AGENTS.md.
# ---------------------------------------------------------------------------
bash "$SKILL_DIR/scripts/generate_agents_md.sh" "$SKILL_DIR/assets/agents.md.tmpl" "$REPO_ROOT"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ DEVSOP initialization complete"
echo ""
echo "  Next steps:"
echo "    1. Fill in .docs/architecture.md and .docs/coding-style.md from project evidence"
echo "    2. Create optional API, database, integration-test, or DevOps docs only when needed"
echo "    3. Add project-specific commands and rules to AGENTS.md"
echo "═══════════════════════════════════════════════════════════════"
