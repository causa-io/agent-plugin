---
name: design-state
description: Reference for designing access patterns, state objects, and Spanner database schemas. Use when designing database tables, Spanner schemas, indexes, query patterns, or storage for a business domain, and load it before writing any state schema or DDL file. Covers access patterns, indexes, row deletion policies, and the databases declared in `causa.yaml`.
---

The state of a domain is what its service persists and how it reads it back: the entities stored in Spanner, the private state and projections alongside them, the access patterns the service needs, and the indexes that serve those patterns.

This reference covers all of the above and the `outputs.google.spanner` declaration that goes with them. It assumes entities, events, and APIs have already been designed, and does not change them — with one exception, adding the Spanner table definition to an entity JSONSchema, described below.

- Entities are defined in `domains/<domain>/entities/<entity>.yaml` (covered by `design-model`).
- Events are defined in `domains/<domain>/events/<event>/<version>.yaml` (covered by `design-model`).
- HTTP APIs are defined in `domains/<domain>/api/` (covered by `design-api-http`).
- Firestore collections are defined in `domains/<domain>/firestore/<name>.yaml` (covered by `design-api-firestore`).
- Triggers, which are a major source of access patterns, are covered by `design-triggers`.

<instructions>

To design or update access patterns, state, and database schemas:

1. Read the relevant contracts and APIs. Read existing state definitions and database schemas in the relevant domain, ensuring you will only add what is necessary compared to what already exists.
2. Enumerate the access patterns the feature needs, following the "Access patterns" section below. This comes before indexes: an index is only justified by a pattern.
3. Identify whether additional internal state (beyond entities) is needed, and whether views on entities from other domains are needed.
4. Learn the global JSONSchema guidelines in `${CLAUDE_SKILL_DIR}/jsonschema-guidelines.md`.
5. Read the example DDL file in `${CLAUDE_SKILL_DIR}/spanner-ddl-example.sql`.
6. Write or update the state object JSONSchema definitions (if any), following the guidelines below.
7. Create new database schema files for domain entities and private state management, with the indexes the access patterns require, following the guidelines below.
8. List the databases written by the service in `serviceContainer.outputs.google.spanner`, in `domains/<domain>/service/causa.yaml`, in the format `<instance>.<database>`, e.g. `backend.content`.

</instructions>

<output>

- State object and projection schemas in `domains/<domain>/spanner/<name>.yaml`.
- Spanner DDL in `domains/<domain>/spanner/<number>-<file>.sql`.
- The Spanner table definition added to entity schemas in `domains/<domain>/entities/<entity>.yaml`.
- Databases listed in `serviceContainer.outputs.google.spanner`, in `domains/<domain>/service/causa.yaml`.
- The access patterns table, in the design document held by the caller. It is working material for the design, not a permanent artifact: the durable record of what access is supported is the set of indexes on disk.

</output>

<validation>

1. Every access pattern the feature needs is listed, including the ones that come from event handlers, crons, tasks, and internal logic rather than from an API endpoint.
2. Every access pattern is served by an index, or by a primary key prefix that covers its filter and ordering. State that key or index explicitly for each pattern.
3. No index is defined that no access pattern justifies.
4. All created and updated YAML files are valid JSONSchema files, and follow the global JSONSchema guidelines.
5. All created and updated SQL files are valid Spanner DDL files, following the guidelines.
6. Existing patterns are followed closely in the created and updated files.
7. Every database written by the service appears in `serviceContainer.outputs.google.spanner`.
8. DDL files are correctly applied and the Spanner emulator starts without DDL errors: run `cs emulators start google.spanner` for this.
9. Code generation succeeds:

- Run `cs model genCode` in the `service` folder of the corresponding domain to ensure the state files are valid.
- Run `npm run typecheck` to ensure there are no TypeScript type errors. Focus on the generated code only.

</validation>

# Access patterns

An index is justified by a query, so the queries have to be known before the indexes are designed. List every way the feature reads data, as a table:

<example>

| # | Pattern | Source | Store | Filter / order | Index | Volume |
| --- | --- | --- | --- | --- | --- | --- |
| Q1 | A user's pending orders, newest first | `GET /orders` | Spanner | `userId`, `state`, `-createdAt` | `OrdersByUserAndState` | ~100 per user |
| Q2 | An order by its external payment reference | `handlePaymentSettled` trigger | Spanner | `paymentRef` | `OrdersByPaymentRef` | 1 |
| Q3 | Orders left pending for more than 24h | `handleOrderExpiry` cron | Spanner | `state`, `createdAt <` | `OrdersByStateAndCreatedAt`, `NULL_FILTERED` | ~1k per night |
| Q4 | A client's live order feed | web app | Firestore | `userId`, `-updatedAt` | — | ~10 per user |

