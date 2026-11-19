#!/usr/bin/env bash
# Install the two lightweight DEVSOP hooks without replacing project files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"

if [[ -z "$PROJECT_ROOT" ]] || ! git -C "$PROJECT_ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "[SKIP] Not a Git repository; hooks were not installed."
  exit 0
fi

PROJECT_ROOT="$(git -C "$PROJECT_ROOT" rev-parse --show-toplevel)"
HOOKS_DIR="$(git -C "$PROJECT_ROOT" rev-parse --git-path hooks)"
if [[ "$HOOKS_DIR" != /* ]]; then
  HOOKS_DIR="$PROJECT_ROOT/$HOOKS_DIR"
fi
mkdir -p "$PROJECT_ROOT/scripts" "$HOOKS_DIR"

install_hook() {
  local script="$1" hook_name="$2"
  local source="$SCRIPT_DIR/$script"
  local target="$PROJECT_ROOT/scripts/$script"
  local hook="$HOOKS_DIR/$hook_name"

  if [[ ! -f "$target" ]]; then
    cp "$source" "$target"
    chmod +x "$target"
    echo "[ADD] $target"
  fi

  if [[ -L "$hook" ]] && [[ "$(readlink "$hook")" == "$target" ]]; then
    echo "[OK] $hook"
  elif [[ -e "$hook" || -L "$hook" ]]; then
    echo "[WARN] $hook already exists; left unchanged."
  else
    ln -s "$target" "$hook"
    echo "[ADD] $hook"
  fi
}

install_hook pre_commit_check.sh pre-commit
install_hook commit_msg_check.sh commit-msg
