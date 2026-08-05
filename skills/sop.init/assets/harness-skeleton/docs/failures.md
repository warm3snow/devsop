# Pitfall Log

> Status: Draft | Maintainer: everyone | Last Updated: {{YYYY-MM-DD}}

## Scope

Records non-obvious problems encountered in development/deployment/runtime, AI collaboration failure cases, and temporary workarounds for known bugs. The purpose of each entry is not "memorializing" but **gradually converting into standard requirements** (update `coding-style.md` / `unittest/unittest.md` / `code-review.md` etc.).

## Writing Standards

- Each entry is its own section; the title is a one-sentence description of the symptom
- Required fields: date, context, root cause, temporary workaround, permanent fix, related links (PR/Issue)
- AI failure cases must be kept: original Prompt, AI output, expected vs actual, root cause analysis
- Entries that have been incorporated into standards are marked `✅ standardized`, and can be archived periodically

## Template

```markdown
### YYYY-MM-DD: {{one-sentence symptom}}

- **Context**: {{when and where, triggered by what operation}}
- **Root cause**: {{the real cause, not the surface symptom}}
- **Temporary workaround**: {{how it was resolved at the time}}
- **Permanent fix**: {{long-term solution / merged PR link}}
- **Incorporated into**: {{which standards file it was updated into, or TODO}}
- **Reference**: {{Issue / PR / doc link}}
```

---

## Records

### {{YYYY-MM-DD}}: {{example: AI treated a timestamp field as a string, causing a panic}}

- **Context**: {{fill in}}
- **Root cause**: {{fill in}}
- **Temporary workaround**: {{fill in}}
- **Permanent fix**: {{fill in}}
- **Incorporated into**: {{api-standards.md §Field Conventions updated}}
- **Reference**: {{link}}

<!-- Append new entries at the top, in reverse chronological order -->

## Archived (Incorporated into Standards)

- {{YYYY-MM-DD}} {{symptom}} → standard: {{file + section}}
