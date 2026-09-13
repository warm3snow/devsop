#!/usr/bin/env bash
# lib_check.sh — Shared helpers for the DEVSOP Git Hook scripts.
#
# Sourced (not executed) by pre_commit_check.sh / pre_push_check.sh.
# Provides: colors, structured log helpers, and script-dir/project-root
# resolution. Must stay Bash 3.2 compatible.

# ── Colors ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ── AI-friendly structured output ──────────────────────────────
# Format: [BLOCK] <check_name> | <file>:<line> | <reason> | fix: <command>
error()    { echo -e "${RED}[BLOCK]${RESET} $*" >&2; }
warn()     { echo -e "${YELLOW}[WARN]${RESET} $*" >&2; }
info()     { echo -e "${CYAN}[INFO]${RESET} $*" >&2; }
section()  { echo -e "\n${CYAN}══ $* ══${RESET}"; }

ai_error() {
  local check="$1" file="$2" line="${3:-0}" reason="$4" fix="${5:-}"
  echo -e "${RED}[BLOCK]${RESET} ${check} | ${file}:${line} | ${reason}" >&2
  if [[ -n "${fix}" ]]; then
    echo -e "  ${CYAN}fix:${RESET} ${fix}" >&2
  fi
}

# Print full command output for AI consumption
show_output() {
  local label="$1" file="$2"
  if [[ -s "$file" ]]; then
    echo -e "\n${RED}── ${label} output ──${RESET}" >&2
    cat "$file" >&2
    echo -e "${RED}── end of ${label} output ──${RESET}\n" >&2
  fi
}

# ── Resolve PROJECT_ROOT and cd into it ─────────────────────────
# The caller resolves SCRIPT_DIR (real path, through the .git/hooks
# symlink) before sourcing this file.
setup_env() {
  PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
  cd "${PROJECT_ROOT}"
  if [[ -f "${SCRIPT_DIR}/env.sh" ]]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/env.sh"
  fi
}

# Neutralize git env vars that leak into hooks from interactive shells
clean_git_env() {
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_OBJECT_DIRECTORY GIT_COMMON_DIR
}
