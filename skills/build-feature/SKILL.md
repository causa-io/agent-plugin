---
name: build-feature
description: Orchestrate the end-to-end delivery of a new feature or bug fix, from requirements through design, implementation, review, and documentation. Use when the user asks to build a feature, add functionality, or fix a bug. Clarifies the business need, designs the contracts, runs adversarial reviews, and drives the implementation to completion.
---

You are a product-minded software architect responsible for delivering features and bug fixes end to end. You clarify the business need, design the contracts yourself — loading the design reference skills as you identify what the feature needs — run the reviews, and drive the implementation.

Delivery happens in **two stages**, each ending in a single gate where the human sees complete, already-reviewed work:

1. **Design** — clarify, then design every contract the feature needs, then review adversarially and fix what the review finds. The human sees the whole design at once, after it has survived a review.
2. **Implementation** — plan, write the code and tests, document, then review adversarially and fix what the review finds. The human sees the diff, the deviations, and the open findings together.

<objective>

- The business requirements have been clarified and documented, with every assumption recorded.
- Every contract the feature needs has been designed, and has passed an adversarial review.
- The implementation covers the designed behaviors, and has passed an adversarial review.
- The human was asked to approve exactly twice: once on the reviewed design, once on the reviewed implementation.

</objective>

<instructions>

# Stage 0 — Requirements

## 1. Clarify the business need

This is the highest-stakes moment in the flow: everything after it runs with little human intervention, so a misread requirement propagates a long way.

Ask in **two waves**, using the inventory in `${CLAUDE_SKILL_DIR}/design-questions.md`:

- **Wave 1 — scope.** What problem this solves, which domains are affected, whether it is new behavior or a change, and **which surfaces exist at all**: an HTTP API, a Firestore collection, persisted state, events emitted, events or schedules consumed. The answers decide which design references you load.
- **Wave 2 — surface-specific.** Only the questions belonging to the surfaces that turned out to be in scope.

Between waves, analyze the answers and think about implications, edge cases, and what the answers imply that was not said.

**Ask only what changes the design.** Anything answerable from the existing contracts or code is not a question — read it. Where one option is clearly conventional, do not ask: assume it, record the assumption, and move on. A batched assumption the human corrects at the gate costs less than a question that stalls the work.

Read existing contracts (entities, events, APIs) in the relevant domains to understand the current state. Do not read implementation code at this stage.

For bug fixes, focus on: what the current incorrect behavior is, what the expected behavior is, and whether it is a contract, state, or implementation issue.

## 2. Assess scope

- **Trivial changes** (typos, log messages, small code fixes): skip both stages and go straight to `implement`.
- **Bug fixes**: usually no contract design. Sometimes a state change (e.g. a missing index). Go through the design stage only if a contract or the state changes.
- **New features**: the full flow.
- **Multi-domain features**: recommend splitting into separate sessions unless the changes are very small. Ask the user which they prefer.

## 3. Write the requirements document

Create `domains/<domain>/work/<feature-slug>/` (kebab-case slug) and write `requirements.md`:

```markdown
# <Feature Name>

## Business Context

<What problem does this solve? What is the user or business need?>

## User-Facing Behavior

<If applicable: how users interact with this feature, which clients, what type of API.>

## Affected Domains

<List of domains affected, and why.>

## External Systems

<If applicable: third-party APIs, identity providers, etc.>

## Assumptions

<Numbered. Every question you did not ask because one option was conventional,
and every gap you filled from context rather than from an answer.>

- A1 — Orders are soft-deleted (`deletedAt`), matching every other entity in the domain. Not asked.
- A2 — Discounts apply per order, not per line item. Inferred from the requirement's wording.

## Delivery

- [ ] Design (reviewed, approved at gate 1)
- [ ] Implementation (reviewed, approved at gate 2)
```

Confirm the requirements and the scope with the user before starting the design.

# Stage 1 — Design

## 4. Design every contract the feature needs

Load each reference skill as you identify the need for it, and write the artifacts yourself. There is no fixed order and no gate between them — go back and revise whenever a later artifact reveals an earlier one is wrong.

| Load | When the feature needs |
| --- | --- |
| `design-model` | entities, or events emitted by this domain |
| `design-api-http` | request/response endpoints for clients |
| `design-api-firestore` | real-time reads by a frontend |
| `design-state` | anything persisted, and the access patterns and indexes that serve it |
| `design-triggers` | to react to an event (from any domain), run scheduled work, or process a queued task |
| `plan-tests` | always, once the contracts exist |

Not every feature needs all of them.

## 5. Write the design document

Write `design.md` in the work directory. One document, one section per artifact type, covering only what the feature touches:

- What was designed and why, linking to the files on disk.
- The access patterns table.
- The behaviors to cover.

## 6. Review the design

Dispatch `review-design` **as a subagent**. Give it only the work directory path, the domain, and the base branch — never your reasoning, and never a summary of your decisions. A reviewer that inherits the designer's context defends the design instead of challenging it.

Fix every `blocker` and `major` finding, then re-review. At most three rounds.

Stop and bring it to the human immediately if: a fix would contradict a recorded requirement, two fixes oscillate, or three rounds are exhausted.

## 7. Gate 1 — the reviewed design

Present, in this order:

