# Causa skills

Engineering skills to design, implement, document, and release features built on the [Causa](https://github.com/causa-io) framework.

## Skills

Delivery runs in **two stages**, each ending in a single gate where the human sees complete, already-reviewed work: design, then implementation. `build-feature` orchestrates both, loading the reference skills as it identifies what a feature needs.

| Skill | Kind | Purpose |
| --- | --- | --- |
| `build-feature` | orchestrator | Clarify the requirements, design the contracts, run the reviews, and drive the implementation. |
| `design-model` | reference | Entity and event schemas, and the topics the domain emits. |
| `design-api-http` | reference | HTTP APIs (OpenAPI), DTOs, and the endpoints the service exposes. |
| `design-api-firestore` | reference | Firestore collections, security rules, and the collections the service writes. |
| `design-state` | reference | Access patterns, Spanner schemas and indexes, and the databases the service writes. |
| `design-triggers` | reference | The events a service consumes, the tasks it enqueues, and the crons it runs. |
| `plan-tests` | reference | The behaviors a feature must have covered, derived from its contracts. |
| `plan-implementation` | reference | Services and controllers, as abstract classes. |
| `implement` | action | Write the code and tests, and record what departed from the plan. |
| `review-design` | review | Adversarially review the design before any code is written. |
| `review-implementation` | review | Adversarially review the code, tests, and documentation. |
| `document` | action | Document the implemented feature. |
| `design-scenario` | reference | End-to-end test scenarios, for large or cross-domain features. |
| `design-timeline` | reference | Visualize events from several sources (service logs, event topics) on one time axis. |
| `improve-skills` | action | Write up the skill changes the kept feedback calls for, as a proposal applied elsewhere. |
| `bump-version` | action | Bump the service version and update the changelog. |

The **reference** skills are knowledge, not workflow: they carry the conventions for one kind of artifact and are loaded on demand, by `build-feature` or directly. They hold no confirmation gates — the gates belong to whoever is talking to the human.

The **review** skills always run in a context that does not hold the author's rationale, receiving paths only. A subagent is the preferred mechanism where one exists; a fresh session given the same paths works too. A reviewer that inherits the author's context defends the work instead of challenging it.

The skills assume a Causa monorepo laid out under `domains/<domain>/` (entities, events, api, firestore, spanner, tasks, service, doc). Work in progress is written to `domains/<domain>/work/<feature-slug>/`.

## Usage

### Claude Code

Add the marketplace and install the plugin:

```
/plugin marketplace add causa-io/agent-plugin
/plugin install causa@causa
```

Then invoke a skill, e.g. `/build-feature`, or just describe the task and let Claude pick the relevant skill.

To enable the plugin for everyone working in a project, commit this to the project's `.claude/settings.json`:

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
    "causa@causa": true
  }
}
```

Claude Code installs and enables the plugin automatically when the project is opened.

After the skills change upstream, refresh with `/plugin marketplace update causa`.

### Other agents

Codex, Cursor, and opencode all read skills from `~/.agents/skills`, and from `.agents/skills` within a project, so installing once covers them. Symlinked skill folders are followed:

```bash
git clone https://github.com/causa-io/agent-plugin.git ~/src/causa-agent-plugin
mkdir -p ~/.agents/skills
ln -s ~/src/causa-agent-plugin/skills/* ~/.agents/skills/
```
