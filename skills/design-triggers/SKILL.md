---
name: design-triggers
description: Reference for designing a service's inbound work — the events it consumes, the tasks it enqueues, and the crons it runs — declared as triggers in `causa.yaml`. Use when a service needs to react to an event from any domain, run scheduled work, or process a queued task, and load it before adding or changing a trigger. Covers trigger types, event name filters, handler naming, and task payload schemas.
license: ISC
compatibility: Requires a checked-out Causa monorepo, git, Node.js with npm, and the Causa CLI (cs).
---

Everything a service does that is not an HTTP request from a client arrives through a **trigger**: an event published on a topic, a task pulled from a queue, or a schedule firing. Triggers are declared in `serviceContainer.triggers` in `domains/<domain>/service/causa.yaml`, and each one is bound to a handler method by name.

This reference covers the consumer side of events, plus tasks and crons. It is independent of `design-model`, which covers the events a domain *emits*:

- A topic designed by `design-model` needs no consumer. Events are published for consumers that may live in another domain, in an external system, or that do not exist yet.
- A trigger often consumes a topic **from another domain**, which involves no contract change at all. `design-model` is not needed in that case.

**Bundled files.** `./` paths are in this skill's own directory, not the working directory.

<instructions>

To design or update triggers:

1. Read `serviceContainer.triggers` in the domain's `causa.yaml`, and the existing handler controllers in `domains/<domain>/service/src`. They are the ground truth for naming and grouping conventions.
2. Identify the inbound work the feature needs:
   - Which events must the service react to, and from which domains? Read those event schemas to know the payload and the available event names.
   - Is there work that must run later, at a time the caller chooses? That is a task.
   - Is there work that must run on a schedule — expiry, reconciliation, cleanup? That is a cron.
3. For each trigger, decide whether the handler needs only a subset of a topic's event names, and write the corresponding filter.
4. Learn the global JSONSchema guidelines in `./jsonschema-guidelines.md`.
5. For each task trigger, design its payload as a JSONSchema in `domains/<domain>/tasks/<name>.yaml`, following those guidelines. Cron triggers usually have no payload; event triggers are typed from the topic's event schema.
6. Write the triggers into `causa.yaml`, following the guidelines below.
7. Note, for each trigger, what the handler will look up when it fires. Those are access patterns, and they belong in the access patterns table covered by `design-state`. Handler and cron lookups are the ones most often missed there, because they are invisible from the API contracts.

</instructions>

<output>

- Triggers in `serviceContainer.triggers`, in `domains/<domain>/service/causa.yaml`.
- Task payload schemas in `domains/<domain>/tasks/<name>.yaml`.

</output>

<validation>

1. Every trigger key is the handler method name, prefixed with `handle`, and matches the method it will be bound to exactly.
2. Every `event` trigger references an existing topic, in the format `<domain>.<event>.<version>`.
3. Every event name referenced in a `google.pubSub.filter` exists in the topic's event name enum.
4. Every `task` trigger declares a `queue` and, when its payload is typed, a `dto` pointing at an existing JSONSchema file.
5. Every `cron` trigger declares a `schedule`.
6. Every trigger declares an `endpoint` whose path is unique within the service, grouped under this domain's entity or under the source domain.
7. Every trigger has a `description` stating what it does.
8. Every lookup a handler performs is listed as an access pattern in the state design.
9. Code generation succeeds:

- Run `cs model genCode` in the `service` folder of the corresponding domain to ensure the triggers and task schemas are valid.
- Run `npm run typecheck` to ensure there are no TypeScript type errors. Focus on the generated code only.

</validation>

# Triggers

Triggers are declared as a map under `serviceContainer.triggers`. The key is the handler method name; the value describes what fires it and where it is exposed.

<example>