</example>

Access patterns come from five places. The first two are visible in the API contracts; the last three are the ones that get missed:

- **HTTP endpoints**: every list, filter, and lookup operation in the OpenAPI files.
- **Firestore queries** run by clients against the collections the domain publishes.
- **Event handlers**: what a handler looks up when it fires, usually by a foreign key carried in the event.
- **Crons and background sweeps**: scans, expiry, reconciliation. These are often the only pattern that filters on a timestamp, and often the one that needs a dedicated index.
- **Internal business logic**: uniqueness checks, validation lookups, and reads a service performs before a mutation.

The `Volume` column is an estimate of how many rows the pattern returns, or how often it runs. It is the column most worth confirming with a human: it decides whether an index is needed at all, whether a query needs to stream in batches, and whether a scan is acceptable.

# State objects design

## Domain entities

Core business entities for the domain are usually stored in the database identically to how they are defined in the entity contracts. If you detect that an entity should be stored in the database, ensure that the following is present in the entity JSONSchema definition (before the list of properties):

```yaml
causa:
  googleSpannerTable:
    primaryKey: [id] # The list of columns forming the primary key.
    name: MyTable # Optional, only when the table name differs from the schema title.
```

This is the only change you're allowed to make to an entity contract, and only to entities owned by the domain being worked on.

You assume in your design that the full entity is stored in the database, as defined in the contract.

## Private state management

If you find that some additional state (not present in the entities stored in the database) is needed to implement the feature or fix the bug, you should specify those state objects in your design. Those state objects will be separate tables in the database. For example, you may need to store:

- Additional private information about each entity instance (not present in the entity contract).
- State related to processing of events and third-party API synchronization.

For each state object, you write its JSONSchema definition to `domains/<domain>/spanner/<name>.yaml` by following the JSONSchema guidelines in `${CLAUDE_SKILL_DIR}/jsonschema-guidelines.md`.

## Views on entities from other domains

If you find that the domain needs to build a view on an entity using events from another domain, you should create a JSONSchema definition for that view. Define the properties of the entity that are needed by the domain. Follow the same guidelines as for private state management.

# Database schemas

Database schemas are Spanner DDL statements stored in `domains/<domain>/spanner/<number>-<file>.sql`. They are applied sequentially when the infrastructure is deployed.

- Always create a new file for new changes, with an incremented number.
- Changes are usually split into multiple files based on the table being created or modified. Several statements on a single table and its indexes can be grouped in a single file.
- Statements should be written in Google SQL for Spanner.
- Table and index names should be in PascalCase, matching the entity or state object name. Column names should be in camelCase, matching the property names in the JSONSchema definition.
- Do not use foreign keys or check constraints.
- Only define indexes for query patterns that are actually needed by services.
- Do not add a trailing semicolon at the end of the file, only to separate statements.
- Generated columns of type `STRING` must always use `STRING(MAX)`.
- Tables holding entities or projections with a `deletedAt` property should define a row deletion policy, e.g. `ROW DELETION POLICY (OLDER_THAN(deletedAt, INTERVAL 1 DAY))`, so soft-deleted rows are eventually removed.
- A child table that is always read alongside its parent can be interleaved, e.g. `INTERLEAVE IN PARENT MyEntity ON DELETE CASCADE`.

There are several types of database schemas that you may need to design or edit.

## Contract entities owned by the domain

An entity managed by the domain being worked on already has a JSONSchema definition. If this entity is being created or updated as part of the current task, and if it is relevant to store in the database, you should create a new DDL file corresponding to the changes in the JSONSchema definition.

If you've identified that indexes are needed to support queries by services, you should also add them in the same DDL file.

## Private state management and views on entities from other domains

All state objects identified in the previous section need to be created in the database. You should create a new DDL file for each created or updated state object, with the corresponding Spanner DDL statements. This can include indexes if needed.

## Indexes

- The name of an index should be the table name (plural form if applicable) followed by "By" and the list of indexed columns in PascalCase, concatenated with "And". For example, an index on `user` and `status` on the `Order` table would be named `OrdersByUserAndStatus`.
- `WHERE` clauses are not supported.
- `NULL_FILTERED` can be used to remove rows with any `NULL` value in the indexed columns.
- `STORING` can be used to add non-indexed columns to the index for performance reasons (no need to read the base table).
- Generated columns can be used to provide more complex indexing logic (e.g. indexing a JSON field, indexing conditionally to a given state, etc). Those generated columns do not need to be `STORED`.

## Example

Read `${CLAUDE_SKILL_DIR}/spanner-ddl-example.sql` for an example of a DDL file, creating the table for the `MyEntity` entity along with an index.
