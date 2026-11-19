#!/usr/bin/env bash
# collect_evidence.sh - collects shared project evidence for devsop-eval sub-agents
#
# Usage:
#   cd <REPO_ROOT> && bash <SKILL_DIR>/scripts/collect_evidence.sh
#
# Outputs structured text to stdout; the main agent injects it into sub-agent prompts.
# Design goal: collect once, reuse many times, avoid duplicate IO by 6 sub-agents.

set -u
# Note: -e/-o pipefail are NOT enabled. This script is read-only probing; the goal is
# "list everything that could be collected". A single section failing should not abort
# the whole evidence cache collection. Each section's commands use || true as a fallback.

DOC_FILES=()
DOC_FOUND=false
while IFS= read -r f; do
  DOC_FILES+=("$f")
  DOC_FOUND=true
done < <(find . \
  \( -type d \( -name .git -o -name node_modules -o -name vendor -o -name .venv -o -name dist -o -name build -o -name target \) -prune \) -o \
  \( -type f \( -name '*.md' -o -name '*.mdx' -o -name '*.rst' -o -name '*.adoc' -o -name '*.asciidoc' \) -print \))
if [ "$DOC_FOUND" = false ]; then
  DOC_FILES+=(/dev/null)
fi

GUIDANCE_FILES=()
GUIDANCE_FOUND=false
echo "=== DOCUMENTATION_INVENTORY ==="
for f in "${DOC_FILES[@]}"; do
  [ "$f" = /dev/null ] && continue
  case "$f" in
    *devsop_report.md|*devsop_improvements.md|*devsop_changelog.md) continue ;;
  esac
  GUIDANCE_FILES+=("$f")
  GUIDANCE_FOUND=true
  lines=$(wc -l < "$f")
  echo "DOC $f ($lines lines)"
  grep -m 12 -E '^#{1,6}[[:space:]]' "$f" 2>/dev/null | sed 's/^/  /' || true
done
if [ "$GUIDANCE_FOUND" = false ]; then
  GUIDANCE_FILES+=(/dev/null)
fi

echo ""
echo "=== STANDARD_FILE_EXISTS ==="
for f in AGENTS.md README.md CONTRIBUTING.md .env.example Makefile lefthook.yml \
         .golangci.yml .golangci.yaml \
         .pre-commit-config.yaml .gitignore \
         Jenkinsfile Jenkinsfile.ci Jenkinsfile.cd \
         .github/workflows/ci.yml .gitlab-ci.yml; do
  if [ -f "$f" ]; then
    lines=$(wc -l < "$f")
    echo "EXISTS $f ($lines lines)"
  else
    echo "MISSING $f"
  fi
done

echo ""
echo "=== DIR_EXISTS ==="
# Agent-agnostic scan: the ~/.agents/ standard dirs only.
for d in docs .docs rules \
         tests/integration test/integration tests/e2e \
         jenkins .jenkins .github/workflows docs; do
  [ -d "$d" ] && echo "EXISTS $d" || echo "MISSING $d"
done

echo ""
echo "=== GIT_RECENCY ==="
for f in "${GUIDANCE_FILES[@]}"; do
  [ "$f" = /dev/null ] && continue
  ts=$(git log -1 --format='%cI' -- "$f" 2>/dev/null || echo 'NO_HISTORY')
  echo "$f: $ts"
done

echo ""
echo "=== DOCS_ACTIVITY ==="
echo "guidance_commits_60d: $(git log --since='60 days ago' --oneline -- "${GUIDANCE_FILES[@]}" 2>/dev/null | wc -l | tr -d ' ')"

echo ""
echo "=== AGENTS_ENTRY ==="
if [ -L "AGENTS.md" ] || [ -f "AGENTS.md" ]; then
  echo "AGENTS.md present"
else
  echo "AGENTS.md missing"
fi

