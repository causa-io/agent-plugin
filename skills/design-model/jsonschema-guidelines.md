# Global JSONSchema guidelines

- End all files with a new line.
- Always define a `title` for objects and enums.
- Use `PascalCase` for object and enum names. Use `camelCase` for property names and enum values. Use `kebab-case.yaml` for file names.
- The root schema should correspond to the name of the file, in PascalCase. For example, the schema in `my-entity.yaml` should be named `MyEntity`.
- Always provide a `description` for objects and their properties. For enums, provide a description for each value in the enum.
- To make a property nullable, use a `oneOf` with `null` and the actual type.
- Date-time properties should use `type: string` with `format: date-time`.
- UUID properties should use `type: string` with `format: uuid`.
- Use `additionalProperties: false` for objects, unless there is a specific reason not to.
- When creating a new schema, make all properties `required` unless there is a specific reason not to.
- When updating an existing schema, add properties as optional (not in `required`), unless introducing a breaking change is explicitly authorized in the current context.
- Store nested or reusable schemas under `$defs`. These should also follow the naming conventions, i.e. `PascalCase` for both the schema name and the title.
- To reference a nested or reusable schema:
  - For a non-array property, always use `$ref` inside a `oneOf`. Never use `$ref` directly in a property. Include a `type: null` in the `oneOf` only if necessary.
  - For an array property, use `items` with `$ref`. Only use `oneOf` inside `items` if elements are nullable.
- Use `$ref` to reference other schemas, either in the same file or in other files.
- Only use string values for enums.
- Use `const` for string properties that must have a single specific value (e.g. in constraints).
