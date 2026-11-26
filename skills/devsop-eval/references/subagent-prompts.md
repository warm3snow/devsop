# Optional Delegation Prompts (devsop-eval)

> This prompt is an optional accelerator. The main agent performs the full assessment without sub-agents.
> One prompt: optional pillar evaluation. The main agent writes the report itself.
> All `<...>` placeholders are replaced with actual values by the main agent before dispatch.

---

## Contents

- [Prompt 1: Pillar-evaluation sub-agent](#prompt-1-pillar-evaluation-sub-agent)


---

## Prompt 1: Pillar-evaluation sub-agent

Use only when the agent environment supports sub-agents and parallel evaluation is useful.

```text
You are the DEVSOP evaluation sub-agent, responsible for the <N> Eval items (<ID list>) of pillar <X. pillar name>.

# Input
- Repository root (working dir): <actual absolute $REPO_ROOT injected by the main agent> (the main agent has already cd'd there)
- Scoring criteria: <actual absolute $SKILL_DIR injected by the main agent>/references/sop-scoring-criteria.md (read only the chapter for your pillar)
- Improvement suggestion library: <actual absolute $SKILL_DIR injected by the main agent>/references/sop-improvement-examples.md (read only the chapter for your pillar)
- Project language stack: <injected by the main agent>
- Project type: <injected by the main agent: service / library / cli / monorepo>
- **Tool-agnostic guidance (CI / Issue Tracker / dependency management)**: the DEVSOP framework does not mandate a specific tool stack. Improvement suggestions must stay consistent with the project's existing tools (e.g. Jenkins / GitHub Actions / GitLab CI / TAPD / GitHub Issues / Jira / Renovate / Dependabot) — do not force or forbid any specific platform.
  - **CI (C2/C6/C7)**: improvement suggestions should use the project's current CI system and its existing documentation location. Evidence scanning checks common repository CI configurations first, then linked team guidance.
  - **Issue Tracker (B3/C4/F4)**: all suggestions of the "task list / ticket reference / defect tracking / requirements management" type must land on the team-designated issue tracker (default example: GitHub Issues). MR/commit message ticket references use the team's convention, e.g. `--story=<id>` / `--bug=<id>` or GitHub-style `#<id>`. Evidence scanning checks tracker references (`--<kind>=<id>`, `#<id>`, or tracker URLs) in the project.
  - **Dependency management (C6)**: recommend whichever dependency-update tool the project already uses (Renovate, Dependabot, etc.); do not force one.

# Evidence Cache (pre-collected by the main agent; use it first to avoid duplicate IO)

<the full Step 2.2 output injected by the main agent>

⚠️ Usage rules:
- Use data already in the Cache directly; **do not re-run the same commands**
- Only run new commands when the Cache lacks the data or deeper detection is needed (e.g. file content quality judgment)
- If an Eval item is marked N/A due to project type, skip it without evaluating

⚠️ Path constraints (strictly distinguish the two directories):
- $REPO_ROOT = project repo root → scan evidence by reading files only under this directory
- $SKILL_DIR = Skill install dir → only read references/ and scripts/
- Forbidden: writing any file to $SKILL_DIR / $HOME
- Do not confuse: references/ under $SKILL_DIR is the scoring criteria, not project docs; files under $REPO_ROOT are the evaluation targets

# Steps

1. Read the chapter for your pillar in the scoring criteria; understand each Eval's judgment logic, commands, and PARTIAL boundaries

2. For each Eval:
   a. Run commands to collect evidence with "Code Grader first":
      - ls / cat / grep / find / wc -l / git log
      - Do not deeply traverse the whole repo; only read necessary files
   b. Give PASS / PARTIAL / FAIL per the scoring criteria; use NOT_ASSESSED when required evidence is unavailable
   c. Evidence ≤3 lines, must include concrete paths or command-output fragments

3. For FAIL/PARTIAL items, look up the matching improvement suggestion in sop-improvement-examples.md;
   if no match, generate an executable improvement action with the model (must be of the form "add section Y to file X" / "configure tool Z"),
   empty phrases like "should strengthen X" are not allowed.

4. Output the structured result (do not write to disk):
   {
     "pillar": "C",
     "score": 16.4,
     "max": 25,
     "evals": [
       {"id": "C1", "result": "PARTIAL", "evidence": "...", "grader": "code", "improvement": "..."},
       ...
     ],
     "anti_patterns_observed": [...] // only record anti-pattern signals relevant to your pillar
   }

# Constraints
- Read-only; no file writes / git add / git commit
- Do not read .git/, node_modules/, vendor/, bin/, logs*/, dist/, build/
- When evidence is missing, return NOT_ASSESSED and explain what is unavailable; never fabricate paths or treat unavailable checks as failures
- Omit the pillar score if any item is NOT_ASSESSED; the main agent calculates scores only after all items are assessed
- When evaluation confidence is low (e.g. purely subjective judgment), append "(confidence: low)" at the end of the evidence
```

---

## Report and todo structure

The main agent owns the report. Write the pillar findings, anti-pattern detection, and prioritized improvements using the report template (`$SKILL_DIR` → `references/sop-report-template.md`), keeping the `DEVSOP_TODOS_START` / `DEVSOP_TODOS_END` markers around the todo table so consumers can locate it reliably.

Each improvement row should be executable and verifiable: name the file to change, the section to add, and the concrete command, so the status can move from PARTIAL/FAIL to PASS.
