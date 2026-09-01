---
name: improve-skills
description: Turn the review findings, deviations, and human feedback that were actually kept in a finished feature into targeted updates to the skills that should have prevented them. Use when the user asks to run a retrospective, learn from the feedback on a feature, or improve the skills themselves. Use at the very end of a feature or bug fix, once the design and implementation are final.
---

You are responsible for closing the loop between what a feature actually needed and what the skills told the agent to do. Every correction a reviewer or a human had to make is a place where a skill was silent, wrong, or too easy to skip. Your job is to find the corrections that survived into the final result, and to turn the generalizable ones into small, testable changes.

You do not re-litigate feedback that was rejected. You do not rewrite skills wholesale. A skill that grows by paraphrase loses the specificity that made it work, so every change you propose is the smallest edit that would have changed the outcome.

Producing no change is a valid and frequent outcome. A skill edited on the strength of a single one-off is worse than one left alone.

<objective>

- Every piece of feedback given during the feature has been collected, from the reviews, the deviations, the feedback journal, the conversation, and the pull request.
- Each candidate has been checked against the final state of the artifacts: only feedback that was kept becomes a lesson.
- Each kept lesson has been classified, and routed to exactly one destination — a skill, or the repository's own memory.
- Every proposed skill change is a minimal delta, deduplicated against what the skill already says.
- A proposal has been written, and changes are applied only after the user approves them.

</objective>

<instructions>

## 1. Gather the candidate feedback

- **`feedback.md`** in the work directory. This is the primary source: corrections recorded as they happened, by the skills that received them. Reconstructing feedback afterwards is unreliable, especially across a compacted or multi-day session.
- **`design-review.md` and `implementation-review.md`**: every finding with its disposition. Accepted findings are candidates; rejected ones are kept separately for step 5.
- **`## Deviations` in `implementation-plan.md`**: each departure from the plan, and its "could the plan have known?" line. This is the highest-signal source you have — see step 4.
- **The conversation**, for corrections that never made it into `feedback.md`.
- **The Git history** of the branch: `git log --oneline`, and the diff between the first version of an artifact and its final state. A design document rewritten immediately after a human message is feedback, whether or not it was phrased as such.
- **The pull request**, if one exists: `gh pr view --comments` and the review threads.

Collect first, with a pointer to where each candidate came from. Do not evaluate yet.

## 2. Prove each candidate was kept

Feedback matters only if it changed the result. For each candidate, find the final state of the file that reflects it, and cite it. Discard anything you cannot ground:

- The design or the code does what the feedback asked for → kept.
- It was discussed and the artifact still does the opposite → not kept, discard.
- It was accepted in a review but no artifact reflects it → not kept. Flag this separately: an accepted finding that never landed is a delivery problem, not a skill problem.

## 3. Classify each kept lesson

Ask one question: would this apply to a different feature, in a different domain, six months from now?

- **Generalizable** — a convention, an invariant, a recurring failure mode, a check that should always be run, a question that should always be asked. Becomes a skill change.
- **Repository-specific** — a business rule, a domain value, a decision that binds this codebase but not others. Becomes an update to the repository's own memory, not to a skill shipped to everyone. This sink matters: it is where most feedback goes, and dropping it is exactly how knowledge gets lost between features.
- **One-off** — specific to this feature and unlikely to recur. Discard, and record that you did.

When unsure between generalizable and repository-specific, choose repository-specific. A rule that only ever applies here costs every other user of the plugin context and gains them nothing.

## 4. Read the deviations for what they actually say

Each recorded deviation carries a "could the plan have known?" line, and the two answers lead to opposite conclusions:

- **Yes** — the planning skill had the information and did not use it. That is a skill delta: add the check, or the question, that would have caught it.
- **No** — the problem was only visible once the code existed. **This is not a skill delta.** Adding a rule that could never have fired makes the planning skill longer and no better. If this recurs across features, the lesson is different in kind: the planning skill should stop pretending to settle that class of decision, and say so.

Unrecorded deviations found by the review belong to `implement`: the recording step was skipped.

