---
name: design-api-http
description: Reference for designing HTTP APIs using OpenAPI. Use when designing, creating, or updating HTTP APIs, REST endpoints, DTOs, or API contracts for a business domain, and load it before writing any OpenAPI or DTO file. Covers CRUD conventions, error responses, and the endpoints declared in `causa.yaml`.
---

Business domains expose an HTTP API, defined using one or several OpenAPI YAML files. Each file focuses on a single entity or feature of the domain.

This reference covers OpenAPI contracts, the DTOs they reference, and the `endpoints.http` declaration that goes with them. Base entities and events are covered by `design-model` — they may be referenced here, but not defined here. Real-time read access for frontends is covered by `design-api-firestore`.

<instructions>

To design or update HTTP APIs:

1. Read existing HTTP API files in the relevant domain, and in other domains if necessary. They are the ground truth for conventions.
2. Identify the OpenAPI contracts and the DTOs (JSONSchema) that need to be created or updated: the commands and mutation operations, the query operations, who can access each of them, and the business errors each can return.
3. Learn the global JSONSchema guidelines in `${CLAUDE_SKILL_DIR}/jsonschema-guidelines.md`. Those should be used for DTOs.
4. Read the example OpenAPI file in `${CLAUDE_SKILL_DIR}/api-example.yaml`.
5. Write or update the HTTP API files and DTOs, following the guidelines below and existing files as reference.
6. List the endpoints exposed by the service in `serviceContainer.endpoints.http`, in `domains/<domain>/service/causa.yaml`. Only the first path segment is listed, e.g. `/myEntities`.

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

</instructions>

<output>

- OpenAPI files in `domains/<domain>/api/<entity>.api.yaml`.
- DTO schemas in `domains/<domain>/api/<name>.dto.yaml`.
- Exposed endpoints listed in `serviceContainer.endpoints.http`, in `domains/<domain>/service/causa.yaml`.

</output>

<validation>

1. The designed HTTP APIs correctly expose the commands and queries to solve the business needs asked for, with the authorization rules stated in each operation's `description`.
2. All created and updated files are valid YAML files, and follow the global OpenAPI and JSONSchema guidelines.
3. HTTP API schemas are located in `domains/<domain>/api/`, following the structure and splitting guidelines.
4. Existing patterns are followed closely in the created and updated contracts.
5. Every exposed endpoint's first path segment appears in `serviceContainer.endpoints.http`.
6. Code generation succeeds:

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
- `errorCode` (string): An error identifier, in the format `domain.errorName`. Description is `An error identifier, as a string.`.
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

Read `${CLAUDE_SKILL_DIR}/api-example.yaml` for an example of an OpenAPI file. Read `${CLAUDE_SKILL_DIR}/entity-example.yaml` for an example of a DTO file.
