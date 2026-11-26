# DEVSOP Evaluation Report Template

## Contents

- Overview Score → Capability Eval Details → Anti-pattern Detection → Entropy Management
- Prioritized Improvement Suggestions → Upgrade Roadmap → Core Conclusions → Todo Suggestions → Appendix
- Todo Suggestions are wrapped in `DEVSOP_TODOS_START` / `DEVSOP_TODOS_END` HTML markers so the improvement list can be extracted reliably.

This template is used by the `devsop-eval` skill to render the final report at the resolved `$REPORT_PATH`, preserving an existing report location or using the project's documentation root.
Use it only for the full 28-item assessment; the default quick check uses a shorter six-pillar format without a score.

> Rendering rules:
> - `{placeholders}` are filled in by the main agent
> - Markers ✅/⚠️/❌/🔴/🟡/🟢 are kept as-is
> - Table rows are generated dynamically from the actual evaluation results
> - The report is written by **direct overwrite**; git keeps version history

---

# 📋 DEVSOP Maturity Evaluation Report

**Project**: {project name}
**Evaluation date**: {YYYY-MM-DD}
**DEVSOP version**: v1.0
**Evaluator**: {evaluator or agent name}
**Previous evaluation**: {YYYY-MM-DD or "first evaluation"}

---

## 📊 Overview Score

| Pillar | Score | Full score | Completion | Status |
|--------|-------|------------|------------|--------|
| A. Project AI-friendliness | {X} | 25 | {X%} | 🔴/🟡/🟢 |
| B. Development coordination | {X} | 15 | {X%} | 🔴/🟡/🟢 |
| C. Quality checks & feedback mechanisms | {X} | 25 | {X%} | 🔴/🟡/🟢 |
| D. Design & change management | {X} | 15 | {X%} | 🔴/🟡/🟢 |
| E. Shared project knowledge | {X} | 5 | {X%} | 🔴/🟡/🟢 |
| F. Measurement mechanisms | {X} | 15 | {X%} | 🔴/🟡/🟢 |
| **Total** | **{X}** | **100** | **{X%}** | — |

> 🔴 0-40% low  🟡 41-70% medium  🟢 71-100% high

### Maturity Level

**🏆 Level {0-4} — {level name}**

