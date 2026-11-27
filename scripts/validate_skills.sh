#!/usr/bin/env bash
# validate_skills.sh — Validate the skills library against the Agent Skills
# specification (agentskills.io) + the repo's own conventions.
#
# Checks per skill:
#   1. SKILL.md exists + YAML frontmatter (name + description required)
#   2. name matches the skill's directory name (spec requirement)
#   3. name is lowercase-hyphen (≤64 chars); legacy dotted names (devsop.*) → warning
#   4. SKILL.md body ≤ 300 lines (repo target) / ≤ 500 (official hard limit)
#   5. references stay one level deep (no references/ → references/ nesting)
#   6. shipped .sh / .py scripts pass syntax checks (no __pycache__ left behind)
#
# Cross-skill contract checks:
#   7. no stale artifact names (user-stories.md / test-cases.md) in skill docs
#   8. delivery-stage skills reference only canonical artifacts
#      (plan / tasks / progress / test-report / ship .md)
#   9. each canonical artifact is referenced by its owning/producing skill
#  10. devsop-flow's stage map covers all six delivery stages
#  11. every backticked devsop-* skill reference in a SKILL.md exists under skills/
#
# Usage:
#   bash scripts/validate_skills.sh            # summary + violations only
#   bash scripts/validate_skills.sh -v         # per-skill detail lines
#   bash scripts/validate_skills.sh --json     # machine-readable result (CI)
#   bash scripts/validate_skills.sh --strict   # warnings also fail
#   bash scripts/validate_skills.sh [dir] ...  # validate a specific skills dir
#
# Exit: 0 = no failures (warnings allowed unless --strict); 1 = failures found.

set -u
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; RESET='\033[0m'

VERBOSE=0; JSON=0; STRICT=0
SKILLS_ROOT=""
for arg in "$@"; do
  case "$arg" in
    -v|--verbose) VERBOSE=1 ;;
    --json)       JSON=1 ;;
    --strict)     STRICT=1 ;;
    -h|--help)    sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)           echo "Unknown option: $arg (see -h)" >&2; exit 2 ;;
    *)            SKILLS_ROOT="$arg" ;;
  esac
done

[ -n "$SKILLS_ROOT" ] || SKILLS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/skills"

FAILS=0; WARNS=0; TOTAL=0
FAILS_JSON=""; WARNS_JSON=""

detail() { if [ "$VERBOSE" -eq 1 ]; then echo -e "  ${CYAN}·${RESET} $*"; fi; return 0; }
warn()   { WARNS=$((WARNS+1)); [ "$JSON" -eq 0 ] && echo -e "${YELLOW}[WARN]${RESET} $*"; WARNS_JSON="${WARNS_JSON}${WARNS_JSON:+,}\"$*\""; }
fail()   { FAILS=$((FAILS+1)); [ "$JSON" -eq 0 ] && echo -e "${RED}[FAIL]${RESET} $*"; FAILS_JSON="${FAILS_JSON}${FAILS_JSON:+,}\"$*\""; }

