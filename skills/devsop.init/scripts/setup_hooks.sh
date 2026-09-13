#!/usr/bin/env bash
# setup_hooks.sh — One-shot Git Hooks initializer
#
# Usage: bash <path-to-skill>/scripts/setup_hooks.sh
#
# What it does:
#   1. Checks if project is a git repo (exits silently if not)
#   2. Copies hook scripts to scripts/ (skips if already exist)
#   3. Registers .git/hooks/ symlinks (skips if already correct)
#
# Idempotent: safe to run multiple times.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET} $*"; }
ok()      { echo -e "${GREEN}[OK]${RESET}   $*"; }
created() { echo -e "${GREEN}[+]${RESET}    $*"; }
skip()    { echo -e "${YELLOW}[SKIP]${RESET} $*"; }

# ── Locate project root and hook templates ──────────────────────
# Resolve the real path of this script (handles symlinks)
REAL_SCRIPT="$(readlink "${BASH_SOURCE[0]}" 2>/dev/null || true)"
[[ -z "${REAL_SCRIPT}" ]] && REAL_SCRIPT="${BASH_SOURCE[0]}"
if [[ "${REAL_SCRIPT}" != /* ]]; then
  if [[ "${REAL_SCRIPT}" == "${BASH_SOURCE[0]}" ]]; then
    REAL_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${REAL_SCRIPT}")"
  else
    REAL_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(dirname "${REAL_SCRIPT}")" && pwd)/$(basename "${REAL_SCRIPT}")"
  fi
fi
TEMPLATE_DIR="$(cd "$(dirname "${REAL_SCRIPT}")" && pwd)"

# Find project root (prefer git, fallback to directory walking)
find_project_root() {
  # Preferred: use git itself
  local git_root
  git_root="$(git rev-parse --show-toplevel 2>/dev/null)" && echo "$git_root" && return 0

  # Fallback: walk up to find .git/
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    [[ -d "$dir/.git" ]] && echo "$dir" && return 0
    dir="$(dirname "$dir")"
  done
  return 1
}

PROJECT_ROOT="$(find_project_root "$(pwd)")" || {
  skip "Not a git repository, skipping hook setup."
  exit 0
}

cd "${PROJECT_ROOT}"

# ── Define hooks (Bash 3.2 compatible — no associative arrays) ──
# HOOK_SCRIPTS = scripts that get a .git/hooks symlink;
# SUPPORT_SCRIPTS = libraries copied alongside (no hook symlink).
HOOK_SCRIPTS="pre_commit_check.sh pre_push_check.sh commit_msg_check.sh"
SUPPORT_SCRIPTS="lib_check.sh"
# Map script filename to git hook name
hook_name_for() {
  case "$1" in
    pre_commit_check.sh) echo "pre-commit" ;;
    pre_push_check.sh)   echo "pre-push" ;;
    commit_msg_check.sh) echo "commit-msg" ;;
  esac
}

echo ""
info "Setting up Git hooks in: ${PROJECT_ROOT}"
echo ""

# ── Step 1: Copy scripts to scripts/ ───────────────────────────
mkdir -p scripts

for script in ${HOOK_SCRIPTS} ${SUPPORT_SCRIPTS}; do
  target="scripts/${script}"
  if [[ -f "${target}" ]]; then
    ok "${target} (already exists, not overwriting)"
  else
    if [[ -f "${TEMPLATE_DIR}/${script}" ]]; then
      cp "${TEMPLATE_DIR}/${script}" "${target}"
      chmod +x "${target}"
      created "${target} (copied from template)"
    else
      skip "${target} (template not found at ${TEMPLATE_DIR}/${script})"
    fi
  fi
done

echo ""

# ── Step 2: Register .git/hooks/ symlinks ───────────────────────
for script in ${HOOK_SCRIPTS}; do
  hook_name="$(hook_name_for "$script")"
  hook_path=".git/hooks/${hook_name}"
  expected_target="../../scripts/${script}"

  # Check if symlink already points to the right place
  if [[ -L "${hook_path}" ]]; then
    current_target="$(readlink "${hook_path}")"
    if [[ "${current_target}" == "${expected_target}" ]]; then
      ok "${hook_path} → ${expected_target}"
      continue
    fi
  fi

  # Create/update symlink
  if [[ -f "scripts/${script}" ]]; then
    ln -sf "${expected_target}" "${hook_path}"
    created "${hook_path} → ${expected_target}"
  else
    skip "${hook_path} (scripts/${script} does not exist)"
  fi
done

echo ""
info "Done. Hooks are ready."
info "To share with team, commit scripts/ and add to Makefile:"
echo ""
echo "  setup-hooks:"
echo "  	ln -sf ../../scripts/pre_commit_check.sh .git/hooks/pre-commit"
echo "  	ln -sf ../../scripts/pre_push_check.sh .git/hooks/pre-push"
echo "  	ln -sf ../../scripts/commit_msg_check.sh .git/hooks/commit-msg"
echo ""
