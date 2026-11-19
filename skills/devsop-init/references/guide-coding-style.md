# Coding Style Documentation Guide

> Use this guide only after the project documentation inventory identifies a gap in coding-convention guidance. Adapt the target to the project's existing documentation location and naming convention.

---

## Core Goal

Apply the relevant language and toolchain conventions from the common template only when useful. Replace placeholders with verified project values, and delete language sections that do not apply.

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
  - Linter: `.golangci.yml` exists → fill in `golangci-lint` and reference that config; `.eslintrc*` exists → fill in `eslint`; neither exists → keep `<!-- TODO(devsop-init) -->`
  - pre-commit hook: read `.git/hooks/pre-commit` or `.pre-commit-config.yaml`, confirm the actual triggered check commands
- If a coding-conventions document or rules file exists in the repository: read it and use it as the authoritative source, regardless of its filename

### 2. Generate / update the document

- "Scope" section: fill in the actual language; for multi-language repositories, note whether frontend/backend/scripts apply
- §1 Mandatory conventions table: replace all placeholders such as `{{gofmt / prettier / black}}`, `{{golangci-lint / eslint / ruff}}`, `{{.golangci.yml / .eslintrc}}` with the real values collected in step 1
- §2 Naming conventions "per-language conventions": keep only the sections for the project's actual languages, **delete the entire sections** for other languages (pick the actual one among Go/Python/Java/C++)
- §5 Error handling / §6 Resource management / §8 Types and zero values: likewise trim language-specific subsections by language
- §11 Toolchain table: fill in real tools and trigger timing (consistent with pre-commit hooks / CI config)
- Threshold clauses (line length ≤120, function ≤80 lines, cyclomatic complexity ≤10, etc.): if the project lint config already has different thresholds, use the lint config and update; otherwise keep the template defaults
- "References" section: link to the project's actual testing or API source when it exists; remove irrelevant links

### 3. Framework specialization (conditionally triggered)

- If the main agent has injected the "coding-style.md sub-Agent additional requirements" section from `references/framework-<name>.md` (e.g. go-zero's directory layering / naming / ServiceContext / errorx conventions): merge those clauses into the corresponding sections, noting the source framework

---

## Constraints

- Only create or update the selected authoritative coding-conventions source when a gap is confirmed; preserve unrelated docs
- All tool names / thresholds / commands must come from real config file evidence; fabricating is forbidden; fields without evidence keep the `<!-- TODO(devsop-init) -->` placeholder
- Language-section trimming must delete entire sections; do not leave platitudes like "this project does not involve this"
- If the project already has an authoritative coding-conventions source: add a concise link or index entry instead of copying its content or introducing a conflicting duplicate
- Applies to both library projects and regular service projects; no skipped determination; if there are no code files at all (pure documentation repository) → output `skipped(no code)`
