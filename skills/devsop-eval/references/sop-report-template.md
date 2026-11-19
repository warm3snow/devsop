# DEVSOP Evaluation Report Template

## Contents

- Overview Score → Capability Eval Details → Anti-pattern Detection → Entropy Management → Skill Health
- Prioritized Improvement Suggestions → Upgrade Roadmap → Core Conclusions → Todo Suggestions → Appendix
- Todo Suggestions must be wrapped in `DEVSOP_TODOS_START` / `DEVSOP_TODOS_END` HTML markers (used by the JSON converter).

This template is used by the `devsop-eval` skill to render the final report, **target path: `.docs/devsop_report.md`**.
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
| B. Dev mode / role collaboration | {X} | 15 | {X%} | 🔴/🟡/🟢 |
| C. Quality checks & feedback mechanisms | {X} | 25 | {X%} | 🔴/🟡/🟢 |
| D. Design & change management | {X} | 15 | {X%} | 🔴/🟡/🟢 |
| E. Shared knowledge base | {X} | 5 | {X%} | 🔴/🟡/🟢 |
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
| A1 AGENTS.md exists and ≤300 lines | ✅/⚠️/❌ | {file path / line count} | code |
| A2 README.md complete | ✅/⚠️/❌ | {covered section list} | model |
| A3 .docs/architecture.md complete | ✅/⚠️/❌ | {covered section list} | model |
| A4 .docs/ regulations library covers the new core docs (incl. content substance) | ✅/⚠️/❌ | {present/missing/placeholder file list} | code+model |
| A5 Multi-tool symlinks + checked in | ✅/⚠️/❌ | {link status + .gitignore check} | code |
| A6 One-command start | ✅/⚠️/❌ | {Makefile target / package.json scripts} | code |
| A7 Environment config template | ✅/⚠️/❌ | {.env.example status / README env-var docs} | code |

**Evaluation confidence**: 🟢 high / 🟡 medium / 🔴 low

**Details**:
> {2-3 sentences explaining the judgment reasons for PARTIAL items, especially the subjective parts judged by the model Grader}

---

### B. Dev mode / role collaboration（{score}/15）

| Eval | Conclusion | Evidence | Grader |
|------|-----------|----------|--------|
| B1 9-step R&D flow explicit | ✅/⚠️/❌ | {doc path + covered steps} | model |
| B2 Role responsibility conventions | ✅/⚠️/❌ | {covered roles + item count} | model |
| B3 Phase deliverables have ownership locations | ✅/⚠️/❌ | {design/task/test dirs} | code+model |
| B4 Branch/Commit conventions | ✅/⚠️/❌ | {commitlint config / conventions doc path} | code+model |

**Evaluation confidence**: 🟢 high / 🟡 medium / 🔴 low

**Details**:
> {supplementary notes}

---

### C. Quality checks & feedback mechanisms（{score}/25）

| Eval | Conclusion | Evidence | Grader |
|------|-----------|----------|--------|
| C1 Commit/Push conventions memorized (AGENTS.md / project rules dir) | ✅/⚠️/❌ | {rule file paths + covered items (commit / push)} | code+model |
| C2 CI pipeline + coverage gate (CI config file or README/deployment.md with CI platform URL) | ✅/⚠️/❌ | {CI config path (e.g. .github/workflows/, .gitlab-ci.yml, Jenkinsfile) or CI platform URL in docs + coverage threshold} | code |
| C3 Prohibited-item protection | ✅/⚠️/❌ | {.gitignore rules + doc explanation} | code+model |
| C4 Branch protection and Review flow | ✅/⚠️/❌ | {documented constraint count} | model |
| C5 failures.md active | ✅/⚠️/❌ | {line count + last commit time} | code+model |
| C6 Security scanning/dependency vulnerabilities | ✅/⚠️/❌ | {security-scan tool config / CI integration} | code |
| C7 E2E/integration tests | ✅/⚠️/❌ | {test dirs + CI steps} | code |

**Evaluation confidence**: 🟢 high / 🟡 medium / 🔴 low

**Details**:
> {supplementary notes}

---

### D. Design & change management（{score}/15）

> **Evaluation system**: based on the 10-file DEVSOP system under `.docs/plans/<task>/` (new devsop-init; task overviews sink into each `00-overview.md`, no global plan.md)

| Eval | Conclusion | Evidence | Grader |
|------|-----------|----------|--------|
| D1 Task directories exist with substantive content (≥1 with the full 10 files) | ✅/⚠️/❌ | {task directory count under .docs/plans/ + file completeness} | code |
| D2 00-overview.md maintenance activity (updated in the last 90 days) | ✅/⚠️/❌ | {latest task 00-overview.md update time} | code+model |
| D3 Small-change TDD/regression testing + template completeness (_template/ has the 10 files + TDD documented in unittest/unittest.md) | ✅/⚠️/❌ | {_template/ file count + unittest TDD section} | code+model |
| D4 Change-classification standard documented | ✅/⚠️/❌ | {classification definition doc path + criteria content} | model |

