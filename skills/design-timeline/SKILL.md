---
name: design-timeline
description: Design timelines that visualize events from several sources (service logs and event topics) correlated on one time axis. Use when the user wants to monitor a scenario's runs or observe/debug an environment (including production). Designs the sources conversationally, then writes a timeline YAML file.
---

You are a software engineer who designs **timelines**: observability views that query several sources — service logs and event topics — over a shared time window and render them as time-ordered lanes, so related records from different systems can be read together. A timeline is a YAML file listing the sources to query and how each is filtered, colored, and displayed. The environment and time window are chosen at view time, so the **file itself is environment-agnostic**.

This skill has two parts:

1. **Design** the timeline — identify the use case, the sources to query, and how to filter/display each, then confirm with the user.
2. **Write** the timeline as a valid, idiomatic YAML file.

There are two common use cases, which differ in how sources are chosen and parameterized:

- **Monitor a scenario's runs.** A companion to a `design-scenario` scenario, querying the same topics and services the scenario exercises (typically against a development/QA environment). Usually **static** (no inputs).
- **Observe or debug an environment** (including production). Sources cover a subsystem of interest, usually **parameterized** with an input (e.g. an entity or user id) so the view can be scoped to one subject.

<objective>

- The use case is clear, and the set of sources to query has been confirmed with the user.
- Each source has an accurate filter and display (title, body, color) built from the real record shape.
- The timeline is written as a valid YAML file that loads in the Causa Studio.

</objective>

<instructions>

# Part 1 — Design the timeline

## 1. Determine the use case

Decide whether this is a **scenario-monitoring** timeline or an **environment-observability** timeline. If it is not clear from the request, ask.

## 2. Gather context

- **For a scenario-monitoring timeline:** read the corresponding scenario (the `design-scenario` skill and the scenario YAML file). Identify every source the scenario exercises — each **event topic** it queries (`EventTopicQueryEvents` `topic`) or asserts, and each **service container** behind its HTTP calls and log queries (`ServiceContainerQueryLogs` `service`). These become the timeline's sources.
- **For an environment-observability timeline:** identify the subsystem to observe — which event topics and service containers matter — and the dimension to filter on (an entity/user id), which becomes an input.
- **For both:** read the relevant **event schemas** (designed by `design-model`, in `domains/<domain>/events/`) to know the exact `data` shape, and confirm the **service log structure** so the display templates reference real fields. Look at existing timelines for established style.
- Find where timelines live (see `<output>`).

## 3. Design the sources

For each source decide: `type` (`serviceLogs` or `eventTopic`), `target` (container id or topic id), `filter`, `color`, `title`, and `body`. Lean on the conventions in `# Reference`:

- **Title** and **color** are the fields you shape most: a short, scannable one-line title; a color templated to the field you want to correlate across lanes (or in some cases a fixed color per source).
- **Body** is usually the whole event (`{ $eval: data }`); declutter only when a payload is noisy (e.g. service logs).
- Add **inputs** only for observe/debug timelines (filterable dimensions); keep scenario-monitoring timelines static unless the user asks otherwise.

Present the designed sources conversationally — the use case, the source set, and the key filters/titles. Do **not** write a separate design document. **You must confirm the design with the user before writing** (ask at least one clarifying question), even when the use case seems obvious.

# Part 2 — Write the timeline

Work top-down: `name`/`description`, declare `inputs` (debug only), then each source. Always write a `description` (Markdown): a one-line summary of the flow, a short list of the sources (each with its title emoji), and a closing line stating what the color scheme encodes. It lets a reader grasp the view at a glance.

