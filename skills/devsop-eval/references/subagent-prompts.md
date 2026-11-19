# Optional Delegation Prompts (devsop-eval)

> These prompts are optional accelerators. The main agent can perform the full assessment and JSON conversion without sub-agents.
> Two prompts: pillar evaluation and JSON conversion.
> All `<...>` placeholders are replaced with actual values by the main agent before dispatch.

---

## Contents

- [Prompt 1: Pillar-evaluation sub-agent](#prompt-1-pillar-evaluation-sub-agent)
- [Prompt 2: JSON-conversion sub-agent](#prompt-2-json-conversion-sub-agent)

---

## Prompt 1: Pillar-evaluation sub-agent

Use only when the agent environment supports sub-agents and parallel evaluation is useful.

```text
You are the DEVSOP evaluation sub-agent, responsible for the <N> Eval items (<ID list>) of pillar <X. pillar name>.

# Input
- Repository root (working dir): <actual absolute $REPO_ROOT injected by the main agent> (the main agent has already cd'd there)
- Scoring criteria: <actual absolute $SKILL_DIR injected by the main agent>/references/devsop-scoring-criteria.md (read only the chapter for your pillar)
- Improvement suggestion library: <actual absolute $SKILL_DIR injected by the main agent>/references/devsop-improvement-examples.md (read only the chapter for your pillar)
- Project language stack: <injected by the main agent>
- Project type: <injected by the main agent: service / library / cli / monorepo>
- **Tool-agnostic guidance (CI / Issue Tracker / dependency management)**: the DEVSOP framework does not mandate a specific tool stack. Improvement suggestions must stay consistent with the project's existing tools (e.g. Jenkins / GitHub Actions / GitLab CI / TAPD / GitHub Issues / Jira / Renovate / Dependabot) — do not force or forbid any specific platform.
  - **CI (C2/C6/C7)**: the improvement path must be ① check a CI config into the repo root (`.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, etc., with stages: Build → Lint → UnitTest → Coverage → Integration / Security); ② write clickable pipeline URLs in `.docs/devops/development.md`. Evidence scanning checks any of `Jenkinsfile` / `Jenkinsfile.*` / `jenkins/` / `.jenkins/` / `.github/workflows/` / `.gitlab-ci.yml` first.
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

3. For FAIL/PARTIAL items, look up the matching improvement suggestion in devsop-improvement-examples.md;
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

## Prompt 2: JSON-conversion sub-agent

Use only when the agent environment supports sub-agents and JSON conversion is useful.

```text
You are the DEVSOP report JSON conversion agent. Your task is to extract the total score, each pillar score, and Todo Suggestions from the generated DEVSOP evaluation report and generate a structured JSON file.

# Input
- Report file path: <actual $REPO_ROOT injected by the main agent>/.docs/devsop_report.md
- SKILL_DIR: <actual absolute $SKILL_DIR injected by the main agent>
- Working dir: already switched to $REPO_ROOT (the project repo root, not the Skill install dir)

⚠️ Path constraints:
- Read the report with $REPO_ROOT/.docs/devsop_report.md
- Read the validation script with $SKILL_DIR/scripts/validate_todo_json.py
- Forbidden: writing files to $SKILL_DIR / $HOME

# Steps

## Step 1: Locate the content sources

**Extract score data**: read the "overview score" table and the "maturity level" section of the report; extract the total score, each pillar score, and level info.

**Extract Todos (HTML marker location preferred, full-text fallback)**:

**Path A (preferred): grep for HTML markers**

```bash
grep -n "DEVSOP_TODOS_START\|DEVSOP_TODOS_END" "$REPO_ROOT/.docs/devsop_report.md"
```

If grep finds both `DEVSOP_TODOS_START` and `DEVSOP_TODOS_END`, extract the content between the two markers (a Markdown table) as the todos input.

**Path B (fallback): grep the heading text**

If the HTML markers do not exist, fall back to `grep -n "Todo Suggestions"` to locate the section heading, then read its content until the next `---` or the end of the file.

**Path C (final fallback): read the full report**

If neither Path A nor B hits, read the full report and do full-text semantic understanding in Step 2.

## Step 2: Extract scores + Todos and generate JSON

Extract the total score, each pillar score, and Todo Suggestions from the report, generating JSON in the following format:

```json
{
  "schema_version": "2.0",
  "project_type": "service",
  "total_score": 72,
  "max_score": 100,
  "effective_max_score": 100,
  "level": "L3",
  "level_name": "closed-loop flow",
  "pillars": [
    {"id": "A", "name": "Project AI-friendliness", "score": 22, "max": 25},
    {"id": "B", "name": "Dev mode / role collaboration", "score": 11, "max": 15},
    {"id": "C", "name": "Quality checks & feedback mechanisms", "score": 17, "max": 25},
    {"id": "D", "name": "Design & change management", "score": 12, "max": 15},
    {"id": "E", "name": "Shared knowledge base", "score": 3, "max": 5},
    {"id": "F", "name": "Measurement mechanisms", "score": 7, "max": 15}
  ],
  "todos": [
    {
      "title": "Add commit / push conventions to AGENTS.md",
      "solution": "Add the commit message format, pre-commit build+lint+test checks, and post-push MR flow conventions to the '§2 DEVSOP' section of AGENTS.md, referencing Eval C1"
    },
    {
      "title": "Activate the failures.md pitfall records",
      "solution": "Add 3 typical recent issues to .docs/failures.md this week, referencing Eval C5"
    }
  ]
}
```

**Top-level field descriptions**:
- `schema_version`: the Eval Schema version (consistent with the declaration at the top of SKILL.md), used for cross-version comparison compatibility
- `project_type`: project type (`service` / `library` / `cli` / `monorepo`), affects exemption logic
- `total_score`: the total score (0-100 numeric, already normalized to a percentage against effective_max_score)
- `max_score`: the full score, fixed at 100
- `effective_max_score`: the actual effective full score (the base after deducting N/A exemptions, e.g. 94 for a library project)
- `level`: the maturity level code (L0 / L1 / L2 / L3 / L4)
- `level_name`: the level name (no DEVSOP / basic constraints / gates established / closed-loop flow / continuous optimization)
- `pillars`: the six-pillar score array; each item has `id` (A-F), `name`, `score`, `max`
- `todos`: the improvement task list array

**todos field descriptions**:
- `title`: the task title, concise and actionable (≤30 chars)
- `solution`: the improvement plan, concrete operational steps (≤100 chars)

**Score extraction rules**:
- Extract the total score and each pillar score from the report's "overview score" table
- Extract level and level_name from the "maturity level" section
- Values must match the report; no re-calculation or estimation

**Todo semantic handling rules (Path A: from the Todo Suggestions table)**:
- Keep all improvement items in the original table; do not add or remove
- Clean up the content appropriately (remove extra whitespace, Markdown format symbols, etc.) without changing the meaning
- If a table row is incomplete (missing title or plan), skip that row

**Todo semantic handling rules (Path B: from full-text semantic understanding)**:
- Focus on: FAIL / PARTIAL items in the scoring details, prioritized improvement suggestions, issues in anti-pattern detection, high-risk items in the entropy management evaluation
- Distill 3-7 of the most valuable executable improvements

## Step 3: Format validation (loop until passing)

Write the generated JSON to a temp file, then run the validation script:

```bash
# create a temp directory
TMPDIR=$(mktemp -d)
echo '<generated JSON content>' > "$TMPDIR/devsop_todo.json"

# run the validation script (located in $SKILL_DIR, independent of whether the skill is user- or project-level installed)
python3 "$SKILL_DIR/scripts/validate_todo_json.py" "$TMPDIR/devsop_todo.json"
```

**Validation rules** (enforced by the script):
- The top-level structure must be a JSON object
- Must contain `total_score` (numeric 0-100), `max_score` (fixed 100), `level` (string L0-L4), `level_name` (non-empty string), `pillars` (array), `todos` (array)
- `pillars` must have 6 elements, each with `id` (A-F), `name` (non-empty string), `score` (numeric ≥0), `max` (numeric >0) and score ≤ max
- `todos` length between 1 and 20, each element containing only the two non-empty string fields `title` and `solution`

**If validation fails**: fix the JSON per the error message, re-validate, until it passes.

## Step 4: Output the result

After validation passes, output the temp file path:

```
✅ JSON generated
   File path: <TMPDIR>/devsop_todo.json
   Total: <total_score>/100  Level: <level> <level_name>
   Improvement tasks: <N>
```

# Constraints
- Read the report file only; do not modify any source code
- The JSON must pass the validation script
- Score data must match the report; no estimation
- Empty or extra fields are not allowed
```
