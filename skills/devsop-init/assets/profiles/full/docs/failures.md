# Pitfall Log

> Status: Draft | Maintainer: everyone | Last Updated: {{YYYY-MM-DD}}

## Scope

Records non-obvious problems encountered in development, deployment, or runtime, including root causes and temporary workarounds. The purpose is to help prevent recurrence and improve relevant project guidance when needed.

## Writing Standards

- Each entry is its own section; the title is a one-sentence description of the symptom
- Required fields: date, context, root cause, temporary workaround, permanent fix, related links (PR/Issue)
- Record only project-relevant facts; do not include credentials, personal data, or private conversation transcripts
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

### {{YYYY-MM-DD}}: {{short description of the failure}}

- **Context**: {{fill in}}
- **Root cause**: {{fill in}}
- **Temporary workaround**: {{fill in}}
- **Permanent fix**: {{fill in}}
- **Incorporated into**: {{api-standards.md §Field Conventions updated}}
- **Reference**: {{link}}

<!-- Append new entries at the top, in reverse chronological order -->

## Archived (Incorporated into Standards)

- {{YYYY-MM-DD}} {{symptom}} → standard: {{file + section}}
