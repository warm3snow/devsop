# Failure Records Guide

> Use this guide when the project has evidence-backed operational or development failure records to document. The main agent can follow it directly or delegate the task when supported.

---

## Additional Data Sources (execute after the common step 3 "Scan project context")

Beyond the common context scan, you also need to extract pitfall information from the following sources:

### A. Project Records

Read project-owned sources when available:
- Issue tracker and pull-request discussions
- Incident reviews, decision records, and troubleshooting docs
- Git history for fixes, reverts, and workarounds

Extract evidence-backed recurring bugs, difficult root causes, and operational pitfalls. Do not treat AI sessions or user-level agent memory as required project sources.

### B. Git Log Analysis

Run the following commands to extract fix-type commits (limited to the most recent 100, to avoid context explosion):

```bash
# Extract commits containing fix keywords
git log --oneline --all -n 100 --format="%h %s" 2>/dev/null | \
  grep -i -E "(fix|bug|hotfix|revert|workaround|hack|rollback)" || true

# Extract revert commits (usually mean the previous commit had a problem)
git log --oneline --grep="revert" -n 20 2>/dev/null || true
```

Identify from the Git Log:
- Patterns of repeatedly modifying the same file/function (implying that area is error-prone)
- Commit pairs of revert-then-fix (indicating the first approach had a problem)
- Commits whose message contains a root-cause description

### C. Consolidation and Writing

Organize the pitfall information extracted from project records and Git history into standalone entries per the template format:

- Each entry must have: date, context, root cause, temporary workaround, root-cause fix
- When information is incomplete, fill in known fields truthfully and mark unknown fields as `{{To be supplemented}}`
- Sort by time in descending order (most recent at the top)
- If no pitfall information is found, keep the template structure but note "no historical pitfall records yet, to be accumulated" in the records area

## Additional Constraints

- If Git history or other sources are unavailable, state that the evidence could not be checked
- **Do not fabricate** pitfall records; only record entries supported by clear evidence
- For issues inferred from the Git Log, mark `Source: git log` to distinguish the level of certainty
