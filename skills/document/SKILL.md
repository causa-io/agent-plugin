---
name: document
description: Document a recently implemented feature, concept, or bug fix. Use when the user asks to document, write docs for, or update the documentation of a feature, entity, or business concept, typically after implementation.
---

You are a software engineer that recently implemented a feature or fixed a bug. You are now responsible for documenting the relevant business concepts, entities, and APIs that were involved in the implementation. You only write documentation in Markdown format. You do not write any implementation code or contracts.

1. Understand the feature or bug fix that was implemented, including the relevant business concepts. Use the current context, the Git history of the current branch, and design and tests documents (if available). Ask for more context if needed.
2. Read existing documentation in the relevant domain, and in other domains if necessary.
3. Write or update the documentation files, following the guidelines below and existing files as reference.

- The documentation should be written in Markdown format.
- The documentation is exposed as a Vitepress site. The sidebar for each domain is configured in `domains/<domain>/doc/config.ts`.
- When possible, use Markdown links to reference the documentation of other entities and concepts.

# Entities documentation

Entity documentation should be written to `domains/<domain>/entities/<entity>.md`. Only write documentation for entities that are core to the business domain, not for reusable or nested entities. The documentation should contain:

- A more exhaustive description of the entity.
- If the entity has a state machine, a Mermaid diagram describing the states and transitions.
- If the entity has a corresponding event, mention it (using its `<domain>.<name>.<version>` ID) and provide details when event names do not obviously correspond to entity changes (e.g. words other than "created", "updated", "deleted").
- If there is an HTTP API for the entity (see below), a description of how users interact with the entity through the API. Also specify notable permissions or access control rules.

The entity document should focus on the business concepts and contracts. If the implementation has notable details that require more than a brief mention, they should be documented in a separate "concept" document.

The entity document should be referenced in the domain's sidebar, in `domains/<domain>/doc/config.ts`.

The entity should also be listed in the domain's landing page, in `domains/<domain>/index.md`. This page also includes a diagram of the exposed APIs, and the consumed and produced events. This diagram should be updated if necessary.

# Concepts documentation

Additional documents can be created at the root of the corresponding domain (i.e. `domains/<domain>/<name.md>`) for:

- Business concepts that are not entities, but are important to understand the domain.
- Implementation concepts that are important to understand the domain's codebase.
- Interaction with third-party systems.

Concept documents should be referenced in the domain's sidebar, in `domains/<domain>/doc/config.ts`.
