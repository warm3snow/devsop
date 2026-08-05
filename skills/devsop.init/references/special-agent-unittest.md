# Unit Test Conventions Review Sub-Agent Instructions

> This file serves as the **supplementary instructions** for the `unittest` review sub-agent, on top of the common prompt. The main Agent passes it along when dispatching.
> Target: `.harness/docs/unittest/unittest.md`.

---

## Core Goal

Fill `.harness/docs/unittest/unittest.md` into an **actionable Go unit test convention** (three-part structure: environment setup / generation conventions / run and debug).

---

## Steps

### 0. Prerequisite check: clean up the legacy testing.md

> `testing.md` is a leftover from older versions of devsop.init; it no longer exists in the new-version skeleton, and `unittest/unittest.md` should be used instead.
> Handling of a leftover `testing.md` is only needed when upgrading old projects.

Check whether `.harness/docs/testing.md` remains:

**If it exists** (old-version devsop.init output):
- Read all the content of `.harness/docs/testing.md`
- Migrate its substantive content (non-placeholder, non-template comments) to `.harness/docs/unittest/unittest.md` using the following mapping:
  - `testing.md`'s "Layering and Responsibilities" / "Coverage Gate" / "Test Case Naming" / "Table-Driven Testing" / "Assertion Conventions" / "Mocks and Stubs" / "TDD Flow" / "Helper Functions and Lifecycle" / "Prohibited Items" / "Test Data" / "Performance Benchmark Tests" → merge into the corresponding subsections of `unittest.md`'s "2. Generation Conventions"
  - Actual tool names in `testing.md` (e.g. `testify`, `gomock`) → fill into the technology selection table of `unittest.md`'s "1. Environment Setup" accordingly
  - Actual run commands in `testing.md` → fill into "3. Run and Debug" of `unittest.md` accordingly
  - Placeholders still `{{placeholder}}` in `testing.md` → keep as `<!-- TODO(devsop.init) -->` for later filling
- After migration completes, **delete** `.harness/docs/testing.md`
- Output `migrated(testing.md → unittest/unittest.md)` + a migration content summary

**If it does not exist**:
- Proceed directly to step 1, update `unittest.md` based on the project's actual situation
- Output `no-migration(no testing.md)`

### 1. Scan unit test facts

- Existing UT cases: `*_test.go` file count / distribution / typical test structure
- Test framework: dependencies such as `testify` / `gomock` / `sqlmock` in `go.mod`
- Mock generation method: whether `//go:generate mockgen` comments / a `mock/` directory exist
- Test run method: test targets in `Makefile` / test commands in CI config
- CI coverage gate: `golangci-lint` config / coverage thresholds in CI pipelines
- If `.codebuddy/rules/unittest_*.md` exists in the repository: read it and use it as the authoritative source

### 2. Generate / update the document

Fill in per the skeleton's three-part structure:
- **1. Environment Setup and Dependency Installation** — technology selection table (`go test` / `testify` / `gomock` / `sqlmock`), prerequisite dependency checklist (filled with this project's actual dependencies), step-by-step installation commands (adjusted per the project's actual dependencies)
- **2. Generation Conventions** — general mandatory clauses (red lines), test types and applicable scenarios (per the project's actual situation), hard constraints on file naming and organization, mock strategy (Go interface as contract), table-driven test case design self-check checklist
- **3. Run and Debug** — standard execution commands (consistent with CI), debugging approaches, CI integration (coverage gate ≥60%)

### 3. Align and reference

- If `.codebuddy/rules/unittest_*.md` exists in the repository: change §2 of `unittest.md` to an excerpt + link, marking it as the "authoritative source", and do not copy-paste conflicting content
- Test commands must come from real commands in `Makefile` / CI config; fabricating is forbidden
- Coverage threshold comes from the actual value in CI config / `.golangci.yml`; default is ≥60%

---

## Constraints

- Forbidden to test the same layer of logic as `integration_test/integration_test.md` (UT = fully mocked + function level; IT = real chain + interface/E2E level)
- Commands / environments must come from real configuration; fabricating is forbidden
- Only touch `unittest/unittest.md`; do not touch other docs
- If the project has no Go code (no `*.go` / no `go.mod`) → skip and output `skipped(no Go code)`
- After migrating the legacy `testing.md`, it must be deleted; do not leave redundant files
