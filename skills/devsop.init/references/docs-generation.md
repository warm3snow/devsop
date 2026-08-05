# references/docs-generation.md

> `.harness/docs/` generation methodology. **Generic version** — not tied to any language, framework, or domain.
>
> When to load:
> 1. **After Scenario A**: the project has just been initialized, and the empty skeleton needs to be filled in
> 2. **Reverse-filling an existing project**: the project already exists but `docs/` is still empty
> 3. **Stage 07 Docs**: when a task reaches the documentation synchronization step, as a decision reference

---

## 0. Before reading this methodology

The directory structure, section templates, and extraction scripts below are all **illustrative**, not hard template constraints.
The only things that truly never change are the following five:

1. **Why**: the purpose of docs (Section 1 core principles)
2. **What layer dimensions**: Orientation / Contract / Internals / Operability (Section 2 four-layer model)
3. **How methodology**: the extract-sample-revise loop from information sources to artifacts (Section 3 generic generation method)
4. **When**: trigger timing and corresponding actions (Section 4)
5. **Invariant anti-patterns** (Section 5)

Which files a specific project ends up with, and which tools are used for extraction, is decided by Section 6 "Project-form adaptation".

---

## 1. Core Principles

`.harness/docs/` is not a "project introduction / README enhanced version"; it is the **minimal knowledge set needed for a brand-new person (or AI Agent) to understand, modify, and operate this project without reading the source code**.

Four principles, independent of project type:

| # | Principle | Meaning |
|---|-----------|---------|
| 1 | **Code is the truth, docs are the map** | Outdated docs are not scary; inconsistency between docs and code is fatal; when writing docs, include "how to keep in sync with the code" (each doc footer notes the source path + sync time) |
| 2 | **Write for the reader, not the author** | Contract docs are written from the caller's perspective; architecture docs are written from the new maintainer's perspective; ADRs are written from the future maintainer's perspective |
| 3 | **Semi-automatic > fully automatic > fully manual** | Fully automatic AI will fabricate details; fully manual nobody maintains; **AI drafts → human reviews → commit to repo** is what works long-term |
| 4 | **Layered, on-demand, incremental** | Don't produce 100 files at once; produce in batches by importance, let people review each batch, then produce the next |

---

## 2. What — the four-layer model of docs (decoupled from project type)

Regardless of whether the project is a backend service, frontend SPA, CLI tool, SDK / library, mobile app, or data pipeline, docs must answer the following four types of questions:

| Layer | Name | Question it answers | Cost of losing it |
|-------|------|---------------------|-------------------|
| L1 | **Orientation layer** | What is this? What does it look like when running? How are modules split? How does data flow? | Newcomers / AI cannot form a mental model, and all lower-layer docs become unreadable |
| L2 | **Contract layer** | How do others use it? What interfaces / APIs / commands / events / props / CLI flags exist? | Integrators stumble; breaking changes from version upgrades are uncontrollable |
| L3 | **Internals layer** | Why is it implemented this way? What are the key algorithms, state machines, data models, and persistence structures? | Maintainers can only reverse-engineer; refactoring is like groping an elephant in the dark |
| L4 | **Operability layer** | How to run locally? How to test? How to release? How to observe? How to roll back? | Project handover = re-stumbling through all the same pitfalls |

**Hard requirement on generation order between layers**: L1 → L2/L3 in parallel → L4. **Strictly forbidden** to write contract docs before the orientation layer (without context, nobody can understand the contract docs).

> Which files each layer maps to in different project types is covered in Section 6.

---

## 3. How — generic generation method (all layers share the same loop)

No matter which layer's docs are being generated, the same 5-step loop is followed:

```
Scan        →  Extract     →  Draft      →  Verify     →  Commit
Scan info sources   Extract structured facts   Generate Markdown   Sample-check against source code   Commit to repo after user review
```

### Step 1: Scan — find the information sources

Each layer has "authoritative information sources", and the AI **must** list them before starting extraction. Common information source types:

