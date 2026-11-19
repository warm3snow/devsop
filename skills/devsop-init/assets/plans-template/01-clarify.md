# 01. Clarify

> **Purpose**: Clarify vague ideas into executable requirements. This stage focuses on the three things **Background / Goals / Risk Points**, and must be fully aligned with the user.
> **Recommended aid**: use `skill: clarify` to clarify requirements; AI switches to the "Product Manager" role to conduct the two-phase Discovery + Challenge dialogue. If the skill is unavailable, proceed manually following the "Decision Framework" below.
> **Input**: user's original description / issue-tracker ticket / Issue link
> **Output**: this file fully filled in + key decision points registered in the `00-overview.md` key decision log

---

## 1. Background (Context)

> Why do it? What are the business / technical pain points? What happens if we don't do it?

<!-- Fill in -->

## 2. Goal

> What counts as done? Quantitative metrics preferred.

**Primary goals**:
-

**Success metrics (verifiable)**:
| Metric | Current Value | Target Value | How to Verify |
|------|-------|-------|---------|
|  |  |  |  |

## 3. Risk Points

> High-level risks at the **requirements** level (business / compliance / resource dependencies / cross-team collaboration, etc.); each must give a mitigation or fallback. Technical implementation risks (interfaces / data / compatibility, etc.) are detailed in `02-plan.md §8` Risks and Fallbacks.

| # | Risk | Severity | Mitigation / Fallback |
|---|------|-------|------------|
|  |  | 🟡 Medium |  |

## 4. Open Questions

> Every question must have a conclusion before proceeding. **Forbidden** to enter the Plan stage with unresolved questions.

| # | Question | Conclusion | Decision Maker |
|---|------|------|-------|
| 1 |  |  |  |

## 5. References

- Ticket / Issue:
- Related APIs / design docs / ADRs:
- Upstream / downstream dependencies:

---

## Decision Framework

1. **5W1H self-check**: Can Why / What / Who / Where / When / How each be answered in one sentence?
2. **INVEST**: Does the requirement satisfy Independent, Negotiable, Valuable, Estimable, Small, Testable?

## Anti-examples

❌ **Vague goal** → "`DescribeInstances` P99 reduced from 800ms to 200ms, verified at 5000 QPS on the dev environment with a benchmark script."
❌ **Risk point without mitigation** → write out "risk + severity + mitigation/fallback", avoid "we know there's a risk, but no solution yet".

## Completion Criteria

- [ ] Background and goals are written out, goals are quantifiable
- [ ] Risk points identified and given mitigation/fallback
- [ ] All open questions have clear conclusions
- [ ] Key decisions synced to the "Key Decision Log" section of `00-overview.md`
- [ ] `00-overview.md` Progress / Current Step / Time Tracking synced
- [ ] End confirmation completed with the user: "Clarify is done, proceed to Plan?"
