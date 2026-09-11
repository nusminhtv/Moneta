## ADDED Requirements

### Requirement: A profile has a first name, and it is the first word

`Profile` SHALL expose a first name: the first whitespace-separated word of the
name, with non-letter characters removed, or empty when the name yields no
letters.

**The first word, not the last.** A string cannot say whether it is written
given-name-first (`Minh Tran`) or surname-first (`Trần Văn Minh`), and either
rule greets somebody by their surname. This one is chosen deliberately and
recorded, rather than detected per name — which would make the greeting
unpredictable.

#### Scenario: The first word of a multi-word name
- **WHEN** the name is `Minh Tran`
- **THEN** the first name is `Minh`
- **AND** for `Trần Văn Minh` it is `Trần` — the surname, which is the stated
  cost of this rule

#### Scenario: Diacritics are letters
- **WHEN** the name is `Đặng Thu Thảo`
- **THEN** the first name is `Đặng`, unchanged and unstripped

#### Scenario: A single word is its own first name
- **WHEN** the name is `Minh`
- **THEN** the first name is `Minh`

#### Scenario: Punctuation and extra spaces do not survive
- **WHEN** the name is `  Minh   Tran  ` or `Minh, Tran`
- **THEN** the first name is `Minh`

#### Scenario: A name with no letters has no first name
- **WHEN** the name is `👨‍👩‍👧`, `123` or whitespace only
- **THEN** the first name is empty, because there is nothing to greet

### Requirement: Home greets by name when it has one

Home's app bar SHALL greet the stored profile's first name, and SHALL fall back
to its existing greeting when there is no name to use.

The greeting SHALL be computed **once** and shown by every Home state. The
constant it replaces existed for that reason: annotation `52:630` requires the
bar to be identical while loading and once loaded, and two sources would be
free to drift apart.

#### Scenario: A stored profile is greeted
- **WHEN** the profile's name is `Minh Tran`
- **THEN** Home's app bar reads `Hi Minh`

#### Scenario: First run greets a stranger
- **WHEN** no profile is stored
- **THEN** Home's app bar reads `Hi there`, which is what it says today

#### Scenario: A name with no letters falls back
- **WHEN** the stored name yields no first name
- **THEN** Home's app bar reads `Hi there` rather than `Hi ` with nothing after
  it

#### Scenario: Every Home state shows the same greeting
- **WHEN** Home is loading, loaded, and in its error state
- **THEN** all three show the identical greeting, asserted across the three
  rather than in one of them
