#!/usr/bin/env bash
# detect_project_type.sh - 探测项目类型（service / library / cli / monorepo）
#
# 用法：
#   cd <REPO_ROOT> && bash <SKILL_DIR>/scripts/detect_project_type.sh
#
# 输出一行：PROJECT_TYPE=<type>
# 支持 Go / JS/TS / Python 项目。未识别默认为 service。

set -euo pipefail

PROJECT_TYPE="service"  # 默认

# --- Go 项目 ---
if [ -f "go.mod" ]; then
  # 检查是否有入口文件：搜索包含 func main() 的 .go 文件（不限文件名）
  # 排除 demo/example/best-practice 等文档/示例目录
  has_main=false
  main_files=$(grep -rl 'func main()' --include='*.go' . 2>/dev/null | grep -vE '(vendor/|best-practice/|/demo/|example|/test/)' || true)
  [ -n "$main_files" ] && has_main=true

  if [ "$has_main" = "false" ]; then
    PROJECT_TYPE="library"
  else
    # 有入口，区分 service vs cli
    if grep -rlqE 'http\.(Handle|ListenAndServe)|gin\.|echo\.|rest\.|fiber\.|mux\.' --include='*.go' . 2>/dev/null; then
      PROJECT_TYPE="service"
    elif grep -rlqE 'cobra|urfave/cli' --include='*.go' . 2>/dev/null; then
      PROJECT_TYPE="cli"
    else
      PROJECT_TYPE="service"
    fi
  fi

  # monorepo 检测：多个 go.mod（排除 demo/example/test 子目录）
  gomod_count=$(find . -name 'go.mod' \
    -not -path './vendor/*' \
    -not -path './best-practice/*' \
    -not -path '*/demo/*' \
    -not -path '*/example/*' \
    -not -path '*/examples/*' \
    -not -path '*/issueexample/*' \
    -not -path '*/test/*' \
    2>/dev/null | wc -l | tr -d ' ')
  if [ "$gomod_count" -gt 1 ]; then
    PROJECT_TYPE="monorepo"
  fi

  # 目录名推断：名字模式覆盖代码探测结果
  dirname=$(basename "$(pwd)")
  if echo "$dirname" | grep -qiE '(sdk|core|library|lib)'; then
    PROJECT_TYPE="library"
  elif echo "$dirname" | grep -qiE '(front|frontend|web|ui|admin)'; then
    PROJECT_TYPE="service"
  elif echo "$dirname" | grep -qiE '(backend|service|server|gateway|api)'; then
    PROJECT_TYPE="service"
  elif echo "$dirname" | grep -qiE '(cli|ctl)$'; then
    PROJECT_TYPE="cli"
  fi

# --- JS/TS 项目 ---
elif [ -f "package.json" ]; then
  if [ -d "packages" ] || [ -f "lerna.json" ] || [ -f "pnpm-workspace.yaml" ]; then
    PROJECT_TYPE="monorepo"
  elif grep -qE '"(express|fastify|koa|next|nuxt|nest|react|vue)"' package.json 2>/dev/null; then
    PROJECT_TYPE="service"
  elif grep -qE '"bin"' package.json 2>/dev/null; then
    PROJECT_TYPE="cli"
  else
    # 无 bin 无 server 框架 → library
    PROJECT_TYPE="library"
  fi

# --- Python 项目 ---
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  if grep -rlqE 'flask|django|fastapi|uvicorn|gunicorn' pyproject.toml setup.py requirements*.txt 2>/dev/null; then
    PROJECT_TYPE="service"
  elif grep -qE '\[project\.scripts\]|\[tool\.poetry\.scripts\]' pyproject.toml 2>/dev/null; then
    PROJECT_TYPE="cli"
  else
    PROJECT_TYPE="library"
  fi

# --- Java 项目 ---
elif [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  # 有 main 方法 → service/cli；否则 library
  if grep -rlqE 'public static void main' --include='*.java' . 2>/dev/null; then
    PROJECT_TYPE="service"
  else
    PROJECT_TYPE="library"
  fi
fi

echo "PROJECT_TYPE=$PROJECT_TYPE"
