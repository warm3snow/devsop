#!/usr/bin/env python3
"""
go-secret-leak-review main entry (script-driven)

Responsibilities (does not call the LLM sub-agent itself; the sub-agent is dispatched by the caller per SKILL.md):
  1. extract : calls extract_diff.sh to extract the commitA..commitB incremental diff.
  2. assemble: aggregates the findings JSON returned by the sub-agent into the final report written to REPO_ROOT.

Typical flow (see SKILL.md):
  A. python3 review_secret_leak.py extract <repo> <A> <B> [--path=...] [--out=diff.txt]
       → get the incremental diff; if empty, directly produce a "no increment" report.
  B. The caller reads references/secret-leak-review-prompt.md and dispatches the sub-agent along with the diff
     (Agent tool, run_in_background, read-only).
  C. The sub-agent returns findings JSON → the caller saves it as findings.json.
  D. python3 review_secret_leak.py assemble <repo> <A> <B> --findings=findings.json [--out=report.json]
       → writes the final report.

Hard constraints: read-only git; never git add/commit; the report is written only to REPO_ROOT, never to SKILL_DIR/HOME.
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


_FULL_KEYWORDS = {"", "all", "*"}
_SINGLE_KEYWORDS = {"", "single", "-"}


def _is_full_mode(commit_a: str, commit_b: str) -> bool:
    """Either commitA/commitB is a full-scan keyword (case-insensitive) → full scan."""
    return commit_a.strip().lower() in _FULL_KEYWORDS or commit_b.strip() in _FULL_KEYWORDS


def _is_single_mode(commit_a: str, commit_b: str) -> bool:
    """commitA is non-empty and not a full-scan keyword, and commitB is a single-commit keyword (empty/single/-) → single-commit mode."""
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
    """Call extract_diff.sh, returning (diff_text, returncode)."""
    sh = _script_dir() / "extract_diff.sh"
    if not sh.is_file():
        raise FileNotFoundError(f"missing script: {sh}")
    cmd = [str(sh), repo, commit_a, commit_b]
    if path_filter:
        cmd.append(path_filter)
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True)
    except Exception as e:  # noqa: BLE001
        print(f"⚠️  failed to run extract_diff.sh: {e}", file=sys.stderr)
        sys.exit(1)
    if proc.returncode != 0:
        # extract_diff.sh already prints the reason to stderr
        print(proc.stderr.strip(), file=sys.stderr)
        sys.exit(proc.returncode)
    return proc.stdout


def _range_str(commit_a: str, commit_b: str, mode: str) -> str:
    if mode == "full":
        return "FULL(full scan)"
    if mode == "single":
        return f"{commit_a}^(single commit)"
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
        "full": "full scan found no Go source files (or the repo is empty).",
        "single": f"commit {commit_a} has no changes relative to its parent (or the commit has no file changes).",
        "incremental": "no incremental code in the specified commit range (or the two commits are identical).",
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
    print(f"✅ No reviewable code, empty report generated: {out_path}")


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
    mode_label = {"full": "full", "single": "single-commit", "incremental": "incremental"}[mode]
    print(f"✅ {mode_label} code extracted: {out_path} ({len(diff.splitlines())} lines)")
    print("Next: read references/secret-leak-review-prompt.md and dispatch the sub-agent along with this diff;")
    print("      after the sub-agent returns the findings JSON, run assemble to aggregate the report.")


def cmd_assemble(args):
    mode = _mode_of(args.commit_a, args.commit_b)
    findings_path = Path(args.findings)
    if not findings_path.is_file():
        print(f"Error: findings file does not exist: {findings_path}", file=sys.stderr)
        sys.exit(1)
    try:
        data = json.loads(findings_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"Error: findings JSON parse failed: {e}", file=sys.stderr)
        sys.exit(1)

    findings = data.get("findings", []) if isinstance(data, dict) else []
    if not isinstance(findings, list):
        print("Error: findings must be an array", file=sys.stderr)
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
    print(f"✅ Report generated: {out_path}")
    print(f"📊 Findings: total {len(findings)} "
          f"(L4={level_counts['L4']}, L3={level_counts['L3']}, "
          f"L2={level_counts['L2']}, L1={level_counts['L1']})")
    print(f"📊 Confidence: high={confidence_counts['high']}, "
          f"medium={confidence_counts['medium']}, low={confidence_counts['low']}")
    if level_counts["L4"] > 0:
        print("🚨 L4-level (extremely sensitive) privacy leaks found, handle immediately!")


def build_parser():
    p = argparse.ArgumentParser(description="go-secret-leak-review main entry")
    sub = p.add_subparsers(dest="cmd", required=True)

    pe = sub.add_parser("extract", help="extract incremental diff / single-commit changes / full code")
    pe.add_argument("repo")
    pe.add_argument("commit_a", help="range start; in single-commit mode the target commit; pass all/* for full scan")
    pe.add_argument("commit_b", help="range end; pass - or leave empty for single commit; pass all/* for full scan")
    pe.add_argument("--path", default="", help="optional path filter, passed to git diff -- <path> or used as the find prefix in full mode")
    pe.add_argument("--out", default="go-secret-leak-diff.txt", help="diff output file (written to REPO_ROOT)")
    pe.set_defaults(func=cmd_extract)

    pa = sub.add_parser("assemble", help="aggregate sub-agent findings into the final report")
    pa.add_argument("repo")
    pa.add_argument("commit_a", help="range start; in single-commit mode the target commit; pass all/* for full scan")
    pa.add_argument("commit_b", help="range end; pass - or leave empty for single commit; pass all/* for full scan")
    pa.add_argument("--findings", required=True, help="path to the findings JSON returned by the sub-agent")
    pa.add_argument("--out", default="go-secret-leak-report.json", help="report output (written to REPO_ROOT)")
    pa.set_defaults(func=cmd_assemble)

    return p


def main():
    args = build_parser().parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
