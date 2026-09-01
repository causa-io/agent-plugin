---
name: design-triggers
description: Reference for designing a service's inbound work — the events it consumes, the tasks it enqueues, and the crons it runs — declared as triggers in `causa.yaml`. Use when a service needs to react to an event from any domain, run scheduled work, or process a queued task, and load it before adding or changing a trigger. Covers trigger types, event name filters, handler naming, and task payload schemas.
---

Everything a service does that is not an HTTP request from a client arrives through a **trigger**: an event published on a topic, a task pulled from a queue, or a schedule firing. Triggers are declared in `serviceContainer.triggers` in `domains/<domain>/service/causa.yaml`, and each one is bound to a handler method by name.

This reference covers the consumer side of events, plus tasks and crons. It is independent of `design-model`, which covers the events a domain *emits*:

- A topic designed by `design-model` needs no consumer. Events are published for consumers that may live in another domain, in an external system, or that do not exist yet. Do not add a trigger to give a new topic a consumer it does not need.
- A trigger often consumes a topic **from another domain**, which involves no contract change at all. `design-model` is not needed in that case.

<instructions>

To design or update triggers:

1. Read `serviceContainer.triggers` in the domain's `causa.yaml`, and the existing handler controllers in `domains/<domain>/service/src`. They are the ground truth for naming and grouping conventions.
2. Identify the inbound work the feature needs:
   - Which events must the service react to, and from which domains? Read those event schemas to know the payload and the available event names.
   - Is there work that must be deferred, retried independently, or fanned out? That is a task.
   - Is there work that must run on a schedule — expiry, reconciliation, cleanup? That is a cron.
3. For each trigger, decide whether the handler needs only a subset of a topic's event names, and write the corresponding filter.
4. For each task trigger, design its payload as a JSONSchema in `domains/<domain>/tasks/<name>.yaml`, following the global JSONSchema guidelines in the `design-model` reference. Cron triggers usually have no payload; event triggers are typed from the topic's event schema.
5. Write the triggers into `causa.yaml`, following the guidelines below.
6. Note, for each trigger, what the handler will look up when it fires. Those are access patterns, and they belong in the access patterns table covered by `design-state`. Handler and cron lookups are the ones most often missed there, because they are invisible from the API contracts.

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
6. Every trigger declares an `endpoint` whose path is unique within the service.
7. No trigger was added merely to give a newly designed topic a consumer.
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
    handleUser:
      type: event
      topic: identity.user.v1
      endpoint:
        type: http
        path: /identity/handleUser

    # Only a subset of the topic's event names is relevant.
    handleAssetFileDeletionRequest:
      type: event
      topic: content.asset.v1
      endpoint:
        type: http
        path: /assets/handleAssetFileDeletionRequest
      google.pubSub:
        filter: attributes.eventName = "assetDeleted"

    # Deferred work, with a typed payload.
    handleAssetFileDeletion:
      type: task
      queue: content-asset-file-deletion
      dto: ../tasks/delete-asset-file.yaml
      endpoint:
        type: http
        path: /assets/handleAssetFileDeletion

    # Scheduled sweep.
    handleStaleAssetCleanup:
      type: cron
      schedule: every 2 hours
      endpoint:
        type: http
        path: /assets/handleStaleAssetCleanup
```

</example>

## Fields

- `type`: one of `event`, `task`, `cron`.
- `topic`: for `event` triggers, the event topic in the format `<domain>.<event>.<version>`, e.g. `identity.user.v1`.
- `queue`: for `task` triggers, the Cloud Tasks queue name. Name it `<domain>-<work>`, e.g. `content-asset-file-deletion`.
- `schedule`: for `cron` triggers, the schedule, e.g. `every 24 hours`.
- `dto`: for non-`event` triggers with a typed payload, a path relative to the service project to the JSONSchema describing the payload, e.g. `../tasks/delete-asset-file.yaml`.
- `endpoint`:
  - `type: http`
  - `path`: the HTTP path the handler is exposed on. Group by the entity or feature the handler serves, e.g. `/assets/handleStaleAssetCleanup`, or by the source domain for projections, e.g. `/identity/handleUser`.

## Handler naming

The trigger key **is** the handler method name, and the two must match exactly: the controller is decorated with a generated `As<Group>EventsController()` decorator whose contract is derived from the triggers, so a mismatch fails to compile.

- Prefix every handler with `handle`, e.g. `handleUser`, `handleStaleAssetCleanup`.
- When two triggers consume the same topic for different purposes, suffix each with its purpose rather than disambiguating with a number, e.g. `handlePostForSearch` and `handlePostForFeed`.

## Event name filters

A topic carries every event name defined in its schema's name enum. A handler that only cares about some of them declares a Pub/Sub filter, which is matched on the message attributes before delivery:

```yaml
google.pubSub:
  filter: attributes.eventName = "assetDeleted"
```

- Equality and inequality are both available, e.g. `attributes.eventName != "companyMemberInviteDeleted"`.
- Filtering is an optimization, not an obligation. A handler that switches on the event name in code is equally valid, and is often clearer when it handles most of the names.
- Filter when the handler would otherwise be woken by events it immediately discards, especially on high-volume topics.
- Every name in a filter must exist in the topic's event name enum. A filter matching a name that no longer exists silently stops delivering.

## Choosing a trigger type

- **Event** — the work is a reaction to something that happened, and the reaction may lag behind it. Projections, cascades, and cross-domain propagation are all events.
- **Task** — the work belongs to a request or a handler that should not wait for it, needs its own retry behavior, or fans out over many items. A task has an explicit payload, so it also carries the parameters the work needs.
- **Cron** — the work is driven by time rather than by anything that happened: expiry, reconciliation, cleanup of rows nothing else will delete.

Work that is triggered by an event but must not block its handler is usually both: the handler consumes the event and enqueues a task.
