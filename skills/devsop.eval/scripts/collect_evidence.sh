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
         .harness/review.md \
         .harness/docs/architecture.md .harness/docs/relationship.md \
         .harness/docs/coding-style.md \
         .harness/docs/unittest/unittest.md .harness/docs/integration_test/integration_test.md \
         .harness/docs/code-review.md \
         .harness/docs/glossary.md .harness/docs/failures.md \
         .harness/docs/logging.md \
         .harness/docs/apis/index.md .harness/docs/apis/api-standards.md \
         .harness/docs/sqls/README.md .harness/docs/sqls/database.md \
         .harness/docs/devops/deployment.md .harness/docs/devops/development.md \
         .harness/docs/devops/env.md .harness/docs/devops/test-env-deploy.md \
         .harness/devsop_report.md .env.example Makefile lefthook.yml \
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
for d in .harness .harness/docs .harness/docs/apis .harness/docs/sqls \
         .harness/docs/unittest .harness/docs/integration_test .harness/docs/devops \
         .harness/plans .harness/plans/_template \
         .codebuddy/skills .codebuddy/rules \
         tests/integration test/integration tests/e2e \
         jenkins .jenkins .github/workflows docs; do
  [ -d "$d" ] && echo "EXISTS $d" || echo "MISSING $d"
done

echo ""
echo "=== GIT_RECENCY ==="
for f in $(find .harness -name '*.md' 2>/dev/null); do
  if [ -f "$f" ]; then
    ts=$(git log -1 --format='%cI' -- "$f" 2>/dev/null || echo 'NO_HISTORY')
    echo "$f: $ts"
  fi
done

echo ""
echo "=== HARNESS_ACTIVITY ==="
echo "commits_60d: $(git log --since='60 days ago' --oneline -- .harness/ 2>/dev/null | wc -l | tr -d ' ')"
echo "commits_90d_failures: $(git log --since='90 days ago' --oneline -- .harness/docs/failures.md 2>/dev/null | wc -l | tr -d ' ')"

echo ""
echo "=== SYMLINKS ==="
for link in CODEBUDDY.md CLAUDE.md; do
  if [ -L "$link" ]; then
    echo "SYMLINK $link -> $(readlink "$link")"
  elif [ -f "$link" ]; then
    echo "FILE_NOT_LINK $link"
  else
    echo "MISSING $link"
  fi
done

