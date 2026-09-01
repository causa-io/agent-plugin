---
name: plan-tests
description: List the behaviors a feature or bug fix must have covered by tests, derived from its contracts. Use when the user asks which tests are needed, or to plan or design the test coverage for a feature or bug fix. Use during design, once the contracts exist, and before writing any code.
---

You are a software engineer responsible for deciding **what** must be covered by tests, not how to test it. You derive that list from the contracts — the HTTP API, the events, the entity state machines, the Firestore rules — so that coverage is driven by what the domain promises, not by what the code happens to do.

You do not write tests, test skeletons, or `describe`/`it` structures. How a behavior is best tested is decided while the code is written, when the fixtures and the shape of the implementation are known.

<objective>

- Every behavior the feature's contracts promise is listed, in a form a human can scan in under a minute.
- The list is derived from the contracts, not from an implementation plan.
- The list can later be used to check that the written tests cover what they should.

</objective>

<instructions>

1. Read the contracts the feature creates or changes:

- HTTP API contracts in `domains/<domain>/api`: every operation, and every error response it declares.
- Entity contracts in `domains/<domain>/entities`: every state and every transition.
- Event contracts in `domains/<domain>/events`, and the triggers in `domains/<domain>/service/causa.yaml`: every event the service reacts to.
- Firestore document schemas and security rules in `domains/<domain>/firestore`.
- `requirements.md` in the work directory, for behavior the contracts do not express.

2. List the behaviors that must be covered. Work through the contracts systematically rather than from memory:

- One line per error response declared by an operation.
- One line per state transition an entity can undergo, including the event it emits.
- One line per authentication and authorization failure, on each operation.
- One line per successful operation, covering the mutation and its event together.
- For a bug fix, the behavior that is currently broken, phrased so that the test would fail today.

3. Write the list, following the guidelines below.

<example>

## Behaviors to cover

- `POST /orders` rejects an unauthenticated request.
- `POST /orders` rejects invalid input: non-UUID `productId`, empty `items`, negative quantity.
- `POST /orders` returns `orders.productNotFound` when a referenced product does not exist.
- `POST /orders` creates the order and emits `orderCreated`.
- `POST /orders/{id}/cancel` returns `orders.notCancellable` for an order that already shipped.
- `POST /orders/{id}/cancel` moves `pending → cancelled` and emits `orderCancelled`.
- `handlePaymentSettled` moves `pending → paid` and emits `orderPaid`.
- `handlePaymentSettled` is idempotent: a second delivery of the same event changes nothing.
- `handlePaymentSettled` acknowledges (does not retry) an event for an unknown order, and logs it.
- A user cannot read another user's order document in Firestore.

</example>

</instructions>

<output>

A `## Behaviors to cover` section in the feature's design document, in the work directory at `domains/<domain>/work/<feature-slug>/`.

One line per behavior, phrased as an observable outcome. No code, no test file names, no `describe`/`it` blocks, no setup hints. The list exists so a human can read it in under a minute and notice what is missing.

</output>

<validation>

1. Every error response declared in the HTTP API contracts has a line.
2. Every entity state transition has a line, including the event it emits.
3. Every operation has an authentication line, and an authorization line where roles or ownership apply.
4. Every trigger has a line for its successful path, and a line for its behavior on a duplicate delivery.
5. For a bug fix, there is a line describing the behavior that is broken today.
6. Every line is an observable outcome, not an implementation detail.
7. The list contains no test file names, no code, and no test structure.

</validation>

# Guidelines

## What belongs on the list

Behaviors that are observable at the boundary of the service: an HTTP response, an entity mutation, a published event, a log the service is expected to emit, a document a client can or cannot read.

## What does not belong on the list

- **How** a behavior will be tested: fixtures, file names, mocking, structure. That is decided when the code is written.
- Internal logic with no contract-level expression. A complex pricing calculation deserves direct tests, but it cannot be listed here because it does not exist yet, and the decision to test it directly depends on the shape it takes. That call is made while writing the code, and audited during review.
- Coverage of code paths that no contract and no requirement asks for.

## Level

Most behaviors on the list are covered at the contract level, by testing the HTTP API or the event handlers. That is the default and it does not need stating.

Direct unit tests are the exception, warranted for logic that contract-level tests reach only incidentally. That decision belongs to whoever writes the code, since the logic does not exist yet — but the shapes that usually warrant one are worth knowing in advance:

- Pure computation with no I/O.
- Combinatorics that would be absurd to cover at the contract level: a dozen input combinations are trivial as unit cases and unreasonable as a dozen API calls.
- Money, date, timezone, and rounding arithmetic.
- Retry, backoff, and idempotency-key logic.
- State transition tables.

## Grouping

Group variations of the same outcome onto one line rather than enumerating them: "rejects invalid input: non-UUID `productId`, empty `items`, negative quantity" is one behavior with three cases, not three behaviors.

## Scope

- Keep the successful-operation lines few. An entity mutation and the event it emits are one behavior, verified together.
- Do not list behavior of generated code: models, DTOs, and testing utilities in `src/model/*` are generated and are not the feature's responsibility.