echo "=== CI_PLATFORM ==="
# Path ①: CI config checked in (any platform: Jenkinsfile / GitHub Actions / GitLab CI)
ci_files=$( (ls Jenkinsfile Jenkinsfile.* 2>/dev/null || true; ls .github/workflows/*.yml .gitlab-ci.yml 2>/dev/null || true) | tr '\n' ' ')
echo "ci_config_files: ${ci_files:-NONE}"
echo "jenkins_dir: $( { [ -d jenkins ] || [ -d .jenkins ]; } && echo YES || echo NO)"
echo "github_actions_dir: $( { [ -d .github/workflows ]; } && echo YES || echo NO)"

# Path ②: README/development.md contains CI platform URLs (any CI / deployment platform)
ci_urls=$(grep -ihE 'https?://[^ )]*(jenkins|argocd|argo-cd|github\.com/.*/(actions|workflows)|gitlab|travis|circleci|zhiyan)' \
  "${GUIDANCE_FILES[@]}" /dev/null 2>/dev/null | head -5 || true)
if [ -n "$ci_urls" ]; then
  echo "ci_url_found: YES"
  echo "$ci_urls" | sed 's/^/  /'
else
  echo "ci_url_found: NO"
fi

# platform name only, no URL (PARTIAL signal)
ci_name_only=$(grep -ihE '\b(jenkins|github[ -]?actions|gitlab[ -]?ci|argo[ -]?cd|zhiyan|travis|circleci)\b' \
  "${GUIDANCE_FILES[@]}" /dev/null 2>/dev/null | grep -vE 'https?://' | head -3 || true)
[ -n "$ci_name_only" ] && echo "ci_name_no_url: YES" || echo "ci_name_no_url: NO"

echo ""
echo "=== ISSUE_TRACKER ==="
# Generic issue-tracker URL traces (GitHub Issues / GitLab / Jira / TAPD / etc.)
tracker_urls=$(grep -ihE 'https?://[^ )]*(github\.com/[^ )]*/(issues|projects)|gitlab\.com/.*/-/issues|jira|tapd\.(cn|woa\.com|oa\.com)|linear)' \
  "${GUIDANCE_FILES[@]}" /dev/null 2>/dev/null | head -3 || true)
if [ -n "$tracker_urls" ]; then
  echo "issue_tracker_url_found: YES"
  echo "$tracker_urls" | sed 's/^/  /'
else
  echo "issue_tracker_url_found: NO"
fi

# commit messages referencing tickets (--story=/--bug= or GitHub-style #<id>)
ticket_commits=$(git log --since='90 days ago' --pretty=%s 2>/dev/null | grep -cE -- '--(story|bug|task|test|other)=[0-9]+|(^|[[:space:]])#[0-9]+' || true)
echo "ticket_commit_refs_90d: ${ticket_commits:-0}"

echo ""
echo "=== DEVSOP_REPORT_HISTORY ==="
report_file=$(find . \
  \( -type d \( -name .git -o -name node_modules -o -name vendor -o -name .venv \) -prune \) -o \
  \( -type f -name devsop_report.md -print -quit \)
)
if [ -n "$report_file" ]; then
  echo "report_path: $report_file"
  echo "commits: $(git log --oneline -- "$report_file" 2>/dev/null | wc -l | tr -d ' ')"
else
  echo "report_path: NONE"
  echo "commits: 0"
fi



echo ""
echo "=== COMMIT_PUSH_RULES ==="
# C1 evidence: commit / push conventions in version-controlled project guidance.
commit_hits=$(grep -inE 'commit' "${GUIDANCE_FILES[@]}" /dev/null 2>/dev/null | head -8 || true)
if [ -n "$commit_hits" ]; then
  echo "commit_rule_hits: $(echo "$commit_hits" | wc -l | tr -d ' ') (showing <=8)"
  echo "$commit_hits" | sed 's/^/  /'
else
  echo "commit_rule_hits: 0"
fi
push_hits=$(grep -inE 'push|force-with-lease|MR|merge' "${GUIDANCE_FILES[@]}" /dev/null 2>/dev/null | head -8 || true)
if [ -n "$push_hits" ]; then
  echo "push_rule_hits: $(echo "$push_hits" | wc -l | tr -d ' ') (showing <=8)"
  echo "$push_hits" | sed 's/^/  /'
else
  echo "push_rule_hits: 0"
fi

echo ""
echo "=== GOLANGCI_GOSEC ==="
# C6 evidence: Go project security-scan main path — gosec enabled in .golangci.yml
golangci_cfg=""
for f in .golangci.yml .golangci.yaml; do
  [ -f "$f" ] && golangci_cfg="$f" && break
done
if [ -n "$golangci_cfg" ]; then
  echo "golangci_config: EXISTS $golangci_cfg"
  if grep -A30 'enable:' "$golangci_cfg" 2>/dev/null | grep -qE '^\s*-\s*gosec'; then
    echo "gosec_in_enable: YES"
  else
    echo "gosec_in_enable: NO"
  fi
  if grep -A30 'disable:' "$golangci_cfg" 2>/dev/null | grep -qE '^\s*-\s*gosec'; then
    echo "gosec_in_disable: YES"
  else
    echo "gosec_in_disable: NO"
  fi
else
  echo "golangci_config: MISSING"
fi

echo ""
echo "=== DONE ==="
