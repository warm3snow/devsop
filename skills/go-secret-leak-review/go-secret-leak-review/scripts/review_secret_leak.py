#!/usr/bin/env python3
"""
go-secret-leak-review 主入口（脚本驱动）

职责（不自己调用 LLM 子 Agent；子 Agent 由调用方按 SKILL.md 派发）：
  1. extract : 调用 extract_diff.sh 抽取 commitA..commitB 增量 diff。
  2. assemble: 把子 Agent 返回的 findings JSON 汇总成最终报告写入 REPO_ROOT。

典型流程（见 SKILL.md）：
  A. python3 review_secret_leak.py extract <repo> <A> <B> [--path=...] [--out=diff.txt]
       → 拿到增量 diff；若为空直接产出「无增量」报告。
  B. 调用方读取 references/secret-leak-review-prompt.md，连同 diff 派发子 Agent
     （Agent tool, run_in_background, 只读）。
  C. 子 Agent 返回 findings JSON → 调用方保存为 findings.json。
  D. python3 review_secret_leak.py assemble <repo> <A> <B> --findings=findings.json [--out=report.json]
       → 写出最终报告。

硬约束：只读 git；绝不 git add/commit；报告只写 REPO_ROOT，绝不写 SKILL_DIR/HOME。
"""

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def _script_dir() -> Path:
    return Path(__file__).resolve().parent


_FULL_KEYWORDS = {"", "all", "全部", "*"}
_SINGLE_KEYWORDS = {"", "single", "-"}


def _is_full_mode(commit_a: str, commit_b: str) -> bool:
    """commitA/commitB 任一为全量关键字（大小写不敏感）→ 全量扫描。"""
    return commit_a.strip().lower() in _FULL_KEYWORDS or commit_b.strip() in _FULL_KEYWORDS


def _is_single_mode(commit_a: str, commit_b: str) -> bool:
    """commitA 非空且非全量关键字，commitB 为单 commit 关键字（空/single/-）→ 单 commit 模式。"""
    a = commit_a.strip()
    b = commit_b.strip().lower()
    return bool(a) and a.lower() not in _FULL_KEYWORDS and b in _SINGLE_KEYWORDS


def _mode_of(commit_a: str, commit_b: str) -> str:
    if _is_full_mode(commit_a, commit_b):
        return "full"
    if _is_single_mode(commit_a, commit_b):
        return "single"
    return "incremental"


def _run_extract_diff(repo: str, commit_a: str, commit_b: str, path_filter: str):
    """调用 extract_diff.sh，返回 (diff_text, returncode)。"""
    sh = _script_dir() / "extract_diff.sh"
    if not sh.is_file():
        raise FileNotFoundError(f"缺少脚本: {sh}")
    cmd = [str(sh), repo, commit_a, commit_b]
    if path_filter:
        cmd.append(path_filter)
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True)
    except Exception as e:  # noqa: BLE001
        print(f"⚠️  执行 extract_diff.sh 失败: {e}", file=sys.stderr)
        sys.exit(1)
    if proc.returncode != 0:
        # extract_diff.sh 已把原因打到 stderr
        print(proc.stderr.strip(), file=sys.stderr)
        sys.exit(proc.returncode)
    return proc.stdout


def _range_str(commit_a: str, commit_b: str, mode: str) -> str:
    if mode == "full":
        return "FULL(全量扫描)"
    if mode == "single":
        return f"{commit_a}^(单 commit)"
    return f"{commit_a}..{commit_b}"


def _empty_report(repo: str, commit_a: str, commit_b: str, out_path: Path, full_mode: bool = False, single_mode: bool = False):
    if full_mode:
        mode = "full"
    elif single_mode:
        mode = "single"
    else:
        mode = "incremental"
    range_str = _range_str(commit_a, commit_b, mode)
    note = {
        "full": "全量扫描未命中任何 Go 源码（或仓库为空）。",
        "single": f"commit {commit_a} 相对其父无变更（或该 commit 不存在文件变更）。",
        "incremental": "指定 commit 区间内无增量代码（或两 commit 相同）。",
    }[mode]
    report = {
        "skill": "go-secret-leak-review",
        "mode": mode,
        "repo": str(Path(repo).resolve()),
        "commit_range": range_str,
        "generated_at": datetime.now().isoformat(timespec="milliseconds"),
        "summary": {"total_findings": 0, "by_level": {"L1": 0, "L2": 0, "L3": 0, "L4": 0}, "by_confidence": {"high": 0, "medium": 0, "low": 0}},
        "findings": [],
        "note": note,
    }
    out_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"✅ 无可审查代码，已生成空报告: {out_path}")


