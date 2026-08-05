#!/usr/bin/env bash
# collect_evidence.sh - 收集项目公共证据供 sop.eval 子 Agent 使用
#
# 用法：
#   cd <REPO_ROOT> && bash <SKILL_DIR>/scripts/collect_evidence.sh
#
# 输出结构化文本到 stdout，主 Agent 注入子 Agent prompt。
# 设计目标：一次收集，多次复用，避免 6 个子 Agent 重复 IO。

set -u
# 注：不启用 -e/-o pipefail。本脚本为只读探测，目标是「尽量收集到的全列出」，
# 单段失败不应中止整个 evidence cache 收集。每段命令自己用 || true 兜底。

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
         .harness/sop_report.md .env.example Makefile lefthook.yml \
         .golangci.yml .golangci.yaml \
         .pre-commit-config.yaml .gitignore \
         Jenkinsfile Jenkinsfile.ci Jenkinsfile.cd; do
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
# CodeBuddy 持久化记忆与会话转录在用户级目录，目录名为项目路径 slug（/ 转 -）
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
# 检查 plans 下 00-overview.md 的最近更新
latest_overview=$(find .harness/plans -name 00-overview.md -not -path '*/_template/*' \
  -exec git log -1 --format='%cI' {} \; 2>/dev/null | sort -r | head -1)
echo "latest_00-overview_update: ${latest_overview:-NONE}"

echo "=== CI_PLATFORM ==="
# 路径 ①：Jenkinsfile 入库
jenkins_files=$( (ls Jenkinsfile Jenkinsfile.* 2>/dev/null || true) | tr '\n' ' ')
echo "jenkinsfile: ${jenkins_files:-NONE}"
echo "jenkins_dir: $( { [ -d jenkins ] || [ -d .jenkins ]; } && echo YES || echo NO)"

# 路径 ②：README/development.md 含 CI 平台 URL（Jenkins / Argo CD / 智研）
ci_urls=$(grep -ihE 'https?://[^ )]*(jenkins|argocd|argo-cd|zhiyan|智研)' \
  README.md .harness/docs/devops/development.md .harness/docs/devops/deployment.md AGENTS.md 2>/dev/null | head -5 || true)
if [ -n "$ci_urls" ]; then
  echo "ci_url_found: YES"
  echo "$ci_urls" | sed 's/^/  /'
else
  echo "ci_url_found: NO"
fi

# 仅提平台名无 URL（PARTIAL 信号）
ci_name_only=$(grep -ihE '\b(jenkins|argo[ -]?cd|智研)\b' \
  README.md .harness/docs/devops/development.md .harness/docs/devops/deployment.md AGENTS.md 2>/dev/null | grep -vE 'https?://' | head -3 || true)
[ -n "$ci_name_only" ] && echo "ci_name_no_url: YES" || echo "ci_name_no_url: NO"

echo ""
echo "=== ISSUE_TRACKER ==="
# Tapd URL 痕迹（团队默认 issue tracker）
tapd_urls=$(grep -ihE 'https?://[^ )]*tapd\.(cn|woa\.com|oa\.com)' \
  README.md AGENTS.md .harness/docs/devops/development.md .harness/docs/code-review.md 2>/dev/null | head -3 || true)
if [ -n "$tapd_urls" ]; then
  echo "tapd_url_found: YES"
  echo "$tapd_urls" | sed 's/^/  /'
else
  echo "tapd_url_found: NO"
fi

# commit message 引用 Tapd 单号
tapd_commits=$(git log --since='90 days ago' --pretty=%s 2>/dev/null | grep -cE -- '--(story|bug)=[0-9]+' || true)
echo "tapd_commit_refs_90d: ${tapd_commits:-0}"

# 禁用 tracker 痕迹（命中即反模式）
forbidden_trackers=$(grep -ihE '\b(jira|linear)\b|github\.com/[^ )]+/issues' \
  README.md AGENTS.md .harness/**/*.md 2>/dev/null | head -3 || true)
if [ -n "$forbidden_trackers" ]; then
  echo "forbidden_trackers_found: YES"
  echo "$forbidden_trackers" | sed 's/^/  /'
else
  echo "forbidden_trackers_found: NO"
fi

echo ""
echo "=== SOP_REPORT_HISTORY ==="
echo "commits: $(git log --oneline -- .harness/sop_report.md 2>/dev/null | wc -l | tr -d ' ')"

echo ""
echo "=== LEGACY_HARNESS ==="
# 旧版 sop.init 产物识别（需迁移到新版 .harness/ 布局）
# ① 旧版非隐藏 harness/ 目录（新版为 .harness/）
if [ -d "harness" ]; then
  echo "LEGACY_DIR harness/ (非隐藏，新版应为 .harness/)"
else
  echo "legacy_dir_harness: NONE"
fi
# ② 旧版根目录 ARCHITECTURE.md（新版迁入 .harness/docs/architecture.md）
if [ -f "ARCHITECTURE.md" ]; then
  echo "LEGACY_FILE ARCHITECTURE.md (根目录，新版应为 .harness/docs/architecture.md)"
else
  echo "legacy_file_architecture_md: NONE"
fi
# ③ 旧版文档名残留（dependency-map.md / testing.md）
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
# ④ 旧版全局 plan.md 残留（新版严禁全局 plan.md，任务总览下沉 00-overview.md）
if [ -f ".harness/plan.md" ] || [ -f "harness/plan.md" ]; then
  echo "LEGACY_FILE plan.md (新版严禁全局 plan.md)"
else
  echo "legacy_plan_md: NONE"
fi

echo ""
echo "=== MEMORY_RULES ==="
# C1 证据：AGENTS.md / .codebuddy/rules/ 中的 commit / push 规范（服务器无 .git/hooks，改评记忆文件）
rule_files=$(ls .codebuddy/rules/*.md 2>/dev/null || true)
if [ -n "$rule_files" ]; then
  echo "$rule_files" | sed 's/^/rule_file: /'
else
  echo "rule_file: NONE"
fi
commit_hits=$(grep -inE 'commit|提交' AGENTS.md .codebuddy/rules/*.md 2>/dev/null | head -8 || true)
if [ -n "$commit_hits" ]; then
  echo "commit_rule_hits: $(echo "$commit_hits" | wc -l | tr -d ' ') (showing <=8)"
  echo "$commit_hits" | sed 's/^/  /'
else
  echo "commit_rule_hits: 0"
fi
push_hits=$(grep -inE 'push|推送|force-with-lease|MR|合并' AGENTS.md .codebuddy/rules/*.md 2>/dev/null | head -8 || true)
if [ -n "$push_hits" ]; then
  echo "push_rule_hits: $(echo "$push_hits" | wc -l | tr -d ' ') (showing <=8)"
  echo "$push_hits" | sed 's/^/  /'
else
  echo "push_rule_hits: 0"
fi

echo ""
echo "=== GOLANGCI_GOSEC ==="
# C6 证据：Go 项目安全扫描主路径——.golangci.yml 启用 gosec
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
