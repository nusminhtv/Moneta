## MODIFIED Requirements

### Requirement: The database is opened once

The application SHALL open **two** databases: a *control* database, always the
same file, and an *active data* database chosen by the demo setting. Each SHALL
use a single connection per process, opened lazily and closed deterministically.

At most one data database SHALL be open at a time. Switching the active data
database SHALL close the connection it replaces before serving a read or write
against the new one.

The control database exists because the setting that chooses the data database
cannot live inside the file it chooses. When demo mode is off, the control
database and the active data database are the same file, and the single
connection is shared rather than opened twice.

#### Scenario: Concurrent first access
- **WHEN** two callers request the database before it has finished opening
- **THEN** both receive the same connection and the open work happens once

#### Scenario: Switching the active database closes the old connection
- **WHEN** the demo setting changes and a different data database becomes active
- **THEN** the previously active connection is closed
- **AND** no subsequent read or write is served against it

#### Scenario: The control and data databases coincide outside demo mode
- **WHEN** demo mode is off
- **THEN** the control database and the active data database are one file and
  one connection
- **AND** the file is not opened twice

#### Scenario: The control database is never swapped
- **WHEN** the demo setting changes in either direction
- **THEN** the control database's file is the same before and after

### Requirement: The database is versioned and migrated forward explicitly

The application SHALL open **each** database at a declared schema version and
SHALL apply every migration between that database's stored version and the
declared version, in order, before any read or write is served against it.

The migration set is shared: both databases are built by the same migrations, so
the demo database cannot drift from the real one.

#### Scenario: First run on a device with no database
- **WHEN** the application opens a database and no file exists
- **THEN** every migration from version 0 to the declared version is applied in
  order
- **AND** the resulting schema is identical to that of a device that upgraded
  step by step

#### Scenario: Upgrading from an earlier version
- **WHEN** the stored schema version is lower than the declared version
- **THEN** only the migrations above the stored version are applied, in
  ascending order
- **AND** rows written before the upgrade are still readable afterwards

#### Scenario: The stored version is newer than the application
- **WHEN** the stored schema version is higher than the declared version, which
  happens when a user downgrades the app
- **THEN** the database is not opened and a storage failure is reported
- **AND** no migration is run and no data is deleted or overwritten

#### Scenario: A migration fails part way
- **WHEN** a migration throws
- **THEN** the failure is reported as a storage failure carrying the version
  that failed
- **AND** the schema version is not advanced past the failed migration

#### Scenario: Migrations are contiguous
- **WHEN** the migration set is inspected
- **THEN** it covers every version from 1 to the declared version with no gaps
  and no duplicates

#### Scenario: The demo database is migrated by the same set
- **WHEN** the demo database is created or opened
- **THEN** it is migrated by the same migration set as the real database
- **AND** its resulting schema is identical to the real database's

#### Scenario: A demo database left by an older build
- **WHEN** a demo database exists at a lower schema version than the application
- **THEN** it is migrated forward like any other database, not deleted
