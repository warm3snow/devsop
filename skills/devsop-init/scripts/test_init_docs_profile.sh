#!/usr/bin/env bash
# Black-box tests for init_docs.sh documentation profiles.

set -uo pipefail
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT="$SCRIPT_DIR/init_docs.sh"
PASS=0
FAIL=0

ok()  { PASS=$((PASS + 1)); echo "  [PASS] $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  [FAIL] $1"; }

assert_exists() {
    if [[ -e "$1" ]]; then ok "$2"; else bad "$2 (missing: $1)"; fi
}

assert_missing() {
    if [[ ! -e "$1" ]]; then ok "$2"; else bad "$2 (unexpected: $1)"; fi
}

new_repo() {
    mktemp -d
}

echo "Core profile is minimal"
REPO="$(new_repo)"
bash "$INIT" "$REPO" >/dev/null 2>&1
assert_exists "$REPO/AGENTS.md" "AI entry generated"
assert_exists "$REPO/docs/architecture.md" "architecture doc generated"
assert_exists "$REPO/docs/unittest/unittest.md" "unit-test doc generated"
if grep -q "Follow the project's established development workflow" "$REPO/AGENTS.md"; then
    ok "AI entry defers to the project's chosen workflow"
else
    bad "AI entry should not prescribe a task workflow"
fi
assert_missing "$REPO/docs/plans" "task-management structure is not imposed"
assert_missing "$REPO/.agents/skills/clarify" "only the two bundled Skills are needed"
assert_missing "$REPO/docs/apis" "API docs omitted by default"
assert_missing "$REPO/docs/sqls" "database docs omitted by default"
assert_missing "$REPO/docs/devops" "DevOps docs omitted by default"
rm -rf "$REPO"

echo "Existing docs and equivalent filenames are reused"
REPO="$(new_repo)"
mkdir -p "$REPO/docs"
printf '# Coding conventions\n\nUse the existing project conventions.\n' > "$REPO/docs/conventions.md"
printf '# Project overview\n' > "$REPO/README.md"
OUTPUT="$(bash "$INIT" "$REPO" 2>&1)"
assert_exists "$REPO/docs/conventions.md" "existing conventions doc preserved"
assert_missing "$REPO/docs/coding-style.md" "equivalent coding guide is not duplicated"
assert_missing "$REPO/.docs" "hidden parallel docs tree is not created"
if echo "$OUTPUT" | grep -q "Existing project documentation found"; then
    ok "template copy deferred until docs inventory"
else
    bad "initializer should defer template copy for documented projects"
fi
rm -rf "$REPO"

echo "Only explicitly selected templates are added to existing docs"
REPO="$(new_repo)"
mkdir -p "$REPO/docs"
printf '# Coding conventions\n' > "$REPO/docs/conventions.md"
bash "$INIT" "$REPO" --docs-dir docs --include architecture.md >/dev/null 2>&1
assert_exists "$REPO/docs/architecture.md" "selected missing architecture template added"
assert_exists "$REPO/docs/conventions.md" "unrelated existing document preserved"
assert_missing "$REPO/docs/coding-style.md" "unselected equivalent template omitted"
rm -rf "$REPO"

echo "Ambiguous docs roots require an explicit choice"
REPO="$(new_repo)"
mkdir -p "$REPO/docs" "$REPO/.docs"
OUTPUT="$(bash "$INIT" "$REPO" 2>&1)"
RC=$?
if [[ $RC -ne 0 ]] && echo "$OUTPUT" | grep -q "Both docs/ and .docs/ exist"; then
    ok "ambiguous documentation roots rejected"
else
    bad "ambiguous documentation roots should require --docs-dir"
fi
assert_missing "$REPO/AGENTS.md" "no files written for ambiguous docs roots"
rm -rf "$REPO"

echo "Documentation paths cannot escape through a symlink"
REPO="$(new_repo)"
OUTSIDE="$(mktemp -d)"
ln -s "$OUTSIDE" "$REPO/docs"
OUTPUT="$(bash "$INIT" "$REPO" --docs-dir docs 2>&1)"
RC=$?
if [[ $RC -ne 0 ]] && echo "$OUTPUT" | grep -q "resolves outside the repository"; then
    ok "external documentation symlink rejected"
else
    bad "external documentation symlink should be rejected"
fi
assert_missing "$OUTSIDE/architecture.md" "no files written through external symlink"
assert_missing "$REPO/AGENTS.md" "no project files written after symlink rejection"
rm -rf "$REPO" "$OUTSIDE"

echo "Full profile includes optional docs"
REPO="$(new_repo)"
bash "$INIT" "$REPO" --full >/dev/null 2>&1
assert_exists "$REPO/docs/apis/index.md" "API docs generated"
assert_exists "$REPO/docs/sqls/database.md" "database docs generated"
assert_exists "$REPO/docs/devops/env.md" "DevOps docs generated"
assert_missing "$REPO/docs/devops/test-env-deploy.md" "no agent-specific environment guide is generated"
assert_missing "$REPO/docs/plans" "full profile does not impose a task workflow"
rm -rf "$REPO"

echo "Full profile adds to an existing core setup without overwriting files"
REPO="$(new_repo)"
bash "$INIT" "$REPO" >/dev/null 2>&1
echo "user content" > "$REPO/docs/architecture.md"
bash "$INIT" "$REPO" --full --include apis/index.md >/dev/null 2>&1
assert_exists "$REPO/docs/apis/index.md" "full profile adds selected optional docs"
assert_missing "$REPO/docs/plans" "profile upgrade does not create task workflow files"
if [[ "$(cat "$REPO/docs/architecture.md")" == "user content" ]]; then
    ok "existing core doc kept"
else
    bad "full profile modified an existing core doc"
fi
rm -rf "$REPO"

echo "Unknown options fail before writing"
REPO="$(new_repo)"
OUTPUT="$(bash "$INIT" "$REPO" --unknown 2>&1)"
RC=$?
if [[ $RC -ne 0 ]] && echo "$OUTPUT" | grep -q "Unknown argument"; then
    ok "unknown option rejected"
else
    bad "unknown option should fail with an error"
fi
assert_missing "$REPO/.docs" "no files written after invalid input"
rm -rf "$REPO"

echo "Existing files are kept and repeated initialization succeeds"
REPO="$(new_repo)"
mkdir -p "$REPO/.docs"
mkdir -p "$REPO/.docs/plans/manual"
echo "user content" > "$REPO/.docs/architecture.md"
echo "user plan" > "$REPO/.docs/plans/manual/notes.md"
echo "project-specific entry" > "$REPO/AGENTS.md"
bash "$INIT" "$REPO" >/dev/null 2>&1
bash "$INIT" "$REPO" >/dev/null 2>&1
RC=$?
[[ $RC -eq 0 ]] && ok "repeat initialization succeeds" || bad "repeat initialization failed"
if [[ "$(cat "$REPO/.docs/architecture.md")" == "user content" ]]; then
    ok "existing architecture doc kept"
else
    bad "existing architecture doc was modified"
fi
if [[ "$(cat "$REPO/AGENTS.md")" == "project-specific entry" ]]; then
    ok "existing AI entry kept"
else
    bad "existing AI entry was modified"
fi
if [[ "$(cat "$REPO/.docs/plans/manual/notes.md")" == "user plan" ]]; then
    ok "existing user task records kept"
else
    bad "existing user task records were modified"
fi
rm -rf "$REPO"

echo ""
echo "Result: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