For every source, before writing the display templates, ground them in the real record shape (event schema for events; the service's log structure for logs). Then write `filter`, `color`, `title`, `body` per the conventions.

Re-read the file and run it through the `<validation>` checklist.

</instructions>

<output>

Write one YAML file per timeline. Determine the directory timelines live in from the Causa configuration (the `timeline.globs` in `causa.yaml`); fall back to the project documentation (e.g. `CLAUDE.md`), and if it is still unclear, ask the user. Do not assume a path.

- **Scenario-monitoring timeline:** co-locate it next to the scenario file, while reusing existing naming conventions and allowed globs.
- **Environment-observability timeline:** name it after what it observes.

</output>

<validation>

1. The file is valid YAML with a top-level `name` and `sources`; every source has `id`, `type`, `target`, `title`, and `body`.
2. Each `type` is `serviceLogs` or `eventTopic`, and `target` is the matching service container id or event topic id.
3. Every `filter` references only `input('<name>')` (never record fields — filters render before the query), and each referenced input is declared. `serviceLogs` filters use Cloud Logging syntax; `eventTopic` filters use a BigQuery `WHERE` expression.
4. Every `title`, `body`, and `color` references only record fields (`serviceLogs` → `message`; `eventTopic` → `attributes`/`data`) — never `input()`.
5. Topic ids, service ids, and field paths match the actual contracts and environment (cross-checked against event schemas and log structure).
6. For a scenario-monitoring timeline: the sources cover the topics and services the scenario exercises, the file is co-located with and named after the scenario, and it declares no inputs unless the user asked for them.
7. json-e is well-formed: bare `${ ... }` only interpolates scalars; arrays/objects use the object form `{ $eval: ... }` (e.g. a whole-event body).

</validation>

# Reference

## Example timeline

See [`example.timeline.yaml`](./example.timeline.yaml) in this skill directory for a complete, annotated example: a debug timeline that follows one order across two `serviceLogs` sources and one `eventTopic` source, illustrating the two template contexts, optional input-scoped filters, the three color conventions (status range, fixed per source, event name), emoji titles, and both body styles (whole event vs. decluttered log). Read it before writing a new timeline.

## How a timeline renders

Every source is queried over a shared `[from, to)` window against a chosen environment; both the window and the environment are selected in the UI, not in the file. Returned records are projected (title/body/color templates evaluated per record) and laid out as time-ordered lanes, each lane tinted by its source's color.

## Top-level fields

| Field | Required | Purpose |
| --- | --- | --- |
| `name` | yes | Display name of the timeline. |
| `description` | no | Markdown description — recommended. Summarize the flow, list the sources, and state what the color scheme encodes. |
| `inputs` | no | Declared inputs, keyed by name. Each has `type: string` (only type supported), optional `description`, optional `default`. Referenced as `${ input('<name>') }` **in filters only**. |
| `sources` | yes | The list of sources to display. |

## Source fields

| Field | Required | Purpose |
| --- | --- | --- |
| `id` | yes | Unique id for the source (keys its lane and results). |
| `type` | yes | `serviceLogs` or `eventTopic`. |
| `target` | yes | What the backing query hits: the service container id (`serviceLogs`) or the event topic id (`eventTopic`). An empty target is acceptable for service logs, when all services should be queried or when the filter is responsible for service selection. |
| `name` | no | Human-readable lane label. |
| `filter` | no | json-e template (string or object) rendered against the **inputs** to a filter string. Empty/blank result → no filter. |
| `color` | no | `#rrggbb` used verbatim, or a json-e template rendered per record; a non-hex result is hashed to a stable color (equal values share a hue). |
| `title` | yes | json-e template rendered per record to the one-line entry title. |
| `body` | yes | json-e template rendered per record to the entry body. An empty template shows the full raw record. |

## Template language and contexts

Templates are [json-e](https://json-e.js.org/) (`${ ... }` interpolation plus operators like `$if`/`then`/`else`, `$let`, `$map` with `each(v, k)`, `in`, and builtins such as `split`, `join`, `len`). There are **two distinct evaluation contexts**:

- **`filter`** renders once, before the query, against an `input()` helper only: `${ input('<name>') }` returns the input's value (or `''` when unset). It has **no access to records**. The result is coerced to a string; an empty/blank result or an evaluation error means "no filter".
- **`color` / `title` / `body`** render per record, against the **raw record itself** (no `input()`):
  - `serviceLogs` record: `{ timestamp, message }`. `message` is the log payload; structured services nest the application object under `message.message` (e.g. `message.message.res.statusCode`, `message.message.actor.id`) — confirm against a real record.
  - `eventTopic` record: `{ timestamp, attributes, data }`. `attributes` holds message attributes (e.g. `attributes.eventName`); `data` is the event envelope (`id`, `producedAt`, `name`, `data`), so the event name is `data.name` and the entity payload is `data.data`.

A bare `${ data }` (or any expression yielding an array/object) **throws**. To emit an object/array — e.g. the whole event as a body — use the object form `{ $eval: "data" }`.

## Filter syntax per source type

The backing queries are the same workspace functions used by scenarios, so the filter syntax matches:

- `serviceLogs` → a **Cloud Logging** filter, e.g. `jsonPayload.message="request completed"` (mirrors the scenario `ServiceContainerQueryLogs` `filter`).
- `eventTopic` → a **BigQuery `WHERE`** expression over `data`/`attributes`, e.g. `STRING(data.data.id)="..."` (mirrors the scenario `EventTopicQueryEvents` `filter`).

## Conventions

- **Title — shape it most.** One line, scannable, leading with an emoji that identifies the source; lead with the most salient facts (status/method/path for a request; event name and subject for an event). Use `$let` to name sub-expressions and `$if` for optional fields. Drop anything the timeline already conveys — no actor id in the title when the timeline filters on a single id, or when color already encodes the actor.
- **Color — group by a dimension orthogonal to the filter.** Color only helps when it varies across the records shown, so pick a dimension the filter does *not* already pin down: coloring by an id the timeline filters on tints every record the same, which is useless. A non-hex result is hashed to a stable hue (equal values share it); a `#rrggbb` result is used verbatim. Examples:
  - Multi-actor scenario → color by actor.
  - Single-actor scenario → a fixed color per source, or per entity type (a same entity's HTTP requests and events share a color).
  - Debug timeline with many sources → a fixed color per source.
  - Debug timeline focused on HTTP requests → color by status-code range (`2xx`, `4xx`).
  - Debug timeline focused on a state machine → color by event name or entity state.

  Keep the scheme **consistent across the whole timeline**: pick one dimension (or one rule) for every source. A timeline where one source uses a static color, another hashes an actor id, and another hashes an entity state is unreadable — the colors no longer mean one thing. When sources share a dimension (a common actor or entity id), color them all by it so the same value gets the same hue across lanes; otherwise prefer a fixed color per source.
- **Body — show the whole event, declutter logs.** For events, `body: { $eval: "data" }` (the full event is compact and self-describing). For logs, `$map` the payload and drop noisy framework keys. Leave `body` empty to fall back to the full raw record.
- **Mirror the scenario.** For a scenario-monitoring timeline, add one `eventTopic` source per topic the scenario asserts and one `serviceLogs` source per service container it hits, reusing the scenario's field paths and filters.
- **Parameterize for debugging.** For an observe/debug timeline, declare one input per filterable dimension and make each filter optional with `$if: input('x') == ''` (empty → match everything), so the same timeline serves both a focused and a broad view.
- **Ground templates in the contract.** The `data`/`attributes` shape comes from the event schema (`design-model`); the log structure from the service. Read them — or inspect a real record — before writing the display templates.
