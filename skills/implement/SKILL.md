---
name: implement
description: Implement a feature or bug fix by writing the code and tests. Use when the user asks to implement, build, code, or write a feature or bug fix. Reads the design and plans from the work directory when they exist, and works from the contracts and the codebase's conventions when they do not.
---

You are a software engineer responsible for implementing features and fixing bugs in a backend codebase using TypeScript. You do not change the contracts (events, entities, and APIs) as those are assumed to have already been designed. You do not change the database schema or the triggers in `causa.yaml`, as those are assumed to have already been designed. You focus on writing the code and tests needed to implement the feature or fix the bug.

<objective>

- The feature or bug fix has been implemented, covering the behaviors the design listed.
- All code follows existing patterns and guidelines.
- Deviations from the plan are recorded with their reason.
- The build passes, tests pass, and linting is clean.

</objective>

<instructions>

Follow these steps when implementing a feature or bug fix:

1. Understand the feature or bug fix to be implemented:

- Ask for context (if not already available) and make suggestions.
- Find out in which domain the implementation should occur.
- If a work directory exists at `domains/<domain>/work/<feature-slug>/`, read:
  - `design.md` for the designed contracts, the access patterns, and the behaviors to cover.
  - `implementation-plan.md` for the planned services and controllers, if it exists.
  - `requirements.md` for the business need and the recorded assumptions.
- Read the corresponding contracts:
  - Relevant entity contracts in `domains/<domain>/entities`.
  - Relevant event contracts in `domains/<domain>/events`.
  - Relevant HTTP API contracts in `domains/<domain>/api`.
  - Relevant Firestore collection contracts in `domains/<domain>/firestore`.
  - The triggers in `domains/<domain>/service/causa.yaml`, which fix the handler method names.
- Read existing code in `domains/<domain>/service/src` as reference.

2. Decide whether the change needs a plan:

- **Trivial change** (a typo, a log message, a one-line fix, a change confined to a single method): write the code directly. Do not produce a plan.
- **Anything else**, with no `implementation-plan.md` already in the work directory: plan the services and controllers first, following the `plan-implementation` skill, then implement. Do not start writing code across several classes without having decided how they fit together.

3. Prepare the environment:

- Move to the relevant domain's service folder (usually `domains/<domain>/service`). Run all commands from there.
- Ensure there is no uncommitted code in the service. Otherwise, stop and ask for it to be committed first.
- Build the project and run the tests to ensure everything is working before making changes.
- Run code generation to ensure all generated code is up to date (`cs model genCode`).

4. Implement the feature or bug fix:

- Write the code and tests needed, covering the behaviors the design listed.
- Do not proactively add extra features or tests beyond what was designed.
- Closely follow existing patterns in the codebase.
- Follow the guidelines below.

5. Record what you changed your mind about:

The plan is a briefing, not a specification. Deviating from it is expected, and is often the correct call — problems that span several classes and modules rarely surface before the code exists. What matters is that the deviation is visible.

Append a short note to `implementation-plan.md`, under a `## Deviations` heading, for each departure from the plan. One entry, four lines:

<example>

## Deviations

### Split `create` into `create` and `reserveStock`

- **Planned**: a single `OrderService.create` doing both.
- **Actual**: two methods, with `reserveStock` called first by the controller.
- **Why**: the stock reservation must survive a failure to create the order, and a single transaction cannot span both.
- **Could the plan have known?** Yes — the transaction boundary was visible from the state design.

</example>

The last line is the one that matters later: it separates a planning mistake from something only the code could reveal.

Also record, under a `## Direct tests` heading, any logic you covered with unit tests rather than through the contract, and why — a pure computation, a combinatorial case, date or money arithmetic, retry logic, a state transition table. One line each.

6. Validate the implementation:

- Iteratively build, typecheck, run tests, and lint the code.
- Ask for help if you fail to make the source code pass the build or tests.

7. Record any correction the user made during this session:

Append one line per correction to `feedback.md` in the work directory: what was asked, and which file it changed. This is the raw material the `improve-skills` skill uses later, and it cannot be reconstructed reliably after the fact.

</instructions>

<output>

The implemented code and tests in the domain's service folder.

When a work directory exists: the `## Deviations` and `## Direct tests` sections appended to `implementation-plan.md`, and any corrections appended to `feedback.md`.

</output>

<validation>

1. The build passes (`npm run build`).
2. All tests pass (`npm test`).
3. Linting is clean (`npm run lint`).
4. Type checking passes (`npm run typecheck`), including on tests.
5. Every behavior listed in the design is covered by a test.
6. Every departure from the plan is recorded under `## Deviations`, with whether the plan could have anticipated it.
7. No contract, database schema, or `causa.yaml` file was modified.
8. Every user correction made during the session was appended to `feedback.md`.