echo ""
echo "=== SKILLS ==="
skill_count=$( (ls .codebuddy/skills/*/SKILL.md 2>/dev/null || true) | wc -l | tr -d ' ')
echo "skill_count: $skill_count"

echo ""
echo "=== AI_MEMORY ==="
# CodeBuddy persistent memory and session transcripts live in the user-level dir,
# named with the project path slug (/ → -)
slug=$(pwd | sed 's|/|-|g; s/^-//')
proj_dir="$HOME/.codebuddy/projects/$slug"
if [ -d "$proj_dir/memory" ]; then
  mem_count=$(find "$proj_dir/memory" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  echo "memory_dir: EXISTS $proj_dir/memory ($mem_count md files)"
else
  echo "memory_dir: MISSING $proj_dir/memory"
fi
sessions_30d=$(find "$proj_dir" -maxdepth 1 -name '*.jsonl' -mtime -30 2>/dev/null | wc -l | tr -d ' ')
echo "session_transcripts_30d: ${sessions_30d:-0}"

echo ""
echo "=== PLANS ==="
task_count=$(find .harness/plans -mindepth 1 -maxdepth 1 -type d -not -name '_template' 2>/dev/null | wc -l | tr -d ' ')
echo "plan_task_dirs: $task_count"
template_files=$(ls .harness/plans/_template/ 2>/dev/null | wc -l | tr -d ' ')
echo "plan_template_files: $template_files"

echo ""
echo "=== PLANS_ACTIVITY ==="
# check the latest update of 00-overview.md under plans
latest_overview=$(find .harness/plans -name 00-overview.md -not -path '*/_template/*' \
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
  README.md .harness/docs/devops/development.md .harness/docs/devops/deployment.md AGENTS.md 2>/dev/null | head -5 || true)
if [ -n "$ci_urls" ]; then
  echo "ci_url_found: YES"
  echo "$ci_urls" | sed 's/^/  /'
else
  echo "ci_url_found: NO"
fi

# platform name only, no URL (PARTIAL signal)
ci_name_only=$(grep -ihE '\b(jenkins|github[ -]?actions|gitlab[ -]?ci|argo[ -]?cd|zhiyan|travis|circleci)\b' \
  README.md .harness/docs/devops/development.md .harness/docs/devops/deployment.md AGENTS.md 2>/dev/null | grep -vE 'https?://' | head -3 || true)
[ -n "$ci_name_only" ] && echo "ci_name_no_url: YES" || echo "ci_name_no_url: NO"

echo ""
echo "=== ISSUE_TRACKER ==="
# Generic issue-tracker URL traces (GitHub Issues / GitLab / Jira / TAPD / etc.)
tracker_urls=$(grep -ihE 'https?://[^ )]*(github\.com/[^ )]*/(issues|projects)|gitlab\.com/.*/-/issues|jira|tapd\.(cn|woa\.com|oa\.com)|linear)' \
  README.md AGENTS.md .harness/docs/devops/development.md .harness/docs/code-review.md 2>/dev/null | head -3 || true)
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
echo "commits: $(git log --oneline -- .harness/devsop_report.md 2>/dev/null | wc -l | tr -d ' ')"

echo ""
echo "=== LEGACY_HARNESS ==="
# old devsop.init artifact recognition (needs migration to the new .harness/ layout)
# ① legacy non-hidden harness/ dir (the new layout is .harness/)
if [ -d "harness" ]; then
  echo "LEGACY_DIR harness/ (non-hidden; the new layout should be .harness/)"
else
  echo "legacy_dir_harness: NONE"
fi
# ② legacy root ARCHITECTURE.md (the new layout moves it to .harness/docs/architecture.md)
if [ -f "ARCHITECTURE.md" ]; then
  echo "LEGACY_FILE ARCHITECTURE.md (root-level; the new layout should be .harness/docs/architecture.md)"
else
  echo "legacy_file_architecture_md: NONE"
fi
# ③ legacy doc names remaining (dependency-map.md / testing.md)
legacy_docs=""
for f in .harness/docs/dependency-map.md .harness/dependency-map.md harness/dependency-map.md \
         .harness/docs/testing.md .harness/testing.md harness/testing.md; do
  [ -f "$f" ] && legacy_docs="$legacy_docs $f"
done
if [ -n "$legacy_docs" ]; then
  echo "LEGACY_DOCS:$legacy_docs"
else
  echo "legacy_docs: NONE"
fi
# ④ legacy global plan.md remaining (the new layout forbids a global plan.md; task overviews sink into 00-overview.md)
if [ -f ".harness/plan.md" ] || [ -f "harness/plan.md" ]; then
  echo "LEGACY_FILE plan.md (the new layout forbids a global plan.md)"
else
  echo "legacy_plan_md: NONE"
fi

echo ""
echo "=== MEMORY_RULES ==="
# C1 evidence: commit / push conventions in AGENTS.md / .codebuddy/rules/ (servers have no .git/hooks; evaluate the memory files instead)
rule_files=$(ls .codebuddy/rules/*.md 2>/dev/null || true)
if [ -n "$rule_files" ]; then
  echo "$rule_files" | sed 's/^/rule_file: /'
else
  echo "rule_file: NONE"
fi
commit_hits=$(grep -inE 'commit' AGENTS.md .codebuddy/rules/*.md 2>/dev/null | head -8 || true)
if [ -n "$commit_hits" ]; then
  echo "commit_rule_hits: $(echo "$commit_hits" | wc -l | tr -d ' ') (showing <=8)"
  echo "$commit_hits" | sed 's/^/  /'
else
  echo "commit_rule_hits: 0"
fi
push_hits=$(grep -inE 'push|force-with-lease|MR|merge' AGENTS.md .codebuddy/rules/*.md 2>/dev/null | head -8 || true)
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
