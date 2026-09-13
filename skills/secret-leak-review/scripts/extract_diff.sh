#!/usr/bin/env bash
#
# extract_diff.sh — read-only extraction of incremental or full code (for the sub-agent to review privacy leaks)
#
# Usage:
#   extract_diff.sh <REPO_ROOT> <commitA> <commitB> [<path_filter>]
#
#   REPO_ROOT   : target git repo root (absolute or relative; resolved by git internally)
#   commitA     : range start commit (exclusive) / branch / tag / SHA
#                 Full-mode keywords (either one works, same for commitB):
#                   all / ALL / All / *  (case-insensitive)
#                 If both params are keywords (or both empty) → full scan of all source files in the working tree
#   commitB     : range end commit (inclusive); same as above for full mode
#   path_filter : optional, restrict to a subdirectory or file
#                 incremental mode passes it to `git diff -- <path>`
#                 full mode uses it as the find path prefix
#
# Output:
#   - incremental mode: git diff text (with + lines, file paths, hunk line-number context)
#   - full mode: pseudo-diff format (`+++ b/<path>` per file + `@@ -0,0 +1,N @@` + `+` prefix per line),
#     line numbers are the real file line numbers, no special handling needed in the sub-agent prompt.
#
# Constraints (hard):
#   - Read-only. Never run git add/commit/checkout/reset/clean or other write operations.
#   - Never write to $SKILL_DIR / $HOME / /tmp.
#   - On failure (not a git repo / invalid commit) → non-zero exit, reason printed to stderr.

set -euo pipefail

REPO_ROOT="${1:-}"
COMMIT_A="${2:-}"
COMMIT_B="${3:-}"
PATH_FILTER="${4:-}"

if [[ -z "$REPO_ROOT" ]]; then
  echo "Usage: extract_diff.sh <REPO_ROOT> <commitA> <commitB> [<path_filter>]" >&2
  exit 2
fi

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Error: REPO_ROOT is not a directory: $REPO_ROOT" >&2
  exit 3
fi

# Resolve the repo root and verify it is a git repository
GIT_ROOT="$(cd "$REPO_ROOT" && git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$GIT_ROOT" ]]; then
  echo "Error: not a git repository: $REPO_ROOT" >&2
  exit 4
fi

cd "$GIT_ROOT"

# Full-mode keyword detection (case-insensitive). Either commitA/commitB being a keyword → full mode.
is_full_keyword() {
  local v="$1"
  local lv
  lv="$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]')"
  [[ -z "$v" || "$lv" == "all" || "$v" == "*" ]]
}

