#!/usr/bin/env bash
# Black-box tests for documentation-root resolution and evidence discovery.

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVAL_SKILL="$(dirname "$SCRIPT_DIR")"
RESOLVER="$SCRIPT_DIR/resolve_paths.sh"
COLLECTOR="$SCRIPT_DIR/collect_evidence.sh"
TMP_ROOT="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

ok() { PASS=$((PASS + 1)); echo "  [PASS] $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  [FAIL] $1"; }

assert_resolved() {
    local repo="$1"
    local expected_docs="$2"
    local expected_report="$3"
    local real_repo
    local output
    real_repo="$(cd "$repo" && pwd -P)"
    expected_docs="$real_repo${expected_docs#"$repo"}"
    expected_report="$real_repo${expected_report#"$repo"}"
    output="$(cd "$repo" && SKILL_DIR="$EVAL_SKILL" bash "$RESOLVER" 2>/dev/null)"
    if echo "$output" | grep -Fxq "DOCS_DIR=$expected_docs" &&
        echo "$output" | grep -Fxq "REPORT_PATH=$expected_report"; then
        ok "resolved docs root and report path for ${repo##*/}"
    else
        bad "incorrect docs/report paths for ${repo##*/}"
    fi
}

echo "Documentation root resolution"
REPO="$TMP_ROOT/docs-root"
mkdir -p "$REPO/docs"
git -C "$REPO" init -q
assert_resolved "$REPO" "$REPO/docs" "$REPO/docs/devsop_report.md"

REPO="$TMP_ROOT/hidden-docs-root"
mkdir -p "$REPO/.docs"
git -C "$REPO" init -q
assert_resolved "$REPO" "$REPO/.docs" "$REPO/.docs/devsop_report.md"

REPO="$TMP_ROOT/existing-report"
mkdir -p "$REPO/docs" "$REPO/.docs"
git -C "$REPO" init -q
touch "$REPO/.docs/devsop_report.md"
assert_resolved "$REPO" "$REPO/.docs" "$REPO/.docs/devsop_report.md"

REPO="$TMP_ROOT/nested-report"
mkdir -p "$REPO/docs/reports"
git -C "$REPO" init -q
touch "$REPO/docs/reports/devsop_report.md"
assert_resolved "$REPO" "$REPO/docs/reports" "$REPO/docs/reports/devsop_report.md"

REPO="$TMP_ROOT/new-repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
assert_resolved "$REPO" "$REPO/docs" "$REPO/docs/devsop_report.md"

OUTPUT="$(cd "$REPO" && bash "$COLLECTOR" 2>/dev/null)"
if echo "$OUTPUT" | grep -Fq '=== DONE ==='; then
    ok "evidence collection tolerates repositories with no documentation"
else
    bad "evidence collection failed on an empty documentation set"
fi

echo "Documentation inventory excludes generated reports"
mkdir -p "$REPO/docs/team"
printf '# Existing conventions\n\nUse the project conventions.\n' > "$REPO/docs/team/conventions.md"
printf '# Evaluation output\n' > "$REPO/docs/devsop_report.md"
OUTPUT="$(cd "$REPO" && bash "$COLLECTOR" 2>/dev/null)"
if echo "$OUTPUT" | grep -Fq 'DOC ./docs/team/conventions.md'; then
    ok "arbitrary documentation path discovered"
else
    bad "documentation file not discovered"
fi
if echo "$OUTPUT" | grep -Fq 'DOC ./docs/devsop_report.md'; then
    bad "evaluation report was counted as project guidance"
else
    ok "evaluation report excluded from project guidance"
fi
if echo "$OUTPUT" | grep -Fq 'report_path: ./docs/devsop_report.md'; then
    ok "existing report path found for history"
else
    bad "existing report path not found"
fi

echo ""
echo "Result: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
