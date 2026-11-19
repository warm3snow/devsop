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

# Keep an existing documentation root and report path when possible.
if [ -f "$REPO_ROOT/docs/devsop_report.md" ]; then
  DOCS_DIR="$REPO_ROOT/docs"
  REPORT_PATH="$DOCS_DIR/devsop_report.md"
elif [ -f "$REPO_ROOT/.docs/devsop_report.md" ]; then
  DOCS_DIR="$REPO_ROOT/.docs"
  REPORT_PATH="$DOCS_DIR/devsop_report.md"
elif [ -d "$REPO_ROOT/docs" ]; then
  DOCS_DIR="$REPO_ROOT/docs"
  REPORT_PATH="$DOCS_DIR/devsop_report.md"
elif [ -d "$REPO_ROOT/.docs" ]; then
  DOCS_DIR="$REPO_ROOT/.docs"
  REPORT_PATH="$DOCS_DIR/devsop_report.md"
else
  DOCS_DIR="$REPO_ROOT/docs"
  REPORT_PATH="$DOCS_DIR/devsop_report.md"
fi

if [ ! -f "$REPORT_PATH" ]; then
  EXISTING_REPORT="$(find "$REPO_ROOT" \
    \( -type d \( -name .git -o -name node_modules -o -name vendor -o -name .venv -o -name dist -o -name build -o -name target \) -prune \) -o \
    \( -type f -name devsop_report.md -print -quit \) 2>/dev/null)"
  if [ -n "$EXISTING_REPORT" ]; then
    REPORT_PATH="$EXISTING_REPORT"
    DOCS_DIR="$(dirname "$REPORT_PATH")"
  fi
fi

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
  printf 'REPO_ROOT=%q\n' "$REPO_ROOT"
  printf 'DOCS_DIR=%q\n' "$DOCS_DIR"
  printf 'REPORT_PATH=%q\n' "$REPORT_PATH"
  printf 'SKILL_DIR=%q\n' ""
else
  printf 'REPO_ROOT=%q\n' "$REPO_ROOT"
  printf 'DOCS_DIR=%q\n' "$DOCS_DIR"
  printf 'REPORT_PATH=%q\n' "$REPORT_PATH"
  printf 'SKILL_DIR=%q\n' "$SKILL_DIR"
fi
