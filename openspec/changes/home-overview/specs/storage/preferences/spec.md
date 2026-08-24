## Purpose

Defines durable storage for small values that belong to no single feature — a
display preference, a last-selected filter — and what is guaranteed about reading
them, writing them, and asking for one that was never set.

## ADDED Requirements

### Requirement: A written preference is readable and durable

The store SHALL return the value most recently written for a key, and that value
SHALL survive the application closing and reopening.

#### Scenario: Write then read
- **WHEN** a value is written for a key and then read
- **THEN** the value read equals the value written

#### Scenario: Overwriting
- **WHEN** a key is written twice
- **THEN** reading returns the second value

#### Scenario: Durability
- **WHEN** a value is written, the database is closed, and a new connection is
  opened against the same file
- **THEN** the value is still present

### Requirement: An absent key is absent, not false

Reading a key that was never written SHALL report absence, distinguishably from
any value that key could legitimately hold.

#### Scenario: Reading a key that was never set
- **WHEN** a key with no stored value is read
- **THEN** the result reports that nothing is stored
- **AND** it is not reported as a stored default, because "the user has never
  chosen" and "the user chose the default" are different facts

#### Scenario: A caller supplying its own default
- **WHEN** a caller reads an absent key with a fallback
- **THEN** it receives the fallback
- **AND** the store still does not record anything for that key

### Requirement: A stored value that cannot be interpreted is a failure

Reading a value that does not parse as the requested type SHALL report a storage
failure rather than a default.

#### Scenario: A malformed boolean
- **WHEN** a key holds text that is neither of the two stored boolean forms
- **THEN** reading it as a boolean reports a storage failure
- **AND** it does not silently read as false

### Requirement: Storage failures are reported, never swallowed

Every operation SHALL report failure as a storage failure carrying a message,
and SHALL NOT report success or a default value on failure.

#### Scenario: A read fails
- **WHEN** the underlying query throws
- **THEN** the caller receives a storage failure

#### Scenario: A write fails
- **WHEN** the underlying write throws
- **THEN** the caller receives a storage failure
- **AND** the previously stored value, if any, is unchanged

### Requirement: Keys are declared, not spelled at call sites

Preference keys SHALL be declared in one place so a typo cannot silently create a
second, permanently-empty setting.

#### Scenario: Enumerating the keys
- **WHEN** the declared keys are enumerated
- **THEN** every key the application reads or writes is among them
- **AND** no two declared keys share a stored name
