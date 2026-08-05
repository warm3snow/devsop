#!/usr/bin/env bash
# install.sh — Symlink the bundled DEVSOP skills into ~/.codebuddy/skills/
#
# Usage: bash install.sh
#
# What it does:
#   1. Resolves this repo's real location (handles being invoked via symlink)
#   2. Ensures ~/.codebuddy/skills/ exists
#   3. Symlinks each skills/<name> dir into ~/.codebuddy/skills/<name>
#      (skips if already a correct symlink; warns on real-dir conflicts)
#
# Idempotent: safe to run multiple times.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET} $*"; }
ok()      { echo -e "${GREEN}[OK]${RESET}   $*"; }
created() { echo -e "${GREEN}[+]${RESET}    $*"; }
skip()    { echo -e "${YELLOW}[SKIP]${RESET} $*"; }
fail()    { echo -e "${RED}[FAIL]${RESET} $*"; }

# ── Resolve this script's real path (handles symlinks) ──────────
REAL_SCRIPT="$(readlink "${BASH_SOURCE[0]}" 2>/dev/null || true)"
[[ -z "${REAL_SCRIPT}" ]] && REAL_SCRIPT="${BASH_SOURCE[0]}"
if [[ "${REAL_SCRIPT}" != /* ]]; then
  if [[ "${REAL_SCRIPT}" == "${BASH_SOURCE[0]}" ]]; then
    REAL_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${REAL_SCRIPT}")"
  else
    REAL_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(dirname "${REAL_SCRIPT}")" && pwd)/$(basename "${REAL_SCRIPT}")"
  fi
fi
REPO_ROOT="$(cd "$(dirname "${REAL_SCRIPT}")" && pwd)"
SKILLS_SRC="${REPO_ROOT}/skills"

DEST_DIR="${HOME}/.codebuddy/skills"

SKILLS="devsop.init devsop.eval go-quality-scorer go-secret-leak-review"

echo ""
info "Installing DEVSOP skills from: ${SKILLS_SRC}"
info "Target directory:           ${DEST_DIR}"
echo ""

# ── Validate source ─────────────────────────────────────────────
if [[ ! -d "${SKILLS_SRC}" ]]; then
  fail "skills/ directory not found at ${SKILLS_SRC}"
  exit 1
fi

# ── Ensure destination exists ───────────────────────────────────
mkdir -p "${DEST_DIR}"

# ── Symlink each skill ──────────────────────────────────────────
for skill in ${SKILLS}; do
  src="${SKILLS_SRC}/${skill}"
  dst="${DEST_DIR}/${skill}"

  if [[ ! -d "${src}" ]]; then
    skip "${skill} (source ${src} not found)"
    continue
  fi

  # Already a correct symlink → skip
  if [[ -L "${dst}" ]]; then
    current_target="$(readlink "${dst}")"
    if [[ "${current_target}" == "${src}" ]]; then
      ok "${dst} → ${src}"
      continue
    fi
    # Wrong symlink → replace
    ln -sf "${src}" "${dst}"
    created "${dst} → ${src} (relinked, was ${current_target})"
    continue
  fi

  # Real dir or file at destination → do not clobber
  if [[ -e "${dst}" ]]; then
    fail "${dst} exists and is not a symlink — refusing to overwrite. Remove it manually if intended."
    continue
  fi

  # Create symlink
  ln -s "${src}" "${dst}"
  created "${dst} → ${src}"
done

echo ""
info "Done. Skills installed into ${DEST_DIR}"
info "Run 'codebuddy' and the skills should be discoverable."
echo ""