| Information source type | Examples |
|-------------------------|----------|
| **Entry files** | `main.*` / `index.*` / `server.*` / `cli.*` / `App.*` / `__main__.py` |
| **Routing / dispatch / entry registries** | `router.*` / `routes/` / `*.routing.ts` / `urls.py` / the `pub` list in `mod.rs` |
| **Type / interface definitions** | `*.proto` / `*.thrift` / `openapi.yaml` / `*.d.ts` / `schema.graphql` / IDL |
| **Build / run configuration** | `Makefile` / `package.json` / `Cargo.toml` / `pyproject.toml` / `pom.xml` / `Dockerfile` |
| **Test entries** | `tests/` / `__tests__/` / `*_test.go` / `spec/` |
| **Persistence schemas** | DB `SHOW CREATE TABLE` / migrations / ORM models / `*.proto` for storage |
| **CI / CD configuration** | `.github/workflows/` / `.gitlab-ci.yml` / Jenkinsfile |
| **Dependency graphs** | lockfile / `go mod graph` / `npm ls` / `cargo tree` |

> The first thing the AI does: use `list_dir` to look at the repository root, then use `codebase_search` to locate files of the above types — **do not** assume from memory that they necessarily exist.

### Step 2: Extract — extract structured facts

Extract facts from the code into "structured entries" and then render them into Markdown; **do not** let the LLM write free-form text descriptions (easy to fabricate).

| Fact to extract | Extraction means (pick one) |
|-----------------|------------------------------|
| Module inventory | Top-level directory tree + README / first-line docstring of each directory |
| Entry points and startup methods | Entry file name + startup command (extracted from `package.json scripts` / `Makefile` / `Dockerfile CMD`) |
| External contracts | IDL first; then annotations / decorators; finally fall back to handler / exported function signatures |
| Error codes / exceptions | grep `raise` / `throw` / `return Err` / `Error(...)` statements + centralized error code table |
| Dependency graphs | Output of package manager commands |
| DB schema | Directly connect to the test DB `SHOW CREATE TABLE` / read migration history |

**Iron rule**: the output of extraction scripts must be **deterministic** — running twice on the same code yields byte-by-byte identical output; only then can it be put into CI for "docs drift" detection.

### Step 3: Draft — generate the draft

- Drafts are written to `*.draft.md` by default; **do not** write directly to the official files, to avoid overwriting manual revisions.
- Keep **`<!-- TODO: ... -->` placeholders** in templates, marking fields the AI is unsure about, for humans to fill in.
- Fixed footer at the top of each document:
  ```markdown
  > Source: <extraction source file / command>
  > Generated: <date>  by <skill / script name>
  ```

### Step 4: Verify — sample-check

For every N docs of the same type generated (N=10 is the empirical value), **randomly pick 2** and check them against the source code:
- Do the names (interface names / field names / command names) match the code?
- Are the default values, required/optional relationships correct?
- Is error handling / failure semantics complete?

If inconsistencies are found: **fix the extraction script**, regenerate everything; **manual patching is forbidden** (a manual patch will be overwritten the next time it is regenerated).

### Step 5: Commit — commit to repo after human review

- Diff `*.draft.md` against existing official files; let the user decide the merge strategy.
- Update the corresponding `index.md` / navigation table at the same time as committing.

---

## 4. When — trigger timing and corresponding actions

| Trigger scenario | Corresponding action | Output location |
|------------------|----------------------|-----------------|
| **Project just initialized (Scenario A)** | In L1 → L2/L3 → L4 order, generate drafts layer by layer + user review | All of `.harness/docs/` |
| **First-time backfill of an existing project** | Same as above, **in batches by module**: fill in core modules first; stop for review every N contract-layer docs | Same as above |
| **Task reaches Stage 07 Docs** | Derive **incremental** updates from this change's code diff; only touch the docs affected by this task | Only the docs involved this time |
| **Quarterly / version health check** | Sample-check (names / default values / error codes); open a chore task for inconsistencies | Exposed problems → task → fix |
| **After a major refactor / architecture evolution** | Forcibly trigger full Stage 07; add a new ADR to record decisions when necessary | `.harness/docs/` + `.harness/adr/` |
| **Major dependency version upgrade** | Regenerate the L4 environment / deployment docs, cross-check against the new version's commands / configuration | `.harness/docs/<L4 file>` |

---

## 5. Anti-patterns (project-type independent, all must be avoided)

