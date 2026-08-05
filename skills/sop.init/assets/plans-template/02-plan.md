# 02. Plan

> **Purpose**: Turn the conclusions of Clarify into an executable technical solution.
> **Input**: goals and scope from `01-clarify.md`
> **Output**: change list, call chain, data model, **UT cases (TDD first)**, IT cases
> **TDD mode**: this stage must design the UT cases (§6) **before** Implement; the UT/IT boundary and Red-Green cycle constraints are detailed in `04-ut.md` §0.5; this file only lists the UT case skeleton, duplicate content is not copied.

---

## 1. Solution Overview

> Describe the overall solution in one paragraph, including key choices.

## 2. Change File List

| File | Change Type | Description |
|------|---------|------|
|  | Add / Modify / Delete |  |

> **Principle**: one row per file, do not merge multiple files. For new files, specify the directory they belong to.

## 3. Impact Scope

| Dimension | Impact |
|------|------|
| Interfaces |  |
| Modules |  |
| DB schema |  |
| Config |  |
| Protocol compatibility |  |
| Upstream / downstream services |  |

## 4. Call Chain

```
<Entry interface>
  → <Layer 1>
    → <Layer 2>
      → <Final storage / external call>
```

> Mark the **added** or **modified** nodes, and explain the differences from the original chain in comments.

## 5. Data Structure Changes

### 5.1 Internal DataType / Schema

| Type | Field | Type | Required | Description |
|------|------|------|------|------|
|  |  |  |  |  |

### 5.2 DB Table Structure

| Table | Change | Index Impact | Rollback Method |
|----|------|---------|---------|
|  |  |  |  |

> Persistence structure changes must also update the corresponding file under `.harness/docs/sqls/` (DB schema / migration / protocol frames / config schema, etc.).

### 5.3 Protocol / Interface Contract

| Interface | Added Fields | Required | Compatibility |
|------|---------|------|-------|
|  |  |  |  |

> **Compatibility check**: are the added fields optional? Can old clients still work normally?

## 6. UT Case Design (TDD required, before Implement)

> **Hard requirement**: this section must be in place before Step 3; the Implement stage proceeds Red → Green → Refactor, and **"write code first, add UT later" is forbidden**.
> Design goals: at least one UT per core function / key branch; UT fully mocked to verify at function level, IT uses the real chain to verify the call chain, **the two do not test the same layer twice** (see `04-ut.md` §0.5).

| # | Tested Object (function / class / module path) | Test File (planned) | Type | Input | Expected Output / Behavior | Mock Boundary |
|---|----------------------------------|------------------|------|------|----------------|-----------|
| 1 | `business.<m>.<func>` |  | Positive |  |  | DB / external API |
| 2 |  |  | Negative (invalid input) |  | Throw `<ErrorCode>` |  |
| 3 |  |  | Boundary (max/min/empty) |  |  |  |
| 4 |  |  | Exception (dependency failure) |  |  | mock throws `Timeout` |
| 5 |  |  | Idempotency (repeated calls) |  | State/side effects consistent |  |

> **Hard requirement**: cover at least the **positive + negative + boundary** three types; write operations must add an **idempotency** type; functions calling external dependencies must add an **exception** type.
> The "Mock Boundary" must explicitly declare which dependencies this case mocks, to avoid UT degrading into implicit IT.
> If the Implement stage finds a gap in the UT design, **you must come back to this section to supplement it** and re-enter Red → Green; "finish writing code first, then add UT" is forbidden.

## 7. IT Case Design

| # | Scenario | Type | Preconditions | Steps | Expected Result |
|---|------|------|---------|---------|---------|
| 1 |  | Positive |  |  |  |
| 2 |  | Positive (typical) |  |  |  |
| 3 |  | Negative (invalid input) |  |  |  |
| 4 |  | Boundary (upper / lower limit) |  |  |  |
| 5 |  | Exception (dependency failure) |  |  |  |
| 6 |  | Idempotency |  |  |  |

> **Hard requirement**: cover at least the positive + negative + boundary three types; cases involving external calls must add an exception type; write operations must add an idempotency type.

## 8. Risks and Fallbacks

| Risk | Trigger | Impact | Mitigation | Rollback Plan |
|------|---------|------|------|---------|
|  |  |  |  |  |

## 9. Effort Estimate

| Stage | Effort | Remarks |
|------|------|------|
| Implement |  | Includes TDD test-writing time |
| UT |  | Includes Red-Green cycle + reaching coverage target |
| Deploy + IT |  |  |
| Docs + Review |  |  |
| **Estimated code change lines** | **<line count>** | **Excludes tests / docs; when ≤ 10, set the `00-overview.md` Meta `Small-requirement mode` to ✅** |

---

## Decision Framework

1. **Draw first**: call chains, data flows, state machines — anything that can be drawn as a diagram should not be written as text.
2. **Find similar**: first look at whether similar interfaces / modules exist in the project; reusing existing patterns is better than inventing new ones.
3. **Minimal changes**: if one file can solve it, do not change two.
4. **Boundaries first**: list all boundary / exception scenarios first, then think about the positive path.

## Anti-examples

❌ **Change list too coarse** → list per file (`internal/logic/auth/loginlogic.go` adds a phone-number branch, `internal/types/types.go` adds a `PhoneNumber` type), not "revamp the auth module".
❌ **IT cases only have positive** → at least positive / negative / boundary three types; add idempotency for write operations, exception for external dependencies.
❌ **DB change without rollback** → write "add column `last_login_ip VARCHAR(45) NULL`, rollback via `ALTER TABLE DROP COLUMN`".

## Completion Criteria

- [ ] Change file list complete, each file has a description
- [ ] Call chain clear (diagram recommended)
- [ ] Data structure changes include rollback method
- [ ] **UT cases designed** (§6), covering positive / negative / boundary, write operations include idempotency, external dependencies include exceptions; Mock boundaries explicitly declared
- [ ] IT cases cover positive / negative / boundary, with exception and idempotency added when necessary
- [ ] Risk table has mitigation and rollback
- [ ] `00-overview.md` Progress / Current Step / Time Tracking synced
- [ ] End confirmation completed with the user
