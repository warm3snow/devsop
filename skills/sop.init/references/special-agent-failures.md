# failures.md Special Sub-Agent Instructions

> This file serves as the **supplementary instructions** for the `failures.md` sub-agent, on top of the common prompt. When the main Agent dispatches the failures.md sub-agent, it passes this file's content along.

---

## Additional Data Sources (execute after the common step 3 "Scan project context")

Beyond the common context scan, you also need to extract pitfall information from the following sources:

### A. Memory Records

Read the AI Agent's Memory/memory files (if any exist):
- `.codebuddy/memory/` directory
- Memory files in the `.claude/` directory
- Other AI memory storage locations in the project (handle per the directories actually found)

Extract from them:
- Records of Bug fixes (especially problems that recurred repeatedly or took a long time to locate)
- Cases where AI-generated code was corrected by humans
- Experience explicitly marked as "pitfall", "caution", "hit this"

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

Organize the pitfall information extracted from Memory and Git Log into standalone entries per the template format:

- Each entry must have: date, context, root cause, temporary workaround, root-cause fix
- When information is incomplete, fill in known fields truthfully and mark unknown fields as `{{To be supplemented}}`
- Sort by time in descending order (most recent at the top)
- If no pitfall information is found, keep the template structure but note "no historical pitfall records yet, to be accumulated" in the records area

## Additional Constraints

- Silently skip Git Log command failures (e.g. not a git repository); do not report errors
- Silently skip when Memory files do not exist
- **Do not fabricate** pitfall records; only record entries supported by clear evidence
- For issues inferred from the Git Log, mark `Source: git log` to distinguish the level of certainty
