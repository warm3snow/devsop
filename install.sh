#!/usr/bin/env bash
# install.sh — Symlink all bundled DEVSOP skills into ~/.agents/skills/ (the
# agent-agnostic standard skills directory).
#
# Usage:
#   bash install.sh          # install (idempotent; auto-discovers skills/*/SKILL.md)
#   bash install.sh --check  # verify existing symlinks, no changes
#
# Idempotent: safe to run multiple times. New skills are picked up automatically.

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; RESET='\033[0m'
ok()      { echo -e "${GREEN}[OK]${RESET}   $*"; }
created() { echo -e "${GREEN}[+]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
fail()    { echo -e "${RED}[FAIL]${RESET} $*"; }

MODE="install"
[[ $# -gt 0 && "$1" == "--check" ]] && MODE="check"

# ── Resolve this repo's real location (handles symlinks) ────────
REAL_SCRIPT="$(readlink "${BASH_SOURCE[0]}" 2>/dev/null || true)"
[[ -z "${REAL_SCRIPT}" ]] && REAL_SCRIPT="${BASH_SOURCE[0]}"
if [[ "${REAL_SCRIPT}" != /* ]]; then
  REAL_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${REAL_SCRIPT}")"
fi
SKILLS_SRC="$(cd "$(dirname "${REAL_SCRIPT}")" && pwd)/skills"
DEST_DIR="${HOME}/.agents/skills"

[[ -d "${SKILLS_SRC}" ]] || { fail "skills/ not found at ${SKILLS_SRC}"; exit 1; }
mkdir -p "${DEST_DIR}"

# ── Auto-discover skills: every skills/*/ dir containing SKILL.md ──
SKILLS=""
for skill_dir in "${SKILLS_SRC}"/*/; do
  [[ -f "${skill_dir}SKILL.md" ]] && SKILLS="${SKILLS} $(basename "${skill_dir}")"
done

for skill in ${SKILLS}; do
  src="${SKILLS_SRC}/${skill}"
  dst="${DEST_DIR}/${skill}"

  if [[ "${MODE}" == "check" ]]; then
    if [[ -L "${dst}" ]] && [[ "$(readlink "${dst}")" == "${src}" ]]; then
      ok "${skill}"
    else
      warn "${skill}: not linked correctly (run 'bash install.sh' to fix)"
    fi
    continue
  fi

  if [[ -L "${dst}" ]] && [[ "$(readlink "${dst}")" == "${src}" ]]; then
    ok "${skill}"
    continue
  fi
  if [[ -L "${dst}" ]]; then
    ln -sf "${src}" "${dst}"
    created "${skill} (relinked)"
    continue
  fi
  if [[ -e "${dst}" ]]; then
    fail "${skill}: ${dst} exists and is not a symlink — remove it manually"
    continue
  fi
  ln -s "${src}" "${dst}"
  created "${skill}"
done

SKILL_COUNT=$(echo "${SKILLS}" | wc -w | tr -d ' ')
echo ""
if [[ "${MODE}" == "check" ]]; then
  echo -e "${CYAN}[INFO]${RESET} Check complete. Skills dir: ${DEST_DIR} (${SKILL_COUNT} skills)"
else
  echo -e "${CYAN}[INFO]${RESET} Done. ${SKILL_COUNT} skills installed into ${DEST_DIR} (the agent-agnostic standard dir)."
fi
echo ""
