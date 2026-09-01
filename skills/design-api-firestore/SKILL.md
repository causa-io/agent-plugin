---
name: design-api-firestore
description: Reference for designing Firestore collections and security rules for real-time data access. Use when designing, creating, or updating Firestore collections, documents, or security rules for a business domain, and load it before writing any Firestore document schema or rule. Covers collection paths, redaction, and the collections declared in `causa.yaml`.
---

Firestore collections are views of entities, asynchronously replicated from entity events. They provide real-time subscriptions for frontends.

This reference covers Firestore document schemas, their security rules, and the `outputs.google.firestore` declaration that goes with them. Base entities and events are covered by `design-model` — they may be referenced here, but not defined here. Request/response APIs are covered by `design-api-http`.

<instructions>

To design or update Firestore collections:

1. Read existing Firestore collections in the relevant domain, and in other domains if necessary. Read the entity schemas that will be projected as Firestore documents.
2. Identify the document schemas and security rules that need to be created or updated: which entities need real-time access, which properties are exposed or redacted, who can read them, and whether the collection is root-level or nested.
3. Learn the global JSONSchema guidelines in `${CLAUDE_SKILL_DIR}/jsonschema-guidelines.md`.
4. Read the example Firestore document schema in `${CLAUDE_SKILL_DIR}/firestore-document-example.yaml`.
5. Write or update the Firestore document schemas and security rules, following the guidelines below and existing files as reference.
6. List the root collections written by the service in `serviceContainer.outputs.google.firestore`, in `domains/<domain>/service/causa.yaml`.

<example>

# `products` collection

A root-level collection exposing `Product` entities for real-time access.

## Document schema (`ProductDocument`)

View of the `Product` entity with all properties exposed.

**Path**: `/products/{id}`

## Security rules

- Any authenticated user can read products.

# `users/{userId}/orders/{orderId}` collection

A nested collection for user orders, using the composite key `(user, order)` as the document path.

## Document schema (`OrderDocument`)

View of the `Order` entity with `internalNotes` redacted.

**Path**: `/users/{user}/orders/{order}`

## Security rules

- Users can only read their own orders.

</example>

</instructions>

<output>

- Firestore document schemas in `domains/<domain>/firestore/<name>.yaml`.
- Security rules in `domains/<domain>/firestore/firestore.rules`.
- Root collections listed in `serviceContainer.outputs.google.firestore`, in `domains/<domain>/service/causa.yaml`.

</output>

<validation>

1. The designed Firestore collections correctly expose the data needed for real-time access by frontends, with properties redacted where access control requires it.
2. All created and updated YAML files are valid JSONSchema files, and follow the global JSONSchema guidelines.
3. Firestore document schemas are located in `domains/<domain>/firestore/`, following the structure and naming guidelines.
4. Security rules are located in `domains/<domain>/firestore/firestore.rules`, and no collection is readable by a caller who should not see it.
5. Existing patterns are followed closely in the created and updated contracts.
6. Every root collection written by the service appears in `serviceContainer.outputs.google.firestore`.
7. Code generation succeeds:

- Run `cs model genCode` in the `service` folder of the corresponding domain to ensure the document schema files are valid.
- Run `npm run typecheck` to ensure there are no TypeScript type errors. Focus on the generated code only.

</validation>

# Firestore document schemas

Firestore document schemas are defined as JSONSchema YAML files. They are located in `domains/<domain>/firestore/<name>.yaml`.

## Structure and naming

- Document schema files are named after the entity they project, in kebab-case: `<entity>.yaml`, e.g. `asset.yaml`, `bookmark.yaml`.
- The schema title should follow the pattern `<EntityName>Document`, e.g. `AssetDocument`, `BookmarkDocument`.
- If a document combines multiple entities or serves a different purpose, use a descriptive name that reflects the document's content.

## Relationship to entities

Firestore documents are views of entities, asynchronously replicated from entity events. Common patterns:

- **Direct view**: All or most properties from the source entity are exposed.
- **Redacted view**: Some properties are omitted for security or simplicity (similar to a custom DTO for HTTP APIs).
- **Combined view**: Properties from multiple entities are combined into a single document for easier frontend consumption (less common).
- **Computed fields**: Derived or computed properties may be added (extremely rare).

## Collection configuration

Each document schema must include the `causa.googleFirestoreCollection` configuration:

```yaml
causa:
  googleFirestoreCollection:
    path: [products, property: id]
    hasSoftDelete: true
```

- `path`: Array defining the full document path, starting with the root collection name. Elements can be:
  - Plain string: A literal path segment, including the (root or nested) collection name (e.g., `products`, `bookmarks`).
  - `property: <prop>`: A dynamic segment using the property value (e.g., `property: id`).
  - The path alternates collection/document segments, so it starts with a collection name and ends with a document segment (e.g., `[users, property: user, bookmarks, property: post]`).
- `hasSoftDelete`: Set to `true` when the source entity has a `deletedAt` property. This is required (not just recommended) to account for unordered event processing.

## Root vs nested collections

- **Root collections** (e.g., `/assets/{id}`) should be preferred for entities with a single unique ID.
- **Nested collections** (e.g., `/users/{userId}/bookmarks/{postId}`) should be used when the entity has a composite key. The path should reflect the composite key structure.

## Example

Read `${CLAUDE_SKILL_DIR}/firestore-document-example.yaml` for an example of a Firestore document schema.

# Security rules

Security rules control access to Firestore collections. They are defined in `domains/<domain>/firestore/firestore.rules`.

## Guidelines

- Security rules should only define `read` access. Firestore writes go through the backend via HTTP APIs.
- Write rules should only be added if explicitly requested for a specific use case.
- Use the helper functions defined in `domains/common/firestore/firestore.rules` (or other domain rule files) for common patterns:
  - `isAuthenticated()` - Check if the caller is authenticated.
  - `isAuthenticatedAs(id)` - Check if the caller is a specific user.
  - `isCompanyAdmin(company)` - Check if the caller is an admin of a company.
  - `isPlatformAdmin()` - Check if the caller is a platform admin.
- Use `resource.data.<field>` to reference document fields in rules.
- Group rules by collection path.
- Read existing security rules in the codebase for examples.
