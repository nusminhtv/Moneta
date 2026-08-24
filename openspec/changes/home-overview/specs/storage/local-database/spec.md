## ADDED Requirements

### Requirement: A migration applied to a populated database preserves its rows

Applying a migration to a database that already contains user data SHALL leave
that data readable and unchanged, except where the migration's own purpose is to
change it.

#### Scenario: Upgrading a database with rows in it
- **WHEN** rows are written under schema version N, and the application then
  opens the same file declaring version N+1
- **THEN** the migration is applied
- **AND** every row written under version N is still present and unchanged

#### Scenario: A column added by a migration
- **WHEN** a migration adds a column to a table that already has rows
- **THEN** existing rows gain the column with its default
- **AND** no existing column's values are altered

#### Scenario: A new table added alongside existing data
- **WHEN** a migration creates a table that did not exist
- **THEN** the new table is empty and usable
- **AND** the tables that already existed are untouched

#### Scenario: A migration that fails on populated data
- **WHEN** a migration throws while upgrading a database containing rows
- **THEN** a storage failure is reported
- **AND** the stored schema version is not advanced
- **AND** the pre-existing rows are still readable at the old version
