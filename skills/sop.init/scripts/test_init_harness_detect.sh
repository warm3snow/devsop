#!/usr/bin/env bash
# test_init_harness_detect.sh —— black-box test for init_harness.sh's --has-api / --has-db flags.
#
# Usage: bash test_init_harness_detect.sh
# Exit codes: 0 = all passed; 1 = at least one case failed.
#
# Test cases (corresponding to 02-plan.md §6):
#   T1 no flags (compat)           → both apis/ and sqls/ generated
#   T2 --has-api=false             → apis/ not generated; sqls/ generated
#   T3 --has-db=false              → sqls/ not generated; apis/ generated
#   T4 both false                  → neither apis/ nor sqls/ generated; rest of the skeleton normal
#   T5 invalid flag value          → non-zero exit + error on stderr
#   T6 upgrade keeps user files    → existing apis/index.md is not deleted
#   T7 idempotent                  → two consecutive runs with the same args give the same result

set -uo pipefail

# macOS bash 3.2 has a false-positive bug ("OUT: unbound variable") when expanding
# variables within multibyte strings under a UTF-8 locale + set -u; unify to the C locale to avoid it.
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT="$SCRIPT_DIR/init_harness.sh"

PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); echo "  [PASS] $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  [FAIL] $1"; }

# assert_exists <path> <msg>
assert_exists() {
    if [[ -e "$1" ]]; then ok "$2"; else bad "$2 (does not exist: $1)"; fi
}
# assert_not_exists <path> <msg>
assert_not_exists() {
    if [[ ! -e "$1" ]]; then ok "$2"; else bad "$2 (should not exist: $1)"; fi
}

new_repo() {
    local d
    d="$(mktemp -d)"
    # minimal skeleton: a git repo + one file, to avoid hooks install errors (non-git is silently skipped)
    echo "# test" > "$d/README.md"
    echo "$d"
}

echo "T1 no flags (backward compatible)"
R="$(new_repo)"
bash "$INIT" "$R" >/dev/null 2>&1
assert_exists     "$R/.harness/docs/apis/index.md"      "apis/ generated"
assert_exists     "$R/.harness/docs/sqls/database.md"   "sqls/ generated"
rm -rf "$R"

echo "T2 --has-api=false"
R="$(new_repo)"
bash "$INIT" "$R" --has-api=false >/dev/null 2>&1
assert_not_exists "$R/.harness/docs/apis"               "apis/ not generated"
assert_exists     "$R/.harness/docs/sqls/database.md"   "sqls/ generated"
rm -rf "$R"

echo "T3 --has-db=false"
R="$(new_repo)"
bash "$INIT" "$R" --has-db=false >/dev/null 2>&1
assert_exists     "$R/.harness/docs/apis/index.md"      "apis/ generated"
assert_not_exists "$R/.harness/docs/sqls"               "sqls/ not generated"
rm -rf "$R"

echo "T4 --has-api=false --has-db=false (both false)"
R="$(new_repo)"
bash "$INIT" "$R" --has-api=false --has-db=false >/dev/null 2>&1
assert_not_exists "$R/.harness/docs/apis"               "apis/ not generated"
assert_not_exists "$R/.harness/docs/sqls"               "sqls/ not generated"
assert_exists     "$R/.harness/docs/unittest/unittest.md" "rest of the skeleton normal (unittest)"
assert_exists     "$R/.harness/docs/devops/env.md"      "rest of the skeleton normal (devops)"
rm -rf "$R"

echo "T5 invalid flag value"
R="$(new_repo)"
OUT="$(bash "$INIT" "$R" --has-api=maybe 2>&1)"
RC=$?
if [[ $RC -ne 0 ]] && echo "$OUT" | grep -qi "has-api"; then
    ok "non-zero exit with error (rc=$RC)"
else
    bad "invalid value should exit non-zero with a message (rc=$RC)"
fi
assert_not_exists "$R/.harness" "no files written after failure"
rm -rf "$R"

echo "T6 upgrade mode keeps existing user files"
R="$(new_repo)"
mkdir -p "$R/.harness/docs/apis"
echo "user content" > "$R/.harness/docs/apis/index.md"
bash "$INIT" "$R" --has-api=false >/dev/null 2>&1
if [[ "$(cat "$R/.harness/docs/apis/index.md")" == "user content" ]]; then
    ok "existing apis/index.md kept"
else
    bad "existing apis/index.md was modified"
fi
assert_exists "$R/.harness/docs/sqls/database.md" "sqls/ gap-filled normally"
rm -rf "$R"

echo "T7 idempotent (both false, run twice)"
R="$(new_repo)"
bash "$INIT" "$R" --has-api=false --has-db=false >/dev/null 2>&1
bash "$INIT" "$R" --has-api=false --has-db=false >/dev/null 2>&1
RC=$?
[[ $RC -eq 0 ]] && ok "second run exit code 0" || bad "second run exit code $RC"
assert_not_exists "$R/.harness/docs/apis" "apis/ still not generated after two runs"
assert_not_exists "$R/.harness/docs/sqls" "sqls/ still not generated after two runs"
rm -rf "$R"

echo ""
echo "════════════════════════════════"
echo "  Result: $PASS passed, $FAIL failed"
echo "════════════════════════════════"
[[ $FAIL -eq 0 ]]
