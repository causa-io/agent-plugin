# Design question inventory

Questions to draw on when clarifying a feature or bug fix. **Not a checklist to run through.**
Ask only what would change the design: anything answerable from the existing contracts or the
code is not a question, and anything with a clearly conventional answer becomes a recorded
assumption instead.

Ask in two waves. Wave 1 determines which surfaces the feature touches, which in turn determines
which sections of wave 2 are relevant at all — and which design reference skills get loaded.

## Contents

- [Wave 1 — scope](#wave-1--scope)
- [Wave 2 — entities and events](#wave-2--entities-and-events)
- [Wave 2 — HTTP API](#wave-2--http-api)
- [Wave 2 — Firestore](#wave-2--firestore)
- [Wave 2 — state and access patterns](#wave-2--state-and-access-patterns)
- [Wave 2 — triggers](#wave-2--triggers)
- [Wave 2 — external systems](#wave-2--external-systems)
- [Bug fixes](#bug-fixes)
- [Questions never worth asking](#questions-never-worth-asking)

## Wave 1 — scope

Everything here changes which surfaces exist, and therefore which references get loaded.

- What problem does this solve? What is the user or business need?
- Which domain(s) are affected? For a new concept, propose the domain rather than asking.
- Is this new behavior, or a change to existing behavior?
- Is it user-facing? Through which client — web app, mobile app, both?
- **Which surfaces does it touch?**
  - New or changed **entities**, or **events emitted** by this domain? → `design-model`
  - **Request/response endpoints** for clients? → `design-api-http`
  - **Real-time reads** by a frontend? → `design-api-firestore`
  - Anything **persisted**, or any new way of reading what is already persisted? → `design-state`
  - Reacting to an **event** (from any domain), **scheduled** work, or **queued** work? → `design-triggers`
- Are external systems involved — third-party APIs, identity providers?
- Are there cross-domain interactions: events consumed from, or published to, other domains?

## Wave 2 — entities and events

- What business concepts need to be represented?
- Do they have lifecycle states? What triggers each transition, and can any state be left?
- How are these entities created, updated, and deleted? By a user command, or by an event?
- Which events need to be emitted, and for what reason — an entity change, or a business fact?
- Is any of this a concept that already exists in this domain, or in `common`?
- Does a change to an existing entity or event break an existing consumer? Removing a property
  or narrowing an enum does.

## Wave 2 — HTTP API

- Who can access each operation? Are there roles, or is ownership the rule?
- Which commands and mutations are needed — create, update, delete, or something more specific?
- Which queries are needed — by id, filtered lists, and filtered on what?
- What are the business errors for each operation, and what should each return?
- Does any response need enrichment, or redaction of entity properties?

## Wave 2 — Firestore

- Which entities need real-time access by the frontend?
- Which properties must be redacted from the client-visible view?
- Who can read each collection? Own documents only, company members, anyone authenticated?
- Is the key single or composite — which decides root-level versus nested collections?

## Wave 2 — state and access patterns

- What is persisted, and what is derived or computed rather than stored?
- **Every way the data is read.** Go source by source, because only the first two are visible
  from the contracts:
  - Each list, filter, and lookup operation in the HTTP API.
  - Each Firestore query the clients run.
  - What each event handler looks up when it fires — usually a foreign key from the payload.
  - What each cron or sweep scans, and on which timestamp.
  - What business logic reads before a mutation: uniqueness checks, validation lookups.
- For each of those, roughly how many rows come back, and how often does it run? This is the
  answer a human has and the model does not, and it decides whether an index is needed at all.
- Is private state needed beyond the entities — processing state, third-party sync state?
- Is a projection of another domain's entity needed?

## Wave 2 — triggers

- Which events must this service react to, and from which domains?
- Does a handler care about all of a topic's event names, or a subset?
- Is there work that should not block the request or handler that causes it, needs its own
  retry behavior, or fans out over many items? That is a task — what is its payload?
- Is there work driven by time rather than by an occurrence: expiry, reconciliation, cleanup?
- What must happen when the same event is delivered twice?

Do not ask whether a newly designed topic needs a consumer. It usually does not.

## Wave 2 — external systems

- Which third-party APIs are called, and from where?
- What happens when one is slow, or down? Retry, fail the request, or degrade?
- If a local write succeeds and the external call then fails, what state is the entity left in?
- Are there credentials or configuration the deployment needs?

## Bug fixes

- What is the current, incorrect behavior? What is the expected behavior?
- Is this a contract issue, a state issue, or an implementation issue?
- What input reproduces it?
- Has data already been written incorrectly? Does it need repairing, and is that in scope?

## Questions never worth asking

These get answered by reading, or by assuming and recording:

- Naming and file placement conventions — read the neighbouring contracts.
- Whether an entity gets `id`, `createdAt`, `updatedAt`, `deletedAt` — it does.
- Which HTTP method or status code a conventional CRUD operation uses.
- Whether writes go through the backend rather than directly to Firestore — they do.
- Anything already stated in `requirements.md` or in an existing contract.