## 5. Turn rejected findings into suppressions

Read the rejected findings from both review documents, and any earlier reviews in other work directories. A finding category rejected more than once is noise the review skill should stop producing. Propose adding it to that skill's "What is not a finding" section, quoting the user's reason.

Rejections are as informative as acceptances, and they are the only defense a review skill has against drifting toward volume.

## 6. Deduplicate before proposing

For each generalizable lesson, grep the plugin's `skills/` directory for the concepts involved, and read the sections around any hit.

- **The guidance already exists** → the skill did not fail on content, it failed on discovery. Do not add a second bullet saying the same thing; two phrasings of one rule contradict each other eventually. Propose instead: move it to a more visible section, add it to the skill's `<validation>` list so it is checked rather than merely stated, or replace the abstract statement with the concrete example from this feature. Record which you chose and why.
- **The guidance does not exist** → propose a new bullet in the most specific existing section. Create a new section only when no existing one fits.

## 7. Route each lesson

| What happened | Target |
| --- | --- |
| The design was wrong or incomplete, and a review or a human caught it | The reference skill that owns the artifact (`design-model`, `design-api-http`, `design-api-firestore`, `design-state`, `design-triggers`) |
| A behavior that should have been covered was missing from the design | `plan-tests` |
| The plan was right, the code was wrong | `implement` |
| The plan was wrong, and could have known better | `plan-implementation` |
| A real problem reached the code because a review did not look for it | `review-design` or `review-implementation`: add the check to a lens |
| A category of review finding was rejected repeatedly | `review-design` or `review-implementation`: add it to "What is not a finding" |
| A question was asked that changed nothing, or one that should have been asked was not | `build-feature`'s `design-questions.md` |
| The wrong skill was loaded, or the right one was not | The `description` frontmatter of that skill |
| The artifact was fine, but the next step lacked the context to use it | The `<output>` section of the producing skill |
| The steps were followed and the outcome was still wrong | The `<validation>` section of the skill that produced it |
| A rule binds this repository only | The repository's `CLAUDE.md`, a domain `CLAUDE.md`, or the domain documentation |

One lesson goes to one destination. A lesson that seems to belong to two is either two lessons, or too vague to act on.

## 8. Write the proposal

Write `skill-feedback.md` in the work directory, following the structure in "Output". Present it and get approval before touching any skill.

## 9. Apply the approved changes

The skills live in this plugin's repository, not in the monorepo where the feature was built. Locate it: a local checkout, or the installed plugin directory. If neither is writable, leave the proposal and tell the user which repository to apply it in.

When applying:

- Make the minimal edit. Never rewrite a `SKILL.md` in full to accommodate one bullet.
- Never delete existing guidance unless the lesson is that it was wrong. If so, say so explicitly in the proposal, with the evidence.
- Keep each `SKILL.md` under roughly 500 lines. If a section grows past that, move the detail into a bundled reference file next to `SKILL.md` and link it with `${CLAUDE_SKILL_DIR}`.
- Add a `CHANGELOG.md` entry. The motivation for a rule lives in the changelog, not in the skill body, which stays imperative.

Repository-specific lessons are applied in the monorepo instead, and need the same approval.

</instructions>

<output>

A Markdown file named `skill-feedback.md`, in the work directory at `domains/<domain>/work/<feature-slug>/`, and, once approved, edits to the skills in the plugin repository or to the monorepo's own memory.

<example>

# Skill feedback — Order discounts

**Sources**: `feedback.md` (4 corrections), `design-review.md` (3 findings, 2 accepted), `implementation-review.md` (3 findings, 2 accepted), 2 deviations, 2 pull request comments.
**Candidates**: 11 → kept: 6 → generalizable: 2, repository-specific: 2, one-off: 2 → proposed: 2 skill changes, 2 repository notes.

## Lessons

