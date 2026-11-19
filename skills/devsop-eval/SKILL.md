---
name: devsop-eval
description: Reviews a project's documented context and engineering practices and produces an evidence-based report. Use for a quick baseline or a detailed assessment.
---

# devsop-eval

Review project context and engineering practices using repository evidence. The default is a quick check; perform the full 28-item scored assessment only when the user asks for a detailed evaluation. Evaluate outcomes, not adoption of a particular coding agent, Skill format, or task workflow.

## Output

Write the result to `$REPO_ROOT/.docs/devsop_report.md`. Create `.docs/` if needed. Do not edit source code or project configuration. Tell the user the report path and summarize the most important findings.

Resolve paths at startup:

```bash
eval "$(bash "$SKILL_DIR/scripts/resolve_paths.sh")"
```

`$SKILL_DIR` is the directory containing this Skill; `$REPO_ROOT` is the current project's Git root, or the current directory when it is not a Git repository. Read criteria and scripts through the absolute `$SKILL_DIR` path; run evidence commands from `$REPO_ROOT`.

## Default: quick check

Inspect the repository once and assess each pillar with the corresponding question. For each, report **Status** (Good / Needs attention / Not assessed), one or two evidence paths or command results, and one practical next step.

| Pillar | Quick-check question |
|---|---|
| A. Project AI-friendliness | Can a developer or AI agent understand the project and run it or its tests from the available entry docs? |
| B. Development coordination | Can contributors discover how changes are coordinated, owned, verified, and reviewed? |
| C. Quality checks | Are automated checks and review rules in place to catch common defects before changes merge? |
| D. Change management | Is change context recorded, verification appropriate, and project guidance updated when needed? |
| E. Shared knowledge | Does the repository preserve reusable project knowledge beyond source code? |
| F. Improvement loop | Does the team review outcomes and track improvements over time? |

Do not calculate a numerical score or maturity level in the quick check. A six-question sample is not a substitute for the full rubric. Keep the report concise: project/date, six pillar findings, prioritized actions (up to five), and evidence limitations.

If evidence is missing or a check cannot be completed, mark it **Not assessed** and state why; do not treat missing execution or unavailable tools as a project failure.

## Full assessment (when requested)

Use the complete 28-item rubric in `references/sop-scoring-criteria.md` and render the detailed report with `references/sop-report-template.md`. Follow these rules:

1. Detect the language stack and project type using repository files and `scripts/detect_project_type.sh`.
2. Collect shared evidence once with `scripts/collect_evidence.sh`. Check the cache first; run additional read-only commands only when needed.
3. Evaluate all 28 items against the rubric. Each item needs a conclusion, concrete evidence, and grader type (code / model / manual).
4. Score PASS at full weight, PARTIAL at 40% of its weight, and FAIL at zero. Apply only rubric-defined exemptions and explain each exemption.
5. Run the required anti-pattern checks. Summarize evidence-backed priorities and actionable tasks.
6. If any item cannot be evaluated, mark it `NOT_ASSESSED`. Do not score it as zero. Complete the evaluation from the main agent when an optional delegated check fails. If any item remains unassessed, label the report incomplete and do not present a total score or maturity level.

Optional sub-agents may evaluate independent pillars, but are never required. The main agent remains responsible for complete coverage, evidence quality, score aggregation, and the final report.

## Optional structured output

When the user asks for JSON, derive it from a completed full report, save it in the target repository or a user-specified path, and validate it with:

```bash
python3 "$SKILL_DIR/scripts/validate_todo_json.py" <json_file_path>
```

Do not use a sub-agent as a required converter. Do not create JSON from an incomplete report.

## Guardrails

- Read-only assessment: write only the requested report and, when requested, the JSON output.
- Evidence first: distinguish observed facts from interpretation; never invent project practices.
- Missing evidence is not proof of failure. Report uncertainty explicitly.
- Do not assess code quality itself; assess the project's documented and automated development practices.
- Never run `git add`, `git commit`, or other commands that change project history.
