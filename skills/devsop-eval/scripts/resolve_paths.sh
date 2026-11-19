#!/usr/bin/env bash
# resolve_paths.sh - resolve REPO_ROOT and SKILL_DIR for devsop-eval
#
# Usage:
#   source <(bash "$SKILL_DIR_OR_SCRIPT_PATH/resolve_paths.sh")
#   # or: eval "$(bash resolve_paths.sh)"
#
# The agent normally injects $SKILL_DIR when loading the skill; this script is
# the fallback over the ~/.agents/ standard locations. Prints shell assignments
# to stdout (source-able), writes nothing else.

# Step A: resolve REPO_ROOT (the current project repo)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Step B: resolve SKILL_DIR (Skill install dir, standard locations only)
if [ -z "${SKILL_DIR:-}" ] || [ ! -d "$SKILL_DIR/references" ]; then
  SKILL_DIR=""
  for c in \
    "$HOME/.agents/skills/devsop-eval" \
    "$REPO_ROOT/.agents/skills/devsop-eval" \
    "$REPO_ROOT/skills/devsop-eval"; do
    if [ -d "$c/references" ]; then SKILL_DIR="$c"; break; fi
  done
fi

if [ -z "$SKILL_DIR" ]; then
  echo "echo '⚠️ cannot locate the devsop-eval skill directory' >&2"
  echo "REPO_ROOT='$REPO_ROOT'"
  echo "SKILL_DIR=''"
else
  echo "REPO_ROOT='$REPO_ROOT'"
  echo "SKILL_DIR='$SKILL_DIR'"
fi