| # | Anti-pattern | Consequence | Correct approach |
|---|--------------|-------------|------------------|
| 1 | **Generate all docs in one batch** | Large volume, low quality, nobody reviews, rotten as soon as written | Batch by module / layer, human review each batch |
| 2 | **AI merges directly after generating** | AI will fabricate parameters / default values / error codes | Sample-check ≥3 places against the code |
| 3 | **Docs and code in two separate PRs** | The docs PR never gets merged | Complete within the same Stage 07, same PR as the code |
| 4 | **Only record "what" not "why"** | Nobody understands the decision six months later | ADR records "why"; contract layer / internals layer record "what" |
| 5 | **Contract docs copy the source code** | Lose the caller's perspective, become "code translation" | Write from the caller's perspective: how to call / what it returns / how to diagnose errors |
| 6 | **Skip the orientation layer and write contract / internals directly** | Contracts pile up, internals are isolated, no context | Must pass L1 review first, then do L2/L3 |
| 7 | **Copy persistence schema as code strings** | Inconsistent with production | Export directly from the test DB / real migration state |
| 8 | **Overwrite existing manual edits** | User revisions are lost | Output to `*.draft.md` by default; user diffs then merges |
| 9 | **AI substitutes memory for scanning** | File paths / command names are made up | Must start with `list_dir` / `codebase_search` verification |
| 10 | **Docs without source footnotes** | Don't know when or with whom to sync | Fixed `Source` + `Generated` footer at the top |

---

## 6. Physical layout of this skeleton

> This skill's skeleton is fully consistent with the team's current `.harness/`. All docs land in the following fixed physical paths:

| Purpose | Physical path |
|---------|---------------|
| System architecture | `.harness/docs/architecture.md` |
| Upstream / downstream & integrations | `.harness/docs/relationship.md` |
| Coding style (line length/complexity/naming/security) | `.harness/docs/coding-style.md` |
| Team manual Code Review process | `.harness/docs/code-review.md` |
| Business glossary | `.harness/docs/glossary.md` |
| Pitfalls log | `.harness/docs/failures.md` |
| Logging standards | `.harness/docs/logging.md` |
| External interfaces | `.harness/docs/apis/<module>/<Action>.md` + `apis/index.md` + `apis/_template.md` + `apis/api-standards.md` |
| Data / Schema | `.harness/docs/sqls/README.md` + `sqls/database.md` |
| Unit testing standards | `.harness/docs/unittest/unittest.md` |
| Integration testing standards | `.harness/docs/integration_test/integration_test.md` |
| Environment setup | `.harness/docs/devops/env.md` |
| Test environment deployment | `.harness/docs/devops/test-env-deploy.md` |
| Deployment & run standards | `.harness/docs/devops/deployment.md` |
| Local development environment standards | `.harness/docs/devops/development.md` |
| AI Code Review guidance standards | `.harness/review.md` (top level, not under docs/) |

> "L1 Orientation / L2 Contract / L3 Internals / L4 Operability" are methodology labels to help the AI think about "what should be written" —
> **physical directory names are fixed as `architecture.md / relationship.md / apis/ / sqls/ / unittest/ / integration_test/ / devops/`; do not create a parallel `contracts/internals/operability` set just to "match the labels"**.

### Information source mapping examples (by form)

| Fact to extract | Backend service | CLI | Library/SDK | Frontend |
|-----------------|-----------------|-----|-------------|----------|
| Entry | `main.py` / `server.go` / `app.js` | `cmd/root.go` / `bin/<name>.js` | `__init__.py` / `lib.rs` / `index.ts` | `main.tsx` / `App.vue` |
| Contracts | router registrations + handler signatures | `argparse` / `cobra` / `clap` subcommands | `__all__` / `pub` exports / `export` | route table + component props |
| Error codes | centralized `raise <Exc>` table | exit code table | custom Error classes | error boundaries + toast copy |
| Persistence | DB schema | config files / cache directories | none (or file format spec) | localStorage / IndexedDB schema |

---

## 7. On-demand loading and directory conventions

`.harness/docs/` grows on demand; do not create all placeholder files at once. But these conventions must be followed:

1. **The first 5 lines of each doc** include:
   - a one-sentence summary
   - target audience
   - Source (information source path)
   - Generated / Last-verified time
   - links to related upper / lower docs
2. **`apis/` list-type directory** must have an `index.md` master table that maps 1:1 to the official document list.
3. **Project-specific rules take priority**: if `.codebuddy/rules/<topic>_*.md` exists at the repository root (e.g. `unittest_rule.md`, `cls_mcp_rule.md`), they are the **authoritative source** for that topic —
   - same-named docs under `docs/<topic>/` should **excerpt + link**, not copy-paste;
   - on conflict, `.codebuddy/rules/` wins;
   - revising rules requires syncing docs and vice versa; stages such as the task template 04-ut.md / 05-deploy.md force reading both.
4. **Do not pre-generate placeholders** like `README.md` / `conventions.md` / `glossary.md` / `risks.md` / `adr/` / `PROFILES.md` just to "look complete" — add them on demand when actually used.

