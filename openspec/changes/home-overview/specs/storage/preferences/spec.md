## Purpose

Defines durable storage for small values that belong to no single feature — a
display preference, a last-selected filter — and what is guaranteed about reading
them, writing them, and asking for one that was never set.

Scope note: this store lives in the database the `storage/local-database`
capability already governs, so failure reporting, durability across restarts and
migration behaviour are **that** capability's requirements and are not restated
here. What follows is only what is specific to key/value preferences.

## ADDED Requirements

### Requirement: An absent key is absent, not a value

Reading a key that was never written SHALL report absence, distinguishably from
any value that key could legitimately hold.

#### Scenario: Reading a key that was never set
- **WHEN** a key with no stored value is read
- **THEN** the result reports that nothing is stored
- **AND** it is not reported as a stored default, because "the user has never
  chosen" and "the user chose the default" are different facts

#### Scenario: A caller supplying its own fallback
- **WHEN** a caller reads an absent key with a fallback
- **THEN** it receives the fallback
- **AND** nothing is written, so the key remains absent

#### Scenario: Absence survives a read
- **WHEN** an absent key is read many times
- **THEN** it stays absent

### Requirement: Booleans have exactly one stored form

A boolean preference SHALL be stored as the text `true` or the text `false`, and
no other text SHALL be accepted as either.

#### Scenario: Round trip
- **WHEN** `true` is written and read back as a boolean
- **THEN** the value is true, and the stored text is `true`

#### Scenario: A value written in another form
- **WHEN** the stored text for a boolean key is `1`, `TRUE`, `yes` or empty
- **THEN** reading it as a boolean reports a storage failure
- **AND** it does not read as false, because a preference that silently becomes
  its default when the data is corrupt is how a bug becomes invisible

#### Scenario: The failure names the key
- **WHEN** a malformed value is read
- **THEN** the failure message identifies which key and what was stored

### Requirement: Overwriting replaces, and the last write wins

Writing a key that already has a value SHALL replace it, leaving exactly one
stored value per key.

#### Scenario: Overwriting
- **WHEN** a key is written twice
- **THEN** reading returns the second value

#### Scenario: One row per key
- **WHEN** a key has been written repeatedly
- **THEN** the store holds a single entry for it

#### Scenario: Writes complete in order
- **WHEN** two writes to the same key are issued in sequence
- **THEN** the value that remains is the one written second

### Requirement: Keys are declared, not spelled at call sites

Preference keys SHALL be declared in one place so a typo cannot silently create a
second, permanently-empty setting.

#### Scenario: Enumerating the keys
- **WHEN** the declared keys are enumerated
- **THEN** every key the application reads or writes is among them

#### Scenario: Stored names are unique
- **WHEN** the declared keys' stored names are compared
- **THEN** no two are the same

#### Scenario: There is no free-text read
- **WHEN** a caller reads a preference
- **THEN** it names a declared key rather than supplying a string
