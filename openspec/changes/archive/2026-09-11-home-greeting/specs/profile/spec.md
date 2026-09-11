## ADDED Requirements

### Requirement: A profile has a first name, and it is the first word

`Profile` SHALL expose a first name: the first whitespace-separated word **that
contains letters**, with its non-letter characters removed, or empty when the
whole name yields no letters.

**The first word, not the last.** A string cannot say whether it is written
given-name-first (`Minh Tran`) or surname-first (`Trần Văn Minh`), and either
rule greets somebody by their surname. This one is chosen deliberately and
recorded, rather than detected per name — which would make the greeting
unpredictable.

**The first word *with letters*, not simply the first word.** `123 Minh` is a
person called Minh with a house number in front; greeting them as a stranger
because of it is worse than skipping the number. Words are skipped, never
joined: `J. R. Minh` greets `J`, because `J` is a word with a letter in it.

**A letter is `\p{L}` or `\p{M}`, not `[A-Za-z À-ỹ]`.** The narrow range was the first
draft and it is wrong in both directions: `李小龙` and `김수현` contain no
character inside it, so a Chinese or Korean name would be greeted as a stranger
permanently, while `×` and `÷` (U+00D7, U+00F7) sit inside it and would be
greeted as names. `MonetaAvatar.initialsOf` still carries the narrow range and
therefore the same defect; it is a design-system component with its own node
and tests, and correcting it is not in this change's scope — it is recorded in
`docs/design-system/figma-map.md` instead.

Combining marks are kept alongside letters so that decomposed input survives,
and a word must contain a letter to be picked, so that a bare mark is not a
name.

**A stated cost: `O'Brien Nguyen` is greeted `Hi OBrien`.** Stripping every
non-letter is what makes `Minh,` work, and it also removes name-internal
apostrophes and hyphens — `Anne-Marie` becomes `AnneMarie`. Treating `'` and `-`
as joiners **between** letters would fix it and is a real change to the rule,
not a detail; it is named here as a known cost rather than left for a user to
find, and is not done in this change.

#### Scenario: The first word of a multi-word name
- **WHEN** the name is `Minh Tran`
- **THEN** the first name is `Minh`
- **AND** for `Trần Văn Minh` it is `Trần` — the surname, which is the stated
  cost of this rule

#### Scenario: Diacritics are letters, however they are encoded
- **WHEN** the name is `Đặng Thu Thảo`
- **THEN** the first name is `Đặng`, unchanged and unstripped
- **AND** this SHALL hold for **decomposed (NFD)** input as well as precomposed:
  `Trần` written as `n` + U+0323 + U+0302 yields `Trần`, not `Tran`. macOS and
  several Vietnamese IMEs produce NFD, and it is indistinguishable on screen
  from NFC, so a rule that only handles NFC deletes accents for half of real
  input and looks correct in every test written from a source literal

#### Scenario: A combining mark is not itself a name
- **WHEN** the name is `\u0301` or `123\u0301`
- **THEN** the first name is empty — a word must contain a letter, not merely a
  mark, which is the cost of keeping marks attached above

#### Scenario: A single word is its own first name
- **WHEN** the name is `Minh`
- **THEN** the first name is `Minh`

#### Scenario: Punctuation and extra spaces do not survive
- **WHEN** the name is `  Minh   Tran  ` or `Minh, Tran`
- **THEN** the first name is `Minh`

#### Scenario: A name with no letters has no first name
- **WHEN** the name is `👨‍👩‍👧`, `123` or whitespace only
- **THEN** the first name is empty, because there is nothing to greet

#### Scenario: A leading word with no letters is skipped, not returned
- **WHEN** the name is `123 Minh` or `--- Minh`
- **THEN** the first name is `Minh`, not empty

#### Scenario: Letters outside the Latin range are letters
- **WHEN** the name is `李小龙`
- **THEN** the first name is `李小龙`
- **AND** for `김수현` it is `김수현`, and for `Привет Мир` it is `Привет`

#### Scenario: Symbols that look like letters are not letters
- **WHEN** the name is `× Minh`
- **THEN** the first name is `Minh` — `×` is U+00D7 MULTIPLICATION SIGN, which
  sits inside the Latin-1 range this deliberately no longer uses

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
- **WHEN** the stored profile's name is `123` — stored, so the profile exists
  and only its name is useless
- **THEN** Home's app bar reads `Hi there` rather than `Hi ` with nothing after
  it, asserted on the rendered bar and not only on the pure function

#### Scenario: Every Home state shows the same greeting
- **WHEN** Home is loading, loaded, and in its error state
- **THEN** all three show the identical greeting, asserted across the three
  rather than in one of them
