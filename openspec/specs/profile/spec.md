# profile Specification

## Purpose
The identity and category-usage behaviour behind four of page 08's remaining
screens: what the app stores about its user, what it derives from the ledger,
and — for each screen that ships less than the design draws — what it must
refuse to claim.

## Requirements

### Requirement: The stored profile is the one every screen shows

The app SHALL store a display name, an email and a main currency, and `08.01`,
`08.02` and `08.03` SHALL all read that store. None SHALL show a hard-coded
identity or a hard-coded currency.

The profile SHALL be **control-scoped**: written to and read from the control
database, which the demo toggle never swaps.

#### Scenario: First run has no profile, and says so
- **WHEN** nothing has been stored
- **THEN** the profile reads as absent — `Ok(null)`, not an empty string
- **AND** `08.01` shows `'Add your name'` and no email line, rather than a name
  nobody entered

#### Scenario: Saving on 08.02 changes what 08.01 shows
- **WHEN** the name `Trần Văn Minh` and an email are saved
- **THEN** `08.01` shows exactly those two strings
- **AND** the avatar's initials are `TM`, from that name

#### Scenario: The profile is readable while demo mode is on
- **WHEN** a profile is saved and demo mode is then turned **on**
- **THEN** the stored name is still read and still shown **while demo mode is
  active**
- **AND** this is asserted with demo mode on, not after toggling it off and
  back: once it is off, the active database and the control database are the
  same object (`app_providers.dart`), so a ledger-scoped implementation would
  pass an after-the-fact check

#### Scenario: The currency reaches 08.03
- **WHEN** the main currency is saved as `USD`
- **THEN** `08.03`'s `Main currency` row shows `USD`, not the hard-coded `VND`
  it shows today

#### Scenario: A storage failure is surfaced, not swallowed
- **WHEN** saving fails
- **THEN** `Err(AppFailure(kind: storage))` reaches the screen and the screen
  reports it
- **AND** the entered values remain on screen, because discarding a user's
  typing on a failed save loses their work

### Requirement: The email rule is one rule, in core

The address rule SHALL live in `lib/core` so that `features/auth` and
`features/settings` use the same one. `tool/check_architecture.dart` forbids a
cross-feature import, and a second rule is a rule that drifts.

#### Scenario: Behaviour is unchanged by the move
- **WHEN** the existing auth credential tests run against the moved rule
- **THEN** they pass unmodified, which is what makes this a move and not a
  rewrite

#### Scenario: The rule is deliberately permissive
- **WHEN** `user+tag@sub.domain.co.uk` is checked
- **THEN** it is accepted
- **AND** `minh.tran`, `@example.com`, `a@b`, `a b@c.com` and `''` are rejected

### Requirement: 08.02 offers three fields and validates one

`08.02` SHALL implement node `100:276` — an `Avatar`, a name field, an email
field, a currency `Select`, and a sticky primary action. Annotation `100:415`:
*"Three editable fields and nothing else."*

#### Scenario: Three inputs, not nine
- **WHEN** the screen is inspected
- **THEN** it contains exactly two `TextField`s and one `Select`

#### Scenario: The app bar action and the footer button do the same thing
- **WHEN** either is activated
- **THEN** the same single callback runs, per annotation `100:415`

#### Scenario: An invalid email is refused with a reason
- **WHEN** the email is `minh.tran`, `@example.com`, `a@b` or contains a space
- **THEN** that field renders in `MonetaTextFieldState.error`, its helper text
  is the rule's message, and nothing is saved

#### Scenario: The currency control says it cannot act
- **WHEN** the screen is rendered with no way to pick a currency
- **THEN** the `Select` is **disabled**, because `08.07` is the screen that
  chooses one and it is not built
- **AND** it is enabled exactly when a picker is supplied, so the control is
  never one that swallows a tap — the standard `08.10`'s call to action is held
  to, applied one screen over

#### Scenario: An empty email is allowed; an empty name is not
- **WHEN** the email is cleared and saved
- **THEN** it saves, because a local-first app with no account does not need one
- **AND** when the name is empty or whitespace, the save is refused with
  `AppFailure(kind: validation)`

