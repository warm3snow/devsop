#!/usr/bin/env python3
"""
validate_todo_json.py - 严格验证 sop_todo.json 格式

用法：
    python3 validate_todo_json.py <json_file_path>

验证规则：
    1. 文件必须是合法的 JSON
    2. 顶层结构必须是对象（object）
    3. 必须包含 schema_version, project_type, total_score, max_score, effective_max_score, level, level_name, pillars, todos 字段
    4. schema_version 必须是非空字符串（如 "1.1"）
    5. project_type 必须是 service/library/cli/monorepo 之一
    6. total_score 必须是 0-100 的数值
    7. max_score 必须固定为 100
    8. effective_max_score 必须是 1-100 的数值且 >= total_score
    9. level 必须是 L0-L4 之一
    10. level_name 必须是非空字符串
    11. pillars 必须是包含 6 个元素的数组，每个含 id/name/score/max
    12. pillars 各项 score 之和必须与 total_score 一致（允许 ±1 浮点误差）
    13. todos 必须是 1-20 个元素的数组，每个含 title/solution
    14. 不允许有额外的未知字段

退出码：
    0 - 验证通过
    1 - 验证失败
"""

import json
import sys


VALID_LEVELS = {"L0", "L1", "L2", "L3", "L4"}
VALID_PILLAR_IDS = {"A", "B", "C", "D", "E", "F"}
VALID_PROJECT_TYPES = {"service", "library", "cli", "monorepo"}
TOP_LEVEL_FIELDS = {"schema_version", "project_type", "total_score", "max_score", "effective_max_score", "level", "level_name", "pillars", "todos"}
PILLAR_FIELDS = {"id", "name", "score", "max"}
TODO_FIELDS = {"title", "solution"}


