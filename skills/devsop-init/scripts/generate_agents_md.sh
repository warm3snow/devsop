#!/usr/bin/env bash
# Generate AGENTS.md only when the project does not already have one.

set -euo pipefail

AGENTS_TMPL="${1:-}"
REPO_ROOT="${2:-$(pwd)}"

if [[ -z "$AGENTS_TMPL" || ! -f "$AGENTS_TMPL" ]]; then
    echo "[ERROR] Template does not exist: ${AGENTS_TMPL:-<missing arg>}" >&2
    exit 1
fi

AGENTS_MD="$REPO_ROOT/AGENTS.md"
if [[ -e "$AGENTS_MD" || -L "$AGENTS_MD" ]]; then
    echo "[SKIP] Keeping existing $AGENTS_MD"
    exit 0
fi

PROJECT_NAME="$(basename "$REPO_ROOT")"
awk -v name="$PROJECT_NAME" '{ gsub(/\{\{PROJECT_NAME\}\}/, name); print }' \
    "$AGENTS_TMPL" > "$AGENTS_MD"
echo "[OK] Generated $AGENTS_MD from the template"
