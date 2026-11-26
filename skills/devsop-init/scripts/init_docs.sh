#!/usr/bin/env bash
# init_docs.sh — create the DEVSOP project skeleton.
#
# Usage:
#   bash init_docs.sh [repo_root] [--profile core|global] [--full] [--docs-dir path] [--include template-path]
#
# The default (core) creates core project context: AGENTS.md plus architecture.md,
# api-standards.md, coding-style.md, code-review.md. --full also creates the
# optional-docs.md catalog (unit/integration testing, database, logging,
# devops, glossary, pitfalls, relationships, per-API docs) — from which
# specific docs are created only for confirmed gaps.
# --profile global creates the orchestration-repo set: AGENTS.md with an
# orchestration section, architecture.md in system view, services.md registry,
# service-dependencies.md derived view, and docs/plans/README.md projection rules.
# It skips code-oriented docs, Git hooks, and lint config.

set -euo pipefail

# ---------------------------------------------------------------------------
# Validate arguments before writing any files.
# ---------------------------------------------------------------------------
REPO_ROOT=""
PROFILE="core"
EXPLICIT_PROFILE=false
DOCS_DIR_ARG=""
INCLUDES=()
HAS_INCLUDES=false
while [[ $# -gt 0 ]]; do
    arg="$1"
    case "$arg" in
        --full) PROFILE="full"; EXPLICIT_PROFILE=true ;;
        --profile)
            if [[ $# -lt 2 || -z "$2" ]]; then
                echo "[ERROR] --profile requires a value (core | global)" >&2
                exit 2
            fi
            case "$2" in
                core|global) PROFILE="$2"; EXPLICIT_PROFILE=true ;;
                *)
                    echo "[ERROR] Unknown profile: $2 (supported: core, global)" >&2
                    exit 2
                    ;;
            esac
            shift
            ;;
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
CORE_PROFILE="$SKILL_DIR/assets/docs"
OPTIONAL_DOC="optional-docs.md"
GLOBAL_PROFILE="$SKILL_DIR/assets/docs/global"

if [[ "$PROFILE" == "global" && -n "${INCLUDES[*]:-}" ]]; then
    echo "[ERROR] --include is not supported with --profile global yet; the global profile has a fixed doc set" >&2
    exit 2
fi

if [[ "$PROFILE" == "global" ]]; then
    if [[ ! -f "$GLOBAL_PROFILE/architecture.md" || ! -f "$SKILL_DIR/assets/global-orchestration.tmpl" ]]; then
        echo "[ERROR] Global profile assets are missing: $GLOBAL_PROFILE" >&2
        exit 1
    fi
fi

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

if [[ ! -f "$CORE_PROFILE/architecture.md" ]]; then
    echo "[ERROR] Core doc assets are missing: $CORE_PROFILE" >&2
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
        [[ -f "$CORE_PROFILE/$include" ]] && found=true
        if [[ "$found" != true ]]; then
            echo "[ERROR] Template not found: $include" >&2
            exit 2
        fi
    done
fi

