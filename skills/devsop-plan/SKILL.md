---
name: devsop-plan
description: Turns user input into user stories, acceptance criteria, and test cases via a Socratic challenge loop. Use before any feature work; challenge until requirements are testable, then generate artifacts for devsop-design.
---

# devsop-plan

Turn what the user said into what can be built and tested: user stories with acceptance criteria, and the test cases that prove them. Simple, unambiguous requests pass through with a light challenge; vague ones are challenged until the artifacts would not be guesses.

Core discipline: ask only when the answer would change what gets built; state your calls as proposals the user can correct.

## Entry check

Read `AGENTS.md`, the README, and relevant `docs/` before the first question. Never ask what the project already answers. If the repository has not been initialized for AI collaboration, suggest running `devsop-init` first and continue only with the facts at hand.

## Challenge loop

One question at a time, in the user's own terms, saying what the answer would change:

- "If this is mostly for admins, approval needs an audit trail the customer flow doesn't. Who actually approves this?"
- Skip questions whose answer does not change a story, a criterion, or a test. State your assumption instead and let the user correct it.

**Ground to cover, as territory not script:** what the feature is and who uses it; why now and what success looks like; goals, non-goals, anti-goals; current behavior that will change; edge cases the user would care about.

**Playback:** as soon as one part is clear, play it back in 2-4 sentences and ask what is wrong or missing. Playback and questions alternate.

**Exit condition:** stop challenging when you can write every story with criteria that are observable and testable, and each criterion maps to at least one test case. Then confirm the artifacts with the user before writing files.

## Fast path

For a small, explicit request ("add a `DELETE /items/{id}` endpoint returning 204"), do not interrogate: echo the request in your own words, list the assumptions you will encode (error codes, auth, idempotency) in one short block, and ask the user to correct or confirm before generating artifacts. One round, not a loop.

## Artifacts

Write to `docs/plans/YYYY-MM-DD-<topic>/` (create it; use the project's existing plan location if one is established):

| File | Content |
|---|---|
| `user-stories.md` | One story per row or block: ID, title, narrative ("As a <role> I want <capability> so that <benefit>"), priority (Must/Should/Could), and acceptance criteria. Each criterion is a single observable statement with exact expected values — no "works correctly". Non-goals are listed explicitly at the top. |
| `test-cases.md` | Grouped by story ID. Each case: ID, the acceptance criterion it proves, preconditions, steps, expected result (exact values), and type (unit / integration / manual). Include at least one negative or boundary case per story. Cases the user must perform are marked manual and kept concrete. |

Exact values come from the user or the codebase, never invented. If a value is unknowable, the story is not done being challenged.

## Handoff

Report the artifact paths and a one-line summary per story. State which next step applies:

- Design/architecture work needed → invoke `devsop-design`, which consumes these artifacts.
- Small change with obvious implementation → go straight to `devsop-code`; pass the test-case file so tests are written against it.

Do not start designing or coding unless the user asks for the next stage.

## Red flags

| Thought | Reality |
|---|---|
| "The request is clear enough" | Clear means every criterion is testable with exact values. Echo it back first. |
| "I'll fill in sensible defaults" | State them as proposals; a default the user never heard is one they couldn't reject. |
| "I'll decide the interface now" | Interfaces belong to `devsop-design`. Plan captures what, not how. |
| "User answered everything at once" | Still play back before writing files; playback catches misunderstandings cheaply. |
