#!/usr/bin/env bash
# Black-box tests for the devsop-plan artifact validator (validate_plan.py).

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATOR="$SCRIPT_DIR/validate_plan.py"
TMP_ROOT="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT

ok() { PASS=$((PASS + 1)); echo "  [PASS] $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  [FAIL] $1"; }

BASE="$TMP_ROOT/base.md"
cat > "$BASE" <<'EOF'
# Todo export — 2026-11-27

## Non-goals
- Bulk export

## Non-functional requirements
### NFR-1 Export speed [integration]
- Constraint: export of 100 items finishes within 5 seconds
- Scenario: Given a list with 100 items / When the user exports / Then the file arrives within 5 seconds

## US-1 Export list to file [Must]
As a list owner I want to export my list so that I can keep a copy.

### S1.1 Export succeeds [manual]
- Given the list has 3 items
- When the user exports
- Then the file contains the 3 item names

### S1.2 Empty list is rejected [unit]
- Given the list is empty
- When the user exports
- Then an error message "nothing to export" is shown
EOF

PLAN="$TMP_ROOT/plan.md"

run_validator() {
    OUTPUT="$(python3 "$VALIDATOR" "$PLAN" 2>&1)"
    RC=$?
}

expect_pass() {
    run_validator
    if [ "$RC" -eq 0 ]; then ok "$1"; else bad "$1 (exit $RC)"; fi
}

expect_fail() {
    run_validator
    if [ "$RC" -ne 0 ] && echo "$OUTPUT" | grep -qi "$2"; then
        ok "$1"
    else
        bad "$1 (exit $RC, output: $OUTPUT)"
    fi
}

echo "Structure validation"

cp "$BASE" "$PLAN"
expect_pass "valid plan passes"

sed '/^## Non-goals/d' "$BASE" > "$PLAN"
expect_fail "missing Non-goals section fails" "non-goals"

sed '/^- Bulk export/d' "$BASE" > "$PLAN"
expect_fail "empty Non-goals section fails" "non-goals"

sed '/^## US-1/,$d' "$BASE" > "$PLAN"
expect_fail "plan without stories fails" "story"

sed '/^As a list owner/d' "$BASE" > "$PLAN"
expect_fail "story without narrative fails" "narrative"

sed '/^### S1\.1/,$d' "$BASE" > "$PLAN"
expect_fail "story without scenarios fails" "scenario"

sed '/- Then the file contains/d' "$BASE" > "$PLAN"
expect_fail "scenario without Then fails" "Then"

sed 's/\[manual\]/[e2e]/' "$BASE" > "$PLAN"
expect_fail "invalid type tag fails" "type tag"

sed 's/^### S1\.1 /### S2.1 /' "$BASE" > "$PLAN"
expect_fail "scenario ID prefix mismatch fails" "prefix"

sed -e 's/Empty list is rejected/Export repeats/' \
    -e 's/Given the list is empty/Given the list has 1 item/' \
    -e 's/an error message "nothing to export" is shown/a message "exported" is shown/' \
    "$BASE" > "$PLAN"
expect_fail "story without negative or boundary scenario fails" "negative"

sed '/- Constraint:/d' "$BASE" > "$PLAN"
expect_fail "NFR without constraint fails" "Constraint"

echo "Warnings do not fail the build"
sed 's/- Then the file contains the 3 item names/- Then the API returns 204/' "$BASE" > "$PLAN"
run_validator
if [ "$RC" -eq 0 ] && echo "$OUTPUT" | grep -qi "warning"; then
    ok "technical value in Then warns without failing"
else
    bad "technical value in Then should warn without failing (exit $RC, output: $OUTPUT)"
fi

echo ""
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
