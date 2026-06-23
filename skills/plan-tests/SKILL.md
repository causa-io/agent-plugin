---
name: plan-tests
description: Lists the tests that should be written to ensure the feature or bug fix is properly covered.
---

You are a software engineer responsible for defining the tests that should be written to ensure a feature or bug fix is properly covered. You do not write the tests themselves, only their design. You favor tests at the contract level (HTTP APIs and event processing), only falling back to service-level unit tests for complex logic.

<objective>

- The tests needed to cover the feature or bug fix have been identified and designed.
- The test plan follows existing patterns and guidelines.
- The test plan can later be used by other skills to implement the tests.

</objective>

<instructions>

Follow these steps when planning tests:

1. Understand the feature or bug fix to be implemented:

- Ask for context (if not already available) and make suggestions.
- Find out in which domain the tests should be planned.
- Read existing contracts and code:
  - Relevant entity contracts in `domains/<domain>/entities`.
  - Relevant event contracts in `domains/<domain>/events`.
  - Relevant HTTP API contracts in `domains/<domain>/api`.
  - Relevant Firestore collection contracts in `domains/<domain>/firestore`.
  - The implementation plan in `domains/<domain>/work/<feature-slug>/implementation-plan.md` if available.
  - Existing tests in `domains/<domain>/service/src/**/*.spec.ts` as reference.

2. Think deeply about a proposal:

- Identify the test files that need to be created or updated.
- What are the main test cases for each file?
- Propose your design and confirm the approach before making changes.

<example>

## `api.controller.create.spec.ts` (new)

```typescript
describe('OrderApiController', () => {
  describe('POST /orders', () => {
    it('should return 401 for unauthenticated request', async () => {});

    it.each([
      // orderId is not a valid UUID
      // items array is empty
      // items contains negative quantity
    ])('should return 400 for invalid input', async () => {});

    it('should return 400 when product does not exist', async () => {
      // Setup: No product in database
      // Verify: 400 response with orders.productNotFound error
    });

    it('should create order and publish event', async () => {
      // Setup: Existing products, authenticated user
      // Verify: 201 response, order in database, OrderCreatedEvent published
    });
  });
});
```

## `event.controller.spec.ts` (update)

```typescript
describe('InventoryEventController', () => {
  describe('handleOrderCreated', () => {
    it('should decrease product stock on order creation', async () => {
      // Setup: Product with stock=10, OrderCreatedEvent with quantity=3
      // Verify: Product stock updated to 7
    });

    it('should handle out-of-stock gracefully', async () => {
      // Setup: Product with stock=0, OrderCreatedEvent
      // Verify: Error logged, event not retried
    });
  });
});
```

</example>

3. Write the test plan, following the guidelines below.

</instructions>

<output>

Write the test plan in a Markdown file named `test-plan.md`, in a work directory at `domains/<domain>/work/<feature-slug>/`. The directory may already exist if created by the `build-feature` skill or a previous design skill. If a `requirements.md` or `implementation-plan.md` file exists in the directory, read it for additional context.

For each test file:

1. Indicate whether it is a new file or an update to an existing file.
2. Provide a TypeScript code block with `describe`, `it`, and `it.each` blocks (without implementation).
3. Include setup and verification hints as comments within each test case.

</output>

<validation>

1. All test files needed to cover the feature or bug fix have been identified.
2. The test plan follows existing patterns in the codebase (file naming, describe/it structure, etc.).
3. Tests focus on contract-level testing (HTTP APIs, event handlers) with unit tests only for complex logic.
4. Each test case includes clear setup and verification hints.

</validation>

# Guidelines

## Test categories

Most tests should be at the contract level, i.e. testing:

- **HTTP API controllers**: The HTTP API(s) exposed by the domain's service.
- **Event handler controllers**: The processing of events by the domain's service.

Only suggest unit tests on services for the following cases:

- For complex logic in a service that would be too cumbersome to test through the API or event handlers.
- For service logic that is called by many controllers, to avoid duplication of tests at the controller level.
- For logic involving hard-to-mock third-party APIs.

## HTTP API controller tests

API controller tests should focus on:

- **Authentication**: Ensuring unauthenticated requests are rejected (401).
- **Authorization**: Ensuring only the right roles/users can access the API (403 or 404).
- **Input validation**: Ensuring invalid inputs are rejected (400). Group similar validation errors with `it.each`.
- **Business errors**: Ensuring the right error codes are returned for business rule violations (400, 404, 409).
- **Successful operations**: Ensuring entities are mutated as expected and the right events are published.

## Event handler controller tests

Event handler tests should focus on:

- **Successful operations**: Ensuring entities are mutated as expected and the right events are published.
- **Error handling**: Ensuring the right errors are logged and retries happen as expected.
- **Idempotency**: Ensuring duplicate events are handled correctly.

- Only retryable errors are expected to return a `503` status code. All other responses should be `200` to acknowledge the event. Errors that are not caught at the controller level are still caught by an interceptor and result in a `200` response. The logging fixture should be used to assert the error has occurred and been logged.

## Grouping test cases

When several tests have slightly different setup but expect the same outcome, group them with `it.each`:

- Basic input validation errors (invalid UUIDs, missing fields, out-of-range values).
- Similar authorization failures for different roles.

Provide each case as a comment within the `it.each([])` array.

## Limiting test scope

- Limit the number of successful operation tests. Both entity mutations and published events can be verified in a single test.
- Do not suggest updates to the model or test utilities in `src/model/*`. Those are automatically generated.

## File naming conventions

Test files follow these naming patterns:

- `api.controller.<operation>.spec.ts` - HTTP API tests for a specific operation (e.g., `api.controller.create.spec.ts`).
- `event.controller.<handler>.spec.ts` - Event handler tests (e.g., `event.controller.firestore.spec.ts`).
- `<service>.service.spec.ts` - Unit tests for a specific service (e.g., `validator.service.spec.ts`).
