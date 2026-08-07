# coding-style.md Special Sub-Agent Instructions

> This file serves as the **supplementary instructions** for the `coding-style.md` sub-agent, on top of the common prompt. The main Agent passes it along when dispatching.
> Target: `.docs/coding-style.md`.

---

## Core Goal

**Trim and apply** `.docs/coding-style.md` from the multi-language common template into coding conventions for this project's actual language and toolchain — replace all `{{placeholder}}` values in the template with real project values, and delete entire language sections that do not apply.

---

## Steps

### 1. Detect the project language and toolchain

- Main language determination (evidence-based, not guessed):
  - Go: `go.mod` exists
  - Python: `requirements.txt` / `pyproject.toml` / `setup.py` exists
  - Java: `pom.xml` / `build.gradle` exists
  - C++: `CMakeLists.txt` / `*.cpp` exists
  - Frontend / Node: `package.json` exists
- Multi-language repository: keep the sections for all languages actually used, delete the rest
- Toolchain fact collection:
  - Formatters: `goimports` / `gofmt` (Go), `prettier` (JS/TS), `black` (Python) — base it on the repository config files (`.prettierrc` / `pyproject.toml` / `.golangci.yml`)
  - Linter: `.golangci.yml` exists → fill in `golangci-lint` and reference that config; `.eslintrc*` exists → fill in `eslint`; neither exists → keep `<!-- TODO(devsop.init) -->`
  - pre-commit hook: read `.git/hooks/pre-commit` or `.pre-commit-config.yaml`, confirm the actual triggered check commands
- If `.codebuddy/rules/coding_style*.md` or a similar coding-conventions file exists at the repository root: read it and use it as the authoritative source

### 2. Generate / update the document

- "Scope" section: fill in the actual language; for multi-language repositories, note whether frontend/backend/scripts apply
- §1 Mandatory conventions table: replace all placeholders such as `{{gofmt / prettier / black}}`, `{{golangci-lint / eslint / ruff}}`, `{{.golangci.yml / .eslintrc}}` with the real values collected in step 1
- §2 Naming conventions "per-language conventions": keep only the sections for the project's actual languages, **delete the entire sections** for other languages (pick the actual one among Go/Python/Java/C++)
- §5 Error handling / §6 Resource management / §8 Types and zero values: likewise trim language-specific subsections by language
- §11 Toolchain table: fill in real tools and trigger timing (consistent with pre-commit hooks / CI config)
- Threshold clauses (line length ≤120, function ≤80 lines, cyclomatic complexity ≤10, etc.): if the project lint config already has different thresholds, use the lint config and update; otherwise keep the template defaults
- "References" section: fix broken links (e.g. `testing.md` has been migrated to `unittest/unittest.md`; `api-standards.md` is under the `apis/` subdirectory)

### 3. Framework specialization (conditionally triggered)

- If the main Agent has injected the "coding-style.md sub-Agent additional requirements" section from `references/framework-<name>.md` (e.g. go-zero's directory layering / naming / ServiceContext / errorx conventions): merge those clauses into the corresponding sections, noting the source framework

---

## Constraints

- Only touch `.docs/coding-style.md`; do not touch other docs
- All tool names / thresholds / commands must come from real config file evidence; fabricating is forbidden; fields without evidence keep the `<!-- TODO(devsop.init) -->` placeholder
- Language-section trimming must delete entire sections; do not leave platitudes like "this project does not involve this"
- If the project already has an authoritative coding-conventions file (in `.codebuddy/rules/` or a team Wiki link): change the corresponding section of this document to an excerpt + link, noting the authoritative source, and do not copy conflicting content
- Applies to both library projects and regular service projects; no skipped determination; if there are no code files at all (pure documentation repository) → output `skipped(no code)`