if is_full_keyword "$COMMIT_A" || is_full_keyword "$COMMIT_B"; then
  # ── Full mode: scan all source files in the working tree (language-agnostic) ──
  # Use git ls-files to only take git-tracked files (avoid scanning artifacts/temp files), naturally read-only.
  # Source extensions cover the mainstream languages; binary-ish/text config with secrets are also in scope.
  SRC_PATTERN='\.(go|py|js|ts|jsx|tsx|java|kt|kts|rs|c|cc|cpp|h|hpp|cs|rb|php|sh|bash|zsh|yaml|yml|toml|json|tf|sql|env|ini|conf)$'

  # Collect source files, excluding vendor / third-party / generated code / lockfiles
  SRC_FILES=()
  if [[ -n "$PATH_FILTER" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] && SRC_FILES+=("$f")
    done < <(
      git ls-files -- "$PATH_FILTER" 2>/dev/null \
        | grep -E "${SRC_PATTERN}" \
        | grep -vE '(^|/)(vendor/|third_party/|node_modules/|dist/|build/)' \
        | grep -vE '\.pb\.go$|\.pb\.cc$|_gen\.(go|py|js|ts)$|\.min\.(js|css)$|package-lock\.json$|go\.sum$|/mocks/|/mock_|\.generated\.' || true
    )
  else
    while IFS= read -r f; do
      [[ -n "$f" ]] && SRC_FILES+=("$f")
    done < <(
      git ls-files 2>/dev/null \
        | grep -E "${SRC_PATTERN}" \
        | grep -vE '(^|/)(vendor/|third_party/|node_modules/|dist/|build/)' \
        | grep -vE '\.pb\.go$|\.pb\.cc$|_gen\.(go|py|js|ts)$|\.min\.(js|css)$|package-lock\.json$|go\.sum$|/mocks/|/mock_|\.generated\.' || true
    )
  fi

  if [[ ${#SRC_FILES[@]} -eq 0 ]]; then
    # no source files: output empty (the caller treats it as "no increment/no code")
    exit 0
  fi

  for f in "${SRC_FILES[@]}"; do
    # the file may have been deleted (git ls-files still lists it) → skip
    [[ -f "$f" ]] || continue
    # line count
    local_lines=$(wc -l < "$f" | tr -d ' ')
    # pseudo-diff header
    echo "+++ b/$f"
    echo "@@ -0,0 +1,${local_lines} @@"
    # prefix each line with +, preserving the original content (including blank lines)
    while IFS= read -r line || [[ -n "$line" ]]; do
      printf '+%s\n' "$line"
    done < "$f"
    echo
  done
  exit 0
fi

# ── Single-commit mode: commitA is non-empty and not a full keyword, commitB is empty/single/- → scan this commit's changes relative to its parent ──
is_single_keyword() {
  local v="$1"
  local lv
  lv="$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]')"
  [[ -z "$v" || "$lv" == "single" || "$v" == "-" ]]
}

# Single-commit takes precedence over incremental (commitB "-" must not be treated as a valid commit for incremental)
if [[ -n "$COMMIT_A" ]] && ! is_full_keyword "$COMMIT_A" && is_single_keyword "$COMMIT_B"; then
  if ! git rev-parse --verify --quiet "$COMMIT_A^{commit}" >/dev/null 2>&1; then
    echo "Error: invalid or nonexistent commit: $COMMIT_A" >&2
    exit 5
  fi
  # the commit has no parent (root commit) → compare against the empty tree (git diff does not support --root; use the empty tree hash)
  if git rev-parse --verify --quiet "$COMMIT_A^" >/dev/null 2>&1; then
    PARENT="$COMMIT_A^"
  else
    PARENT="4b825dc642cb6eb9a060e54bf8d69288fbee4904"
  fi
  DIFF_CMD=(git diff --no-color --unified=3 "$PARENT" "$COMMIT_A")
  if [[ -n "$PATH_FILTER" ]]; then
    DIFF_CMD+=(-- "$PATH_FILTER")
  fi
  "${DIFF_CMD[@]}"
  exit 0
fi

# ── Incremental mode: both params must be valid commits ──
if [[ -z "$COMMIT_A" || -z "$COMMIT_B" ]]; then
  echo "Error: commitA and commitB are required (incremental); single commit: <commit> -; full: all all" >&2
  exit 2
fi

if ! git rev-parse --verify --quiet "$COMMIT_A^{commit}" >/dev/null 2>&1; then
  echo "Error: invalid or nonexistent commitA: $COMMIT_A" >&2
  exit 5
fi
if ! git rev-parse --verify --quiet "$COMMIT_B^{commit}" >/dev/null 2>&1; then
  echo "Error: invalid or nonexistent commitB: $COMMIT_B" >&2
  exit 6
fi

# Extract the range diff (unified=3 keeps line-number context).
# Note: use $COMMIT_A $COMMIT_B (not three-dot ..), meaning the changes in B relative to A.
# If commitA == commitB, git diff is empty (no increment), handled by the caller as empty output.
DIFF_CMD=(git diff --no-color --unified=3 "$COMMIT_A" "$COMMIT_B")
if [[ -n "$PATH_FILTER" ]]; then
  DIFF_CMD+=(-- "$PATH_FILTER")
fi

"${DIFF_CMD[@]}"