for skill_dir in "$SKILLS_ROOT"/*/; do
  [ -d "$skill_dir" ] || continue
  skill="$(basename "$skill_dir")"
  skill_file="$skill_dir/SKILL.md"

  # Only dirs with a SKILL.md at their root count as skills (assets/*/SKILL.md.tmpl are templates)
  [ -f "$skill_file" ] || continue
  TOTAL=$((TOTAL+1))

  # 1. frontmatter
  head -1 "$skill_file" | grep -q '^---$' || { fail "$skill: missing YAML frontmatter (must start with ---)"; continue; }
  name="$(awk '/^name:/{sub(/^name:[[:space:]]*/, ""); sub(/^"/, ""); sub(/"$/, ""); print; exit}' "$skill_file")"
  desc="$(awk '/^description:/{print; exit}' "$skill_file")"
  [ -n "$name" ] || fail "$skill: frontmatter 'name' missing"
  [ -n "$desc" ] || fail "$skill: frontmatter 'description' missing"

  # 2. name == directory name (agentskills spec: required)
  if [ -n "$name" ] && [ "$name" != "$skill" ]; then
    fail "$skill: frontmatter name '$name' does not match directory name '$skill'"
  fi

  # 3. name format: lowercase-hyphen, ≤64 chars (dots → legacy warning)
  if [[ "$name" =~ ^[a-z0-9][a-z0-9.-]{0,62}[a-z0-9]$ && "$name" != *..* ]]; then
    if [[ "$name" == *.* ]]; then
      warn "$skill: name '$name' contains a dot (spec allows only [a-z0-9-]; legacy names pending rename)"
    else
      detail "$skill: name '$name' valid"
    fi
  else
    fail "$skill: name '$name' violates lowercase-hyphen rule"
  fi

  # 4. body length
  lines=$(wc -l < "$skill_file" | tr -d ' ')
  if [ "$lines" -le 300 ]; then
    detail "$skill: SKILL.md $lines lines (excellent)"
  elif [ "$lines" -le 500 ]; then
    warn "$skill: SKILL.md $lines lines (repo target ≤300; official limit 500)"
  else
    fail "$skill: SKILL.md $lines lines exceeds the 500-line hard limit"
  fi

  # 5. references stay one level deep (SKILL_DIR-injected absolute paths excluded)
  nested=0
  for ref in "$skill_dir"/references/*.md; do
    [ -f "$ref" ] || continue
    if grep -qE 'references/[a-z0-9._-]+\.md' "$ref" \
       && grep -qE 'references/[a-z0-9._-]+\.md' <(grep -vE 'SKILL_DIR' "$ref"); then
      nested=$((nested+1))
    fi
  done
  [ "$nested" -eq 0 ] && detail "$skill: references one level deep" \
    || warn "$skill: $nested references file(s) nest other references"

  # 6. script syntax (ast.parse instead of py_compile → no __pycache__ left behind)
  for sh in "$skill_dir"/scripts/*.sh; do
    [ -f "$sh" ] || continue
    bash -n "$sh" 2>/dev/null && detail "$skill: $(basename "$sh") syntax OK" \
      || fail "$skill: $(basename "$sh") bash syntax error"
  done
  for py in "$skill_dir"/scripts/*.py; do
    [ -f "$py" ] || continue
    python3 -c 'import ast,sys; ast.parse(open(sys.argv[1]).read())' "$py" 2>/dev/null \
      && detail "$skill: $(basename "$py") syntax OK" \
      || fail "$skill: $(basename "$py") python syntax error"
  done
done

# ── Cross-skill contract checks (delivery pipeline) ─────────────

# 7. stale artifact names must not reappear anywhere in skill docs
while IFS= read -r hit; do
  fail "contract: stale artifact name in ${hit#$SKILLS_ROOT/} — plans use plan.md scenarios"
done < <(grep -rlE --include='*.md' --include='*.tmpl' 'user-stories\.md|test-cases\.md' "$SKILLS_ROOT" 2>/dev/null)

# 8. delivery-stage skills reference only canonical artifacts
CANONICAL_MD="plan.md tasks.md progress.md test-report.md ship.md SKILL.md AGENTS.md README.md"
for stage in devsop-plan devsop-design devsop-code devsop-test devsop-ship devsop-flow; do
  stage_file="$SKILLS_ROOT/$stage/SKILL.md"
  [ -f "$stage_file" ] || continue
  for tok in $(grep -oE '[A-Za-z0-9_.-]+\.md' "$stage_file" | sort -u); do
    case " $CANONICAL_MD " in
      *" $tok "*) ;;
      *) fail "contract: $stage references non-canonical artifact '$tok' (canonical: $CANONICAL_MD)" ;;
    esac
  done
done

# 9. each canonical artifact is referenced by the skill that owns/produces it
requires() { # artifact skill [skill ...]
  artifact="$1"; shift
  for owner in "$@"; do
    grep -q "$artifact" "$SKILLS_ROOT/$owner/SKILL.md" 2>/dev/null \
      || fail "contract: $owner does not reference its artifact '$artifact'"
  done
}
requires plan.md devsop-plan devsop-design devsop-code devsop-test
requires tasks.md devsop-design devsop-code
requires progress.md devsop-code
requires test-report.md devsop-test devsop-ship
requires ship.md devsop-ship devsop-flow

# 10. devsop-flow's stage map covers all six delivery stages
flow_file="$SKILLS_ROOT/devsop-flow/SKILL.md"
if [ -f "$flow_file" ]; then
  for stage in devsop-init devsop-plan devsop-design devsop-code devsop-test devsop-ship; do
    grep -q "$stage" "$flow_file" \
      || fail "contract: devsop-flow stage map is missing '$stage'"
  done
fi

# 11. every backticked devsop-* skill reference in a SKILL.md exists under skills/
for name in $(grep -hoE '`devsop-[a-z0-9-]+`' "$SKILLS_ROOT"/*/SKILL.md 2>/dev/null | sed 's/^`//; s/`$//' | sort -u); do
  [ -d "$SKILLS_ROOT/$name" ] \
    || fail "contract: referenced skill '$name' has no skills/$name/ directory"
done

[ "$TOTAL" -eq 0 ] && { fail "no skills found under $SKILLS_ROOT"; }

# ── Result ──────────────────────────────────────────────────────
# ok = no failures AND (not strict OR no warnings)
OK=true
[ "$FAILS" -gt 0 ] && OK=false
{ [ "$STRICT" -eq 1 ] && [ "$WARNS" -gt 0 ]; } && OK=false

if [ "$JSON" -eq 1 ]; then
  echo "{\"skills\": $TOTAL, \"failures\": $FAILS, \"warnings\": $WARNS, \"ok\": $OK, \"failure_items\": [${FAILS_JSON}], \"warning_items\": [${WARNS_JSON}]}"
else
  echo ""
  if [ "$OK" == "true" ]; then
    printf "${GREEN}Validated %d skill(s): all checks passed.${RESET}\n" "$TOTAL"
  else
    printf "${RED}Validated %d skill(s): %d failure(s), %d warning(s).${RESET}\n" "$TOTAL" "$FAILS" "$WARNS"
  fi
fi

[ "$OK" == "true" ] || exit 1
