# storage Specification

## Purpose
TBD - created by archiving change profile-screens. Update Purpose after archive.

## Requirements

### Requirement: PreferencesStore stores strings as well as booleans

`PreferencesStore` SHALL read and write `String` values for a
`PreferenceKey`, alongside the boolean accessors it already has, using the
same `settings` table and the same two columns. No migration SHALL be
required.

Absence SHALL be reported distinctly from a stored value: nothing stored is
`Ok(null)`, and a stored empty string is `Ok('')`. "Never chose" and "chose
nothing" are different facts, and the boolean accessors already hold this line.

#### Scenario: A string round-trips
- **WHEN** a string is written for a key and read back
- **THEN** the same string is returned

#### Scenario: Nothing stored is not an empty string
- **WHEN** a key that has never been written is read
- **THEN** `Ok(null)` is returned
- **AND** after writing `''` to that key, reading it returns `Ok('')`

#### Scenario: Writing replaces
- **WHEN** a key is written twice
- **THEN** the second value is the one read back, and only one row exists

#### Scenario: Strings a careless implementation would break
- **WHEN** a value containing a single quote, a newline, a unicode grapheme
  cluster (`👨‍👩‍👧`) and a Vietnamese diacritic (`Trần`) is written
- **THEN** it reads back byte-for-byte identical

#### Scenario: A very long value
- **WHEN** a 10,000-character value is written
- **THEN** it reads back identical and its length is exactly 10,000, because
  SQLite TEXT has no practical limit and a truncating write would corrupt a
  stored value silently

#### Scenario: A storage failure is reported, not defaulted
- **WHEN** the underlying database throws on read or on write
- **THEN** `Err(AppFailure(kind: storage))` is returned
- **AND** no exception escapes

#### Scenario: A boolean key read as a string
- **WHEN** a key written by `writeBool` is read by `readString`
- **THEN** the literal stored text (`'true'` or `'false'`) is returned rather
  than an error, because the column is TEXT and that is what is in it
- **AND** the reverse — a string key read by `readBool` — remains a storage
  failure, which is the existing behaviour and is not changed here