copy_selected_template() {
    local rel="$1"
    local src=""
    local dst="$SPECS_DIR/$rel"

    if [[ -f "$CORE_PROFILE/$rel" ]]; then
        src="$CORE_PROFILE/$rel"
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
    if [[ "$PROFILE" == "global" ]]; then
        mkdir -p "$SPECS_DIR/plans"
        for doc in architecture.md services.md service-dependencies.md; do
            dst="$SPECS_DIR/$doc"
            if [[ ! -e "$dst" ]]; then
                cp "$GLOBAL_PROFILE/$doc" "$dst"
                echo "[ADD] Added global doc: ${dst#"$REPO_ROOT"/}"
            else
                echo "[SKIP] Keeping existing doc: ${dst#"$REPO_ROOT"/}"
            fi
        done
        dst="$SPECS_DIR/plans/README.md"
        if [[ ! -e "$dst" ]]; then
            cp "$GLOBAL_PROFILE/plans-README.md" "$dst"
            echo "[ADD] Added global plan projection rules: ${dst#"$REPO_ROOT"/}"
        else
            echo "[SKIP] Keeping existing doc: ${dst#"$REPO_ROOT"/}"
        fi
    else
        mkdir -p "$SPECS_DIR"
        for doc in architecture.md api-standards.md coding-style.md code-review.md; do
            dst="$SPECS_DIR/$doc"
            if [[ ! -e "$dst" ]]; then
                cp "$CORE_PROFILE/$doc" "$dst"
                echo "[ADD] Added core doc: ${dst#"$REPO_ROOT"/}"
            else
                echo "[SKIP] Keeping existing doc: ${dst#"$REPO_ROOT"/}"
            fi
        done
        if [[ "$PROFILE" == "full" ]]; then
            dst="$SPECS_DIR/$OPTIONAL_DOC"
            if [[ ! -e "$dst" ]]; then
                cp "$CORE_PROFILE/$OPTIONAL_DOC" "$dst"
                echo "[ADD] Added optional-docs catalog: ${dst#"$REPO_ROOT"/}"
            else
                echo "[SKIP] Keeping existing doc: ${dst#"$REPO_ROOT"/}"
            fi
        fi
    fi
fi

echo "[OK] Project documentation initialized at: $SPECS_DIR"
echo "     - profile: $PROFILE"
if [[ "$PROFILE" == "global" ]]; then
    echo "     - global docs: architecture.md (system view), services.md, service-dependencies.md, plans/README.md"
elif [[ "$HAS_INCLUDES" == true ]]; then
    echo "     - selected templates: ${INCLUDES[*]}"
else
    echo "     - core docs: architecture.md, api-standards.md, coding-style.md, code-review.md (new documentation set only)"
fi
if [[ "$PROFILE" == "core" ]]; then
    echo "     - optional docs: run with --full to add optional-docs.md (a catalog for confirmed gaps)"
elif [[ "$PROFILE" == "global" ]]; then
    echo "     - next: fill docs/services.md with the real service list, then complete the Orchestration section in AGENTS.md"
fi

# ---------------------------------------------------------------------------
# Git Hooks installation (idempotent)
#
# Installs lightweight pre-commit / commit-msg hooks via setup_hooks.sh.
# Non-git repos skip silently; existing hooks and scripts are not overwritten.
# Skipped for the global profile: an orchestration repo has no service code to
# whitespace/commit-check here.
# ---------------------------------------------------------------------------
HOOKS_SETUP="$SKILL_DIR/scripts/setup_hooks.sh"
if [[ "$PROFILE" == "global" ]]; then
    echo "[HOOKS] Global profile: skipping Git hooks (no service code in this repo)"
elif [[ -f "$HOOKS_SETUP" ]]; then
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
# copy one from the Skill template. This is a Go-specific convenience; projects
# in other languages keep their own lint setup untouched. Skipped for the global
# profile (no service code).
# ---------------------------------------------------------------------------
if [[ "$PROFILE" == "global" ]]; then
    echo "[LINT] Global profile: skipping .golangci.yml"
elif [[ -f "$REPO_ROOT/go.mod" ]]; then
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
AGENTS_TMPL="$SKILL_DIR/assets/agents.md.tmpl"
AGENTS_MD="$REPO_ROOT/AGENTS.md"
if [[ -e "$AGENTS_MD" || -L "$AGENTS_MD" ]]; then
    echo "[SKIP] Keeping existing AGENTS.md"
elif [[ ! -f "$AGENTS_TMPL" ]]; then
    echo "[WARN] AGENTS.md template does not exist: $AGENTS_TMPL" >&2
else
    PROJECT_NAME="$(basename "$REPO_ROOT")"
    awk -v name="$PROJECT_NAME" '{ gsub(/\{\{PROJECT_NAME\}\}/, name); print }' \
        "$AGENTS_TMPL" > "$AGENTS_MD"
    echo "[ADD] Generated AGENTS.md from the template"
    if [[ "$PROFILE" == "global" && -f "$SKILL_DIR/assets/global-orchestration.tmpl" ]]; then
        ORCH_TMPL="$SKILL_DIR/assets/global-orchestration.tmpl"
        if tail -n 1 "$AGENTS_MD" | grep -q .; then printf '\n' >> "$AGENTS_MD"; fi
        cat "$ORCH_TMPL" >> "$AGENTS_MD"
        echo "[ADD] Appended Orchestration section to AGENTS.md"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ DEVSOP initialization complete"
echo ""
echo "  Next steps:"
if [[ "$PROFILE" == "global" ]]; then
    echo "    1. Fill docs/services.md with the real service list (dev repos + manual platforms)"
    echo "    2. Complete the Orchestration section in AGENTS.md (dispatch and sync specifics)"
    echo "    3. Sync docs/service-dependencies.md from service repos before planning; it is generated, never hand-edited"
else
    echo "    1. Inventory existing docs and source evidence; link authoritative docs rather than duplicating them"
    echo "    2. Add only confirmed missing guidance, using the project's existing docs layout"
    echo "    3. Add key commands and links to AGENTS.md"
fi
echo "═══════════════════════════════════════════════════════════════"
