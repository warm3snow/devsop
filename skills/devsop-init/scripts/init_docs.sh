#!/usr/bin/env bash
# init_docs.sh — create the DEVSOP project skeleton.
#
# Usage:
#   bash init_docs.sh [repo_root] [--full] [--docs-dir path] [--include template-path]
#
# The default creates core project context. --full also creates optional API,
# database, integration-test, DevOps, relationship, glossary, failure, and logging docs.

set -euo pipefail

# ---------------------------------------------------------------------------
# Validate arguments before writing any files.
# ---------------------------------------------------------------------------
REPO_ROOT=""
PROFILE="core"
DOCS_DIR_ARG=""
INCLUDES=()
HAS_INCLUDES=false
while [[ $# -gt 0 ]]; do
    arg="$1"
    case "$arg" in
        --full) PROFILE="full" ;;
        --docs-dir)
            if [[ $# -lt 2 || -z "$2" ]]; then
                echo "[ERROR] --docs-dir requires a path" >&2
                exit 2
            fi
            DOCS_DIR_ARG="$2"
            shift
            ;;
        --include)
            if [[ $# -lt 2 || -z "$2" ]]; then
                echo "[ERROR] --include requires a template path" >&2
                exit 2
            fi
            INCLUDES+=("$2")
            HAS_INCLUDES=true
            shift
            ;;
        --*)
            echo "[ERROR] Unknown argument: $arg (supported: --full, --docs-dir, --include)" >&2
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
    shift
done
REPO_ROOT="${REPO_ROOT:-$(pwd)}"
REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CORE_PROFILE="$SKILL_DIR/assets/profiles/core"
FULL_PROFILE="$SKILL_DIR/assets/profiles/full"

if [[ -n "$DOCS_DIR_ARG" ]]; then
    case "$DOCS_DIR_ARG" in
        /*) SPECS_DIR="$DOCS_DIR_ARG" ;;
        *) SPECS_DIR="$REPO_ROOT/$DOCS_DIR_ARG" ;;
    esac
    SPECS_PARENT="$(cd "$(dirname "$SPECS_DIR")" 2>/dev/null && pwd)" || {
        echo "[ERROR] Documentation directory parent does not exist: $DOCS_DIR_ARG" >&2
        exit 2
    }
    SPECS_DIR="$SPECS_PARENT/$(basename "$SPECS_DIR")"
    case "$SPECS_DIR/" in
        "$REPO_ROOT/"*) ;;
        *)
            echo "[ERROR] Documentation directory must be inside the repository: $DOCS_DIR_ARG" >&2
            exit 2
            ;;
    esac
elif [[ -d "$REPO_ROOT/docs" && -d "$REPO_ROOT/.docs" ]]; then
    echo "[ERROR] Both docs/ and .docs/ exist. Review the existing docs and pass --docs-dir explicitly." >&2
    exit 2
elif [[ -d "$REPO_ROOT/docs" ]]; then
    SPECS_DIR="$REPO_ROOT/docs"
elif [[ -d "$REPO_ROOT/.docs" ]]; then
    SPECS_DIR="$REPO_ROOT/.docs"
else
    SPECS_DIR="$REPO_ROOT/docs"
fi

if [[ -e "$SPECS_DIR" || -L "$SPECS_DIR" ]]; then
    SPECS_REAL="$(cd "$SPECS_DIR" 2>/dev/null && pwd -P)" || {
        echo "[ERROR] Cannot resolve documentation directory: $SPECS_DIR" >&2
        exit 2
    }
else
    SPECS_PARENT="$(cd "$(dirname "$SPECS_DIR")" 2>/dev/null && pwd -P)" || {
        echo "[ERROR] Cannot resolve documentation directory parent: $SPECS_DIR" >&2
        exit 2
    }
    SPECS_REAL="$SPECS_PARENT/$(basename "$SPECS_DIR")"
fi
REPO_REAL="$(cd "$REPO_ROOT" && pwd -P)"
case "$SPECS_REAL/" in
    "$REPO_REAL/"*) SPECS_DIR="$SPECS_REAL" ;;
    *)
        echo "[ERROR] Documentation directory resolves outside the repository: $SPECS_DIR" >&2
        exit 2
        ;;
esac

if [[ ! -d "$CORE_PROFILE/docs" ]]; then
    echo "[ERROR] Core profile assets are missing: $CORE_PROFILE" >&2
    exit 1
fi
if [[ "$PROFILE" == "full" && ! -d "$FULL_PROFILE/docs" ]]; then
    echo "[ERROR] Full profile assets are missing: $FULL_PROFILE" >&2
    exit 1
fi

if [[ "$HAS_INCLUDES" == true ]]; then
    for include in "${INCLUDES[@]}"; do
        case "$include" in
            /*|../*|*/../*|*/..|..)
                echo "[ERROR] Template path must be relative and cannot traverse directories: $include" >&2
                exit 2
                ;;
        esac
        found=false
        [[ -f "$CORE_PROFILE/docs/$include" ]] && found=true
        if [[ "$PROFILE" == "full" && -f "$FULL_PROFILE/docs/$include" ]]; then found=true; fi
        if [[ "$found" != true ]]; then
            echo "[ERROR] Template not found in the selected profile: $include" >&2
            exit 2
        fi
    done
fi

copy_profile_tree() {
    local source="$1"
    local destination="$2"
    local label="$3"

    (cd "$source" && find . -type f -print0) | while IFS= read -r -d '' rel; do
        src="$source/$rel"
        dst="$destination/$rel"
        mkdir -p "$(dirname "$dst")"
        if [[ ! -e "$dst" ]]; then
            cp "$src" "$dst"
            echo "[ADD] Added ${label}: ${dst#"$REPO_ROOT"/}"
        fi
    done
}

copy_selected_template() {
    local rel="$1"
    local src=""
    local dst="$SPECS_DIR/$rel"

    if [[ -f "$CORE_PROFILE/docs/$rel" ]]; then
        src="$CORE_PROFILE/docs/$rel"
    elif [[ "$PROFILE" == "full" && -f "$FULL_PROFILE/docs/$rel" ]]; then
        src="$FULL_PROFILE/docs/$rel"
    fi
    mkdir -p "$(dirname "$dst")"
    if [[ ! -e "$dst" ]]; then
        cp "$src" "$dst"
        echo "[ADD] Added selected doc: ${dst#"$REPO_ROOT"/}"
    else
        echo "[SKIP] Keeping existing doc: ${dst#"$REPO_ROOT"/}"
    fi
}

if [[ "$HAS_INCLUDES" == true ]]; then
    for include in "${INCLUDES[@]}"; do
        copy_selected_template "$include"
    done
elif find "$REPO_ROOT" \
    \( -type d \( -name .git -o -name node_modules -o -name vendor -o -name .venv -o -name dist -o -name build \) -prune \) -o \
    \( -type f \( -name '*.md' -o -name '*.mdx' -o -name '*.rst' -o -name '*.adoc' \) -print -quit \) |
    grep -q .; then
    echo "[INFO] Existing project documentation found; not copying templates."
    echo "       Inventory its content first; use --include <template-path> only for confirmed gaps."
else
    mkdir -p "$SPECS_DIR"
    copy_profile_tree "$CORE_PROFILE/docs" "$SPECS_DIR" "core doc"
    if [[ "$PROFILE" == "full" ]]; then
        copy_profile_tree "$FULL_PROFILE/docs" "$SPECS_DIR" "optional doc"
    fi
fi

echo "[OK] Project documentation initialized at: $SPECS_DIR"
echo "     - profile: $PROFILE"
if [[ "$HAS_INCLUDES" == true ]]; then
    echo "     - selected templates: ${INCLUDES[*]}"
else
    echo "     - core docs: review.md, architecture.md, coding-style.md, code-review.md, unittest/unittest.md (new documentation set only)"
fi
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
echo "    1. Inventory existing docs and source evidence; link authoritative docs rather than duplicating them"
echo "    2. Add only confirmed missing guidance, using the project's existing docs layout"
echo "    3. Add key commands and links to AGENTS.md"
echo "═══════════════════════════════════════════════════════════════"
