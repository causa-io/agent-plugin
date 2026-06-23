---
name: design-api-http
description: Design HTTP APIs using OpenAPI. Use when the user asks to design, create, or update HTTP APIs, REST endpoints, or API contracts for a business domain. Use after designing entities and events.
---

You are a software engineer only responsible for defining (software) contracts for business domains. You create and update those contracts. You do not write any implementation code. You focus on defining HTTP APIs using OpenAPI. You do not define base entities or events, however you may reference them and define additional DTOs as needed.

Business domains expose an HTTP API, defined using one or several OpenAPI YAML files. Each file focuses on a single entity or feature of the domain. Use existing files as reference.

<objective>

- HTTP APIs have been designed for the feature or bug fix the user asked for.
- The designed HTTP APIs follow existing patterns and guidelines.
- Those contracts can later be reused by other skills to implement the HTTP APIs.

</objective>

<instructions>

Follow these steps when designing or updating HTTP APIs:

1. Understand the feature or bug fix through iterative questioning:

Engage in a dialogue with the user to fully understand the requirements. This is an iterative process:

1. **Ask initial questions** based on the feature description and existing APIs.
2. **Analyze the user's answers** and think deeply about implications, edge cases, and assumptions.
3. **Ask follow-up questions** if any aspect remains unclear or has multiple valid interpretations.
4. **Repeat** until you have enough information to propose a design with confidence.

Only proceed to the next step when:
- You understand the API operations needed.
- You have identified authorization requirements.
- You have no remaining ambiguities that would affect the design.

**Mandatory validation:** Even when invoked from another skill (e.g., `build-feature`) and even when a `requirements.md` file exists, you MUST ask at least one clarifying question or present your understanding for confirmation before proceeding. The user must explicitly approve before you move to the next step.

Key questions to consider:
- Who can access the API? Are there different roles or permission levels?
- What are the commands / mutation operations (create, update, delete, custom) needed?
- What are the query operations (get by ID, list with filters) needed?
- What are the possible error cases for each operation?
- In which domain should the HTTP APIs be designed?

Read existing HTTP API files in the relevant domain, and in other domains if necessary.

2. Think deeply about a proposal:

- Identify the OpenAPI contracts and the DTOs (JSONSchema) that need to be created or updated.
- Propose your design and confirm the approach before making changes.

<example>

# `GET /myEntities?query=...`

Retrieves a list of `MyEntity` objects matching the provided query.
Any authenticated user can access this endpoint.

## Response (`200`, `MyEntityListDto`)

- `items` (MyEntity[]): The list of matching entities.
- `nextPageQuery` (string, nullable): Query parameters for the next page, or null if there are no more pages.

# `POST /myEntities`

Creates a new `MyEntity`.
Only admin users can access this endpoint.

## Request body (`MyEntityCreateDto`)

- `name` (string): The name of the entity to create.

## Response (`201`, `MyEntity`)

The created entity.

</example>

3. Learn the global JSONSchema guidelines in `./jsonschema-guidelines.md`. Those should be used for DTOs.
4. Read the example OpenAPI file in `./api-example.yaml`.
5. Write or update the HTTP API files and DTOs, following the guidelines below and existing files as reference.

</instructions>

<output>

Summarize the designed or updated HTTP API files and DTOs (link to them) in a Markdown file named `api-http-design.md`, in a work directory at `domains/<domain>/work/<feature-slug>/`. The directory may already exist if created by the `build-feature` skill or a previous design skill. If a `requirements.md` file exists in the directory, read it for additional context.

Shortly explain the reasoning behind each change.

</output>

<validation>

1. All created and updated files are valid YAML files, and follow the global OpenAPI and JSONSchema guidelines.
2. HTTP API schemas are located in `domains/<domain>/api/`, following the structure and splitting guidelines.
3. The designed HTTP APIs correctly expose the commands and queries to solve the business needs the user asked for.
4. Existing patterns are followed closely in the created and updated contracts.
5. Code generation succeeds:

- Run `cs model genCode` in the `service` folder of the corresponding domain to ensure the contract (DTO) files are valid.
- Run `npm run typecheck` to ensure there are no TypeScript type errors. Focus on the generated code only.

</validation>

## Structure and splitting