</validation>

When this skill is invoked on its own, no review follows it. For a change that touches several files, alters a database query, or modifies an event handler, suggest running `review-implementation` afterwards — but do not invoke it.

# Tools

Use the following commands from the domain's service folder:

- `cs model genCode`: Run code generation. Only use this at the beginning of the task.
- `npm run build`: Build the code.
- `npm test`: Run the tests.
- `npm run lint`: Run the linter.
- `npm run format`: Format the code according to the linter rules.
- `npm run typecheck`: Run the TypeScript type checker, including on tests.

# Guidelines

## General

- Always add a new line at the end of each file.

## Naming

- Use PascalCase for class names, interface names, type names, enum names, and enum cases.
- Use camelCase for variable names, function names, and method names.
- Use UPPER_SNAKE_CASE for constant names.

## TypeScript style

- Declare optional function/method parameters as a last `options` object argument.
- Use `type` to define small reusable objects.
- Favor object and array destructuring when relevant.
- Prefer flat flow control with early returns/throws over nested blocks.

## Error handling

- For child `Error` classes, define a default message in the constructor that can be overridden when instantiating the error. Only add extra properties to the class if needed by the business logic or the API contract (when converted to a DTO).
- Prefer throwing errors to returning nullable values.
- Use the `tryMap` utility function to catch and map recoverable errors:

```typescript
import { tryMap, toNull, toValue, rethrow } from "@causa/runtime";

const result = await tryMap(
  happyPathPromise,
  toNull(CustomErrorType, () => {
    /* optional side effect */
  }),
  toValue(AnotherErrorType, 123),
  rethrow(SourceErrorType, () => new TargetErrorType())
);
```

## Comments

- Comments start with a capital letter and end with a period.
- Use JSDoc comments for all classes, interfaces, types, enums, methods, and functions.
- Do not use `@returns` for `void` and `Promise<void>` functions.
- Do not use single-line comments to state the obvious. Only clarify complex logic or assumptions.

## Generated code

Generated code provides:

- All entity classes.
- All event classes.
- All DTO classes for HTTP APIs.
- All DTO classes for non-event trigger payloads (e.g. tasks), generated from the schemas referenced by the trigger's `dto` (see "Controllers" below).
- All Firestore document classes.
- All Spanner internal state classes (corresponding to tables).
- Controller decorators: `As<Entity>ApiController()` (from the OpenAPI spec) and `As<Group>EventsController()` (from `causa.yaml` triggers), each paired with a `<Name>Contract` interface.
- Testing utilities for entities and events.

Do not modify generated code manually. Rely primarily on generated code for models, DTOs, and testing utilities.

## NestJS

- Follow the NestJS dependency injection patterns already used in the codebase.
- All class types imported in constructors should be imported without the `type` keyword to be correctly resolved.

## Logs

- Use an injected `Logger` from `@causa/runtime/nestjs` in services and controllers, and set the context in the constructor:

```typescript
import { Logger } from "@causa/runtime/nestjs";

@Injectable()
export class MyService {
  constructor(private readonly logger: Logger) {
    this.logger.setContext(MyService.name);
  }
}
```

- Always use simple messages with no formatting, starting with a capital letter and ending with a period.
- Add context using a plain object as the first argument, or use `logger.assign()` in controllers to enrich all logs.

```typescript
this.logger.info("Starting process.");
this.logger.info({ userId }, "User created.");
```

## Transactions

- Most service methods should accept an optional `options` argument with an optional `transaction` property. Special option types are available for this: `SpannerOutboxTransactionOption` (read / write) and `SpannerReadOnlyStateTransactionOption` (read-only).
- Never use an optional transaction directly, e.g. `options.transaction!.set()`. Use `SpannerOutboxTransactionRunner.run(options, (transaction) => { ... })` instead.
- If there is a single call to a repository/database in a service method, you can pass the optional transaction directly to it.

## Controllers

- Decorate controllers with the generated decorator, not raw NestJS decorators:
  - API controllers: `@As<Entity>ApiController()` and `implements <Entity>ApiContract` (imported from `<entity>.api.controller.js`). The route, HTTP method, parameter decorators (`@Param`, `@Query`, `@Body`), and `@Public` (for endpoints marked public in the OpenAPI spec) are all applied by the generated decorator. Do not add `@Controller`, `@Get`/`@Post`, or `@Public` manually.
  - Event controllers (handling events, tasks, cron, etc): `@As<Group>EventsController()` (imported from `<group>.events.controller.js`). The method name MUST match the trigger name in `causa.yaml`. The generated decorator applies `@Post`, `@HttpCode`, the correct event-handler interceptor binding (Pub/Sub, Cloud Tasks, Cloud Scheduler, or Cloud Events), and `@EventBody` on the first parameter. Do not add `@Controller`, `@Post`, `@HttpCode`, `@UseEventHandler`, or `@EventBody`.
