#!/usr/bin/env bash
# test_init_harness_detect.sh —— init_harness.sh 的 --has-api / --has-db flag 黑盒测试。
#
# 用法：bash test_init_harness_detect.sh
# 退出码：0 = 全部通过；1 = 有用例失败。
#
# 覆盖用例（对应 02-plan.md §6）：
#   T1 不传 flag（兼容）        → apis/ + sqls/ 均生成
#   T2 --has-api=false          → apis/ 不生成；sqls/ 生成
#   T3 --has-db=false           → sqls/ 不生成；apis/ 生成
#   T4 双 false                 → apis//sqls/ 均不生成；其余骨架正常
#   T5 非法 flag 值             → 非 0 退出 + stderr 报错
#   T6 升级保留用户文件          → 已有 apis/index.md 不被删
#   T7 幂等                     → 同参数连跑两次结果一致

set -uo pipefail

# macOS bash 3.2 在 UTF-8 locale + set -u 下对多字节字符串中的变量展开有
# 误判 bug（"OUT: unbound variable" 误报），统一 C locale 规避。
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT="$SCRIPT_DIR/init_harness.sh"

PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); echo "  [PASS] $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  [FAIL] $1"; }

# assert_exists <path> <msg>
assert_exists() {
    if [[ -e "$1" ]]; then ok "$2"; else bad "$2（不存在：$1）"; fi
}
# assert_not_exists <path> <msg>
assert_not_exists() {
    if [[ ! -e "$1" ]]; then ok "$2"; else bad "$2（不应存在：$1）"; fi
}

new_repo() {
    local d
    d="$(mktemp -d)"
    # 最小骨架：git 仓库 + 一个文件，避免 hooks 安装报错（非 git 会静默跳过）
    echo "# test" > "$d/README.md"
    echo "$d"
}

echo "T1 不传 flag（向后兼容）"
R="$(new_repo)"
bash "$INIT" "$R" >/dev/null 2>&1
assert_exists     "$R/.harness/docs/apis/index.md"      "apis/ 已生成"
assert_exists     "$R/.harness/docs/sqls/database.md"   "sqls/ 已生成"
rm -rf "$R"

echo "T2 --has-api=false"
R="$(new_repo)"
bash "$INIT" "$R" --has-api=false >/dev/null 2>&1
assert_not_exists "$R/.harness/docs/apis"               "apis/ 未生成"
assert_exists     "$R/.harness/docs/sqls/database.md"   "sqls/ 已生成"
rm -rf "$R"

echo "T3 --has-db=false"
R="$(new_repo)"
bash "$INIT" "$R" --has-db=false >/dev/null 2>&1
assert_exists     "$R/.harness/docs/apis/index.md"      "apis/ 已生成"
assert_not_exists "$R/.harness/docs/sqls"               "sqls/ 未生成"
rm -rf "$R"

echo "T4 --has-api=false --has-db=false（双 false）"
R="$(new_repo)"
bash "$INIT" "$R" --has-api=false --has-db=false >/dev/null 2>&1
assert_not_exists "$R/.harness/docs/apis"               "apis/ 未生成"
assert_not_exists "$R/.harness/docs/sqls"               "sqls/ 未生成"
assert_exists     "$R/.harness/docs/unittest/unittest.md" "其余骨架正常（unittest）"
assert_exists     "$R/.harness/docs/devops/env.md"      "其余骨架正常（devops）"
rm -rf "$R"

echo "T5 非法 flag 值"
R="$(new_repo)"
OUT="$(bash "$INIT" "$R" --has-api=maybe 2>&1)"
RC=$?
if [[ $RC -ne 0 ]] && echo "$OUT" | grep -qi "has-api"; then
    ok "非 0 退出且报错（rc=$RC）"
else
    bad "非法值应非 0 退出并提示（rc=$RC）"
fi
assert_not_exists "$R/.harness" "失败后未写入任何文件"
rm -rf "$R"

echo "T6 升级模式保留用户已有文件"
R="$(new_repo)"
mkdir -p "$R/.harness/docs/apis"
echo "user content" > "$R/.harness/docs/apis/index.md"
bash "$INIT" "$R" --has-api=false >/dev/null 2>&1
if [[ "$(cat "$R/.harness/docs/apis/index.md")" == "user content" ]]; then
    ok "已有 apis/index.md 保留"
else
    bad "已有 apis/index.md 被改动"
fi
assert_exists "$R/.harness/docs/sqls/database.md" "sqls/ 正常补缺"
rm -rf "$R"

echo "T7 幂等（双 false 连跑两次）"
R="$(new_repo)"
bash "$INIT" "$R" --has-api=false --has-db=false >/dev/null 2>&1
bash "$INIT" "$R" --has-api=false --has-db=false >/dev/null 2>&1
RC=$?
[[ $RC -eq 0 ]] && ok "第二次运行退出码 0" || bad "第二次运行退出码 $RC"
assert_not_exists "$R/.harness/docs/apis" "两次后 apis/ 仍未生成"
assert_not_exists "$R/.harness/docs/sqls" "两次后 sqls/ 仍未生成"
rm -rf "$R"

echo ""
echo "════════════════════════════════"
echo "  结果：$PASS passed, $FAIL failed"
echo "════════════════════════════════"
[[ $FAIL -eq 0 ]]
