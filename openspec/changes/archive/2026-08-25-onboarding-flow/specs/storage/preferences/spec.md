## Purpose

Durable storage for small values that belong to no single feature, added so the
introduction can be shown once.

## ADDED Requirements

### Requirement: A settings table

The database SHALL provide a `settings(key TEXT PRIMARY KEY, value TEXT NOT
NULL)` table, added by migration `v2`, for small durable values that belong to no
single feature.

#### Scenario: An existing database is upgraded
- **WHEN** a database created at v1 is opened by an app expecting v2
- **THEN** the `settings` table is created
- **AND** every existing row is preserved

#### Scenario: A first-run database
- **WHEN** a database is created from nothing
- **THEN** it is at v2 with both tables present and `settings` empty

### Requirement: Typed preference access

Preferences SHALL be read and written through a typed accessor returning
`Result<T>`, keyed by a value in a single declared enum.

A stored value that does not parse SHALL be reported as a storage failure naming
the key. It SHALL NOT be silently treated as absent or as `false`.

#### Scenario: A boolean round-trips across a restart
- **WHEN** a boolean is written, the database is closed and reopened
- **THEN** reading it returns the value written

#### Scenario: Absence and false are distinguishable
- **WHEN** a key has never been written
- **THEN** the read reports absence, not `false`

#### Scenario: A malformed stored value
- **WHEN** a stored value is neither `'true'` nor `'false'`
- **THEN** the read returns a storage failure naming the key

A silent `false` here would either re-show the introduction forever or hide it
forever, depending on which way the default fell, and would look like a UI bug.

#### Scenario: The store cannot be built
- **WHEN** the database cannot be opened
- **THEN** callers that only read fall back to their safe default
- **AND** callers that write SHALL NOT let the failure escape into navigation

The last clause is a defect this change shipped and then fixed. Completing the
introduction awaited a store that throws when the database cannot open, inside an
async navigation callback — so the exception escaped, `context.go` never ran, and
the user was left on the last slide with nothing happening. The test named
`a failed write does not crash the caller` closed the database while keeping the
store object, so the write returned `Err` and the test passed. It read as
coverage of this case and was not.
