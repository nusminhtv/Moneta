## MODIFIED Requirements

### Requirement: A settings table

The database SHALL provide a `settings(key TEXT PRIMARY KEY, value TEXT NOT
NULL)` table, added by migration `v2`, for small durable values that belong to no
single feature.

**Both** databases SHALL carry it, since both are built by the same migration
set. Every preference SHALL be read from and written to the *control* database,
so no preference changes value when the active data database changes.

The demo database's `settings` table SHALL therefore hold no preference. It is
not required to be empty: the demo ledger's own seed-completion marker lives
there, because it describes that database and must not claim the real ledger was
seeded. A marker is not a preference and is not reachable through the typed
preference accessor.

A setting stored in the database it selects cannot work: writing "use the demo
database" to the real database and then reading the value back from the demo
database returns whatever the demo database happens to say, which is how a
toggle undoes itself. Every preference this application has is about the person
using it rather than about the ledger — whether the introduction was finished,
whether demo mode is on — so all of them belong on the side that does not move.

#### Scenario: An existing database is upgraded
- **WHEN** a database created at v1 is opened by an app expecting v2
- **THEN** the `settings` table is created
- **AND** every existing row is preserved

#### Scenario: A first-run database
- **WHEN** a database is created from nothing
- **THEN** it is at the declared schema version with every table that version
  defines present, and `settings` empty

The previous wording said "at v2 with both tables present". That was true when
it was written and is now wrong: the declared version is 3 and there are three
tables — `transactions` (v1), `settings` (v2), `budgets` (v3). Corrected here
because this change edits this requirement, and a MODIFIED block replaces the
whole thing.

#### Scenario: No preference changes value when the database swaps
- **WHEN** the active data database changes in either direction
- **THEN** every preference reads back the value it had before the change

#### Scenario: Finishing the introduction is not undone by demo mode
- **WHEN** the introduction has been completed and demo mode is then turned on
- **THEN** the introduction is not shown again

#### Scenario: The demo database's settings table holds no preference
- **WHEN** the demo database is inspected after any amount of use
- **THEN** its `settings` table contains no row whose key is a declared
  `PreferenceKey`
- **AND** the only row it may contain is the demo ledger's seed-completion
  marker

### Requirement: Typed preference access

Preferences SHALL be read and written through a typed accessor returning
`Result<T>`, keyed by a value in a single declared enum.

A stored value that does not parse SHALL be reported as a storage failure naming
the key. It SHALL NOT be silently treated as absent or as `false`.

The accessor SHALL be constructed over the control database only, so that a new
key cannot be stored in a database the toggle swaps without changing the
accessor itself.

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

The last clause is a defect an earlier change shipped and then fixed. Completing
the introduction awaited a store that throws when the database cannot open,
inside an async navigation callback — so the exception escaped, `context.go`
never ran, and the user was left on the last slide with nothing happening. The
test named `a failed write does not crash the caller` closed the database while
keeping the store object, so the write returned `Err` and the test passed. It
read as coverage of this case and was not.

#### Scenario: The accessor cannot be pointed at a swappable database
- **WHEN** the preference accessor is constructed
- **THEN** it is bound to the control database
- **AND** no code path constructs one over the active data database
