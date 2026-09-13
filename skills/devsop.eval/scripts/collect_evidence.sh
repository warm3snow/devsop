#!/usr/bin/env bash
# collect_evidence.sh - collects shared project evidence for devsop.eval sub-agents
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

echo "=== FILE_EXISTS ==="
for f in AGENTS.md README.md \
         .docs/review.md \
         .docs/architecture.md .docs/relationship.md \
         .docs/coding-style.md \
         .docs/unittest/unittest.md .docs/integration_test/integration_test.md \
         .docs/code-review.md \
         .docs/glossary.md .docs/failures.md \
         .docs/logging.md \
         .docs/apis/index.md .docs/apis/api-standards.md \
         .docs/sqls/README.md .docs/sqls/database.md \
         .docs/devops/deployment.md .docs/devops/development.md \
         .docs/devops/env.md .docs/devops/test-env-deploy.md \
         .docs/devsop_report.md .env.example Makefile lefthook.yml \
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
for d in .docs .docs/apis .docs/sqls \
         .docs/unittest .docs/integration_test .docs/devops \
         .docs/plans .docs/plans/_template \
         .agents/skills .agents/memory rules \
         tests/integration test/integration tests/e2e \
         jenkins .jenkins .github/workflows docs; do
  [ -d "$d" ] && echo "EXISTS $d" || echo "MISSING $d"
done

echo ""
echo "=== GIT_RECENCY ==="
for f in $(find .docs -name '*.md' 2>/dev/null); do
  if [ -f "$f" ]; then
    ts=$(git log -1 --format='%cI' -- "$f" 2>/dev/null || echo 'NO_HISTORY')
    echo "$f: $ts"
  fi
done

echo ""
echo "=== DOCS_ACTIVITY ==="
echo "commits_60d: $(git log --since='60 days ago' --oneline -- .docs/ 2>/dev/null | wc -l | tr -d ' ')"
echo "commits_90d_failures: $(git log --since='90 days ago' --oneline -- .docs/failures.md 2>/dev/null | wc -l | tr -d ' ')"

echo ""
echo "=== AGENTS_ENTRY ==="
if [ -L "AGENTS.md" ] || [ -f "AGENTS.md" ]; then
  echo "AGENTS.md present"
else
  echo "AGENTS.md missing"
fi

echo ""
echo "=== SKILLS ==="
# Count SKILL.md files under the standard repo-local skills dir.
skill_count=$( (ls .agents/skills/*/SKILL.md 2>/dev/null || true) | wc -l | tr -d ' ')
echo "skill_count: $skill_count"

echo ""
echo "=== AI_MEMORY ==="
# Memory/session retention probe over the ~/.agents/ standard locations.
slug=$(pwd | sed 's|/|-|g; s/^-//')
for d in ".agents/memory" "$HOME/.agents/projects/$slug/memory"; do
  if [ -d "$d" ]; then
    mem_count=$(find "$d" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    echo "memory_dir: EXISTS $d ($mem_count md files)"
  else
    echo "memory_dir: MISSING $d"
  fi
done
sessions_30d=$( (find ".agents/sessions" -name '*.md' -o -name '*.jsonl' -mtime -30 2>/dev/null || true) | wc -l | tr -d ' ')
echo "session_transcripts_30d: ${sessions_30d:-0}"

echo ""
echo "=== PLANS ==="
task_count=$(find .docs/plans -mindepth 1 -maxdepth 1 -type d -not -name '_template' 2>/dev/null | wc -l | tr -d ' ')
echo "plan_task_dirs: $task_count"
template_files=$(ls .docs/plans/_template/ 2>/dev/null | wc -l | tr -d ' ')
echo "plan_template_files: $template_files"

echo ""
echo "=== PLANS_ACTIVITY ==="
# check the latest update of 00-overview.md under plans
latest_overview=$(find .docs/plans -name 00-overview.md -not -path '*/_template/*' \
  -exec git log -1 --format='%cI' {} \; 2>/dev/null | sort -r | head -1)
echo "latest_00-overview_update: ${latest_overview:-NONE}"

echo "=== CI_PLATFORM ==="
# Path ①: CI config checked in (any platform: Jenkinsfile / GitHub Actions / GitLab CI)
ci_files=$( (ls Jenkinsfile Jenkinsfile.* 2>/dev/null || true; ls .github/workflows/*.yml .gitlab-ci.yml 2>/dev/null || true) | tr '\n' ' ')
echo "ci_config_files: ${ci_files:-NONE}"
echo "jenkins_dir: $( { [ -d jenkins ] || [ -d .jenkins ]; } && echo YES || echo NO)"
echo "github_actions_dir: $( { [ -d .github/workflows ]; } && echo YES || echo NO)"

# Path ②: README/development.md contains CI platform URLs (any CI / deployment platform)
ci_urls=$(grep -ihE 'https?://[^ )]*(jenkins|argocd|argo-cd|github\.com/.*/(actions|workflows)|gitlab|travis|circleci|zhiyan)' \
  README.md .docs/devops/development.md .docs/devops/deployment.md AGENTS.md 2>/dev/null | head -5 || true)
if [ -n "$ci_urls" ]; then
  echo "ci_url_found: YES"
  echo "$ci_urls" | sed 's/^/  /'
else
  echo "ci_url_found: NO"
fi

# platform name only, no URL (PARTIAL signal)
ci_name_only=$(grep -ihE '\b(jenkins|github[ -]?actions|gitlab[ -]?ci|argo[ -]?cd|zhiyan|travis|circleci)\b' \
  README.md .docs/devops/development.md .docs/devops/deployment.md AGENTS.md 2>/dev/null | grep -vE 'https?://' | head -3 || true)
[ -n "$ci_name_only" ] && echo "ci_name_no_url: YES" || echo "ci_name_no_url: NO"

echo ""
echo "=== ISSUE_TRACKER ==="
# Generic issue-tracker URL traces (GitHub Issues / GitLab / Jira / TAPD / etc.)
tracker_urls=$(grep -ihE 'https?://[^ )]*(github\.com/[^ )]*/(issues|projects)|gitlab\.com/.*/-/issues|jira|tapd\.(cn|woa\.com|oa\.com)|linear)' \
  README.md AGENTS.md .docs/devops/development.md .docs/code-review.md 2>/dev/null | head -3 || true)
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
echo "commits: $(git log --oneline -- .docs/devsop_report.md 2>/dev/null | wc -l | tr -d ' ')"



echo ""
echo "=== MEMORY_RULES ==="
# C1 evidence: commit / push conventions in AGENTS.md / rules/ (servers have
# no .git/hooks; evaluate the memory files instead).
rule_files=$(ls rules/*.md 2>/dev/null || true)
if [ -n "$rule_files" ]; then
  echo "$rule_files" | sed 's/^/rule_file: /'
else
  echo "rule_file: NONE"
fi
commit_hits=$(grep -inE 'commit' AGENTS.md rules/*.md 2>/dev/null | head -8 || true)
if [ -n "$commit_hits" ]; then
  echo "commit_rule_hits: $(echo "$commit_hits" | wc -l | tr -d ' ') (showing <=8)"
  echo "$commit_hits" | sed 's/^/  /'
else
  echo "commit_rule_hits: 0"
fi
push_hits=$(grep -inE 'push|force-with-lease|MR|merge' AGENTS.md rules/*.md 2>/dev/null | head -8 || true)
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
