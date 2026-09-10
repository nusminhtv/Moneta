## MODIFIED Requirements

### Requirement: The database is opened once

The application SHALL open **two** databases: a *control* database, always the
same file, and an *active data* database chosen by the demo setting. Each SHALL
use a single connection per process, opened lazily and closed deterministically.

At most one **demo** connection SHALL be open at a time, and switching away from
the demo database SHALL close it before serving a read or write against the
other.

The control connection SHALL NOT be closed by a switch, in either direction.
When demo mode is off the control database *is* the active data database, so
"close the connection you replace" would close the connection holding the
setting that decides which database is active — and the store answering the next
read of that setting. The rule is therefore about the demo connection
specifically, not about whichever connection was previously active.

The control database exists because the setting that chooses the data database
cannot live inside the file it chooses. When demo mode is off, the control
database and the active data database are the same file, and the single
connection is shared rather than opened twice.

#### Scenario: Concurrent first access
- **WHEN** two callers request the database before it has finished opening
- **THEN** both receive the same connection and the open work happens once

#### Scenario: Leaving demo mode closes the demo connection
- **WHEN** the demo setting changes from on to off
- **THEN** the demo connection is closed
- **AND** no subsequent read or write is served against it

#### Scenario: A switch never closes the control connection
- **WHEN** the demo setting changes in either direction
- **THEN** the control connection is still open
- **AND** a preference read immediately afterwards is served without reopening
  the file

Entering demo mode replaces the control database *as the active one*, and the
control connection stays open regardless — closing it would take the settings
store down with it, and the very next thing that happens after the toggle is a
read of the setting the toggle just wrote.

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