> {one sentence: the current state of the project's implementation of the team DEVSOP}

| Total | Level | Name |
|-------|-------|------|
| 0-19 | L0 | No DEVSOP |
| 20-39 | L1 | Basic constraints |
| 40-59 | L2 | Gates established |
| 60-79 | L3 | Closed-loop flow |
| 80-100 | L4 | Continuous optimization |

---

## 🔬 Capability Eval Details

### A. Project AI-friendliness（{score}/25）

| Eval | Conclusion | Evidence | Grader |
|------|-----------|----------|--------|
| A1 Project AI entry is concise and useful | ✅/⚠️/❌ | {entry point and linked sources} | code+model |
| A2 Project introduction and getting started | ✅/⚠️/❌ | {entry-point content and links} | model |
| A3 Architecture guidance complete | ✅/⚠️/❌ | {authoritative source path(s) and covered topics} | model |
| A4 Core project guidance is relevant and substantive | ✅/⚠️/❌ | {relevant guidance and gaps} | model |
| A5 Generic AI entry present | ✅/⚠️/❌ | {AGENTS.md and .gitignore check} | code |
| A6 One-command start | ✅/⚠️/❌ | {Makefile target / package.json scripts} | code |
| A7 Environment config template | ✅/⚠️/❌ | {.env.example status / README env-var docs} | code |

**Evaluation confidence**: 🟢 high / 🟡 medium / 🔴 low

**Details**:
> {2-3 sentences explaining the judgment reasons for PARTIAL items, especially the subjective parts judged by the model Grader}

---

### B. Development coordination（{score}/15）

| Eval | Conclusion | Evidence | Grader |
|------|-----------|----------|--------|
| B1 Project development workflow is discoverable | ✅/⚠️/❌ | {repository docs or linked team process} | model |
| B2 Ownership and responsibilities are clear | ✅/⚠️/❌ | {owners/review responsibilities or gaps} | model |
| B3 Change context and outputs are findable | ✅/⚠️/❌ | {issue, PR, docs, tests, and result locations} | code+model |
| B4 Branch/Commit conventions | ✅/⚠️/❌ | {commitlint config / conventions doc path} | code+model |

**Evaluation confidence**: 🟢 high / 🟡 medium / 🔴 low

**Details**:
> {supplementary notes}

---

### C. Quality checks & feedback mechanisms（{score}/25）

| Eval | Conclusion | Evidence | Grader |
|------|-----------|----------|--------|
| C1 Commit and push conventions documented | ✅/⚠️/❌ | {version-controlled guidance + covered items (commit / push)} | code+model |
| C2 CI pipeline + coverage gate (CI config file or project docs with CI platform URL) | ✅/⚠️/❌ | {CI config path (e.g. .github/workflows/, .gitlab-ci.yml, Jenkinsfile) or CI platform URL in docs + coverage threshold} | code |
| C3 Prohibited-item protection | ✅/⚠️/❌ | {.gitignore rules + doc explanation} | code+model |
| C4 Branch protection and Review flow | ✅/⚠️/❌ | {documented constraint count} | model |
| C5 Recurring-issue feedback | ✅/⚠️/❌ | {authoritative source path + maintenance/review evidence} | code+model |
| C6 Security scanning/dependency vulnerabilities | ✅/⚠️/❌ | {security-scan tool config / CI integration} | code |
| C7 E2E/integration tests | ✅/⚠️/❌ | {test dirs + CI steps} | code |

**Evaluation confidence**: 🟢 high / 🟡 medium / 🔴 low

**Details**:
> {supplementary notes}

---

### D. Design & change management（{score}/15）

| Eval | Conclusion | Evidence | Grader |
|------|-----------|----------|--------|
| D1 Significant change intent is captured | ✅/⚠️/❌ | {sampled issue, PR, design note, or equivalent} | code+model |
| D2 Change records reflect outcomes | ✅/⚠️/❌ | {sampled records and links to outcomes/status} | code+model |
| D3 Verification matches change risk | ✅/⚠️/❌ | {relevant tests/checks and regression evidence} | code+model |
| D4 Project guidance changes with the product | ✅/⚠️/❌ | {documentation updates for behavior/setup changes} | code+model |

**Evaluation confidence**: 🟢 high / 🟡 medium / 🔴 low

**Details**:
> {supplementary notes}

---

### E. Shared project knowledge（{score}/5）

| Eval | Conclusion | Evidence | Grader |
|------|-----------|----------|--------|
| E1 Project guidance is discoverable | ✅/⚠️/❌ | {entry point and linked project guidance} | model |
| E2 Shared knowledge is useful and maintained | ✅/⚠️/❌ | {substantive project docs or linked team knowledge base} | code+model |

**Evaluation confidence**: 🟢 high / 🟡 medium / 🔴 low

**Details**:
> {supplementary notes}

---

### F. Measurement mechanisms（{score}/15）

| Eval | Conclusion | Evidence | Grader |
|------|-----------|----------|--------|
| F1 Evaluation history and improvement actions | ✅/⚠️/❌ | {report history + concrete improvement records} | code+model |
| F2 Decisions and recurring failure knowledge are retained | ✅/⚠️/❌ | {decision records, incident notes, or documented lessons} | code+model |
| F3 Project-guidance changes traceable | ✅/⚠️/❌ | {relevant update evidence or stale guidance} | code+model |
| F4 Improvement-loop closure | ✅/⚠️/❌ | {historical evaluation count + improved items} | code+model |

**Evaluation confidence**: 🟢 high / 🟡 medium / 🔴 low

**Details**:
> {supplementary notes}

---

## ⚠️ Anti-pattern Detection

| Anti-pattern | Status | Notes |
|--------------|--------|-------|
| Project guidance materially out of sync with code | 🟢 not found / 🔴 present | {verified mismatch examples} |
| Excessive test mocking | 🟢 not found / 🔴 present | {mock vs integration test file ratio} |
| Sensitive files or artifacts committed | 🟢 not found / 🔴 present | {hit file list} |
| Important decisions not captured in docs | 🟢 not found / 🔴 present | {sampled PR commit summary} |
| Recurring-issue records are stale or empty | 🟢 not found / 🔴 present | {authoritative source path + last modified time} |
| Project AI entry lacks useful context | 🟢 not found / 🔴 present | {entry point and missing links/context} |

> Anti-patterns do not affect pillar scores, but a 🔴 status is emphasized in the "Core Conclusions".

---

## 🌪️ Entropy Management Evaluation

| Metric | Current value | Healthy threshold | Rating |
|--------|---------------|-------------------|--------|
| Project-guidance freshness | {accurate / stale / unknown with evidence} | Context-dependent | 🟢/🟡/🔴 |
| Mock health (mock file count / integration test file count) | {mock: X, integration: Y} | integration tests >0 | 🟢/🟡/🔴 |
| Recurring-issue learning | {evidence of resolution and retained lessons when relevant} | Context-dependent | 🟢/🟡/🔴 |
| Project-guidance traceability | {relevant updates or justified stability} | Context-dependent | 🟢/🟡/🔴 |

**Entropy management judgment**:
> {1-2 sentences: is the tech-debt cleanup mechanism running? Are docs/code evolving in sync?}

---

## 🎯 Prioritized Improvement Suggestions

### 🔥 High priority (complete within this sprint)

| # | Related Eval | Issue | Action | Expected benefit |
|---|--------------|-------|--------|------------------|
| 1 | {C1} | {specific missing content} | {concrete executable action, with file path/command} | {expected status or score change} |
| 2 | ... | | | |

### 🌱 Medium priority (complete within this month)

| # | Related Eval | Issue | Action | Expected benefit |
|---|--------------|-------|--------|------------------|
| ... | | | | |

### 🌳 Low priority (quarterly planning)

| # | Related Eval | Issue | Action | Expected benefit |
|---|--------------|-------|--------|------------------|
| ... | | | | |

> Improvement suggestions reference: the `devsop-eval` Skill's `sop-improvement-examples.md` (in the Skill install dir, user-level `~/.agents/skills/devsop-eval/` or project-level `<repo>/.agents/skills/devsop-eval/`)

---

## 🚀 Upgrade Roadmap

**Current level**: L{N} — {level name}
**Next target**: L{N+1} — {next level name}

### Improvement milestones

To reach L{N+1}, prioritize:

- [ ] {milestone 1: e.g. "improve C2 from PARTIAL to PASS"}
  - Key action: {concrete action}
  - Owner: {suggested assignee}
- [ ] {milestone 2}
  - ...
- [ ] {milestone 3}

> After completing the milestones above, ask an AI coding agent to run `devsop-eval` again and verify the evidence.

---

## 💡 Core Conclusions

{3-4 sentence summary, including:
1. the overall level of the project's current DEVSOP implementation
2. the strongest 1-2 pillars
3. the weakest 1-2 pillars (including anti-patterns, if any)
4. the single most critical improvement direction for the next step}

---

## 📌 Todo Suggestions

> This table targets the team task system; the frontend can parse it and convert it into issue-tracker tickets with one click. Distill 3-7 **independently actionable** items that are **completable within a week** from the "Prioritized Improvement Suggestions".

<!-- DEVSOP_TODOS_START -->
| Todo title | Improvement plan |
|------------|------------------|
| {short action description, ≤25 chars} | {3-5 sentence concrete plan: where to change, change it to what, related Eval ID} |
| ... | ... |
<!-- DEVSOP_TODOS_END -->

---

## 📎 Appendix

### A. Evaluation command arguments

```
{$ARGUMENTS as passed by the user}
```

### B. Next recommended evaluation time

**{YYYY-MM-DD}** (recommended monthly or after every major process change)

---

*This report was generated by the `devsop-eval` Skill (install location: user-level `~/.agents/skills/devsop-eval/` or repo-level `<repo>/.agents/skills/devsop-eval/`). To adjust the scoring dimensions or weights, modify `devsop-scoring-criteria.md` in the Skill install dir and re-run.*