def cmd_extract(args):
    mode = _mode_of(args.commit_a, args.commit_b)
    diff = _run_extract_diff(args.repo, args.commit_a, args.commit_b, args.path)
    if not diff.strip():
        out = Path(args.out)
        _empty_report(args.repo, args.commit_a, args.commit_b, out,
                      full_mode=(mode == "full"), single_mode=(mode == "single"))
        return
    out_path = Path(args.out)
    out_path.write_text(diff, encoding="utf-8")
    mode_label = {"full": "全量", "single": "单 commit", "incremental": "增量"}[mode]
    print(f"✅ {mode_label}代码已抽取: {out_path} ({len(diff.splitlines())} 行)")
    print("下一步: 读取 references/secret-leak-review-prompt.md，连同该 diff 派发子 Agent；")
    print("       子 Agent 返回 findings JSON 后，运行 assemble 汇总报告。")


def cmd_assemble(args):
    mode = _mode_of(args.commit_a, args.commit_b)
    findings_path = Path(args.findings)
    if not findings_path.is_file():
        print(f"错误: findings 文件不存在: {findings_path}", file=sys.stderr)
        sys.exit(1)
    try:
        data = json.loads(findings_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"错误: findings JSON 解析失败: {e}", file=sys.stderr)
        sys.exit(1)

    findings = data.get("findings", []) if isinstance(data, dict) else []
    if not isinstance(findings, list):
        print("错误: findings 必须是数组", file=sys.stderr)
        sys.exit(1)

    level_counts = {"L1": 0, "L2": 0, "L3": 0, "L4": 0}
    confidence_counts = {"high": 0, "medium": 0, "low": 0}
    for f in findings:
        lvl = f.get("level")
        if lvl in level_counts:
            level_counts[lvl] += 1
        conf = f.get("confidence")
        if conf in confidence_counts:
            confidence_counts[conf] += 1

    range_str = _range_str(args.commit_a, args.commit_b, mode)
    report = {
        "skill": "go-secret-leak-review",
        "mode": mode,
        "repo": str(Path(args.repo).resolve()),
        "commit_range": range_str,
        "generated_at": datetime.now().isoformat(timespec="milliseconds"),
        "summary": {
            "total_findings": len(findings),
            "by_level": level_counts,
            "by_confidence": confidence_counts,
        },
        "findings": findings,
    }
    out_path = Path(args.out)
    out_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"✅ 报告已生成: {out_path}")
    print(f"📊 命中: 总计 {len(findings)} "
          f"(L4={level_counts['L4']}, L3={level_counts['L3']}, "
          f"L2={level_counts['L2']}, L1={level_counts['L1']})")
    print(f"📊 置信度: high={confidence_counts['high']}, "
          f"medium={confidence_counts['medium']}, low={confidence_counts['low']}")
    if level_counts["L4"] > 0:
        print("🚨 存在 L4 级（极高敏感）隐私泄露，请立即处理！")


def build_parser():
    p = argparse.ArgumentParser(description="go-secret-leak-review 主入口")
    sub = p.add_subparsers(dest="cmd", required=True)

    pe = sub.add_parser("extract", help="抽取增量 diff / 单 commit 变更 / 全量代码")
    pe.add_argument("repo")
    pe.add_argument("commit_a", help="区间起点；单 commit 模式为目标 commit；全量传 all/全部/*")
    pe.add_argument("commit_b", help="区间终点；单 commit 传 - 或留空；全量传 all/全部/*")
    pe.add_argument("--path", default="", help="可选路径过滤，传给 git diff -- <path> 或全量 find 前缀")
    pe.add_argument("--out", default="go-secret-leak-diff.txt", help="diff 输出文件（写 REPO_ROOT）")
    pe.set_defaults(func=cmd_extract)

    pa = sub.add_parser("assemble", help="汇总子 Agent findings 为最终报告")
    pa.add_argument("repo")
    pa.add_argument("commit_a", help="区间起点；单 commit 模式为目标 commit；全量传 all/全部/*")
    pa.add_argument("commit_b", help="区间终点；单 commit 传 - 或留空；全量传 all/全部/*")
    pa.add_argument("--findings", required=True, help="子 Agent 返回的 findings JSON 路径")
    pa.add_argument("--out", default="go-secret-leak-report.json", help="报告输出（写 REPO_ROOT）")
    pa.set_defaults(func=cmd_assemble)

    return p


def main():
    args = build_parser().parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
