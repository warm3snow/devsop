#!/usr/bin/env bash
# install_clarify.sh — Install the clarify skill into the target repo's standard
# repo-local skills dir .agents/skills/clarify/ (the agent-agnostic standard location).
#
# Usage: bash install_clarify.sh <clarify-skill-template-dir> <repo_root>
#
# clarify is a strongly recommended dialogue-protocol skill for Stage 01. Install it into the target repo
# so the target repo's AI can directly use_skill clarify during DEVSOP execution, without depending on an external skill.
#
# Note: source files end with .tmpl (e.g. SKILL.md.tmpl) to avoid conflicting with the library repo's
# skills/ and being double-recognized by the skill system.
# On install, iterate source files; for files with the .tmpl suffix, strip the .tmpl and write to the target; other files are copied with their original names.
# Existing files are always skipped, protecting user changes.

set -euo pipefail

CLARIFY_SKILL_SRC="${1:-}"
REPO_ROOT="${2:-$(pwd)}"

if [[ -z "$CLARIFY_SKILL_SRC" || ! -d "$CLARIFY_SKILL_SRC" ]]; then
    echo "[WARN] clarify skill template does not exist: ${CLARIFY_SKILL_SRC:-<missing arg>}, skipping install" >&2
    exit 0
fi

CLARIFY_DST="$REPO_ROOT/.agents/skills/clarify"
if [[ -e "$CLARIFY_DST/SKILL.md" ]]; then
    echo "[SKIP] $CLARIFY_DST/SKILL.md already exists, keeping as-is"
    exit 0
fi

mkdir -p "$CLARIFY_DST"
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
