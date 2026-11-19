#!/usr/bin/env bash
# Require: <type>(<module-or-service>): <subject>

set -eu

if [[ $# -ne 1 || ! -f "$1" ]]; then
  echo "Usage: commit_msg_check.sh <commit-message-file>" >&2
  exit 2
fi

title="$(awk '!/^#/ && NF { print; exit }' "$1")"
pattern='^(feat|fix|docs|refactor)\([a-z0-9][a-z0-9-]*\):[[:space:]]+[^[:space:]].*$'

if [[ "$title" =~ $pattern ]]; then
  exit 0
fi

echo "[BLOCK] Use <type>(<module-or-service>): <subject>." >&2
echo "        Types: feat, fix, docs, refactor" >&2
echo "        Scope: lowercase module/service name, e.g. gateway" >&2
echo "        Example: feat(gateway): add circuit break function" >&2
exit 1
