#!/usr/bin/env bash
# init_harness.sh —— SOP 初始化 / 升级脚本（幂等）。
#
# 用法：
#   bash init_harness.sh [repo_root] [--has-api=true|false] [--has-db=true|false]
#
#   --has-api   为 false 时跳过复制骨架 docs/apis/（缺省 true，向后兼容）
#   --has-db    为 false 时跳过复制骨架 docs/sqls/（缺省 true，向后兼容）
#   两个 flag 只影响「补缺复制」阶段；目标项目已存在的 apis//sqls/ 文件一律保留不删。
#
# 功能（全新项目初始化 + 老项目升级通用）：
#   1. 补缺：把 Skill 自带的 `.harness/` 骨架与 `plans/_template` 复制到目标仓库（已存在文件不覆盖）
#   2. 刷新契约性文件：00-overview / 05-deploy / 06-it / test-env-deploy（有差异则直接覆盖）
#   3. 智能合并 CODEBUDDY.md：刷新一二章（skill 管控），保留三四章（项目自定义）
#   4. 确保 CODEBUDDY.md / CLAUDE.md 软链 → AGENTS.md（双 Agent 入口：CodeBuddy + Claude Code）
#   5. 安装 clarify skill 到 .codebuddy/skills/clarify/（已存在则跳过）

set -euo pipefail

# ---------------------------------------------------------------------------
# 参数解析：首位置参数 = repo_root；--has-api/--has-db 为可选 flag（缺省 true）。
# 校验在任何写操作之前完成，非法输入直接 exit 2、不落任何文件。
# ---------------------------------------------------------------------------
REPO_ROOT=""
HAS_API=true
HAS_DB=true
for arg in "$@"; do
    case "$arg" in
        --has-api=*) HAS_API="${arg#--has-api=}" ;;
        --has-db=*)  HAS_DB="${arg#--has-db=}" ;;
        --*)
            echo "[ERROR] 未知参数：$arg（仅支持 --has-api= / --has-db=）" >&2
            exit 2
            ;;
        *)
            if [[ -z "$REPO_ROOT" ]]; then
                REPO_ROOT="$arg"
            else
                echo "[ERROR] 多余的位置参数：$arg" >&2
                exit 2
            fi
            ;;
    esac
done
REPO_ROOT="${REPO_ROOT:-$(pwd)}"

for pair in "has-api=$HAS_API" "has-db=$HAS_DB"; do
    name="${pair%%=*}"
    val="${pair#*=}"
    if [[ "$val" != "true" && "$val" != "false" ]]; then
        echo "[ERROR] --$name 只接受 true/false，收到：$val" >&2
        exit 2
    fi
done
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
SKELETON="$SKILL_DIR/assets/harness-skeleton"
TEMPLATE="$SKILL_DIR/assets/plans-template"
CLARIFY_SKILL_SRC="$SKILL_DIR/assets/clarify-skill"

if [[ ! -d "$SKELETON" ]]; then
    echo "[ERROR] 骨架目录不存在：$SKELETON" >&2
    exit 1
fi
if [[ ! -d "$TEMPLATE" ]]; then
    echo "[ERROR] 任务模板目录不存在：$TEMPLATE" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 旧版 harness/ 迁移（老版 sop.init → 新版 sop.init）
