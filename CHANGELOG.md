# 🔖 Changelog

## v2.0.0 (2026-09-11)

Breaking changes:

- Rename the plugin from `skills` to `causa`, so its skills are namespaced as `causa:<skill>`.
- Restructure delivery into two stages, each ending in a single human gate on complete, already-reviewed work: design (clarify, design every contract, review, fix), then implementation (plan, code, document, review, fix). `build-feature` now orchestrates both and writes the contracts itself, rather than invoking a gated design skill per artifact.
- Turn the design skills into pure knowledge references: `design-model`, `design-api-http`, `design-api-firestore`, `design-state`, `design-scenario`, and `design-timeline` lose their personas, `<objective>` blocks, questioning steps, and confirmation gates, and their `<output>` sections now describe the artifacts on disk rather than a work-directory document. Gates belong to whoever is talking to the human.
- Replace the per-skill design documents with a single `design.md`, written by `build-feature`.
- Move access patterns, indexes, triggers, and the whole of `causa.yaml` into the design stage. `plan-implementation` no longer writes `causa.yaml` and is limited to code architecture.
- Replace `plan-tests`' test skeletons with a list of the behaviors to cover, derived from the contracts and written during design. How a behavior is tested is now decided while writing the code.

Features:

- Define the `review-design` and `review-implementation` skills: adversarial reviewers that always run in a context holding none of the author's rationale, ground every finding in cited evidence and a concrete failure scenario, and must attempt to refute each finding before reporting it.
- Define the `improve-skills` skill, which turns the review findings, deviations, and human feedback that were kept into minimal skill deltas, and routes repository-specific lessons to the repository's own memory instead of discarding them. It stops at a self-contained `skill-feedback.md`, leaving the edits to an agent working in the plugin's own repository.
- Define the `design-triggers` skill, covering the events a service consumes, the tasks it enqueues, and the crons it runs. It is independent of `design-model`: a new topic needs no consumer, and a trigger on another domain's topic needs no contract.
- Add access patterns to `design-state`, listing every way the feature reads data — including the lookups from event handlers, crons, and internal logic that are invisible from the API contracts — so that indexes are justified by a query rather than guessed.
- Add a bundled question inventory to `build-feature`, asked in two waves — scope first, then only the surfaces in scope — with an assumption ledger in `requirements.md` for everything not asked.
- Record deviations from the implementation plan in `implement`, each with whether the plan could have anticipated it. The plan is a briefing, not a specification.
- Add a `feedback.md` journal, appended to by `build-feature` and `implement` as corrections happen, so `improve-skills` reads a log instead of reconstructing one.
- Add validation checklists to the `bump-version` and `document` skills.
- Add a Spanner DDL example to the `design-state` skill, and document the table name override, row deletion policies, and interleaved tables.
- Make the skills portable across harnesses, by conforming to the [Agent Skills](https://agentskills.io) open standard rather than to Claude Code's extensions.

Fixes:

- Correct the `errorCode` property description in the `design-api-http` skill, which duplicated the `statusCode` one.
- Pass `--no-git-tag-version` to `npm version` in the `bump-version` skill, so it no longer creates a commit and tag that conflict with the following step.
- Declare the JSONSchema examples as draft 2020-12, the first draft to define the `$defs` keyword they use.
- Add the missing usage triggers to the `implement` and `plan-tests` descriptions.
- Fix a typo in the `design-scenario` skill.
- Fix the step numbering in the design skills, where a nested list restarted the outer sequence.
- Reference the timeline JSONSchema from the `design-timeline` skill and its example, matching the `design-scenario` skill.
- Replace the skill reference appendix in the `build-feature` skill with a table of skill outputs, dropping guidance already carried by each skill's description.

Chores:

- Complete the plugin and marketplace manifests and add a license.

## v1.1.0 (2026-06-24)

Features:

- Define the `design-timeline` skill, referenced by the `build-feature` and `design-scenario` skills.

## v1.0.0 (2026-06-23)

Features:

- Define the `build-feature`, `bump-version`, `design-api-firestore`, `design-api-http`, `design-model`, `design-scenario`, `design-state`, `document`, `implement`, `plan-implementation`, and `plan-tests` skills.
