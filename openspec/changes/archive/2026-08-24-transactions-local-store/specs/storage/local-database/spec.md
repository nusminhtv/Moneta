## Purpose

Defines how Moneta's on-device database is opened, versioned and migrated, and
how storage failures are reported, so that a user's financial history survives
upgrades and a corrupt read never silently reads as an empty wallet.

## ADDED Requirements

### Requirement: The database is versioned and migrated forward explicitly

The application SHALL open its database at a declared schema version and SHALL
apply every migration between the stored version and the declared version, in
order, before any read or write is served.

#### Scenario: First run on a device with no database
- **WHEN** the application opens the database and no file exists
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

### Requirement: Storage failures are reported, never swallowed

Every database operation SHALL report failure as a storage failure carrying a
message. It SHALL NOT return an empty result to indicate an error.

#### Scenario: A read fails
- **WHEN** a query throws
- **THEN** the caller receives a storage failure
- **AND** it does not receive an empty list, which would read as "no
  transactions" and be indistinguishable from an empty wallet

#### Scenario: A write fails
- **WHEN** an insert or delete throws
- **THEN** the caller receives a storage failure
- **AND** the database is left unchanged by that operation

### Requirement: Writes are durable across restarts

Data written and acknowledged SHALL be present after the application is closed
and reopened.

#### Scenario: A record survives a restart
- **WHEN** a record is written, the database is closed, and a new connection is
  opened against the same file
- **THEN** the record is present and identical

### Requirement: The database is opened once

The application SHALL use a single database connection per process, opened
lazily and closed deterministically.

#### Scenario: Concurrent first access
- **WHEN** two callers request the database before it has finished opening
- **THEN** both receive the same connection and the open work happens once