#### Scenario: A long name truncates by mechanism, not by luck
- **WHEN** a 200-character name is **displayed** on `08.01`
- **THEN** the widgets showing the name and the email each have `maxLines: 1`
  and `TextOverflow.ellipsis`, asserted on the widget rather than on a measured
  width, because under the metrics-only test font a width is a fact about that
  font
- **AND** when the same name is **edited** on `08.02`, its fields are
  single-line — a `TextField` cannot carry a `TextOverflow`, so single-line is
  the mechanism it has, and requiring an overflow of it was a requirement no
  implementation could meet
- **AND** neither screen reports an overflow

#### Scenario: Every failure reaches the user somewhere, and the right one takes it
- **WHEN** a save is refused for any reason, with the name filled or empty
- **THEN** the message is rendered, and **which** renderer takes it is asserted:
  the email field takes a validation failure raised while the name is filled,
  and the banner takes every other case
- **AND** this is asserted as a sweep over the failure kinds rather than a case
  per kind, because what went wrong was the **gap between** two cases: one
  renderer took a validation failure with a filled name and another took a
  storage failure, and a validation failure with an empty name — the first-run
  path — matched neither and was shown nowhere

#### Scenario: A name of diacritics or emoji still yields initials
- **WHEN** the name is `Trần Văn Minh` or `👨‍👩‍👧 family`
- **THEN** the save succeeds and the avatar renders without throwing

### Requirement: 08.11 is five answers, searchable

`08.11` SHALL implement node `102:1189` — a `SearchField`, five collapsible
question-and-answer items with the first expanded, and a `ListRow` to contact
support.

#### Scenario: One expanded, four collapsed, and every chevron agrees
- **WHEN** the screen opens
- **THEN** exactly one item shows its answer
- **AND** for **each** of the five items, its chevron is `chevron-up` when
  expanded and `chevron-down` when collapsed — asserted per item against that
  item's own state, because annotation `102:1300` calls a mismatched chevron
  *"the most common copy-paste bug in this pattern"*

#### Scenario: Expanding one does not collapse another
- **WHEN** a second item is expanded
- **THEN** both show their answers, because these are independent answers and
  not a single-selection group

#### Scenario: Searching filters, ignoring case and Vietnamese diacritics
- **WHEN** the query is `du lieu`
- **THEN** an item whose question contains `dữ liệu` is shown
- **AND** `DU LIEU` and `Dữ Liệu` give the same result
- **AND** an item matching neither its question nor its answer is hidden

#### Scenario: No result offers the one action that can help
- **WHEN** the query is `xyzzy`
- **THEN** `EmptyState` with an action is shown, offering support
- **AND** the search field still holds `xyzzy` and still offers to clear it

#### Scenario: Clearing restores the opening state
- **WHEN** the query is cleared
- **THEN** all five items are shown, the first expanded and the other four
  collapsed

### Requirement: 08.10 shows prices and refuses to take money

`08.10` SHALL implement node `102:1044` — three plan cards with the middle one
on `brandSubtle` carrying a `Badge`, a `SectionHeader`, a comparison table using
`icon/check` and `icon/x`, and a sticky primary action with fine print.

Nothing SHALL be purchasable. The primary action SHALL report that purchases are
unavailable; it SHALL NOT appear to succeed and SHALL NOT be a control that does
nothing when activated.

#### Scenario: The saving is computed from the prices, and rounds to 31
- **WHEN** the plans are `59,000 ₫` monthly and `490,000 ₫` yearly
- **THEN** the badge claims **31%**, computed as
  `(1 - 490000 / (59000 * 12)) * 100 = 30.79`, **rounded** to the nearest whole
  percent
- **AND** rounding is `round`, not `floor`, which is stated because `floor`
  gives 30 and would contradict the badge
- **AND** changing either price changes the claim

#### Scenario: A zero or absurd price does not divide by zero
- **WHEN** the monthly price is zero
- **THEN** the saving is reported as absent (`null`), not `0%` and not infinity
- **AND** when the yearly price exceeds twelve monthly payments, the saving is
  absent rather than negative, because a negative saving is not a saving

#### Scenario: Yearly is preselected, and exactly one plan is selected
- **WHEN** the screen opens
- **THEN** the yearly plan reads selected, per annotation `102:1182`
- **AND** after tapping any other plan, that one reads selected and the other
  two do not