```yaml
serviceContainer:
  triggers:
    # Projection from another domain. No contract is created here.
    handleOtherEntity:
      type: event
      description: Maintains the local projection of `OtherEntity`.
      topic: other-domain.other-entity.v1
      endpoint:
        type: http
        path: /otherDomain/handleOtherEntity

    # Only a subset of the topic's event names is relevant.
    handleMyEntityForCleanup:
      type: event
      description: Schedules the cleanup of a deleted `MyEntity`'s external resources.
      topic: my-domain.my-entity.v1
      endpoint:
        type: http
        path: /myEntities/handleMyEntityForCleanup
      google.pubSub:
        filter: attributes.eventName = "myEntityDeleted"

    # Deferred work, with a typed payload.
    handleMyEntityCleanup:
      type: task
      description: Deletes a `MyEntity`'s external resources, once its retention delay has elapsed.
      queue: my-domain-my-entity-cleanup
      dto: ../tasks/my-entity-cleanup.yaml
      endpoint:
        type: http
        path: /myEntities/handleMyEntityCleanup

    # Scheduled sweep.
    handleStaleMyEntityCleanup:
      type: cron
      description: Removes `MyEntity` rows left in a non-terminal state for too long.
      schedule: every 2 hours
      endpoint:
        type: http
        path: /myEntities/handleStaleMyEntityCleanup
```

</example>

## Fields

- `type`: one of `event`, `task`, `cron`.
- `description`: what the trigger does, in one sentence ending with a period. It is the only place the *purpose* of a trigger is recorded — the key names the handler, and the topic names the cause, but neither says why the service reacts.
- `topic`: for `event` triggers, the event topic in the format `<domain>.<event>.<version>`, e.g. `other-domain.other-entity.v1`.
- `queue`: for `task` triggers, the Cloud Tasks queue name. Name it `<domain>-<work>`, e.g. `my-domain-my-entity-cleanup`.
- `schedule`: for `cron` triggers, the schedule, e.g. `every 24 hours`.
- `dto`: for non-`event` triggers with a typed payload, a path relative to the service project to the JSONSchema describing the payload, e.g. `../tasks/my-entity-cleanup.yaml`.
- `endpoint`:
  - `type: http`
  - `path`: the HTTP path the handler is exposed on, grouped by a first segment:
    - **A trigger on this domain's own entity** is grouped under that entity, matching its API path where one exists, e.g. `/myEntities/handleMyEntityCleanup`.
    - **A trigger on another domain's event** is grouped under the source domain, e.g. `/otherDomain/handleOtherEntity`, regardless of which local entity it updates.

## Handler naming

The trigger key **is** the handler method name, and the two must match exactly: the controller is decorated with a generated `As<Group>EventsController()` decorator whose contract is derived from the triggers, so a mismatch fails to compile.

- Prefix every handler with `handle`, e.g. `handleUser`, `handleStaleAssetCleanup`.
- When two triggers consume the same topic for different purposes, suffix each with its purpose rather than disambiguating with a number, e.g. `handleMyEntityForSearch` and `handleMyEntityForCleanup`.

## Event name filters

A topic carries every event name defined in its schema's name enum. A handler that only cares about some of them declares a Pub/Sub filter, which is matched on the message attributes before delivery:

```yaml
google.pubSub:
  filter: attributes.eventName = "myEntityDeleted"
```

**A filter is an optimization, never the logic.** The handler still implements the exact condition itself, checking the event name and whatever else it needs before acting. The two are not alternatives: the code decides, and the filter merely spares the service from being woken for events it would have discarded.

Never let the filter carry a condition the handler then assumes. A handler that acts unconditionally because "the filter guarantees it" breaks silently the moment the filter is edited, the subscription is recreated without it, or the event is replayed through another path.

- Equality and inequality are both available, e.g. `attributes.eventName != "myEntityDeleted"`.
- Add a filter when the handler would otherwise be woken by events it immediately discards, especially on a high-volume topic. Omit it when the handler acts on most of the topic's names, where it buys nothing.
- Every name in a filter must exist in the topic's event name enum. A filter matching a name that no longer exists silently stops delivering.

## Choosing a trigger type

- **Event** — the work is a reaction to something that happened, and the reaction may lag behind it. Projections, cascades, and cross-domain propagation are all events. Note that a handler **synchronizing state** can correctly drop a superseded event, whereas one **reacting to a transition** (e.g. by event name) cannot: nothing will re-deliver it. A staleness guard suiting the first silently loses the second.
- **Task** — the work must run **later, at a time the caller chooses**, and with parameters the caller computes. Deleting an entity's external file 24 hours after the entity is soft-deleted is a task; so is re-indexing an account's records after a grace period, once the denormalized values have settled.
- **Cron** — the work is driven by time rather than by anything that happened: expiry, reconciliation, cleanup of rows nothing else will delete.

Work that is triggered by an event but must be delayed is usually both: the handler consumes the event and schedules a task.
