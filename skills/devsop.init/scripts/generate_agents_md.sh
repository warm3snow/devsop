#!/usr/bin/env bash
# generate_agents_md.sh — Generate/refresh the repo-root AGENTS.md (single source
# of truth, generic across all AI agents).
#
# Usage: bash generate_agents_md.sh <agents.md.tmpl path> <repo_root>
#
# Generated from the template, replacing only {{PROJECT_NAME}}. No tool-specific
# entry files are created.
#
# Update strategy (chapter-divided):
#   - AGENTS.md does not exist  → generate fully from the template
#   - AGENTS.md exists  → split into three segments by "## §2 DEVSOP" and "## §3 Development Guidelines":
#       segment A (header + §1 quick index)   → keep existing (the project may have appended custom index lines)
#       segment B (§2 DEVSOP)                    → force-refresh to the latest template version (core DEVSOP contract)
#       segment C (§3 dev guidelines + §4 forbidden red lines) → keep existing (project-custom; no change/no delete)
#     update only when segment B differs.

set -euo pipefail

AGENTS_TMPL="${1:-}"
REPO_ROOT="${2:-$(pwd)}"

if [[ -z "$AGENTS_TMPL" || ! -f "$AGENTS_TMPL" ]]; then
    echo "[WARN] Template does not exist: ${AGENTS_TMPL:-<missing arg>}, skipping AGENTS.md generation" >&2
    exit 0
fi

AGENTS_MD="$REPO_ROOT/AGENTS.md"
PROJECT_NAME="$(basename "$REPO_ROOT")"

if [[ ! -e "$AGENTS_MD" && ! -L "$AGENTS_MD" ]]; then
    # ---- fresh generation ----
    awk -v name="$PROJECT_NAME" '{ gsub(/\{\{PROJECT_NAME\}\}/, name); print }' \
        "$AGENTS_TMPL" > "$AGENTS_MD"
    echo "[OK] Generated $AGENTS_MD from the template"
else
    # ---- smart merge: only refresh chapter 2 (DEVSOP), keep the rest ----
    # 1) generate the full version from the template to a temp file
    TMPL_FULL="$(mktemp)"
    awk -v name="$PROJECT_NAME" '{ gsub(/\{\{PROJECT_NAME\}\}/, name); print }' \
        "$AGENTS_TMPL" > "$TMPL_FULL"

    # 2) extract segment B of the template (§2 DEVSOP chapter)
    TMPL_DEVSOP="$(mktemp)"
    awk '/^## §2 DEVSOP/{p=1} p && /^## §3 Development Guidelines/{exit} p{print}' "$TMPL_FULL" > "$TMPL_DEVSOP"

    # 3) extract segment B of the existing file (for comparison)
    EXISTING_DEVSOP="$(mktemp)"
    awk '/^## §2 DEVSOP/{p=1} p && /^## §3 Development Guidelines/{exit} p{print}' "$AGENTS_MD" > "$EXISTING_DEVSOP"

    # 4) compare whether segment B differs
    if cmp -s "$TMPL_DEVSOP" "$EXISTING_DEVSOP"; then
        echo "[SKIP] AGENTS.md chapter 2 (DEVSOP) is already up to date, no update needed"
    else
        # 5) extract segment A of the existing file (header + §1 quick index)
        EXISTING_HEAD="$(mktemp)"
        awk '/^## §2 DEVSOP/{exit} {print}' "$AGENTS_MD" > "$EXISTING_HEAD"

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
        cat "$EXISTING_HEAD" "$TMPL_DEVSOP" "$EXISTING_TAIL" > "$AGENTS_MD"
        echo "[REFRESH] Updated AGENTS.md (chapter 2 DEVSOP refreshed to the latest; chapters 1/3/4 kept unchanged)"

        rm -f "$EXISTING_HEAD" "$EXISTING_TAIL"
    fi

    rm -f "$TMPL_FULL" "$TMPL_DEVSOP" "$EXISTING_DEVSOP"
fi

echo "[OK] AGENTS.md is the single generic AI entry (no tool-specific entry files are created)"
