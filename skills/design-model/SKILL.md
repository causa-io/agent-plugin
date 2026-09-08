---
name: design-model
description: Reference for designing entity and event schemas. Use when designing, creating, or updating entities, events, or data models for a business domain, and load it before writing any entity or event contract. Covers JSONSchema conventions, state machines, constraints, and the emitted topics declared in `causa.yaml`.
---

Entities and events are the contracts a business domain publishes:

- Entities, managed and exposed by domains through HTTP APIs.
- Events, emitted by domains, either when entities change or for other business reasons.

This reference covers those two contracts and the `outputs.eventTopics` declaration that goes with them. HTTP API contracts are covered by `design-api-http`. Consuming an event — a trigger on a topic, whether it belongs to this domain or another — is covered by `design-triggers`, and is independent of this reference: a topic designed here needs no consumer.

<instructions>

To design or update entity and event contracts:

1. Read existing contracts in the relevant domain, and in other domains if necessary. They are the ground truth for conventions.
2. Identify the entities and events that need to be created or updated. Determine whether they have a state machine, what its states and transitions are, and which changes are triggered by other events or by user commands.
3. Learn the global JSONSchema guidelines in `${CLAUDE_SKILL_DIR}/jsonschema-guidelines.md`.
4. Read the example entity and event schemas in `${CLAUDE_SKILL_DIR}/entity-example.yaml` and `${CLAUDE_SKILL_DIR}/event-example.yaml`.
5. Write or update the contracts, following the guidelines below, the global JSONSchema guidelines, the examples, and existing contracts as reference.
6. Add every topic the domain emits to `serviceContainer.outputs.eventTopics` in `domains/<domain>/service/causa.yaml`, in the format `<domain>.<event>.<version>`.

<example>

# MyEntity

## Definition

This is what the entity represents.

## Properties

- `id` (uuid): Unique identifier of the entity.
- `createdAt` (timestamp): Date and time when the entity was created.
- `updatedAt` (timestamp): Date and time when the entity was last updated.
- `deletedAt` (timestamp, nullable): Date and time when the entity was deleted.
- `name` (string): Some name.
- `state` (enum MyEntityState): Current state of the entity.
  - `processing`: The entity is being processed.
  - `completed`: The entity has been processed.
  - `failed`: The entity processing has failed.
- `details` (MyEntityDetails): Additional details about the entity.
  - `nestedProperty` (integer): A nested property inside details.
- `reusedObject` (ReusableObject): A reusable object defined in the same domain.

# MyEntityEvent

**Topic**: `my-domain.my-entity-event.v1`

## Event names

- `myEntityCreated`: Emitted when a new MyEntity is created.
- `myEntityUpdated`: Emitted when an existing MyEntity is updated.
- `myEntityDeleted`: Emitted when an existing MyEntity is deleted.

</example>

</instructions>

<output>

- Entity schemas in `domains/<domain>/entities/<entity>.yaml`.
- Event schemas in `domains/<domain>/events/<event>/<version>.yaml`.
- Emitted topics listed in `serviceContainer.outputs.eventTopics`, in `domains/<domain>/service/causa.yaml`.

</output>

<validation>

1. Entities represent the core business concepts asked for, and events cover both entity changes and the other business concepts asked for.
2. All created and updated files are valid YAML files, and follow the global JSONSchema guidelines.
3. Entity schemas are located in `domains/<domain>/entities/` and event schemas in `domains/<domain>/events/`, following the structure and splitting guidelines.
4. Existing patterns are followed closely in the created and updated contracts.
5. Every topic the domain emits appears in `serviceContainer.outputs.eventTopics`.
6. Code generation succeeds:

- Run `cs model genCode` in the `service` folder of the corresponding domain to ensure the contract files are valid.
- Run `npm run typecheck` to ensure there are no TypeScript type errors. Focus on the generated code only.

</validation>

