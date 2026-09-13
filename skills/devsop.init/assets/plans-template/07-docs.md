# 07. Docs

> **Purpose**: Ensure all docs corresponding to the code changes are updated in sync, preventing "code moves on while docs stay behind".
> **Input**: code changes + deliverables from Plan / Implement / IT
> **Output**: updated documentation files

---

## 1. Mandatory Checklist

> Actual paths must first be confirmed from the `.docs/` directory. Fill "➖ Not applicable" for items that do not apply.

**Architecture and upstream/downstream**
- [ ] `.docs/architecture.md` — system architecture (when adding modules / changing call chains / changing concurrency models)
- [ ] `.docs/relationship.md` — upstream/downstream / integrator relationships (when adding dependencies / adjusting topology)

**External interfaces / contracts**
- [ ] API docs `.docs/apis/<module>/<Action>.md` (must change when adding / modifying interfaces)
- [ ] API master index `.docs/apis/index.md` (append when adding interfaces)

**Data / persistence**
- [ ] DB schema / migration `.docs/sqls/<...>` (must change on DDL changes)

**Test standards**
- [ ] `.docs/unittest/unittest.md` (when test conventions / naming / mock strategy change)
- [ ] If unit-test project rules exist in the repo (`rules/unittest_*.md`), revise them in sync as the authoritative source

**Environment / deployment**
- [ ] `.docs/devops/env.md` (when environment setup / startup methods change)
- [ ] `.docs/devops/test-env-deploy.md` (when test environment deployment / sync flow changes)

**Global**
- [ ] External README / user guide — changes visible to users
- [ ] CHANGELOG — version change log

## 2. Change Details

| Document | Path | Change Type | Change Description | Status |
|------|------|---------|---------|------|
|  |  | Add / Modify |  | ⬜ |

> Status: ⬜ Pending \| ✅ Updated \| ➖ Not applicable

## 3. Consistency Spot-Check

> After the docs are written, randomly spot-check several places to confirm consistency with the code.

| Spot-Check Item | Corresponding Code | Consistent |
|-------|---------|------|
| API parameter names |  | ⬜ |
| Error code enums |  | ⬜ |
| Field default values |  | ⬜ |
| Config item names |  | ⬜ |

---

## Anti-examples

❌ **Anti-example 1: only change code, not docs**
> Added a new field, but it is not in the docs. Six months later someone integrates against the docs and fails.

❌ **Anti-example 2: writing docs like commit messages**
> "Fixed bug", "optimized performance" — external users cannot understand.

✅ **Principle**
> API docs are written from the caller's perspective, explaining "what it does / how to call it / what it returns / how to see what went wrong".

❌ **Anti-example 3: only change one place, forget the rest**
> Changed `apis/<module>/<Action>.md`, forgot to update the call-chain diagram in `apis/index.md` and `architecture.md`.

✅ **Principle**
> Use this stage's checklist to check off item by item, preventing omissions.

---

## Completion Criteria

- [ ] Every item on the mandatory checklist is explicitly "Updated" or "Not applicable"
- [ ] All change details marked ✅
- [ ] All consistency spot-checks pass
- [ ] Checked off 07. in `00-overview.md` Progress
- [ ] End confirmation completed with the user