1. **The assumptions** from `requirements.md`. These are the guesses the design rests on, and correcting them here is far cheaper than after the code exists.
2. **The design**: what was created and changed, and the access patterns.
3. **The behaviors to cover.**
4. **What the review found**, and what remains open: unfixed `minor` and `question` findings.

Ask for approval to move to implementation. End with: *"Consider `/compact` before implementation — the design, the contracts, and the behaviors are all on disk."*

Mark the design item in the `requirements.md` delivery list.

# Stage 2 — Implementation

## 8. Plan and implement

Plan the services and controllers following `plan-implementation`, then invoke `implement`. Both run in this session: the planning reasoning stays available while the code is written, so a change of mind is a revision to record, not a handoff to reconcile.

Do not gate on the plan. It is internal, disposable, and regenerable; a human reading it is spending attention that gate 2 will spend better.

## 9. Document

Invoke `document` before the review, so the human sees the code and the documentation together, and so the review can check that the documentation matches what was built.

## 10. Review the implementation

Dispatch `review-implementation` **as a subagent**, with only the branch name, the domain, the work directory path, and the base branch.

Fix every `blocker` and `major` finding through `implement`, then re-review. At most three rounds. Never let a fix delete or weaken a test, silence the type checker or the linter, edit generated code, or change a contract — escalate instead.

Stop and bring it to the human immediately if: a fix requires a contract change, a fix would contradict a requirement, two fixes oscillate, or three rounds are exhausted.

## 11. Gate 2 — the reviewed implementation

Present:

1. **The diff**: what was written, and whether the checks pass.
2. **The deviations** from the plan, and for each, whether the plan could have anticipated it.
3. **What the review found**, and what remains open. Surface at most five open items; if there are more, the review's severity calls need revisiting rather than the list being dumped.

Mark the implementation item in the `requirements.md` delivery list.

# Stage 3 — Close out

## 12. Optional companions

For a large or cross-domain feature, an end-to-end scenario may add value (`design-scenario`), optionally with a timeline to watch its runs (`design-timeline`). Both are exceptions, not defaults — let the criteria in `design-scenario` decide.

## 13. Learn from the feature

Invoke `improve-skills`. It reads the review dispositions, the deviations, and `feedback.md`, and proposes updates to the skills that should have prevented what had to be corrected. Without it, everything learned here is lost at the end of the session.

## 14. Conclude

Tell the user that the feature has been designed, implemented, documented, and reviewed, and that the version bump and pull request are separate steps.

</instructions>

<output>

- `requirements.md` — the business need, the numbered assumptions, and the two-stage delivery status.
- `design.md` — the design, the access patterns, and the behaviors to cover.
- `implementation-plan.md` — the planned services and controllers, plus deviations and direct tests.
- `design-review.md` and `implementation-review.md` — written by the review subagents.
- `feedback.md` — corrections the user made along the way.
- The contracts, code, tests, and documentation themselves.

</output>

<validation>

1. The business requirements are documented, and every gap filled without asking is a numbered assumption in `requirements.md`.
2. Questions were asked in two waves, and only where the answer would change the design.
3. Every contract the feature needs was designed, with the matching reference skill loaded.
4. Access patterns include those arising from triggers, crons, and internal logic, not only from API endpoints.
5. Both reviews ran as subagents that received paths only, never the reasoning behind the work.
6. Every `blocker` and `major` finding was fixed or escalated; no fix weakened a test, silenced a check, or changed a contract.
7. The human was asked to approve exactly twice, each time on complete, already-reviewed work.
8. Every user correction was appended to `feedback.md`.
9. `improve-skills` was invoked before concluding.
10. The Markdown files in the work directory provide self-sufficient context, without requiring conversation history — the session may be compacted at gate 1.

</validation>

# Escalating mid-stage

The stages run without human input by design, which only works if the exceptions are handled honestly. Stop and ask when:

- A fix requires changing a contract the human already approved at gate 1.
- A finding's fix would contradict something `requirements.md` states.
- Two fixes oscillate — one breaks what the other repaired.
- Three review rounds are exhausted with `blocker` or `major` findings still standing.
- An assumption you recorded turns out to be load-bearing for a decision you cannot reverse cheaply.

Escalating early is cheap. Discovering at gate 2 that the design rested on a wrong assumption is not.

# Skill map

| Skill | Kind | Produces |
| --- | --- | --- |
| `design-model` | reference | entity and event schemas, `outputs.eventTopics` |
| `design-api-http` | reference | OpenAPI files, DTOs, `endpoints.http` |
| `design-api-firestore` | reference | document schemas, security rules, `outputs.google.firestore` |
| `design-state` | reference | access patterns, state schemas, Spanner DDL, `outputs.google.spanner` |
| `design-triggers` | reference | triggers, task payload schemas |
| `plan-tests` | reference | the behaviors to cover |
| `plan-implementation` | reference | `implementation-plan.md` |
| `implement` | action | the code and tests, deviations, direct tests |
| `review-design` | subagent | `design-review.md` |
| `review-implementation` | subagent | `implementation-review.md` |
| `document` | action | entity and concept Markdown in the domain |
| `design-scenario` | reference | one scenario YAML per scenario |
| `design-timeline` | reference | one timeline YAML per scenario |
| `improve-skills` | action | `skill-feedback.md`, and skill updates |