Business domains are organized in folders, under `domains/` at the root of the repository. The types of contracts are defined in the following sections. Use existing contracts as reference.

# Entities (data models)

Entities are defined as JSONSchema YAML files. They are located in `domains/<domain>/entities/<entity>.yaml`.

## Structure and splitting

- Entity files can correspond to core concepts of the business domain or to reusable concepts within the domain.
- For a nested object that is only used by a single entity, define it within the entity file itself, under `$defs`.
- For an object that is reused across multiple entities within the same domain, define it as a separate entity file.
- If an existing nested `$defs` object turns out to be needed by other entities, you can suggest splitting it into its own entity file.
- For more generic concepts that are likely to be reused across domains, define them in the `common` domain. (This does not happen often, but you can suggest it when relevant.)

## Common entity patterns

- A core business entity usually has `id`, `createdAt`, `updatedAt`, and `deletedAt` properties, with `deletedAt` being nullable.
- If an entity has a clear and useful state machine, it is defined as a `state` property.

## Constraints

For an entity that defines a core business concept, you may define possible states in the form of constraints. This is different from the entity having a `state` property. Constraints can be defined even if the entity does not have a `state` property. For an entity with a `state` property, each constraint corresponds to a possible value of the `state` property.

- Each constraint is defined as a schema under `$defs`.
- A constraint name should be suffixed with `Constraint`, e.g. `MyEntityInStateXConstraint`.
- At the root of the constraint schema, set the `causa.constraintFor` property to `"#"` (the root schema).
- A constraint schema only contains properties that exist in the root schema.
- A constraint schema only contains properties that are relevant to the constraint. Do not duplicate properties that don't change from the root schema.

## Example

Read `${CLAUDE_SKILL_DIR}/entity-example.yaml` for an example of an entity schema.

# Event schemas

Event schemas are defined as JSONSchema YAML files, just like entities. Those are located in `domains/<name>/events/<event>/<version>.yaml`. Event versions are simple integers and start at `1`, e.g. `v1`. Use the global JSONSchema guidelines at the end of those instructions.

## Guidelines

- An event schema always define the same properties: `id` (UUID), `producedAt` (date time), `name` (string), and `data` (reference to an object).
- The `data` property contains the payload of the event:
  - Most of the time, it references an entity schema.
  - If the event does not correspond to an entity change, it can define its own payload.
- If the event schema corresponds to a core business concept, set `causa.entityEvent: true` at the root of the schema.
- The `name` property must be of `type: string`. Use the `causa.enumHint` property to reference an enum defined under `$defs` in the same file. The enum must contain all possible event names for that event type.
- Event names should be in `camelCase` (like all enums), and always use a past participle (passive voice). A common pattern is "entity name + past participle", e.g. `companyCreated`.
- If the event schema corresponds to an entity with no particular state machine, the event names should usually be "created", "updated", and "deleted".
- If the event schema corresponds to an entity with a state machine, the event names should correspond to the state transitions.

## Constraints

Similarly to entities, you may define constraints for events. If there is more than one event name value, each usually map to a constraint. The constraint limits the `name` property to the corresponding `const` value, while the `data` property references the corresponding entity constraint (nested under `$defs` in the entity schema).

Constraints follow the same guidelines as entity constraints. In addition, if the event corresponds to an entity change, set the following `causa` properties at the root of the constraint schema:

- `entityMutationFrom`: This is a list of references to the entity constraints that the entity could have been in before the event. Use `[null]` if the entity did not exist before (e.g. for "created" events).
- `entityPropertyChanges`: This is a list of entity properties that are expected to change as a result of the mutation the event describes. Use `"*"` if any property can change. This list should be updated when new properties are added to the entity (if relevant).

## Example

Read `${CLAUDE_SKILL_DIR}/event-example.yaml` for an example of an event schema.

Use the exact types provided in the example. Use the exact description for `id`, `producedAt`, and `name`. Match the description of the `data` property to the entity being referenced.
