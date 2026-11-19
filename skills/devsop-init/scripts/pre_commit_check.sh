#!/usr/bin/env bash
# Check the staged diff for whitespace errors and unresolved conflict markers.

set -eu

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "[BLOCK] Not inside a Git repository." >&2
  exit 1
}
cd "$repo_root"

if git diff --cached --check; then
  echo "[OK] Staged diff is clean."
else
  echo "[BLOCK] Fix whitespace errors or conflict markers in the staged diff." >&2
  exit 1
fi
