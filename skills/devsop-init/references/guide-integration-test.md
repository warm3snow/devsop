# Integration Test Documentation Guide

> Use this guide when the project has integration tests to document. The main agent can follow it directly or delegate the task when supported.
> Adapt any output to the project's existing testing-documentation location and naming convention.

---

## Core Goal

Document the relevant integration-test scope and run guidance for **real chains, interface / E2E level**, aligned with the project's existing dependency and environment sources when present.

---

## Steps

### 1. Scan integration test facts

- Existing IT cases: tests in `*_test.go` that go through real chains / the `integration_test/` directory / e2e scripts
- External dependencies: database / MQ / third-party services (from `relationship.md`)
- Test environment: setup and deployment method (from the relevant project docs or configuration)
- Framework: testify / ginkgo / built-in test runner

### 2. Generate / update the document

Fill in per the skeleton's three-part structure:
- **Environment and Dependencies** — middleware / services / data preparation required for integration tests, with dependency items aligned to `relationship.md`
- **Test Case Design** — E2E case list for core chains (scenario / prerequisites / steps / assertions), with no overlap with the UT layering (IT = real chain + interface/E2E level; UT = fully mocked + function level)
- **Run and Debug** — start commands / environment variables / how to run a single IT locally / common failure troubleshooting

### 3. Align and reference

- Dependencies and environment setup come from the relevant project docs or configuration — link to them rather than duplicating content.
- If the repository has integration-test project rules (`rules/integration_test_*.md` / `it_*.md`), excerpt + link and mark the authority relationship.

---

## Constraints

- Forbidden to test the same layer of logic as `unittest/unittest.md` (UT = function-level mock; IT = real chain).
- Commands / environments must come from real configuration; fabricating is forbidden.
- Only create or update the selected authoritative testing source when a gap is confirmed; preserve unrelated docs.
