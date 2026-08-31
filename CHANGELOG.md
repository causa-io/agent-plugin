# 🔖 Changelog

## Unreleased

Breaking changes:

- Rename the plugin from `skills` to `causa`, so its skills are namespaced as `causa:<skill>`.

Features:

- Add validation checklists to the `bump-version` and `document` skills.
- Add a Spanner DDL example to the `design-state` skill, and document the table name override, row deletion policies, and interleaved tables.

Fixes:

- Correct the `errorCode` property description in the `design-api-http` skill, which duplicated the `statusCode` one.
- Pass `--no-git-tag-version` to `npm version` in the `bump-version` skill, so it no longer creates a commit and tag that conflict with the following step.
- Reference bundled skill files with `${CLAUDE_SKILL_DIR}` instead of relative paths, which did not resolve from the working directory.
- Declare the JSONSchema examples as draft 2020-12, the first draft to define the `$defs` keyword they use.
- Add the missing usage triggers to the `implement` and `plan-tests` descriptions.
- Fix a typo in the `design-scenario` skill.
- Fix the step numbering in the design skills, where a nested list restarted the outer sequence.
- Reference the timeline JSONSchema from the `design-timeline` skill and its example, matching the `design-scenario` skill.
- Replace the skill reference appendix in the `build-feature` skill with a table of skill outputs, dropping guidance already carried by each skill's description.

Chores:

- Complete the plugin and marketplace manifests, and add a license, a `.gitignore`, and a validation workflow.

## v1.1.0 (2026-06-24)

Features:

- Define the `design-timeline` skill, referenced by the `build-feature` and `design-scenario` skills.

## v1.0.0 (2026-06-23)

Features:

- Define the `build-feature`, `bump-version`, `design-api-firestore`, `design-api-http`, `design-model`, `design-scenario`, `design-state`, `document`, `implement`, `plan-implementation`, and `plan-tests` skills.