---

## 8. Recommended workflow (after Scenario A)

In order, strictly batched, waiting for user confirmation at each step:

```
Step 1  Generate architecture.md / relationship.md drafts (architecture diagram / module table / data flow / upstream-downstream) → user review
Step 2  Generate sqls/ drafts (persistence schema, key state machines) → DBA / maintainer review
Step 3  Generate apis/ drafts, batched by module, N=10 per batch → sample-check 2 against the code
Step 4  Generate unittest/unittest.md + integration_test/integration_test.md + devops/{env.md, test-env-deploy.md} (including run commands) → actually run once to verify the commands work
Step 5  Fill in other docs/<topic>/ files on demand
```

---

## 9. Quality self-check checklist (decoupled from form)

Minimum standard for docs to be considered "complete":

### Orientation
- [ ] Has an ASCII / mermaid diagram that fully draws the flow from external trigger to core components to output
- [ ] Module table covers all top-level directories (each row: module / responsibility / entry file / main dependencies)
- [ ] At least 1 end-to-end typical flow is fully drawn

### Contract
- [ ] ≥ 80% of external interfaces / commands / public APIs have their own docs
- [ ] Each doc has: usage, parameter table, return / output, error / failure modes, examples, change log
- [ ] `index.md` maps 1:1 to the files
- [ ] 3 sample-checked docs match the source code

### Internals
- [ ] Every persistence structure has a corresponding file, with all fields explained
- [ ] Every key state machine has a diagram + transition conditions
- [ ] Contracts with external dependencies (e.g. third-party APIs, protocol versions) have their own section

### Operability
- [ ] A newcomer can run it locally within 30 minutes following the docs
- [ ] Test / build / deploy / rollback commands are all one-click executable
- [ ] Key observability metrics / alert thresholds are listed
- [ ] `unittest/unittest.md` has all three sections (environment setup / generation standards / running & debugging), and the "pre-dependency check checklist" in Section 1 is filled in according to this project's reality
- [ ] If `.codebuddy/rules/unittest_*.md` exists in the repo, `unittest/unittest.md` links to it and states the authority relationship (no copying of conflicting content)
- [ ] `integration_test/integration_test.md` has all three sections (environment & dependencies / test case design / running & debugging) and is aligned with `relationship.md` and `devops/test-env-deploy.md` (dependencies come from relationship, environment deployment comes from devops)
- [ ] If `.codebuddy/rules/integration_test_*.md` / `it_*.md` exists in the repo, `integration_test/integration_test.md` links to it and states the authority relationship
- [ ] `devops/env.md` lists local startup methods
- [ ] `devops/test-env-deploy.md` lists the test environment deployment / sync process

---

## 10. Relationship with other DEVSOP stages

```
Stage 02 Plan        → must read L1 / L2 of docs/ before designing the solution
Stage 03 Implement   → implement cross-checked against L3 (schema / state machine) of docs/
Stage 04 UT          → write tests per L4 (unittest standards) of docs/
Stage 05 Deploy      → execute per L4 (deployment / rollback) of docs/
Stage 06 IT          → run integration tests per L4 (integration_test standards) of docs/
Stage 07 Docs        → incrementally update docs/, one-to-one with this change's code modifications
```

`.harness/docs/` is not a write-once-and-done thing; **it is the blood-supply system of the DEVSOP** — every stage reads it, Stage 07 replenishes it, and it becomes more accurate over time.

---

## Appendix A: Minimal viable output (MVP docs)

If the project is just starting and time is tight so only the minimal set can be done, the **3 things that cannot be cut** are:

1. `.harness/docs/architecture.md` — one diagram plus one paragraph to clearly explain "what this is" (at least 1 Mermaid diagram + system positioning)
2. `.harness/docs/relationship.md` — upstream / downstream & integration relationships (upstream callers + downstream dependency table, even if each row only has names)
3. `.harness/docs/apis/index.md` — at least list the full external exposure surface (names alone are fine, details can be added later; for projects without APIs, Agent C deletes the `apis/` directory, so this item can be omitted)

The rest may be temporarily missing, but each temporarily missing doc should keep a `<!-- TODO(devsop.init): ... -->` placeholder in the corresponding file to avoid omissions. **Strictly forbidden** to pre-generate `.harness/docs/README.md` / `conventions.md` / `glossary.md` / `risks.md` / `adr/` placeholders (red line 3) — create them on demand.
