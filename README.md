# Causa skills

A Claude Code plugin providing engineering skills to design, implement, document, and release features built on the [Causa](https://github.com/causa-io) framework.

## Skills

| Skill | Purpose |
| --- | --- |
| `build-feature` | Orchestrate end-to-end delivery, invoking the skills below in order. |
| `design-model` | Design entity and event schemas. |
| `design-api-http` | Design HTTP APIs (OpenAPI) and DTOs. |
| `design-api-firestore` | Design Firestore collections and security rules. |
| `design-state` | Design Spanner schemas, indexes, and state objects. |
| `plan-implementation` | Plan services and controllers. |
| `plan-tests` | Plan contract and unit tests. |
| `implement` | Write the code and tests from the plans. |
| `design-scenario` | Author end-to-end test scenarios. |
| `document` | Document the implemented feature. |
| `bump-version` | Bump the service version and update the changelog. |

The skills assume a Causa monorepo laid out under `domains/<domain>/` (entities, events, api, firestore, spanner, service, doc). Design skills write their artifacts to `domains/<domain>/work/<feature-slug>/`.

## Usage

### CLI

Add the marketplace and install the plugin from within Claude Code:

```
/plugin marketplace add causa-io/agent-plugin
/plugin install skills@causa
```

Then invoke a skill, e.g. `/build-feature`, or just describe the task and let Claude pick the relevant skill.

### Project `.claude/settings.json`

To enable the plugin for everyone working in a project, commit it to the project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "causa": {
      "source": {
        "source": "github",
        "repo": "causa-io/agent-plugin"
      }
    }
  },
  "enabledPlugins": {
    "skills@causa": true
  }
}
```

Claude Code installs and enables the plugin automatically when the project is opened.

### Updating

After the skills change upstream, refresh it to pull the latest:

```
/plugin marketplace update causa
```