#
# 老版 sop.init 产出 `harness/`（非隐藏），
# 新版使用 `.harness/`（隐藏目录），路径不兼容。
# 检测到旧版 harness/ 时：
#   1. 将 harness/ 重命名为临时目录
#   2. 将旧版顶层文档（*.md、apis/、sqls/ 等）迁入 .harness/docs/
#   3. 保留 plans/、review.md 等顶层文件在 .harness/ 下
#   4. 后续升级流程在新骨架基础上补缺，不删除旧文件
# ---------------------------------------------------------------------------
if [[ -d "$REPO_ROOT/harness" ]]; then
    echo "[MIGRATE] 检测到旧版 harness/ 目录，准备迁移到 .harness/"

    # 创建 .harness/ 并建立 docs/ 子目录
    mkdir -p "$REPO_ROOT/.harness/docs"

    # 将旧版 harness/ 顶层属于文档的文件/目录移入 .harness/docs/
    # 文档类型：*.md（除 review.md / plan.md 等顶层保留文件）、apis/、sqls/、
    #          unittest/、integration_test/、devops/
    # 顶层保留：review.md、plans/ 等非文档型目录
    for item in "$REPO_ROOT/harness"/*; do
        if [[ ! -e "$item" ]]; then
            continue
        fi
        item_name="$(basename "$item")"
        case "$item_name" in
            review.md|plans)
                # 顶层保留文件/目录 → 移到 .harness/ 顶层
                mv "$item" "$REPO_ROOT/.harness/"
                echo "[MIGRATE] 保留顶层：$item_name → .harness/$item_name"
                ;;
            plan.md|README.md)
                # 旧版弃用文件（新版骨架无对应位置，无子 Agent 消化）→ 直接删除
                rm -f "$item"
                echo "[MIGRATE] 删除旧版弃用文件：$item_name"
                ;;
            development.md|env.md|deployment.md|test-env-deploy.md)
                # devops 类文档 → 归置到 .harness/docs/devops/
                mkdir -p "$REPO_ROOT/.harness/docs/devops"
                mv "$item" "$REPO_ROOT/.harness/docs/devops/"
                echo "[MIGRATE] devops 文档迁移：$item_name → .harness/docs/devops/$item_name"
                ;;
            api-standards.md)
                # 接口规范 → 归置到 .harness/docs/apis/
                mkdir -p "$REPO_ROOT/.harness/docs/apis"
                mv "$item" "$REPO_ROOT/.harness/docs/apis/"
                echo "[MIGRATE] apis 文档迁移：$item_name → .harness/docs/apis/$item_name"
                ;;
            database.md)
                # 数据/Schema 规范 → 归置到 .harness/docs/sqls/
                mkdir -p "$REPO_ROOT/.harness/docs/sqls"
                mv "$item" "$REPO_ROOT/.harness/docs/sqls/"
                echo "[MIGRATE] sqls 文档迁移：$item_name → .harness/docs/sqls/$item_name"
                ;;
            *)
                # 文档型 → 移入 .harness/docs/
                mv "$item" "$REPO_ROOT/.harness/docs/"
                echo "[MIGRATE] 文档迁移：$item_name → .harness/docs/$item_name"
                ;;
        esac
    done

    # 删除已空的旧 harness/ 目录
    rmdir "$REPO_ROOT/harness" 2>/dev/null || true
    echo "[MIGRATE] harness/ → .harness/ 迁移完成"
    echo "         旧版文档已迁入 .harness/docs/，顶层保留文件已迁入 .harness/ 顶层"
else
    echo "[MIGRATE] 无旧版 harness/，跳过迁移"
fi

# ---------------------------------------------------------------------------
# 根目录旧版 ARCHITECTURE.md 迁移
#
# 老版 sop.init 在仓库根生成 ARCHITECTURE.md，新版要求放在 .harness/docs/。
# 检测到根目录 ARCHITECTURE.md 时移到 .harness/docs/architecture.md。
# ---------------------------------------------------------------------------
mkdir -p "$REPO_ROOT/.harness/docs"
if [[ -f "$REPO_ROOT/ARCHITECTURE.md" ]]; then
    if [[ ! -e "$REPO_ROOT/.harness/docs/architecture.md" ]]; then
        mv "$REPO_ROOT/ARCHITECTURE.md" "$REPO_ROOT/.harness/docs/architecture.md"
        echo "[MIGRATE] 根目录 ARCHITECTURE.md → .harness/docs/architecture.md"
    else
        # .harness/docs/architecture.md 已存在，保留已有版本，删除根目录旧文件
        rm -f "$REPO_ROOT/ARCHITECTURE.md"
        echo "[MIGRATE] 根目录 ARCHITECTURE.md 已存在新版，删除根目录旧文件"
    fi
else
    echo "[MIGRATE] 根目录无 ARCHITECTURE.md，跳过迁移"
fi

SPECS_DIR="$REPO_ROOT/.harness"
PLANS_TEMPLATE_DIR="$SPECS_DIR/plans/_template"

# 判断是全新初始化还是升级已有项目
IS_UPGRADE=0
if [[ -d "$SPECS_DIR" ]]; then
    IS_UPGRADE=1
fi

mkdir -p "$SPECS_DIR"
mkdir -p "$SPECS_DIR/plans"

# ---------------------------------------------------------------------------
# 复制骨架（已存在的文件不覆盖，新补的文件逐一报告）
#
# --has-api=false → 跳过 docs/apis/；--has-db=false → 跳过 docs/sqls/。
# 仅影响补缺复制：目标项目已存在的同名文件本就「不覆盖」，更不会被删除。
# ---------------------------------------------------------------------------
(cd "$SKELETON" && find . -type f -print0) | while IFS= read -r -d '' rel; do
    case "$rel" in
        ./docs/apis/*) [[ "$HAS_API" == "false" ]] && continue ;;
        ./docs/sqls/*) [[ "$HAS_DB" == "false" ]] && continue ;;
    esac
    src="$SKELETON/$rel"
    dst="$SPECS_DIR/$rel"
    mkdir -p "$(dirname "$dst")"
    if [[ ! -e "$dst" ]]; then
        cp "$src" "$dst"
        echo "[ADD] 补充骨架文件：.harness/${rel#./}"
    fi
done
[[ "$HAS_API" == "false" ]] && echo "[SKIP] --has-api=false，跳过骨架 docs/apis/"
[[ "$HAS_DB" == "false" ]] && echo "[SKIP] --has-db=false，跳过骨架 docs/sqls/"

# 复制 plans/_template（文件级不覆盖，新补的文件逐一报告）
mkdir -p "$PLANS_TEMPLATE_DIR"
(cd "$TEMPLATE" && find . -type f -print0) | while IFS= read -r -d '' rel; do
    src="$TEMPLATE/$rel"
    dst="$PLANS_TEMPLATE_DIR/$rel"
    mkdir -p "$(dirname "$dst")"
    if [[ ! -e "$dst" ]]; then
        cp "$src" "$dst"
        echo "[ADD] 补充模板文件：.harness/plans/_template/${rel#./}"
    fi
done

if [[ $IS_UPGRADE -eq 1 ]]; then
    echo ""
    echo "[升级模式] 检测到已有 .harness/ 目录，执行升级检测..."
    echo "          - 缺失的骨架/模板文件已自动补充（见上方 [ADD]）"
    echo "          - 下面将检测契约性文件是否需要刷新..."
else
    echo "[OK] 已初始化 .harness 于：$SPECS_DIR"
    echo "     - 顶层：review.md"
    docs_list="architecture.md, relationship.md"
    [[ "$HAS_API" == "true" ]] && docs_list="$docs_list, apis/"
    [[ "$HAS_DB" == "true" ]] && docs_list="$docs_list, sqls/"
    docs_list="$docs_list, unittest/, integration_test/, devops/"
    echo "     - docs/：$docs_list"
    echo "     - plans/：_template/（10 文件任务模板）"
fi

# ---------------------------------------------------------------------------
# 强制刷新 plans/_template/ 中的全部模板文件
#
# plans/_template/ 下所有文件均为 SOP 契约模板，skill 升级时需要把最新
# 结构同步给老项目，否则老项目新建的任务仍沿用旧模板。
#
# 策略：对 _template/ 下每个文件，有差异则直接覆盖。
#
# 注意：这里只刷新 `_template/` 目录本身；用户已创建的具体任务目录
# （plans/<task>/）一律不动，保护进行中的任务进度。
# ---------------------------------------------------------------------------
(cd "$TEMPLATE" && find . -type f -print0) | while IFS= read -r -d '' rel; do
    SRC="$TEMPLATE/$rel"
    DST="$PLANS_TEMPLATE_DIR/$rel"
    if [[ ! -f "$SRC" ]]; then
        continue
    fi
    if [[ -f "$DST" ]]; then
        if ! cmp -s "$SRC" "$DST"; then
            cp "$SRC" "$DST"
            echo "[REFRESH] 已刷新 plans/_template/${rel#./}"
        fi
    fi
done

# ---------------------------------------------------------------------------
# 强制刷新 docs/devops/test-env-deploy.md（按章节分治）
#
# 该文件包含环境管理 CLI 工具就绪检查 + 安装引导，
# 以及团队环境管理 Skill / 团队测试工具 Skill 的操作说明，是工具链规范的一部分。
#
# 更新策略（与 CODEBUDDY.md 一致）：
#   - 以「## 项目自定义」为分界线：
#     skill 管控区（开头 ~ 「## 项目自定义」之前）→ 强制刷新为最新版
#     项目自定义区（「## 项目自定义」含 ~ 文件末尾）→ 保留现有不改不删
#   - 仅当 skill 管控区有差异时才执行更新
# ---------------------------------------------------------------------------
TEST_ENV_DEPLOY_SRC="$SKELETON/docs/devops/test-env-deploy.md"
TEST_ENV_DEPLOY_DST="$SPECS_DIR/docs/devops/test-env-deploy.md"
if [[ -f "$TEST_ENV_DEPLOY_SRC" ]]; then
    if [[ ! -f "$TEST_ENV_DEPLOY_DST" ]]; then
        # 文件不存在 → 全量写入
        mkdir -p "$(dirname "$TEST_ENV_DEPLOY_DST")"
        cp "$TEST_ENV_DEPLOY_SRC" "$TEST_ENV_DEPLOY_DST"
        echo "[OK] 已写入 docs/devops/test-env-deploy.md"
    else
        # 文件已存在 → 按章节分治刷新
        # 提取源文件的 skill 管控区（开头 ~ 「## 项目自定义」之前）
        SRC_SKILL_PART="$(mktemp)"
        awk '/^## 项目自定义/{exit} {print}' "$TEST_ENV_DEPLOY_SRC" > "$SRC_SKILL_PART"

        # 提取现有文件的 skill 管控区（用于对比）
        DST_SKILL_PART="$(mktemp)"
        awk '/^## 项目自定义/{exit} {print}' "$TEST_ENV_DEPLOY_DST" > "$DST_SKILL_PART"

        if cmp -s "$SRC_SKILL_PART" "$DST_SKILL_PART"; then
            echo "[SKIP] docs/devops/test-env-deploy.md skill 管控区已是最新，无需更新"
        else
            # 提取现有文件的项目自定义区
            DST_CUSTOM_PART="$(mktemp)"
            if grep -q '^## 项目自定义' "$TEST_ENV_DEPLOY_DST"; then
                awk '/^## 项目自定义/{p=1} p{print}' "$TEST_ENV_DEPLOY_DST" > "$DST_CUSTOM_PART"
            else
                # 无项目自定义区 → 从源文件补齐默认
                awk '/^## 项目自定义/{p=1} p{print}' "$TEST_ENV_DEPLOY_SRC" > "$DST_CUSTOM_PART"
                echo "[INFO] test-env-deploy.md 未检测到「## 项目自定义」章节，已从模板补齐默认"
            fi

            # 拼接：最新 skill 管控区 + 现有项目自定义区
            cat "$SRC_SKILL_PART" "$DST_CUSTOM_PART" > "$TEST_ENV_DEPLOY_DST"
            echo "[REFRESH] 已刷新 docs/devops/test-env-deploy.md（skill 管控区已更新；项目自定义区保持不变）"

            rm -f "$DST_CUSTOM_PART"
        fi

        rm -f "$SRC_SKILL_PART" "$DST_SKILL_PART"
    fi
fi

# ---------------------------------------------------------------------------
# 安装 clarify skill 到目标仓库的 .codebuddy/skills/clarify/
#
# clarify 是 Stage 01 强烈推荐的对话协议 skill。把它一并安装到目标仓库，
# 让目标仓库的 AI 在执行 SOP 时能直接 use_skill clarify，不依赖外部 skill。
#
# 注意：源端文件以 .tmpl 结尾（如 SKILL.md.tmpl），目的是避免与本仓库根
# .codebuddy/skills/clarify/SKILL.md 冲突、被 skill 系统重复识别。
# 安装时遍历源端文件，对 .tmpl 后缀的文件去掉 .tmpl 写入目标；其它文件原名复制。
# 已存在文件一律跳过，保护用户改动。
# ---------------------------------------------------------------------------
CLARIFY_DST="$REPO_ROOT/.codebuddy/skills/clarify"
if [[ -d "$CLARIFY_SKILL_SRC" ]]; then
    if [[ -e "$CLARIFY_DST/SKILL.md" ]]; then
        echo "[SKIP] $CLARIFY_DST/SKILL.md 已存在，保持不动"
    else
        mkdir -p "$CLARIFY_DST"
        installed_any=0
        (cd "$CLARIFY_SKILL_SRC" && find . -type f -print0) | while IFS= read -r -d '' rel; do
            src="$CLARIFY_SKILL_SRC/$rel"
            # 去除 .tmpl 后缀（仅末尾的 .tmpl 视为模板标记，保留路径结构）
            dst_rel="${rel%.tmpl}"
            dst="$CLARIFY_DST/$dst_rel"
            mkdir -p "$(dirname "$dst")"
            if [[ ! -e "$dst" ]]; then
                cp "$src" "$dst"
            fi
        done
        echo "[OK] 已安装 clarify skill 到：$CLARIFY_DST"
    fi
else
    echo "[WARN] clarify skill 模板不存在：$CLARIFY_SKILL_SRC，跳过安装" >&2
fi

# ---------------------------------------------------------------------------
# Git Hooks 安装（幂等）
#
# 通过 setup_hooks.sh 安装 pre-commit / pre-push / commit-msg 三个 hook 的
# 软链到 .git/hooks/ 下，脚本复制到 scripts/ 目录。
# 非 Git 仓库静默跳过；已存在不覆盖；缺失的补建。
# ---------------------------------------------------------------------------
HOOKS_SETUP="$SKILL_DIR/scripts/setup_hooks.sh"
if [[ -f "$HOOKS_SETUP" ]]; then
    # setup_hooks.sh 内部以 git rev-parse --show-toplevel 二次确认项目根
    bash "$HOOKS_SETUP" "$REPO_ROOT"
    echo "[HOOKS] Git Hooks 安装完成"
else
    echo "[WARN] setup_hooks.sh 不存在：$HOOKS_SETUP，跳过 hooks 安装" >&2
fi

# ---------------------------------------------------------------------------
# Go 项目 Lint 配置注入
#
# 仅当项目为 Go 语言（go.mod 存在）且 .golangci.yml 不存在时，
# 从 Skill 模板复制一份。
# ---------------------------------------------------------------------------
if [[ -f "$REPO_ROOT/go.mod" ]]; then
    GOLANGCI_SRC="$SKILL_DIR/assets/.golangci.yml"
    GOLANGCI_DST="$REPO_ROOT/.golangci.yml"
    if [[ -f "$GOLANGCI_SRC" ]]; then
        if [[ ! -f "$GOLANGCI_DST" ]]; then
            cp "$GOLANGCI_SRC" "$GOLANGCI_DST"
            echo "[LINT] 已复制 .golangci.yml（从 SOP 模板）"
        else
            echo "[LINT] .golangci.yml 已存在，跳过"
        fi
    else
        echo "[WARN] .golangci.yml 模板不存在：$GOLANGCI_SRC" >&2
    fi
else
    echo "[LINT] 非 Go 项目，跳过 .golangci.yml"
fi

# ---------------------------------------------------------------------------
# 仓库根 AI 入口文档：AGENTS.md（真源）+ CODEBUDDY.md / CLAUDE.md 双软链
#
# 目标：给 CodeBuddy / Claude Code / Codex CLI / Cursor 等 Agent 一个统一的入口。
# 从模板 $SKILL_DIR/assets/agents.md.tmpl 生成，仅替换 {{PROJECT_NAME}}。
# AGENTS.md 是唯一真源，CODEBUDDY.md / CLAUDE.md 均为指向 AGENTS.md 的软链。
#
# 更新策略（按章节分治）：
#   - AGENTS.md 不存在  → 从模板全量生成
#   - AGENTS.md 已存在  → 按「## 二、」和「## 三、」切为三段：
#       段 A（头部 + 一、快速索引）→ 保留现有（项目可能追加了自定义索引行）
#       段 B（二、SOP）           → 强制刷新为模板最新版（核心 SOP 契约）
#       段 C（三、开发准则 + 四、禁止红线）→ 保留现有（项目自定义，不改不删）
#     仅当段 B 有差异时才执行更新。
#   - CODEBUDDY.md / CLAUDE.md 若是软链    → 直接删除并重建
#   - CODEBUDDY.md / CLAUDE.md 若是真实文件 → 直接删除后重建为软链
# ---------------------------------------------------------------------------
AGENTS_TMPL="$SKILL_DIR/assets/agents.md.tmpl"
AGENTS_MD="$REPO_ROOT/AGENTS.md"
if [[ ! -f "$AGENTS_TMPL" ]]; then
    echo "[WARN] 模板不存在：$AGENTS_TMPL，跳过 AGENTS.md 生成" >&2
else
    PROJECT_NAME="$(basename "$REPO_ROOT")"

    if [[ ! -e "$AGENTS_MD" && ! -L "$AGENTS_MD" ]]; then
        # ---- 全新生成 ----
        awk -v name="$PROJECT_NAME" '{ gsub(/\{\{PROJECT_NAME\}\}/, name); print }' \
            "$AGENTS_TMPL" > "$AGENTS_MD"
        echo "[OK] 已基于模板生成 $AGENTS_MD"
    else
        # ---- 智能合并：仅刷新第二章 SOP，其余保留 ----
        #
        # 文件按两条分界线切为三段：
        #   段 A = 文件开头 ~ 「## 二、」之前（头部 + 一、快速索引）
        #   段 B = 「## 二、」(含) ~ 「## 三、」之前（二、SOP）
        #   段 C = 「## 三、」(含) ~ 文件末尾（三、开发准则 + 四、禁止红线）
        #
        # 更新规则：段 A 保留现有 | 段 B 从模板刷新 | 段 C 保留现有

        # 1) 从模板生成完整版到临时文件
        TMPL_FULL="$(mktemp)"
        awk -v name="$PROJECT_NAME" '{ gsub(/\{\{PROJECT_NAME\}\}/, name); print }' \
            "$AGENTS_TMPL" > "$TMPL_FULL"

        # 2) 提取模板的段 B（二、SOP 章节）
        TMPL_SOP="$(mktemp)"
        awk '/^## 二、/{p=1} p && /^## 三、/{exit} p{print}' "$TMPL_FULL" > "$TMPL_SOP"

        # 3) 提取现有文件的段 B（用于对比）
        EXISTING_SOP="$(mktemp)"
        awk '/^## 二、/{p=1} p && /^## 三、/{exit} p{print}' "$AGENTS_MD" > "$EXISTING_SOP"

        # 4) 比较段 B 是否有差异
        if cmp -s "$TMPL_SOP" "$EXISTING_SOP"; then
            echo "[SKIP] AGENTS.md 第二章（SOP）已是最新，无需更新"
        else
            # 5) 提取现有文件的段 A（头部 + 一、快速索引）
            EXISTING_HEAD="$(mktemp)"
            awk '/^## 二、/{exit} {print}' "$AGENTS_MD" > "$EXISTING_HEAD"

            # 6) 提取现有文件的段 C（三、开发准则 + 四、禁止红线）
            EXISTING_TAIL="$(mktemp)"
            if grep -q '^## 三、' "$AGENTS_MD"; then
                awk '/^## 三、/{p=1} p{print}' "$AGENTS_MD" > "$EXISTING_TAIL"
            else
                # 无三四章 → 从模板补齐默认
                awk '/^## 三、/{p=1} p{print}' "$TMPL_FULL" > "$EXISTING_TAIL"
                echo "[INFO] 未检测到三四章，已从模板补齐默认章节"
            fi

            # 7) 拼接：现有段 A + 模板段 B + 现有段 C
            cat "$EXISTING_HEAD" "$TMPL_SOP" "$EXISTING_TAIL" > "$AGENTS_MD"
            echo "[REFRESH] 已更新 AGENTS.md（第二章 SOP 已刷新为最新；一/三/四章保持不变）"

            rm -f "$EXISTING_HEAD" "$EXISTING_TAIL"
        fi

        rm -f "$TMPL_FULL" "$TMPL_SOP" "$EXISTING_SOP"
    fi
fi

# CODEBUDDY.md / CLAUDE.md：始终重建为指向 AGENTS.md 的软链，确保多 Agent 入口一致。
#   - CODEBUDDY.md → CodeBuddy 识别
#   - CLAUDE.md    → Claude Code 识别
ensure_ai_agent_symlink() {
    local link_name="$1"   # 软链名（如 CODEBUDDY.md / CLAUDE.md）
    local link_path="$REPO_ROOT/$link_name"
    if [[ -L "$link_path" ]]; then
        # 已是软链：直接删除（skill 自身资源，无需备份）
        rm -f "$link_path"
    elif [[ -e "$link_path" ]]; then
        # 真实文件：直接删除（Git 管理可找回，无需备份）
        rm -f "$link_path"
        echo "[OK] 删除原真实文件 $link_name（已重建为软链）"
    fi
    # 使用相对软链，保证仓库可移植。
    ln -s AGENTS.md "$link_path"
    echo "[OK] $link_name → AGENTS.md 软链已就绪"
}

for AGENT_LINK in CODEBUDDY.md CLAUDE.md; do
    ensure_ai_agent_symlink "$AGENT_LINK"
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
if [[ $IS_UPGRADE -eq 1 ]]; then
    echo "  ✅ SOP 升级完成"
    echo ""
    echo "  本次升级自动处理了以下内容："
    echo "    • 缺失的骨架/模板文件 → 自动补充（见上方 [ADD]）"
    echo "    • 契约性模板（00-overview / 05-deploy / 06-it）→ 有差异则直接覆盖"
    echo "    • test-env-deploy.md → 按章节分治：skill 管控区刷新，「## 项目自定义」保留"
    echo "    • AGENTS.md → 仅刷新第二章（SOP），一/三/四章保留不动（见上方 [REFRESH] 或 [SKIP]）"
    echo "    • CODEBUDDY.md / CLAUDE.md → 确保软链指向 AGENTS.md（双 Agent 入口）"
    echo "    • clarify skill → 不存在则安装"
else
    echo "  ✅ SOP 初始化完成"
    echo ""
    echo "  后续步骤："
    echo "    1. 填写 .harness/docs/architecture.md 与 .harness/docs/relationship.md"
    echo "    2. 按需在 .harness/docs/apis/<module>/ 下新建接口文档；同步 apis/index.md"
    echo "    3. 按需在 .harness/docs/sqls/ 下补齐 DB schema / migration 文档"
    echo "    4.【必填】填写 .harness/docs/unittest/unittest.md（三段式：环境 / 生成 / 运行调试）"
    echo "    5.【必填】填写 .harness/docs/integration_test/integration_test.md（三段式）"
    echo "    6. 填写 .harness/docs/devops/env.md + test-env-deploy.md"
    echo "    7. 编辑 AGENTS.md：「三、开发准则」+「四、禁止红线」"
fi
echo "═══════════════════════════════════════════════════════════════"
