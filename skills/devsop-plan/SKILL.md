---
name: devsop-plan
description: Turns user input into a single scenario-based plan.md (stories, non-functional requirements, Given/When/Then verification scenarios) via a Socratic challenge loop. Use before any feature work; challenge until requirements are testable, then generate artifacts for devsop-design.
---

# devsop-plan

Turn what the user said into what can be built and tested: one `plan.md` where user stories carry functional scenarios and a separate section carries non-functional constraints. Each scenario is both the acceptance criterion and its test — written once, in business terms. Simple, unambiguous requests pass through with a light challenge; vague ones are challenged until the artifact would not be guesses.

Core discipline: ask only when the answer would change what gets built; state your calls as proposals the user can correct.

## Entry check

Read `AGENTS.md`, the README, and relevant `docs/` before the first question. Never ask what the project already answers. If the repository has not been initialized for AI collaboration, suggest running `devsop-init` first and continue only with the facts at hand.

## Challenge loop

One question at a time, in the user's own terms, saying what the answer would change:

- "If this is mostly for admins, approval needs an audit trail the customer flow doesn't. Who actually approves this?"
- Skip questions whose answer does not change a story, a scenario, or a constraint. State your assumption instead and let the user correct it.

**Ground to cover, as territory not script:** what the feature is and who uses it; why now and what success looks like; goals, non-goals, anti-goals; current behavior that will change; edge cases the user would care about.

**UI ground, when the feature has an interface:** platform (web / mobile / both); style direction (e.g. tech / enterprise) or reference material (screenshots, links, an existing product to imitate); for an existing repo, which pages or components the change touches. Record the answers in the plan — `devsop-design` turns them into prototypes.

**Playback:** as soon as one part is clear, play it back in 2-4 sentences and ask what is wrong or missing. Playback and questions alternate.

**Exit condition:** stop challenging when every story has at least one scenario (including a negative or boundary one), every non-functional requirement has a verifiable scenario or exact metric, and all expected values are known. Then confirm the artifact with the user before writing files.

## Fast path

For a small, explicit request ("add a `DELETE /items/{id}` endpoint returning 204"), do not interrogate: echo the request in your own words, list the assumptions you will encode (error codes, auth, idempotency) in one short block, and ask the user to correct or confirm before generating artifacts. One round, not a loop. Keep these technical assumptions out of `plan.md`; hand the confirmed block to the next stage as interface-contract input.

## Artifacts

Write one file, `docs/plans/YYYY-MM-DD-<topic>/plan.md` (create the directory; use the project's existing plan location if one is established):

```markdown
# <topic> — <date>

## Non-goals
- ...

## Non-functional requirements
### NFR-1 <name> [integration|manual]
- Constraint: <business-visible statement, e.g. "list page loads in under 2 seconds">
- Scenario: Given <precondition> / When <action> / Then <exact observable result>

## US-1 <title> [Must]
As a <role> I want <capability> so that <benefit>.

### S1.1 <scenario name> [unit|integration|manual]
- Given <precondition>
- When <action>
- Then <exact business-observable result>

### S1.2 <negative or boundary scenario> [...]
- Given ... / When ... / Then ...
```

Rules:

- **A scenario is both the acceptance criterion and its test case.** Write it once; the type tag (`unit` / `integration` / `manual`) tells downstream stages how it is verified. Scenarios the user must perform are marked `manual` and kept concrete.
- **Every story has at least one negative or boundary scenario.**
- **Functional vs non-functional:** stories carry functional scenarios; performance, security, availability and similar constraints go in the NFR section, each with its own verifiable scenario or exact metric. NFRs apply across stories — do not bury them inside one story.
- **Stay non-technical:** narrative and scenarios use user/business language. `Then` states business-observable exact values ("3 items remain", "shows 'Deleted'") — never API paths, status codes, field names, or library names. Those belong to `devsop-design`'s interface contract and the test implementation.
- Exact values come from the user or the codebase, never invented. If a value is unknowable, the story is not done being challenged.
- **Self-check before handoff:** run `python3 "$SKILL_DIR/scripts/validate_plan.py" docs/plans/<topic-dir>/plan.md` (`SKILL_DIR` = this skill's directory) and fix every reported error. Warnings flag technical values that belong in `devsop-design`'s interface contracts.

## Handoff

Report the artifact path and a one-line summary per story. State which next step applies:

- Design/architecture work needed → invoke `devsop-design`, which consumes `plan.md`.
- Small change with obvious implementation → go straight to `devsop-code`; pass `plan.md` plus the confirmed assumptions block — `devsop-code` derives a minimal task list from the scenarios.

Do not start designing or coding unless the user asks for the next stage.

## Red flags

| Thought | Reality |
|---|---|
| "The request is clear enough" | Clear means every scenario is testable with exact values. Echo it back first. |
| "I'll fill in sensible defaults" | State them as proposals; a default the user never heard is one they couldn't reject. |
| "I'll decide the interface now" | Interfaces belong to `devsop-design`. Plan captures what, not how. |
| "Status codes and field names make it precise" | They make it implementation. Precision comes from exact observable outcomes; technical contracts are design's job. |
| "User answered everything at once" | Still play back before writing files; playback catches misunderstandings cheaply. |