#### Scenario: The negatives are not errors
- **WHEN** the comparison table is rendered
- **THEN** a present feature's glyph is `income` and an absent one's is
  `textDisabled`
- **AND** neither is `expense`, and the two colours are asserted to differ —
  annotation `102:1188`: *"the free tier is not an error"*

#### Scenario: The action tells the truth
- **WHEN** the primary action is activated
- **THEN** the screen reports that purchases are not available in this build
- **AND** nothing is stored and nothing claims the user is premium

### Requirement: 08.08 reports real usage and claims nothing else

`08.08` SHALL implement the **usage half** of node `101:978`: two `Chip`s of
`Type=Filter`, and one row per category carrying its `CategoryIcon`, its name,
and its real transaction count and total for the period.

Editing is out of scope. The rows SHALL NOT be tappable and the authored drag
handle SHALL be absent, because a row that looks tappable and is not, and a
handle that does not drag, each promise what the screen cannot deliver.

#### Scenario: The filter is a transaction direction, not a category property
- **WHEN** `Expenses` is selected
- **THEN** the rows are built from transactions whose
  `TransactionDirection` is expense
- **AND** selecting `Income` uses the income direction
- **AND** the filter is **not** `SpendCategory.isIncome`, which
  `lib/core/spend_category.dart` documents as *"a display hint only"* and which
  would list exactly one category and hide every income-direction `gift`

#### Scenario: Exactly one chip is selected
- **WHEN** either chip is tapped
- **THEN** that one reads selected and the other does not; the two are never
  both selected and never both unselected

#### Scenario: The numbers come from the ledger
- **WHEN** three expense transactions of 10,000, 20,000 and 30,000 sit in one
  category and one of 5,000 in another
- **THEN** the first row reads a count of 3 and a total of 60,000, and the
  second reads 1 and 5,000

#### Scenario: The period is a whole local month, and the test discriminates
- **WHEN** usage is computed for a clock reading 2026-09-11
- **THEN** it covers 2026-09-01T00:00 to 2026-10-01T00:00 **in the local zone**,
  from an injected `Clock`
- **AND** a transaction at 2026-08-31T18:00 UTC — which is
  2026-09-01T01:00 in `Asia/Ho_Chi_Minh` — is **included**, so an
  implementation that computes the boundary in UTC fails, which under the
  gate's pinned `TZ` it otherwise would not

#### Scenario: A category with no transactions shows zero
- **WHEN** a category has no transactions in the period
- **THEN** it is listed with a count of 0 and a zero total, not omitted,
  because its absence is the information the screen exists to show

#### Scenario: Sorted by total, largest first
- **WHEN** categories are listed
- **THEN** they are ordered by total descending, and ties keep the enum's own
  order so the list is stable

#### Scenario: Mixed currencies within one category are reported, not summed
- **WHEN** one category holds transactions in two currencies
- **THEN** the computation throws `ArgumentError`, which is what `Money`'s own
  addition does and what `DonutChart` already relies on
- **AND** the screen surfaces it rather than rendering a wrong total

#### Scenario: An empty ledger
- **WHEN** there are no transactions
- **THEN** every category is listed with a count of 0, and nothing throws

#### Scenario: Negative and very large amounts
- **WHEN** a refund of −20,000 and an amount of `(1 << 61) - 1` are present
- **THEN** the totals are exactly their arithmetic sums, and no row overflows
  its parent

#### Scenario: No row is a button
- **WHEN** the rendered semantics of the category list are inspected
- **THEN** no row exposes a button or a tap action, asserted on the semantics
  tree rather than by scanning the source for `onTap` — a source scan cannot
  see a `GestureDetector`, an `InkWell`, or a callback passed through a variable

#### Scenario: The filter row is 44 tall, which is 10 more than the file draws
- **WHEN** the filter row is laid out
- **THEN** its height is **44**, asserted as that literal rather than as
  `MonetaLayout.minTouchTarget`, because an expectation taken from the
  implementation's own constant cannot fail
- **AND** `101:1001` draws 34, so this is the deviation `settings-components`
  introduced when `Chip` took ownership of its touch target

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