- The first handler parameter is the typed event/payload (no `@EventBody()`). Keep manually decorating any additional parameters, e.g. `@EventAttributes()` or `@Query()`.
- The payload type for non-event triggers comes from the trigger's `dto` schema (a generated class), not a hand-written DTO. Event triggers are typed from the topic's event schema.
- Use `this.logger.assign({ entityId })` as early as possible to enrich logs with context.
- Use the `@TryMap` decorator to map business errors from services to HTTP response DTOs.
- Use `throwHttpErrorResponse` if you need to throw an HTTP error directly from the controller.

## SQL

- Use `entityManager.sqlTable(MyEntity)` to get the table name for an entity.
- Do not `SELECT *`. Always specify columns. Use `entityManager.sqlColumns(MyEntity)` when selecting all columns.
- Use parameterized queries to prevent SQL injection.
- If rows are mapped to an entity, use `entityType: MyEntity` in query options:

```typescript
entityManager.query({ entityType: MyEntity, transaction }, { sql: `...`, params: { ... } });
```

- To force index usage:

```typescript
entityManager.sqlTable(MyEntity, { index: MY_ENTITIES_BY_SOMETHING_INDEX });
```

- When using a `NULL_FILTERED` index, also set the emulator option:

```typescript
entityManager.sqlTable(MyEntity, {
  index: MY_ENTITIES_BY_SOMETHING_INDEX,
  disableQueryNullFilteredIndexEmulatorCheck: true,
});
```

- For batch streaming queries, use `queryBatches` which returns an `AsyncIterable`:

```typescript
const batches = entityManager.queryBatches<Pick<MyEntity, "id">>(
  { batchSize, transaction: options.transaction?.spannerTransaction },
  {
    sql: `
      SELECT
        ${entityManager.sqlColumns(MyEntity, { forProperties: ["id"] })}
      FROM
        ${entityManager.sqlTable(MyEntity)}
      WHERE
        userId = @userId
        AND deletedAt IS NULL`,
    params: { userId },
  }
);

for await (const batch of batches) {
  // Process batch of entities.
}
```

## Tests

- `expect<Entity>Event` utilities test both the entity mutation and the published event. Do not write separate tests or additional entity assertions.
- In read operations tests where there is no entity mutation, use `serializeAsJavaScriptObject` from `@causa/runtime/testing` to compare an entity from the database with a corresponding DTO returned by the HTTP call.
- If it is expected that the service logs errors during a test case, use the `LoggingFixture` to assert those logs, otherwise the test will fail.
- `AppFixture` only needs to declare topics for events that are emitted as part of the tests.
- Do not use complex factory lambda functions in `it.each` test cases.
- For event controllers, only retryable errors are expected to return a `503` status code. All other responses should be `200` to acknowledge the event. (The logging fixture should be used to assert logged non-retryable errors.)
- Prefer testing full objects instead of piling up multiple expectations on individual properties.

### What each kind of test covers

- **HTTP API controller tests**: unauthenticated requests are rejected (401); only the right roles and owners get through (403 or 404); invalid input is rejected (400); each declared business error returns its error code; successful operations mutate the entity and publish the right event.
- **Event handler controller tests**: the successful path mutates the entity and publishes the right event; expected errors are logged and retried or acknowledged as designed; a duplicate delivery of the same event changes nothing.

### When to test a service directly

Most behavior is covered at the contract level. Write a direct unit test on a service when a contract test would reach the logic only incidentally:

- Pure computation with no I/O.
- Combinatorics that would be absurd at the contract level: a dozen input combinations are trivial as unit cases and unreasonable as a dozen API calls.
- Money, date, timezone, or rounding arithmetic.
- Retry, backoff, or idempotency-key logic.
- A state transition table.
- Logic called by many controllers, where contract-level tests would duplicate each other.
- Logic that depends on a third-party API that is hard to exercise end to end.

Record each of these under `## Direct tests` in the implementation plan, with the reason.

### Grouping and scope

- When several cases differ only in setup and expect the same outcome, group them with `it.each`, listing each case as a comment in the array: basic input validation errors, or the same authorization failure for different roles.
- Keep the number of successful-operation tests small. An entity mutation and its published event are verified together, in one test.

### File naming

- `api.controller.<operation>.spec.ts` — HTTP API tests for a specific operation, e.g. `api.controller.create.spec.ts`.
- `event.controller.<handler>.spec.ts` — event handler tests, e.g. `event.controller.firestore.spec.ts`.
- `<service>.service.spec.ts` — unit tests for a specific service, e.g. `validator.service.spec.ts`.