| # | Lesson | Kept because | Class | Target | Change |
| --- | --- | --- | --- | --- | --- |
| 1 | A list query on a user-owned entity must carry the ownership filter | `orders.service.ts:91` gained `AND userId = @userId` | generalizable | `plan-implementation` | addition |
| 2 | Per-property assertions are fine on single-field DTOs | rejected twice, here and in `work/order-refunds` | suppression | `review-implementation` | suppression |
| 3 | Discounts are capped at 30% in this domain | `order.yaml:36` has `maximum: 0.3` | repository | `domains/orders/CLAUDE.md` | note |
| 4 | Splitting `create` for the stock reservation | deviation D1, "could the plan have known? No" | — | none | none — only visible once the code existed |

## 1. A list query on a user-owned entity must carry the ownership filter

- **Origin**: `implementation-review.md` finding 1, accepted; also raised by a human in the pull request.
- **Kept**: `domains/orders/service/src/orders/orders.service.ts:91`.
- **Why it was missed**: access pattern Q1 in `design.md` did name `userId` in its filter, so the design was right; the plan documented the method without restating the filter, and `userId` ended up used only in logs.
- **Duplicate check**: grepped `skills/` for "tenant", "userId", "ownership", "scope". `implement` covers parameterized queries and index hints, nothing about ownership. No duplicate.
- **Proposed edit**: `skills/plan-implementation/SKILL.md`, service method guidelines, add: "For a method listing a user-owned entity, state the ownership filter in its JSDoc alongside the index it uses. A method that takes a user id and uses it only in logs is a defect."

</example>

</output>

<validation>

1. Every source was checked: `feedback.md`, both review documents, the deviations, the conversation, the Git history, and the pull request if one exists.
2. Every lesson cites the final artifact that proves the feedback was kept.
3. Every kept lesson is classified as generalizable, repository-specific, or one-off, and repository-specific lessons were routed to the repository rather than discarded.
4. Every deviation was read for its "could the plan have known?" answer, and no skill delta was proposed for one answered "no".
5. Every generalizable lesson was checked for duplicate guidance before a change was proposed.
6. Every proposed change names exactly one destination and quotes the exact text to add or replace.
7. Rejected review findings were reviewed for suppression rules.
8. The user approved the proposal before anything was edited.
9. No skill was rewritten wholesale, and no existing guidance was removed without explicit justification.

</validation>

# What makes a good skill delta

A good delta is imperative, testable, and about one behavior. It tells the agent what to do, in a situation it can recognize.

Bad, because it is unfalsifiable and describes an attitude:

> Be careful about data access patterns and think about security implications when writing queries.

Good, because an agent can tell whether it complied:

> For a query listing a user-owned entity, the ownership filter belongs in the SQL. A method that takes a user id and uses it only in logs is a defect.

Check each proposed delta:

- Could a reviewer tell, from the artifact alone, whether it was followed?
- Does it name the situation it applies to, rather than applying always?
- Is it shorter than the sentence it replaces, or is it earning its length?
- Does it contradict anything already in that skill, or in a skill upstream of it?

# Budget and pruning

Skills degrade by accumulation as surely as by omission. There is no automated check on these edits, so restraint is the only safeguard. Each run:

- Propose at most five changes. If you have more candidates, keep the ones whose failure mode recurred, or whose consequence was most severe, and record the rest as observed but not acted on.
- Prefer strengthening a `<validation>` list to adding a guideline. Validation items are checked; prose is skimmed.
- Look for rules to remove: guidance this feature contradicted, that a review kept rejecting, or that duplicates something now enforced by code generation, the type checker, or the linter. Propose removing them, with the evidence.
- If two skills say related things about the same subject, propose consolidating into the one that owns the subject, and referencing it from the other.

# What never becomes a skill change

- Feedback the user rejected. It goes to a review skill's suppression list, or nowhere.
- Business rules and domain values. Those belong in the repository's own memory, not in a skill shipped to every user of the plugin.
- A deviation whose "could the plan have known?" answer is "no". A rule that could never have fired is pure cost.
- Anything already enforced by the linter, the formatter, the type checker, or code generation. Fix the tooling instead, and say so.
- A preference expressed once, with no consequence named.
- A restatement of guidance the skill already gives. That is a discovery problem; treat it as step 6 describes.
