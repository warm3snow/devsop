#!/usr/bin/env bash
# Black-box tests for the cross-skill contract checks in validate_skills.sh.

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate_skills.sh"
TMP_ROOT="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT

ok() { PASS=$((PASS + 1)); echo "  [PASS] $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  [FAIL] $1"; }

make_fixture() {
    local root="$1"
    local stage
    rm -rf "$root"
    for stage in devsop-init devsop-plan devsop-design devsop-code devsop-test devsop-ship devsop-flow; do
        mkdir -p "$root/$stage"
        printf -- '---\nname: %s\ndescription: Contract fixture.\n---\n\n# %s\n' "$stage" "$stage" > "$root/$stage/SKILL.md"
    done
    cat >> "$root/devsop-flow/SKILL.md" <<'EOF'
| init | `devsop-init` | repo | AGENTS.md | yes |
| plan | `devsop-plan` | request | plan.md | no |
| design | `devsop-design` | plan.md | tasks.md | no |
| code | `devsop-code` | task list | progress.md | no |
| test | `devsop-test` | scenarios | test-report.md | no |
| ship | `devsop-ship` | report | ship.md | no |
EOF
    printf 'Consumes `plan.md` scenarios.\n' >> "$root/devsop-plan/SKILL.md"
    printf 'Reads `plan.md`, writes `tasks.md`.\n' >> "$root/devsop-design/SKILL.md"
    printf 'Reads `plan.md` and `tasks.md`, writes `progress.md`.\n' >> "$root/devsop-code/SKILL.md"
    printf 'Reads `plan.md`, writes `test-report.md`.\n' >> "$root/devsop-test/SKILL.md"
    printf 'Reads `test-report.md`, writes `ship.md`.\n' >> "$root/devsop-ship/SKILL.md"
}

run_validate() {
    OUTPUT="$(bash "$VALIDATE" "$1" 2>&1)"
    RC=$?
}

expect_pass() {
    run_validate "$1"
    if [ "$RC" -eq 0 ]; then ok "$2"; else bad "$2 (exit $RC: $OUTPUT)"; fi
}

expect_fail() {
    run_validate "$1"
    if [ "$RC" -ne 0 ] && echo "$OUTPUT" | grep -qi "$3"; then
        ok "$2"
    else
        bad "$2 (exit $RC, output: $OUTPUT)"
    fi
}

FX="$TMP_ROOT/skills"

echo "Valid library passes"
make_fixture "$FX"
expect_pass "$FX" "clean fixture passes contract checks"

echo "Stale artifact names fail"
make_fixture "$FX"
printf 'See user-stories.md for details.\n' >> "$FX/devsop-plan/SKILL.md"
expect_fail "$FX" "stale artifact name rejected" "stale"

echo "Non-canonical artifact references fail"
make_fixture "$FX"
printf 'Also reads notes.md.\n' >> "$FX/devsop-code/SKILL.md"
expect_fail "$FX" "unknown artifact rejected" "non-canonical"

echo "Stage map must cover every stage"
make_fixture "$FX"
printf -- '---\nname: devsop-flow\ndescription: Contract fixture.\n---\n\n# devsop-flow\n\nStages: devsop-init, devsop-plan, devsop-design, devsop-code, devsop-test.\n' > "$FX/devsop-flow/SKILL.md"
expect_fail "$FX" "missing stage in flow rejected" "devsop-ship"

echo "Unknown skill references fail"
make_fixture "$FX"
printf 'Then `devsop-prototype` runs.\n' >> "$FX/devsop-plan/SKILL.md"
expect_fail "$FX" "unknown skill reference rejected" "devsop-prototype"

echo ""
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
