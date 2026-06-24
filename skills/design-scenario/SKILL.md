---
name: design-scenario
description: Design end-to-end test scenarios for a feature or bug fix, then write them as scenario YAML files run against a development environment. Use for large or cross-domain features where a realistic, multi-step end-to-end test adds value. Designs the scenarios conversationally, then writes one YAML file per scenario.
---

You are a software engineer who designs and authors end-to-end test scenarios for the backend. A scenario is a YAML file that probes a real (development) environment: it calls HTTP APIs, queries databases, generates tokens, and inspects published events and service logs, then asserts on the results.

This skill has two parts:

1. **Design** the scenario(s) — decide whether the feature or bug fix warrants a scenario, then design the realistic client flow(s) and the ordered steps and assertions, confirming with the user.
2. **Write** each scenario as a valid, idiomatic YAML file, one at a time.

<objective>

- It is clear whether the feature or bug fix warrants one or more scenarios, and the user has confirmed.
- Each warranted scenario is designed as a realistic, multi-step client flow with assertions, and confirmed with the user.
- Each designed scenario is written as a YAML file that validates against the scenario JSONSchema and runs reliably against an eventually-consistent environment.

</objective>

<instructions>

# Part 1 — Design the scenario(s)

## 1. Decide whether a scenario is warranted

Scenarios are end-to-end tests that exercise the deployed system across realistic interactions. They are **not** a substitute for the unit/contract tests planned by `plan-tests`. Reserve them for cases where an end-to-end test adds real value:

- A **useful scenario spans several domains**, or at least several features of a single domain. A scenario that exercises one endpoint in isolation is better covered by a contract test.
- Scenarios should be **close to realistic interactions** that clients (e.g. the frontend) have with the backend — a sequence of calls a real user flow would produce, not an arbitrary probe.
- **Not every feature or bug fix needs a scenario.** They are usually reserved for large features. If you are uncertain whether the current work warrants one, **ask the user for confirmation** before designing.

If no scenario is warranted, say so and stop.

## 2. Gather context

- Read the work directory for the feature or bug fix (`domains/<domain>/work/<feature-slug>/`): `requirements.md` and any design/plan outputs (`model-design.md`, `api-http-design.md`, `state-design.md`, `implementation-plan.md`, `test-plan.md`).
- Read the relevant contracts in the affected `domains/<domain>/` (entities, events, API specs, Firestore/Spanner schemas) to know exact endpoints, field names, topic names, and table/collection names.
- Look at existing scenarios for established style (see `<output>` for where they live).

## 3. Design the flow(s)

Identify the realistic client flow(s) the feature enables. A large, cross-domain feature may justify **more than one scenario**, each covering a distinct flow. For each scenario, design:

- The **entry point(s)**: how the client authenticates and what it calls first.
- The **ordered steps**: each client action (HTTP call) and each backend effect to assert — primarily state changes and published events, including the cross-domain propagation that makes the scenario worthwhile. Probe **service logs only when crucial information or errors are expected to be logged** (e.g. asserting a specific failure was reported). Do not add steps that check generic request logs — those carry no signal worth a scenario step.
- Which steps observe **asynchronous** results (events, logs, projections built from events) and therefore need retries.

## 4. Confirm with the user

Present the designed scenario(s) conversationally: the flow, the ordered steps, and the key assertions. Do **not** write a separate design document. Confirm the design (and, for multiple scenarios, the set and their priority) before moving to Part 2.

# Part 2 — Write each scenario

Write one YAML file per confirmed scenario, **one at a time**. For each scenario, follow the steps below, then move to the next.

1. Work top-down: `id`/`description`, declare `inputs`, set `defaultCallArgs` for shared HTTP config (base URL, auth header), then write each step.

