#!/usr/bin/env bash
# detect_project_type.sh - detects the project type (service / library / cli / monorepo)
#
# Usage:
#   cd <REPO_ROOT> && bash <SKILL_DIR>/scripts/detect_project_type.sh
#
# Outputs one line: PROJECT_TYPE=<type>
# Supports Go / JS/TS / Python projects. Defaults to service if unrecognized.

set -euo pipefail

PROJECT_TYPE="service"  # default

# --- Go projects ---
if [ -f "go.mod" ]; then
  # check for an entry file: search for .go files containing func main() (any filename)
  # exclude demo/example/best-practice and other doc/sample dirs
  has_main=false
  main_files=$(grep -rl 'func main()' --include='*.go' . 2>/dev/null | grep -vE '(vendor/|best-practice/|/demo/|example|/test/)' || true)
  [ -n "$main_files" ] && has_main=true

  if [ "$has_main" = "false" ]; then
    PROJECT_TYPE="library"
  else
    # has an entry; distinguish service vs cli
    if grep -rlqE 'http\.(Handle|ListenAndServe)|gin\.|echo\.|rest\.|fiber\.|mux\.' --include='*.go' . 2>/dev/null; then
      PROJECT_TYPE="service"
    elif grep -rlqE 'cobra|urfave/cli' --include='*.go' . 2>/dev/null; then
      PROJECT_TYPE="cli"
    else
      PROJECT_TYPE="service"
    fi
  fi

  # monorepo detection: multiple go.mod (excluding demo/example/test subdirs)
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

  # dirname inference: name patterns override the code detection result
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

# --- JS/TS projects ---
elif [ -f "package.json" ]; then
  if [ -d "packages" ] || [ -f "lerna.json" ] || [ -f "pnpm-workspace.yaml" ]; then
    PROJECT_TYPE="monorepo"
  elif grep -qE '"(express|fastify|koa|next|nuxt|nest|react|vue)"' package.json 2>/dev/null; then
    PROJECT_TYPE="service"
  elif grep -qE '"bin"' package.json 2>/dev/null; then
    PROJECT_TYPE="cli"
  else
    # no bin and no server framework → library
    PROJECT_TYPE="library"
  fi

# --- Python projects ---
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  if grep -rlqE 'flask|django|fastapi|uvicorn|gunicorn' pyproject.toml setup.py requirements*.txt 2>/dev/null; then
    PROJECT_TYPE="service"
  elif grep -qE '\[project\.scripts\]|\[tool\.poetry\.scripts\]' pyproject.toml 2>/dev/null; then
    PROJECT_TYPE="cli"
  else
    PROJECT_TYPE="library"
  fi

# --- Java projects ---
elif [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  # has a main method → service/cli; otherwise library
  if grep -rlqE 'public static void main' --include='*.java' . 2>/dev/null; then
    PROJECT_TYPE="service"
  else
    PROJECT_TYPE="library"
  fi
fi

echo "PROJECT_TYPE=$PROJECT_TYPE"
