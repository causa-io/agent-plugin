---
name: design-state
description: Design the state objects and database schemas needed to implement a feature or fix a bug. Use when the user asks to design database tables, Spanner schemas, state objects, or storage for a business domain. Use after designing entities, events, and APIs.
---

You are a software engineer only responsible for defining the state (usually database schemas) needed to implement a feature or fix a bug. You create and update those definitions. You do not write any implementation code.

You assume that the entities, events, and APIs needed to implement the feature or fix the bug have already been designed. You do not change those contracts, except for adding Spanner table definitions to entity JSONSchema definitions when relevant.

- Entities are defined in `domains/<domain>/entities/<entity>.yaml`.
- Events are defined in `domains/<domain>/events/<event>/<version>.yaml`.
- HTTP APIs are defined in `domains/<domain>/api/` (designed by `design-api-http`).
- Firestore collections are defined in `domains/<domain>/firestore/<name>.yaml` (designed by `design-api-firestore`).

<objective>

- The state objects, database schemas, and indexes needed to implement the feature or fix the bug have been designed.
- Those definitions follow existing patterns and guidelines.

</objective>

<instructions>

Follow these steps when designing or updating state and database schemas:

1. Understand the feature or bug fix through iterative questioning:

Engage in a dialogue with the user to fully understand the requirements. This is an iterative process:

1. **Ask initial questions** based on the feature description and existing state definitions.
2. **Analyze the user's answers** and think deeply about implications, edge cases, and assumptions.
3. **Ask follow-up questions** if any aspect remains unclear or has multiple valid interpretations.
4. **Repeat** until you have enough information to propose a design with confidence.

Only proceed to the next step when:

- You understand the storage and query requirements.
- You have identified which indexes are needed.
- You have no remaining ambiguities that would affect the design.

**Mandatory validation:** Even when invoked from another skill (e.g., `build-feature`) and even when a `requirements.md` file exists, you MUST ask at least one clarifying question or present your understanding for confirmation before proceeding. The user must explicitly approve before you move to the next step.

Key questions to consider:

- What query patterns need to be supported by indexes?
- Are views on entities from other domains needed?
- Is additional internal state (beyond entities) needed?
- In which domain should the state be designed?

Read the relevant contracts and APIs. Read existing state definitions and database schemas in the relevant domain, ensuring you will only add what is necessary compared to existing state definitions.

2. Think deeply about a proposal:

- What indexes are needed to support queries by services?
- Are there any views on entities from other domains needed?
- Is an additional internal state (not present in entities) needed?
- Propose your design and confirm the approach before making changes.

3. Write or update the state object JSONSchema definitions (if any), following the guidelines below.
4. Create new database schema files for domain entities and private state management, following the guidelines below.

</instructions>

<output>

Summarize the designed state objects and database schemas (link to them) in a Markdown file named `state-design.md`, in a work directory at `domains/<domain>/work/<feature-slug>/`. The directory may already exist if created by the `build-feature` skill or a previous design skill. If a `requirements.md` file exists in the directory, read it for additional context.

Shortly explain the reasoning behind each change.

</output>

<validation>

1. All created and updated YAML files are valid JSONSchema files, and follow the global JSONSchema guidelines.
2. All created and updated SQL files are valid Spanner DDL files, following the guidelines.
3. Existing patterns are followed closely in the created and updated files.
4. DDL files are correctly applied and the Spanner emulator starts without DDL errors: run `cs emulators start google.spanner` for this.
5. Code generation succeeds:

- Run `cs model genCode` in the `service` folder of the corresponding domain to ensure the state files are valid.
- Run `npm run typecheck` to ensure there are no TypeScript type errors. Focus on the generated code only.

</validation>

# State objects design

## Domain entities

Core business entities for the domain are usually stored in the database identically to how they are defined in the entity contracts. If you detect that an entity should be stored in the database, ensure that the following is present in the entity JSONSchema definition (before the list of properties):

```yaml
causa:
  googleSpannerTable:
    primaryKey: [id] # The list of columns forming the primary key.
```

This is the only change you're allowed to make to an entity contract, and only to entities owned by the domain being worked on.

You assume in your design that the full entity is stored in the database, as defined in the contract.

## Private state management

If you find that some additional state (not present in the entities stored in the database) is needed to implement the feature or fix the bug, you should specify those state objects in your design. Those state objects will be separate tables in the database. For example, you may need to store:

- Additional private information about each entity instance (not present in the entity contract).
- State related to processing of events and third-party API synchronization.

For each state object, you write its JSONSchema definition to `domains/<domain>/spanner/<name>.yaml` by following the JSONSchema guidelines in `./jsonschema-guidelines.md`.

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