2. For every step decide:
   - Which call function and its `args` (see `# Reference`).
   - Whether it needs `expectations`.
   - Whether it needs `retry` (any step that observes an asynchronously-produced result: events, logs, projections).
   - Whether it needs an explicit `after` (it must run after another step but does not reference that step's `output`).

3. Re-read the file and run it through the `<validation>` checklist. Do not run the scenario yourself unless asked.

</instructions>

<output>

Write one YAML file per scenario, named after the scenario (e.g. `<slug>.yaml`). Determine the directory scenarios live in from the Causa configuration (the `scenario.globs` in `causa.yaml`); fall back to the project documentation (e.g. `CLAUDE.md`), and if it is still unclear, ask the user. Do not assume a path.

Start each file with the schema reference comment so editors validate it:

```yaml
# yaml-language-server: $schema=<path-to>/.causa/node_modules/@causa/workspace-core/dist/scenarios/schemas/scenario.yaml
```

The `$schema` value is a path relative to the scenario file — adjust the number of leading `../` segments to the file's depth.

</output>

<validation>

1. The decision to write (or not write) a scenario is justified — it spans multiple domains or features and mirrors a realistic client flow — and was confirmed with the user.
2. The file has a top-level `id` and `steps`; every step has a `call` with a `name`.
3. Every `${ ... }` expression uses only available helpers: `input`, `output`, `configuration`, `str`, `rand`, and json-e builtins (`now`, `len`, …).
4. Every `output('<id>')` and `after: [<id>]` references an existing step. No step references its own output in its `args`.
5. Each call function's `args` match its signature (see `# Reference`).
6. Steps observing asynchronous results (events, logs, projections) have a `retry` policy.
7. Expectations use `toMatchObject` (subset) semantics by default; `exact: true` is only set where a full deep-equality match is intended.

</validation>

# Reference

## Example scenario

See [`example.yaml`](./example.yaml) in this skill directory for a complete, annotated example: a user updates their profile via the HTTP API, then the scenario asserts the change landed in Spanner, was logged by the service, and was published as an event. It illustrates authentication, threading a value forward, and retrying on asynchronously-produced results. Read it before writing a new scenario.

See [`example-reusable.yaml`](./example-reusable.yaml) for the `ScenarioRun`, cleanup, and `rand('uuid')` patterns.

## How a scenario runs

Steps run in **dependency order**, and independent steps run **in parallel**. Dependencies are inferred automatically from `output('<id>')` references inside a step's `args` and `expectations`, plus any explicit `after` IDs. A step's `output` is whatever its call function returns; it becomes available to later steps only after the step succeeds (call returned **and** all expectations passed). If a step fails, dependents are skipped.

## Top-level fields

| Field | Required | Purpose |
| --- | --- | --- |
| `id` | yes | Unique scenario identifier. |
| `description` | no | Human-readable summary. |
| `inputs` | no | Declared inputs, keyed by name. Each has `type: string` (only type supported), optional `description`, optional `default`. An input without a default must be supplied at run time. Reference as `${ input('name') }`. |
| `defaultCallArgs` | no | Default `args` per call function name, **shallow-merged** under each step's own `args` for that function. Use it for shared HTTP `baseUrl`/`headers`. The merge is per top-level key, so a step that sets its own `headers` **replaces** the default `headers` wholesale (not a deep merge). In a multi-actor scenario (two different bearer tokens), keep auth **out** of `defaultCallArgs` and set `Authorization` per step. |
| `steps` | yes | Map of step ID → step. |

## Step fields

| Field | Required | Purpose |
| --- | --- | --- |
| `name` / `description` | no | Human-readable labels. |
| `call` | yes | `{ name, args }` — the workspace function to invoke and its arguments. |
| `expectations` | no | List of assertions on the output (see below). |
| `retry` | no | `{ maxAttempts, delay }` — retries the whole step (call + expectations); `delay` is in ms. |
| `after` | no | List of step IDs that must complete first, when there is no `output` reference to create the dependency implicitly. Reserve it for genuine ordering with no data flow (create-after-cleanup, assert-before-mutate). Do not list a step you already reference via `output(...)`. |

## Template language

Expressions are [json-e](https://json-e.js.org/) `${ ... }`. Available context:

- `input('<name>')` — a declared input value.
- `output('<id>')` — the return value of another step (or the current step, inside its own `expectations`). Index arrays, e.g. `output('getUserState')[0].updatedAt`.
- `configuration('<path>')` — a workspace configuration value, e.g. `configuration('dns.api')`.
- `str(value)` — stringifies; a `Date` becomes an ISO string, otherwise `String(value)`. Use it when interpolating non-string values into queries/filters.
- `rand('uuid')` — a fresh random UUID (each evaluation differs). Also `rand('int', min, max)` and `rand('float', min, max)`. Use for client-generated IDs (post element IDs, interaction IDs) so the scenario stays re-runnable against a persistent environment.
- `now` — json-e built-in, the current timestamp as an ISO string.
- json-e builtins are available too — notably `len(x)` (length of an array/string/object), useful for asserting counts or guarding possibly-empty lookups.
- A bare `${ output('x') }` **throws** if the value is an array or object. To pass an array/object use the object form `{ $eval: "output('x')…" }` instead.
- Other json-e operators work anywhere a value is expected: `$if`/`then`/`else`, `$merge` (build an object with conditional/dynamic keys), `$let` + `$map`, `in` (membership). Note: json-e has no list-comprehension syntax, use `$map` (with `$let` to name the result) instead.

## Call functions

Probe-type workspace functions usable from a step `call`:

- **`HttpMakeRequest`** → `{ statusCode, headers, body }`.
  Args: `baseUrl` (scheme optional, defaults to `https://`), `method` (default `GET`), `path` (default `/`), `query` (object, URL-encoded), `headers` (object), `body` (object/array JSON-serialized, string sent as-is). Typically `baseUrl`/auth `headers` live in `defaultCallArgs`.
  For a **multipart upload**, set `headers.Content-Type: multipart/form-data` and make `body` an object of form fields: a string value becomes a text part, an object value becomes a file part sourced from a local `path` (resolved from the workspace root) or inline `value`, with optional `filename`/`contentType`.

- **`DatabaseQueryRecords`** → array of records.
  Args: `engine`, `database`, `query`.
  - `engine: google.spanner` — `database` is the DB name, `query` is SQL. Returns matching rows as plain objects keyed by column.
  - `engine: google.firestore` — `query` is a **single document path** (e.g. `users/<id>/bookmarks/<id>`), `database` optional. Returns a one-element array with the document data, or empty if missing.

- **`EventTopicQueryEvents`** → `QueriedEvent[]` (`{ timestamp, attributes, data }`).
  Args: `topic` (e.g. `domain.entity.v1`), `filter` (BigQuery `WHERE`-clause expression over `data`/`attributes`, e.g. `STRING(data.data.id)="..."`), optional `from`/`to`, `limit`. Almost always needs `retry`.

- **`ServiceContainerQueryLogs`** → `QueriedLogEntry[]` (`{ timestamp, message }`).
  Args: `service`, `filter` (Cloud Logging filter, e.g. `jsonPayload.req.method="PATCH"`), optional `from`/`to`, `limit`. Almost always needs `retry`. Use this **only** when crucial information or an error is expected in the logs — not to check generic request logs. The example scenario probes a request log purely for completeness; most scenarios should not.

- **`GoogleIdentityPlatformGenerateToken`** → ID token string.
  Args: `user` (user ID), optional `claims`, optional `refreshToken`. Use its output as a bearer token in HTTP `headers`.

- **`GoogleAppCheckGenerateToken`** → AppCheck token string.
  Args: optional `app` (Firebase app ID).

- **`ScenarioRun`** → runs another scenario as a sub-step. Args: `path` (the YAML path, **relative to the workspace root**, not the calling file) and `inputs` (object of input values). Returns a snapshot `{ status, steps: { <stepId>: { status, output, … } } }`. Read a sub-step's result via `output('<step>').steps.<subStep>.output`. Use it to factor reusable flows and call them from several scenarios. Note the `scenario.globs` typically do not match reusable scenarios, so utilities are not run as standalone scenarios.

## Expectations

Each entry asserts on a value; on the first failing entry the step fails.

| Field | Purpose |
| --- | --- |
| `value` | Expected value. May be templated. **Required.** |
| `actual` | Value to compare; defaults to the step's call output. May be templated, often `{ $eval: "..." }`. |
| `exact` | `false` (default) → `toMatchObject` (listed properties must match, extra properties allowed). `true` → `toEqual` (deep equality). A non-object `value` always uses equality regardless of `exact`. |
| `description` | Optional label included in failure messages. |

Inside a step's own expectations, `output('<thisStepId>')` refers to this step's output (available before it is published globally).

To assert **no rows / empty result**: `value: []` with `exact: true`, or `actual: { $eval: "len(output('x'))" }` with `value: 0`. To assert **membership / absence** of an item, build a list with `$map` and use `in` (e.g. `${ id } in [ids…]` → `value: false` to assert absence).

## Patterns

- **Mutate, then observe asynchronously.** A step that mutates (e.g. `HttpMakeRequest` PATCH) produces events/logs read by later steps. Give those observer steps a `retry` (e.g. `maxAttempts: 15`, `delay: 1000`) to tolerate propagation delay, and an `after: [<mutationStep>]` if they don't already reference its output.
- **Thread values forward.** Capture a value from one call (`output('patchUser').body.updatedAt`) and use it in a later filter or expectation to assert the same change propagated.
- **Auth once, reuse everywhere.** When a single actor drives the scenario, generate a token in one step and reference `${ output('<tokenStep>') }` from `defaultCallArgs.HttpMakeRequest.headers.Authorization`. With **multiple actors**, set `Authorization` per step instead (see the `defaultCallArgs` shallow-merge note).
- **Make scenarios re-runnable, but only clean up what would actually collide.** Scenarios run against a persistent environment, so a second run hits state the first left behind. Entities created with a **server-generated id** or a `rand('uuid')` client id don't collide across runs and need **no** cleanup — leftover rows are harmless. Add a cleanup step only when a run reuses a **fixed or derived** id that would return a conflict the second time: look the entity up and `DELETE` it without asserting the status code (a no-op when absent), guarding the `[0]` access with `$if: "len(output('lookup')) > 0"`.
- **Assert as much as is deterministic — and no more.** Make each observing step's expectation as complete as the data you already hold: assert every field you set or can derive from earlier `output(...)`, and cross-check derived data against its source (a projection or list item should equal the event/entity it was built from). Do **not** assert values you don't control (timestamps, non-deterministic content). Prefer a single `toMatchObject` expectation over many single-field ones.
- **Factor reusable flows into sub-scenarios.** Put shared sequences in utility scenarios and invoke them with `ScenarioRun`, reading results via `output('<step>').steps.<subStep>.output`. Keeps cross-cutting setup/cleanup out of every scenario. To allow more customization if needed, use `$if`/`$merge` templating in calls.

## Monitoring runs with a timeline

Once a scenario is written, a **timeline** can monitor its runs — visualizing the events and logs it produces across sources on one time axis. Use the `design-timeline` skill to write a timeline YAM file next to the scenario, querying the same event topics and service containers it exercises.