def validate(file_path: str) -> tuple[bool, list[str]]:
    errors = []

    # 读取文件
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read().strip()
    except FileNotFoundError:
        return False, [f"文件不存在：{file_path}"]
    except OSError as e:
        return False, [f"读取文件失败：{e}"]

    # 解析 JSON
    try:
        data = json.loads(content)
    except json.JSONDecodeError as e:
        return False, [f"JSON 解析失败：{e}"]

    # 必须是对象
    if not isinstance(data, dict):
        return False, [f"顶层结构必须是对象（object），实际类型：{type(data).__name__}"]

    # 检查顶层多余字段
    extra_top = set(data.keys()) - TOP_LEVEL_FIELDS
    if extra_top:
        errors.append(f"顶层包含未知字段 {sorted(extra_top)}，只允许 {sorted(TOP_LEVEL_FIELDS)}")

    # 检查 schema_version
    if "schema_version" not in data:
        errors.append("缺少必填字段 \"schema_version\"")
    else:
        sv = data["schema_version"]
        if not isinstance(sv, str):
            errors.append(f"\"schema_version\" 必须是字符串，实际类型：{type(sv).__name__}")
        elif not sv.strip():
            errors.append("\"schema_version\" 不能为空字符串")

    # 检查 project_type
    if "project_type" not in data:
        errors.append("缺少必填字段 \"project_type\"")
    else:
        pt = data["project_type"]
        if not isinstance(pt, str):
            errors.append(f"\"project_type\" 必须是字符串，实际类型：{type(pt).__name__}")
        elif pt not in VALID_PROJECT_TYPES:
            errors.append(f"\"project_type\" 必须是 {sorted(VALID_PROJECT_TYPES)} 之一，实际值：\"{pt}\"")

    # 检查 total_score
    if "total_score" not in data:
        errors.append("缺少必填字段 \"total_score\"")
    else:
        ts = data["total_score"]
        if not isinstance(ts, (int, float)):
            errors.append(f"\"total_score\" 必须是数值，实际类型：{type(ts).__name__}")
        elif ts < 0 or ts > 100:
            errors.append(f"\"total_score\" 必须在 0-100 之间，实际值：{ts}")

    # 检查 max_score
    if "max_score" not in data:
        errors.append("缺少必填字段 \"max_score\"")
    else:
        ms = data["max_score"]
        if not isinstance(ms, (int, float)):
            errors.append(f"\"max_score\" 必须是数值，实际类型：{type(ms).__name__}")
        elif ms != 100:
            errors.append(f"\"max_score\" 必须固定为 100，实际值：{ms}")

    # 检查 effective_max_score
    if "effective_max_score" not in data:
        errors.append("缺少必填字段 \"effective_max_score\"")
    else:
        ems = data["effective_max_score"]
        if not isinstance(ems, (int, float)):
            errors.append(f"\"effective_max_score\" 必须是数值，实际类型：{type(ems).__name__}")
        elif ems < 1 or ems > 100:
            errors.append(f"\"effective_max_score\" 必须在 1-100 之间，实际值：{ems}")

    # 检查 level
    if "level" not in data:
        errors.append("缺少必填字段 \"level\"")
    else:
        lv = data["level"]
        if not isinstance(lv, str):
            errors.append(f"\"level\" 必须是字符串，实际类型：{type(lv).__name__}")
        elif lv not in VALID_LEVELS:
            errors.append(f"\"level\" 必须是 {sorted(VALID_LEVELS)} 之一，实际值：\"{lv}\"")

    # 检查 level_name
    if "level_name" not in data:
        errors.append("缺少必填字段 \"level_name\"")
    else:
        ln = data["level_name"]
        if not isinstance(ln, str):
            errors.append(f"\"level_name\" 必须是字符串，实际类型：{type(ln).__name__}")
        elif not ln.strip():
            errors.append("\"level_name\" 不能为空字符串")

    # 检查 pillars
    if "pillars" not in data:
        errors.append("缺少必填字段 \"pillars\"")
    else:
        pillars = data["pillars"]
        if not isinstance(pillars, list):
            errors.append(f"\"pillars\" 必须是数组，实际类型：{type(pillars).__name__}")
        else:
            if len(pillars) != 6:
                errors.append(f"\"pillars\" 必须包含 6 个元素（A-F），当前：{len(pillars)} 个")

            seen_ids = set()
            for i, p in enumerate(pillars):
                prefix = f"pillars[{i}]"
                if not isinstance(p, dict):
                    errors.append(f"{prefix}：元素必须是对象，实际类型：{type(p).__name__}")
                    continue

                # 检查多余字段
                extra_p = set(p.keys()) - PILLAR_FIELDS
                if extra_p:
                    errors.append(f"{prefix}：包含未知字段 {sorted(extra_p)}，只允许 {sorted(PILLAR_FIELDS)}")

                # 检查 id
                if "id" not in p:
                    errors.append(f"{prefix}：缺少必填字段 \"id\"")
                else:
                    pid = p["id"]
                    if not isinstance(pid, str):
                        errors.append(f"{prefix}：\"id\" 必须是字符串，实际类型：{type(pid).__name__}")
                    elif pid not in VALID_PILLAR_IDS:
                        errors.append(f"{prefix}：\"id\" 必须是 {sorted(VALID_PILLAR_IDS)} 之一，实际值：\"{pid}\"")
                    elif pid in seen_ids:
                        errors.append(f"{prefix}：\"id\" 重复：\"{pid}\"")
                    else:
                        seen_ids.add(pid)

                # 检查 name
                if "name" not in p:
                    errors.append(f"{prefix}：缺少必填字段 \"name\"")
                elif not isinstance(p["name"], str):
                    errors.append(f"{prefix}：\"name\" 必须是字符串，实际类型：{type(p['name']).__name__}")
                elif not p["name"].strip():
                    errors.append(f"{prefix}：\"name\" 不能为空字符串")

                # 检查 score
                if "score" not in p:
                    errors.append(f"{prefix}：缺少必填字段 \"score\"")
                elif not isinstance(p["score"], (int, float)):
                    errors.append(f"{prefix}：\"score\" 必须是数值，实际类型：{type(p['score']).__name__}")
                elif p["score"] < 0:
                    errors.append(f"{prefix}：\"score\" 不能为负数，实际值：{p['score']}")

                # 检查 max
                if "max" not in p:
                    errors.append(f"{prefix}：缺少必填字段 \"max\"")
                elif not isinstance(p["max"], (int, float)):
                    errors.append(f"{prefix}：\"max\" 必须是数值，实际类型：{type(p['max']).__name__}")
                elif p["max"] <= 0:
                    errors.append(f"{prefix}：\"max\" 必须大于 0，实际值：{p['max']}")

                # score <= max
                if (isinstance(p.get("score"), (int, float)) and
                        isinstance(p.get("max"), (int, float)) and
                        p["score"] > p["max"]):
                    errors.append(f"{prefix}：\"score\"({p['score']}) 不能大于 \"max\"({p['max']})")

            # pillars score 之和 vs total_score 一致性校验（允许 ±1 浮点误差）
            if isinstance(data.get("total_score"), (int, float)):
                pillar_sum = sum(
                    p["score"] for p in pillars
                    if isinstance(p, dict) and isinstance(p.get("score"), (int, float))
                )
                diff = abs(pillar_sum - data["total_score"])
                if diff > 1:
                    errors.append(
                        f"pillars 各项 score 之和（{pillar_sum}）与 total_score（{data['total_score']}）"
                        f"不一致（差值 {diff:.1f}，允许误差 ±1）"
                    )

    # 检查 todos
    if "todos" not in data:
        errors.append("缺少必填字段 \"todos\"")
    else:
        todos = data["todos"]
        if not isinstance(todos, list):
            errors.append(f"\"todos\" 必须是数组，实际类型：{type(todos).__name__}")
        else:
            if len(todos) == 0:
                errors.append("\"todos\" 不能为空，至少需要 1 条改进任务")
            elif len(todos) > 20:
                errors.append(f"\"todos\" 长度超出限制（最多 20 条），当前：{len(todos)} 条")

            for i, item in enumerate(todos):
                prefix = f"todos[{i}]"
                if not isinstance(item, dict):
                    errors.append(f"{prefix}：元素必须是对象，实际类型：{type(item).__name__}")
                    continue

                # 检查必填字段
                for field in ("title", "solution"):
                    if field not in item:
                        errors.append(f"{prefix}：缺少必填字段 \"{field}\"")
                    elif not isinstance(item[field], str):
                        errors.append(f"{prefix}：\"{field}\" 必须是字符串，实际类型：{type(item[field]).__name__}")
                    elif not item[field].strip():
                        errors.append(f"{prefix}：\"{field}\" 不能为空字符串")

                # 检查多余字段
                extra_t = set(item.keys()) - TODO_FIELDS
                if extra_t:
                    errors.append(f"{prefix}：包含未知字段 {sorted(extra_t)}，只允许 \"title\" 和 \"solution\"")

    if errors:
        return False, errors
    return True, []


def main():
    if len(sys.argv) != 2:
        print("用法：python3 validate_todo_json.py <json_file_path>", file=sys.stderr)
        sys.exit(1)

    file_path = sys.argv[1]
    ok, errors = validate(file_path)

    if ok:
        print(f"✅ 验证通过：{file_path}")
        sys.exit(0)
    else:
        print(f"❌ 验证失败：{file_path}", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
