---
name: bump-version
description: Bump the service version (including its active version) and update the changelog following a feature or bug fix. Use when the user asks to bump, release, or version a service, or to update the changelog and deploy a new version.
---

1. Understand the feature or bug fix that was implemented, either from previous context or the changes on the current Git branch. Understand if the changes break backward compatibility. Ask for more context if needed.
2. Ensure you are in the correct domain's service folder (usually `domains/<domain>/service`). Run all commands from there.
3. Ensure there is no uncommitted code in the service you are working on. Uncommitted code outside the service does not matter. Otherwise, stop and ask for the uncommitted code to be committed first.
4. Bump the service version using `npm version <newversion>`, where `<newversion>` is one of:
   - `patch` for bug fixes and chores.
   - `minor` for new features without breaking changes.
   - `major` for new features with breaking changes, but only if the current version is `1.0.0` or higher. Otherwise, use `minor`.
5. Commit `package.json` and `package-lock.json` with a message like `🔖 Set version to X.Y.Z`.
6. Update the changelog in `CHANGELOG.md` by adding a new section `## vX.Y.Z`. List the changes made, grouped by either `Features`, `Fixes`, `Chores`, or `Breaking changes`. Use only a short sentence for each item, starting with a capital letter and ending with a period. Use present tense. Use existing entries as examples.
7. Commit `CHANGELOG.md` with a message like `📝 Update changelog`.
8. Bump the service's `project.activeVersion` in `causa.yaml` to the new version as `release-X.Y.Z`, where `X.Y.Z` matches the bumped version in `package.json`.
9. Commit `causa.yaml` with a message like `🚀 Deploy <service>-service X.Y.Z`, where the service matches the project name in `causa.yaml` and the version is the newly bumped version.