**Evaluation confidence**: 🟢 high / 🟡 medium / 🔴 low

**Details**:
> {supplementary notes}

---

### E. Shared knowledge base（{score}/5）

| Eval | Conclusion | Evidence | Grader |
|------|-----------|----------|--------|
| E1 In-project Skills accumulation | ✅/⚠️/❌ | {.agents/skills dir + Skill count} | code |
| E2 Knowledge accumulation completeness (path α: specs/openspec/docs or remote wiki; path β: remote wiki or ≥10 docs after excluding design dirs) | ✅/⚠️/❌ | {hit path + quantitative evidence: specs module count / docs doc count / external links} | code+model |

**Evaluation confidence**: 🟢 high / 🟡 medium / 🔴 low

**Details**:
> {supplementary notes}

---

### F. Measurement mechanisms（{score}/15）

| Eval | Conclusion | Evidence | Grader |
|------|-----------|----------|--------|
| F1 devsop_report.md exists and is updated regularly | ✅/⚠️/❌ | {file path + latest update} | code |
| F2 AI session/memory/failure-case retention (AI memory store of any agent / logs/ai-sessions / failures.md in git, choose one of three) | ✅/⚠️/❌ | {hit path + file count} | code |
| F3 .docs/ doc changes traceable | ✅/⚠️/❌ | {commit count in 60 days} | code |
| F4 Improvement-loop closure | ✅/⚠️/❌ | {historical evaluation count + improved items} | code+model |

**Evaluation confidence**: 🟢 high / 🟡 medium / 🔴 low

**Details**:
> {supplementary notes}

---

## ⚠️ Anti-pattern Detection

| Anti-pattern | Status | Notes |
|--------------|--------|-------|
| Docs severely out of sync with code (.docs/ not updated in >60 days) | 🟢 not found / 🔴 present | {git log output summary} |
| Excessive test mocking | 🟢 not found / 🔴 present | {mock vs integration test file ratio} |
| Sensitive files or artifacts committed | 🟢 not found / 🔴 present | {hit file list} |
| Important decisions not captured in docs | 🟢 not found / 🔴 present | {sampled PR commit summary} |
| failures.md long empty | 🟢 not found / 🔴 present | {line count + last modified time} |
| AGENTS.md shallow | 🟢 not found / 🔴 present | {line count + chapter keyword check} |

> Anti-patterns do not affect pillar scores, but a 🔴 status is emphasized in the "Core Conclusions".

---

## 🌪️ Entropy Management Evaluation

| Metric | Current value | Healthy threshold | Rating |
|--------|---------------|-------------------|--------|
| .docs/ file update median days-to-today | {X days} | <60 days | 🟢/🟡/🔴 |
| Mock health (mock file count / integration test file count) | {mock: X, integration: Y} | integration tests >0 | 🟢/🟡/🔴 |
| failures.md commit count in 90 days | {X} | ≥1 | 🟢/🟡/🔴 |
| Regulation docs commit count in 60 days | {X} | ≥3 | 🟢/🟡/🔴 |

**Entropy management judgment**:
> {1-2 sentences: is the tech-debt cleanup mechanism running? Are docs/code evolving in sync?}

---

## 🧭 Skill Health (observational, does not affect scores)

> Purpose: measure whether the project's skill library is actually being used — skills that exist but never trigger are decoration. This section is informational and feeds the anti-pattern "skills present but never triggered".

| Metric | Current value | Healthy signal |
|--------|---------------|----------------|
| Repo-local skills count (`.agents/skills/*/SKILL.md`) | {X} | ≥3 (E1) |
| Skill-trigger traces in git (commits/messages referencing skill names in 60 days) | {X} | >0 |
| Session retention (F2 evidence hit) | {hit path or NONE} | any path hit |
| Task-plan discipline (new `.docs/plans/<task>/` dirs in 30 days vs code commits) | {X dirs / Y commits} | dirs >0 when commits >10 |

**Skill health judgment**:
> {1 sentence: are skills activated in real work, or only installed? If traces = 0, recommend adding the skill-trigger matrix to AGENTS.md §1 or enabling session logging per F2.}

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

> Improvement suggestions reference: the `devsop-eval` Skill's `devsop-improvement-examples.md` (in the Skill install dir, user-level `~/.agents/skills/devsop-eval/` or project-level `<repo>/.agents/skills/devsop-eval/`)

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
