# devsop

A library of reusable Skills that run the full development pipeline — project context, requirements, design, implementation, verification, deployment — with any AI coding agent.

## Skills

| Skill | Purpose |
|-------|---------|
| `devsop-init` | Build project context (`AGENTS.md` + core docs) from existing evidence; interactive scaffold for greenfield repos; `global` mode sets up a multi-repo orchestration repo. |
| `devsop-plan` | Turn a request into `plan.md` — stories, non-functional requirements, Given/When/Then scenarios. |
| `devsop-design` | Map the plan onto the architecture — impact analysis, interface contracts, UI prototypes, ordered task list. |
| `devsop-code` | Implement the task list with TDD discipline and a progress ledger. |
| `devsop-test` | Execute the scenarios; report a pass/fail matrix per scenario. |
| `devsop-ship` | Deploy to the dev environment behind an explicit human confirmation gate. |
| `devsop-eval` | Evidence-based assessment of project practices. |
| `devsop-flow` | Orchestrate the stages end to end, or route a request to the right entry stage. |

Stages exchange disk artifacts as their contract: `plan.md` → `tasks.md` → `progress.md` → `test-report.md` (on demand) → `ship.md`. Artifact volume scales with the change; see `devsop-flow` for the scaling rules.

## Supported agents

Any AI coding agent. Skills install to `~/.agents/skills/` — the agent-agnostic standard location — as plain `SKILL.md` (Markdown + Bash/Python); no agent-specific configuration is involved. Agents with native Skills discovery pick them up automatically; with any other agent, point it at a `SKILL.md` or paste the content. Skills are invoked by the agent, not from a terminal.

## Install

```bash
git clone https://github.com/warm3snow/devsop.git
cd devsop
bash install.sh          # symlink all skills into ~/.agents/skills/
bash install.sh --check  # verify the links
```

The links point back into this clone — update skills with `git pull`. Requirements: Bash, Git, Python 3 (standard library only).

## Repository layout

```text
skills/<skill>/     # one directory per skill: SKILL.md + assets/ references/ scripts/
rules/              # language style guides (Go, Python, Java, TypeScript, Rust)
scripts/            # this repo's tooling: validation, contract checks, git hooks
```

## Language neutrality

Workflow stages never assume a language, framework, or toolchain — commands (test, lint, deploy) come from the target project's own configuration. Language-specific content lives only in `rules/`; adding a language means adding one file there, no skill changes.

## Development checks

```bash
bash scripts/validate_skills.sh --strict                     # library + contract validation
bash skills/devsop-init/scripts/test_init_docs_profile.sh    # black-box tests
bash skills/devsop-eval/scripts/test_doc_discovery.sh
bash skills/devsop-plan/scripts/test_validate_plan.sh
bash scripts/test_validate_skills.sh
```

CI runs all checks on every push and pull request. See [AGENTS.md](AGENTS.md) for contribution conventions.