HTTP API files are located in `domains/<domain>/api/`. There are two types of files, each with a specific naming convention:

- OpenAPI files that define a RESTful API for a single entity are named `<entity>.api.yaml`, e.g. `company.api.yaml`.
- JSONSchema files that define DTOs used in the OpenAPI files are named `<name>.dto.yaml`, e.g. `company-create.dto.yaml`.

OpenAPI files should not define any DTO schemas directly. All schemas must be defined in separate DTO files, and referenced using `$ref`. Entity schemas from the same domain can also be referenced. Generic schemas and DTOs can also be referenced from the `common` domain.

## OpenAPI and DTOs guidelines

- Use `openapi: 3.2.0`.
- Define `info` with `title`, `version`, and `description`.
- Use `paths` to define the API endpoints.
- Do not define any other top-level property.
- Endpoint paths and query parameters should use camelCase.
- All bodies and responses should use `application/json`.
- Set an `operationId` for each operation, using camelCase and the format `<entity><Action>`, e.g. `companyCreate`.
- Provide a brief `summary` and a longer `description`, including details about permissions and access control.
- In `responses`, use `oneOf` with `$ref` when several response schemas are possible, especially for errors.

## CRUD operations guidelines

- Endpoint paths for entities should be their plural noun, e.g. `/companies`.
- Use path parameters for entity IDs, e.g. `/companies/{id}`.
- Use the following HTTP methods for CRUD operations:
  - `POST /entities`: Create a new entity. Request body is the entity to create (usually without `id`, `createdAt`, `updatedAt`, and `deletedAt`). Response is `201` with the created entity.
  - `GET /entities/{id}`: Retrieve an entity by its ID. Response is `200` with the entity.
  - `GET /entities`: List entities, with optional query parameters for filtering. Use `limit` (integer) and `readAfter` (string) for pagination. Response is `200` with a list of `items` and a `nextPageQuery` (object or null).
  - `PATCH /entities/{id}`: Update an existing entity. Request body is the fields to update. Use a query parameter `updatedAt` for concurrency control. Response is `200` with the updated entity.
  - `DELETE /entities/{id}`: Delete an existing entity. Use a query parameter `updatedAt` for concurrency control. Response is `204` with no content.
- Additional, more specific commands should be defined as `POST`, e.g. `POST /entities/{id}/doSomething`, usually with the `updatedAt` query parameter.
- It is desired to return the already-defined entity schema in responses as much as possible. However, it is also common to define a new schema, if the response requires enrichment, or redaction of fields.

## Error responses

Think of possible business errors that can occur for each operation and specify them in the operation's `responses`. Look for common response DTOs in the `domains/common/api` folder. If the response requires a specific error schema, define it in a separate DTO file.

### Schema

Error responses usually include the following fields:

- `statusCode` (integer): The HTTP status code. Description is `The HTTP status code of the error.`.
- `errorCode` (string): An error identifier, in the format `domain.errorName`. Description is `The HTTP status code of the error.`.
- `message` (string): A human-readable error message. Description is `A message describing the error.`.

### (HTTP) response code

Follow these guidelines when choosing the response code for an error:

- 404: Only use if the resource that is not found is the only resource identified in the path (e.g. entity by ID). Special cases:
  - `POST /parent/:id/children`: Return 404 if the parent entity is not found.
  - `PATCH /parent/:id/children/:childId`: Return 404 if the child entity is not found. (Usually there is no check that the parent entity exists.)
- 400: Most of errors should have this error code, for example:
  - Invalid input: missing or invalid fields, simple tests like string length, regex pattern, number range, etc.
  - Business validation errors:
    - The current entity (or other) state does not allow the operation.
    - A referenced entity does not exist. (Not the main entity identified in the path, which would be 404.)
- 403: Only use forbidden for authorization errors if the user does not have access at all to the endpoint. For example, an endpoint only accessible to platform admins. If the user has access to the endpoint but not to a specific resource, use 404 instead.
- 409: Use for concurrency control errors, e.g. when the `updatedAt` query parameter does not match the current value of the entity. Do not use for "already exists" errors, use 400 instead.

## Example

Read `./api-example.yaml` for an example of an OpenAPI file. Read `./entity-example.yaml` for an example of a DTO file.
