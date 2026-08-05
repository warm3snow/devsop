#!/usr/bin/env bash
#
# extract_diff.sh — 只读抽取增量代码或全量代码（供子 Agent 审查隐私泄露）
#
# 用法:
#   extract_diff.sh <REPO_ROOT> <commitA> <commitB> [<path_filter>]
#
#   REPO_ROOT   : 目标 git 仓库根目录（绝对或相对均可，脚本内部用 git 解析）
#   commitA     : 区间起点 commit（不含）/ 分支 / tag / SHA
#                 全量模式关键字（任一即可，commitB 同理）：
#                   all / ALL / All / 全部 / *  （大小写不敏感）
#                 两参数均为关键字（或均空） → 全量扫描工作区所有 Go 源码
#   commitB     : 区间终点 commit（含）；全量模式同上
#   path_filter : 可选，限制到某子目录或文件
#                 增量模式传给 `git diff -- <path>`
#                 全量模式作为 find 过滤路径前缀
#
# 输出:
#   - 增量模式：git diff 文本（含 + 行、文件路径、hunk 行号上下文）
#   - 全量模式：伪 diff 格式（每文件 `+++ b/<path>` + `@@ -0,0 +1,N @@` + 每行 `+` 前缀），
#     行号即文件真实行号，子 Agent prompt 无需特殊处理。
#
# 约束（硬）:
#   - 只读。绝不执行 git add/commit/checkout/reset/clean 等写操作。
#   - 不写 $SKILL_DIR / $HOME / ~/.codebuddy / /tmp。
#   - 失败（非 git 仓库 / 非法 commit）→ 非 0 退出，原因打到 stderr。

set -euo pipefail

REPO_ROOT="${1:-}"
COMMIT_A="${2:-}"
COMMIT_B="${3:-}"
PATH_FILTER="${4:-}"

if [[ -z "$REPO_ROOT" ]]; then
  echo "用法: extract_diff.sh <REPO_ROOT> <commitA> <commitB> [<path_filter>]" >&2
  exit 2
fi

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "错误: REPO_ROOT 不是目录: $REPO_ROOT" >&2
  exit 3
fi

# 解析仓库根，校验确实是 git 仓库
GIT_ROOT="$(cd "$REPO_ROOT" && git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$GIT_ROOT" ]]; then
  echo "错误: 不是 git 仓库: $REPO_ROOT" >&2
  exit 4
fi

cd "$GIT_ROOT"

# 全量模式关键字检测（大小写不敏感）。commitA/commitB 任一为关键字 → 全量。
is_full_keyword() {
  local v="$1"
  local lv
  lv="$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]')"
  [[ -z "$v" || "$lv" == "all" || "$v" == "全部" || "$v" == "*" ]]
}

if is_full_keyword "$COMMIT_A" || is_full_keyword "$COMMIT_B"; then
  # ── 全量模式：扫描工作区所有 .go 源码（排除 vendor/ 测试桩等） ──
  # 用 git ls-files 保证只取 git 跟踪的文件（避免扫描产物/临时文件），且天然只读。

  # 收集 .go 文件，排除 vendor / 第三方 / 生成代码（_gen.go / *.pb.go / mock_）
  GO_FILES=()
  if [[ -n "$PATH_FILTER" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] && GO_FILES+=("$f")
    done < <(
      git ls-files -- "$PATH_FILTER" 2>/dev/null \
        | grep -E '\.go$' \
        | grep -vE '(^|/)(vendor/|third_party/|node_modules/)' \
        | grep -vE '\.pb\.go$|_gen\.go$|^mock_|/mocks/' || true
    )
  else
    while IFS= read -r f; do
      [[ -n "$f" ]] && GO_FILES+=("$f")
    done < <(
      git ls-files 2>/dev/null \
        | grep -E '\.go$' \
        | grep -vE '(^|/)(vendor/|third_party/|node_modules/)' \
        | grep -vE '\.pb\.go$|_gen\.go$|^mock_|/mocks/' || true
    )
  fi

  if [[ ${#GO_FILES[@]} -eq 0 ]]; then
    # 无 Go 文件：输出空（调用方按「无增量/无代码」处理）
    exit 0
  fi

  for f in "${GO_FILES[@]}"; do
    # 文件可能已被删除（git ls-files 仍列出）→ 跳过
    [[ -f "$f" ]] || continue
    # 行数
    local_lines=$(wc -l < "$f" | tr -d ' ')
    # 伪 diff 头
    echo "+++ b/$f"
    echo "@@ -0,0 +1,${local_lines} @@"
    # 每行加 + 前缀，保留原始内容（含空行）
    while IFS= read -r line || [[ -n "$line" ]]; do
      printf '+%s\n' "$line"
    done < "$f"
    echo
  done
  exit 0
fi

# ── 单 commit 模式：commitA 非空非全量关键字，commitB 为空/single/- → 扫该 commit 相对其父的变更 ──
is_single_keyword() {
  local v="$1"
  local lv
  lv="$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]')"
  [[ -z "$v" || "$lv" == "single" || "$v" == "-" ]]
}

# 单 commit 优先于增量判断（commitB 为 "-" 时不能当合法 commit 走增量）
if [[ -n "$COMMIT_A" ]] && ! is_full_keyword "$COMMIT_A" && is_single_keyword "$COMMIT_B"; then
  if ! git rev-parse --verify --quiet "$COMMIT_A^{commit}" >/dev/null 2>&1; then
    echo "错误: 非法或不存在的 commit: $COMMIT_A" >&2
    exit 5
  fi
  # 该 commit 无父（根 commit）→ 对比空 tree（git diff 不支持 --root，用空 tree hash）
  if git rev-parse --verify --quiet "$COMMIT_A^" >/dev/null 2>&1; then
    PARENT="$COMMIT_A^"
  else
    PARENT="4b825dc642cb6eb9a060e54bf8d69288fbee4904"
  fi
  DIFF_CMD=(git diff --no-color --unified=3 "$PARENT" "$COMMIT_A")
  if [[ -n "$PATH_FILTER" ]]; then
    DIFF_CMD+=(-- "$PATH_FILTER")
  fi
  "${DIFF_CMD[@]}"
  exit 0
fi

# ── 增量模式：两参数都必须是合法 commit ──
if [[ -z "$COMMIT_A" || -z "$COMMIT_B" ]]; then
  echo "错误: 需要 commitA 与 commitB（增量）；单 commit 传 <commit> -；全量传 all all" >&2
  exit 2
fi

if ! git rev-parse --verify --quiet "$COMMIT_A^{commit}" >/dev/null 2>&1; then
  echo "错误: 非法或不存在的 commitA: $COMMIT_A" >&2
  exit 5
fi
if ! git rev-parse --verify --quiet "$COMMIT_B^{commit}" >/dev/null 2>&1; then
  echo "错误: 非法或不存在的 commitB: $COMMIT_B" >&2
  exit 6
fi

# 抽取区间 diff（unified=3 保留行号上下文）。
# 注意：用 $COMMIT_A $COMMIT_B（非三点 ..），表示 B 相对 A 的变更。
# 若 commitA == commitB，git diff 为空（无增量），由调用方处理空输出。
DIFF_CMD=(git diff --no-color --unified=3 "$COMMIT_A" "$COMMIT_B")
if [[ -n "$PATH_FILTER" ]]; then
  DIFF_CMD+=(-- "$PATH_FILTER")
fi

"${DIFF_CMD[@]}"
