#!/usr/bin/env python3
"""
validate_todo_json.py - strictly validates the sop_todo.json format

Usage:
    python3 validate_todo_json.py <json_file_path>

Validation rules:
    1. The file must be valid JSON
    2. The top-level structure must be an object
    3. Must contain the fields schema_version, project_type, total_score, max_score, effective_max_score, level, level_name, pillars, todos
    4. schema_version must be a non-empty string (e.g. "1.1")
    5. project_type must be one of service/library/cli/monorepo
    6. total_score must be a numeric value between 0-100
    7. max_score must be fixed at 100
    8. effective_max_score must be a numeric value between 1-100 and >= total_score
    9. level must be one of L0-L4
    10. level_name must be a non-empty string
    11. pillars must be an array of 6 elements, each containing id/name/score/max
    12. the sum of pillars' scores must equal total_score (allowed ±1 float error)
    13. todos must be an array of 1-20 elements, each containing title/solution
    14. no extra unknown fields are allowed

Exit codes:
    0 - validation passed
    1 - validation failed
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

    # read the file
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read().strip()
    except FileNotFoundError:
        return False, [f"file does not exist: {file_path}"]
    except OSError as e:
        return False, [f"failed to read file: {e}"]

    # parse JSON
    try:
        data = json.loads(content)
    except json.JSONDecodeError as e:
        return False, [f"JSON parse failed: {e}"]

    # must be an object
    if not isinstance(data, dict):
        return False, [f"top-level structure must be an object, actual type: {type(data).__name__}"]

    # check for extra top-level fields
    extra_top = set(data.keys()) - TOP_LEVEL_FIELDS
    if extra_top:
        errors.append(f"top-level contains unknown fields {sorted(extra_top)}, only {sorted(TOP_LEVEL_FIELDS)} are allowed")

    # check schema_version
    if "schema_version" not in data:
        errors.append("missing required field \"schema_version\"")
    else:
        sv = data["schema_version"]
        if not isinstance(sv, str):
            errors.append(f"\"schema_version\" must be a string, actual type: {type(sv).__name__}")
        elif not sv.strip():
            errors.append("\"schema_version\" cannot be an empty string")

    # check project_type
    if "project_type" not in data:
        errors.append("missing required field \"project_type\"")
    else:
        pt = data["project_type"]
        if not isinstance(pt, str):
            errors.append(f"\"project_type\" must be a string, actual type: {type(pt).__name__}")
        elif pt not in VALID_PROJECT_TYPES:
            errors.append(f"\"project_type\" must be one of {sorted(VALID_PROJECT_TYPES)}, actual value: \"{pt}\"")

    # check total_score
    if "total_score" not in data:
        errors.append("missing required field \"total_score\"")
    else:
        ts = data["total_score"]
        if not isinstance(ts, (int, float)):
            errors.append(f"\"total_score\" must be numeric, actual type: {type(ts).__name__}")
        elif ts < 0 or ts > 100:
            errors.append(f"\"total_score\" must be between 0-100, actual value: {ts}")

    # check max_score
    if "max_score" not in data:
        errors.append("missing required field \"max_score\"")
    else:
        ms = data["max_score"]
        if not isinstance(ms, (int, float)):
            errors.append(f"\"max_score\" must be numeric, actual type: {type(ms).__name__}")
        elif ms != 100:
            errors.append(f"\"max_score\" must be fixed at 100, actual value: {ms}")

    # check effective_max_score
    if "effective_max_score" not in data:
        errors.append("missing required field \"effective_max_score\"")
    else:
        ems = data["effective_max_score"]
        if not isinstance(ems, (int, float)):
            errors.append(f"\"effective_max_score\" must be numeric, actual type: {type(ems).__name__}")
        elif ems < 1 or ems > 100:
            errors.append(f"\"effective_max_score\" must be between 1-100, actual value: {ems}")

    # check level
    if "level" not in data:
        errors.append("missing required field \"level\"")
    else:
        lv = data["level"]
        if not isinstance(lv, str):
            errors.append(f"\"level\" must be a string, actual type: {type(lv).__name__}")
        elif lv not in VALID_LEVELS:
            errors.append(f"\"level\" must be one of {sorted(VALID_LEVELS)}, actual value: \"{lv}\"")

    # check level_name
    if "level_name" not in data:
        errors.append("missing required field \"level_name\"")
    else:
        ln = data["level_name"]
        if not isinstance(ln, str):
            errors.append(f"\"level_name\" must be a string, actual type: {type(ln).__name__}")
        elif not ln.strip():
            errors.append("\"level_name\" cannot be an empty string")

    # check pillars
    if "pillars" not in data:
        errors.append("missing required field \"pillars\"")
    else:
        pillars = data["pillars"]
        if not isinstance(pillars, list):
            errors.append(f"\"pillars\" must be an array, actual type: {type(pillars).__name__}")
        else:
            if len(pillars) != 6:
                errors.append(f"\"pillars\" must contain 6 elements (A-F), current: {len(pillars)}")

            seen_ids = set()
            for i, p in enumerate(pillars):
                prefix = f"pillars[{i}]"
                if not isinstance(p, dict):
                    errors.append(f"{prefix}: element must be an object, actual type: {type(p).__name__}")
                    continue

                # check for extra fields
                extra_p = set(p.keys()) - PILLAR_FIELDS
                if extra_p:
                    errors.append(f"{prefix}: contains unknown fields {sorted(extra_p)}, only {sorted(PILLAR_FIELDS)} are allowed")

                # check id
                if "id" not in p:
                    errors.append(f"{prefix}: missing required field \"id\"")
                else:
                    pid = p["id"]
                    if not isinstance(pid, str):
                        errors.append(f"{prefix}: \"id\" must be a string, actual type: {type(pid).__name__}")
                    elif pid not in VALID_PILLAR_IDS:
                        errors.append(f"{prefix}: \"id\" must be one of {sorted(VALID_PILLAR_IDS)}, actual value: \"{pid}\"")
                    elif pid in seen_ids:
                        errors.append(f"{prefix}: duplicate \"id\": \"{pid}\"")
                    else:
                        seen_ids.add(pid)

                # check name
                if "name" not in p:
                    errors.append(f"{prefix}: missing required field \"name\"")
                elif not isinstance(p["name"], str):
                    errors.append(f"{prefix}: \"name\" must be a string, actual type: {type(p['name']).__name__}")
                elif not p["name"].strip():
                    errors.append(f"{prefix}: \"name\" cannot be an empty string")

                # check score
                if "score" not in p:
                    errors.append(f"{prefix}: missing required field \"score\"")
                elif not isinstance(p["score"], (int, float)):
                    errors.append(f"{prefix}: \"score\" must be numeric, actual type: {type(p['score']).__name__}")
                elif p["score"] < 0:
                    errors.append(f"{prefix}: \"score\" cannot be negative, actual value: {p['score']}")

                # check max
                if "max" not in p:
                    errors.append(f"{prefix}: missing required field \"max\"")
                elif not isinstance(p["max"], (int, float)):
                    errors.append(f"{prefix}: \"max\" must be numeric, actual type: {type(p['max']).__name__}")
                elif p["max"] <= 0:
                    errors.append(f"{prefix}: \"max\" must be greater than 0, actual value: {p['max']}")

                # score <= max
                if (isinstance(p.get("score"), (int, float)) and
                        isinstance(p.get("max"), (int, float)) and
                        p["score"] > p["max"]):
                    errors.append(f"{prefix}: \"score\"({p['score']}) cannot be greater than \"max\"({p['max']})")

            # consistency check: sum of pillars scores vs total_score (allowed ±1 float error)
            if isinstance(data.get("total_score"), (int, float)):
                pillar_sum = sum(
                    p["score"] for p in pillars
                    if isinstance(p, dict) and isinstance(p.get("score"), (int, float))
                )
                diff = abs(pillar_sum - data["total_score"])
                if diff > 1:
                    errors.append(
                        f"the sum of pillars scores ({pillar_sum}) is inconsistent with total_score ({data['total_score']})"
                        f" (difference {diff:.1f}, allowed error ±1)"
                    )

    # check todos
    if "todos" not in data:
        errors.append("missing required field \"todos\"")
    else:
        todos = data["todos"]
        if not isinstance(todos, list):
            errors.append(f"\"todos\" must be an array, actual type: {type(todos).__name__}")
        else:
            if len(todos) == 0:
                errors.append("\"todos\" cannot be empty, at least 1 improvement task is required")
            elif len(todos) > 20:
                errors.append(f"\"todos\" exceeds the length limit (max 20), current: {len(todos)}")

            for i, item in enumerate(todos):
                prefix = f"todos[{i}]"
                if not isinstance(item, dict):
                    errors.append(f"{prefix}: element must be an object, actual type: {type(item).__name__}")
                    continue

                # check required fields
                for field in ("title", "solution"):
                    if field not in item:
                        errors.append(f"{prefix}: missing required field \"{field}\"")
                    elif not isinstance(item[field], str):
                        errors.append(f"{prefix}: \"{field}\" must be a string, actual type: {type(item[field]).__name__}")
                    elif not item[field].strip():
                        errors.append(f"{prefix}: \"{field}\" cannot be an empty string")

                # check for extra fields
                extra_t = set(item.keys()) - TODO_FIELDS
                if extra_t:
                    errors.append(f"{prefix}: contains unknown fields {sorted(extra_t)}, only \"title\" and \"solution\" are allowed")

    if errors:
        return False, errors
    return True, []


def main():
    if len(sys.argv) != 2:
        print("Usage: python3 validate_todo_json.py <json_file_path>", file=sys.stderr)
        sys.exit(1)

    file_path = sys.argv[1]
    ok, errors = validate(file_path)

    if ok:
        print(f"✅ Validation passed: {file_path}")
        sys.exit(0)
    else:
        print(f"❌ Validation failed: {file_path}", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
