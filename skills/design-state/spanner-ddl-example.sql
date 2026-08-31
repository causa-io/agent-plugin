-- Example DDL file, as it would be written to
-- `domains/<domain>/spanner/0002-create-my-entity-table.sql`, for the entity
-- defined in the `design-model` skill's `entity-example.yaml`.

CREATE TABLE MyEntity (
  id STRING(36) NOT NULL,
  createdAt TIMESTAMP NOT NULL,
  updatedAt TIMESTAMP NOT NULL,
  deletedAt TIMESTAMP,
  prop1 INT64 NOT NULL,
  nullableProp STRING(MAX),
  nestedProp JSON NOT NULL,
  nullableNestedProp JSON,
  newPropertyAfterInitialRelease BOOL,
) PRIMARY KEY (id),
ROW DELETION POLICY (OLDER_THAN(deletedAt, INTERVAL 1 DAY));

CREATE INDEX MyEntitiesByProp1 ON MyEntity (prop1) STORING (deletedAt)
