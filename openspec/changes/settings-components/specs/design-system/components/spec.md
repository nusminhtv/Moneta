## ADDED Requirements

### Requirement: A variant is an authored node, and a boolean property is not

For every component in this change, the **variant set** SHALL be the set of
authored nodes under the variant properties (`Tone`, `Size`, `Type`,
`Selected`, `State`). A **boolean component property** — `Badge`'s `dot`,
`Chip`'s `leadingIcon` — SHALL NOT count as a variant: the file authors no node
for "Success/Sm without its dot".

This is stated once so that "the gallery renders every component in every
variant" and the literal counts below do not appear to contradict each other.

#### Scenario: The gallery registers nodes, not property combinations
- **WHEN** the gallery catalog is inspected
- **THEN** it holds one entry per authored variant node — ten for `Badge`, six
  for `Chip`, two for `NumpadKey`, one for `Numpad`, and `SearchField`'s two
  derived states
- **AND** the boolean properties are exercised by tests rather than by catalog
  entries

### Requirement: Badge implements all ten authored variants

`Badge` SHALL implement the full Figma variant set from node `17:32`: tones
`Success`, `Warning`, `Danger`, `Info` and `Neutral`, each at `Size=Sm` and
`Size=Md` — ten variants.

The tone SHALL determine both colours, and a caller SHALL NOT be able to supply
either. The four semantic tones pair a `*Subtle` fill with the tone's own text
colour; `Neutral` is **not** such a pair and uses `surfaceRaised` with
`textSecondary`:

| Tone | Fill | Label |
| --- | --- | --- |
| Success | `incomeSubtle` | `income` |
| Warning | `warningSubtle` | `warning` |
| Danger | `expenseSubtle` | `expense` |
| Info | `infoSubtle` | `info` |
| Neutral | `surfaceRaised` | `textSecondary` |

#### Scenario: Variant coverage
- **WHEN** the gallery catalog is inspected
- **THEN** exactly ten badge variants are registered, asserted as a literal ten
  as well as against the tone and size enums, so adding an enum member cannot
  satisfy the count on its own
- **AND** no two of them build the same widget

#### Scenario: Each tone's pair, including the one that is not a pair
- **WHEN** a badge is rendered in each of the five tones
- **THEN** the fill and label colours reaching the render tree are that row of
  the table above
- **AND** `Neutral` is `surfaceRaised` with `textSecondary`, not a subtle/base
  pair

#### Scenario: A tone is a meaning, not a colour
- **WHEN** the public API is inspected
- **THEN** it exposes no `Color` parameter, so `expenseSubtle` cannot be paired
  with `income`

#### Scenario: The pill's shape and box
- **WHEN** any badge is rendered
- **THEN** its corner radius is `theme.radii.borderPill`
- **AND** its total height is **22** at `Sm` and **26** at `Md` — the vertical
  padding either side of a `labelSm` 16px line box — so the four padding numbers
  cannot be met with a wrong box

#### Scenario: The dot is a second cue, and both values are authored
- **WHEN** a badge is rendered with its dot
- **THEN** a dot is drawn in the label's colour, **5px** at `Sm` and **6px** at
  `Md`
- **AND** a badge rendered without it still carries its label, because `17:32`'s
  description requires tone to be paired with the dot **or** with text
- **AND** the dot defaults to present, matching the Figma property's own default

#### Scenario: An empty label is refused
- **WHEN** a badge is given an empty or whitespace-only label
- **THEN** construction fails a debug assertion, because the label is the cue
  that survives a monochrome or colour-blind reading and `''` satisfies "carries
  text" while defeating its purpose

#### Scenario: Size changes only the four metrics it is authored to change
- **WHEN** the same tone is rendered at `Sm` and at `Md`
- **THEN** horizontal padding is 8 against 10, vertical 3 against 5, the gap 4
  against 5, and the dot 5 against 6
- **AND** the label style is `labelSm` and both colours are identical in both
  sizes

#### Scenario: A long label
- **WHEN** a badge whose label cannot fit is rendered inside a 120px-wide parent
- **THEN** the badge does not overflow that parent
- **AND** the label truncates on one line, because a pill with two lines of text
  is not a pill

#### Scenario: A large platform text size
- **WHEN** a badge is rendered inside a 120px-wide parent at text scales 1.0,
  1.3 and 2.0
- **THEN** nothing overflows at any of them
- **AND** the assertion is containment, not width, because under the
  metrics-only test font a width is a fact about that font

### Requirement: Chip implements all six authored variants

`Chip` SHALL implement the full Figma variant set from node `17:65`:
`Type=Filter`, `Type=Choice` and `Type=Input`, each unselected and selected.

The label SHALL be `labelMd`. Selected SHALL be `brandSubtle` fill, `brand`
border and `brandOnSurface` label; unselected `surfaceRaised`, `borderDefault`
and `textSecondary`.

#### Scenario: Variant coverage
- **WHEN** the gallery catalog is inspected
- **THEN** exactly six chip variants are registered, asserted as a literal six
  as well as against the type enum
- **AND** no two of them build the same widget

#### Scenario: Selection is three changes at once
- **WHEN** a chip is selected
- **THEN** all three of fill, border and label colour are the brand triple
- **AND** all three are asserted together, so changing one alone fails

#### Scenario: Input always carries its close control
- **WHEN** a chip of `Type=Input` is rendered, selected or not
- **THEN** a trailing close control is present, because `17:65`'s description
  states *"Input always shows the trailing close icon"*
- **AND** `Type=Filter` and `Type=Choice` have none

#### Scenario: Close and select are different actions
- **WHEN** the close control of an input chip is activated
- **THEN** the close callback fires and the selection callback does not

#### Scenario: The pill's shape
- **WHEN** any chip is rendered
- **THEN** its corner radius is `theme.radii.borderPill` and its border
  `MonetaLayout.borderWidthHairline`

#### Scenario: The chip meets the 44px target itself
- **WHEN** a chip is rendered
- **THEN** its painted pill is the authored **34** tall — `8 + 18 + 8`, with the
  1px border painted inside it rather than added to it, which is the height of
  `101:1002` — while the box it occupies is `MonetaLayout.minTouchTarget`
- **AND** the tap area is the full 44, matching what `MonetaCheckbox` and
  `MonetaRadio` already do with `hitSize`, rather than leaving the description's
  *"must sit inside a >=44px scroll row"* to the caller

#### Scenario: A leading glyph is optional and changes nothing else
- **WHEN** a chip is given a leading icon
- **THEN** a 16px glyph is drawn before the label
- **AND** the chip's type, selection colours and callbacks are unchanged

#### Scenario: Close and select each own part of the 44px box
- **WHEN** an input chip is rendered
- **THEN** the close control's tap area is `MonetaLayout.minTouchTarget` square
  at the trailing end of the box
- **AND** the selection tap area is the remainder, so the two partition the box
  rather than one sitting inside the other

#### Scenario: A long label truncates and the close control survives
- **WHEN** an input chip whose label cannot fit is rendered in a 140px-wide
  parent
- **THEN** the label truncates on one line and nothing overflows
- **AND** the close control remains fully visible, because a chip whose remove
  affordance is clipped cannot be removed

#### Scenario: An empty label is refused
- **WHEN** a chip is given an empty or whitespace-only label
- **THEN** construction fails a debug assertion

#### Scenario: A chip with no callback is inert and silent
- **WHEN** a chip with no selection callback is tapped
- **THEN** nothing fires and no exception is thrown

#### Scenario: A large platform text size
- **WHEN** a chip is rendered in a 140px-wide parent at text scales 1.0, 1.3 and
  2.0
- **THEN** nothing overflows at any of them

### Requirement: SearchField implements both authored states, derived from its text

`SearchField` SHALL implement node `35:38`: `State=Empty` and `State=Filled`.
The state SHALL be **derived from whether there is text** and SHALL NOT be a
parameter, so a field cannot offer to clear nothing, or hold text with no way
out.

Text SHALL be `bodyLg`; the placeholder `textTertiary` and the value
`textPrimary`. The field SHALL be **50** tall — `13 + 24 + 13`, with the 1px
border painted inside it rather than added to it — which is the height of
`102:1213`, the instance on `08.11`. Its shape SHALL be
`theme.radii.borderPill` and its border `MonetaLayout.borderWidthHairline`.

The 13 is **off the spacing scale**, which holds 12 and 16. It is authored: the
codegen reports it and the frame height confirms it. Recorded, not rounded.

#### Scenario: Variant coverage
- **WHEN** the gallery catalog is inspected
- **THEN** both states are registered, reached by supplying text or not, which
  is also how a user reaches them

#### Scenario: Empty shows its placeholder and no clear control
- **WHEN** the field holds no text
- **THEN** the placeholder is drawn in `textTertiary`
- **AND** no clear control is present

#### Scenario: Filled shows the value and a clear control
- **WHEN** the field holds text
- **THEN** the text is drawn in `textPrimary`
- **AND** a clear control is present

#### Scenario: The state cannot be passed in
- **WHEN** the **constructor parameters** are read from the source
- **THEN** none of their names contains `state` — a check scoped to the
  constructor, because the widget's own `createState` and its `State` subclass
  would otherwise match
- **AND** the check is guarded by a counterfeit so it can itself fail

#### Scenario: Clearing empties the field and reports it
- **WHEN** the clear control is activated
- **THEN** the field becomes empty and the clear control disappears
- **AND** the change is reported to the caller, because a screen filtering a
  list on this text must hear that the filter is gone

#### Scenario: Typing reports every change
- **WHEN** text is entered
- **THEN** each change is reported to the caller

#### Scenario: Both targets clear 44px
- **WHEN** the field is rendered
- **THEN** its height is 50, which clears the 44px target as `35:38`'s
  description claims for it
- **AND** the clear control's tap area is `MonetaLayout.minTouchTarget`, because
  the authored 18px glyph is not a target

#### Scenario: A disabled field accepts nothing
- **WHEN** the field is disabled
- **THEN** it accepts no text, reports nothing, and offers no clear control

#### Scenario: Focus changes nothing
- **WHEN** the field takes focus
- **THEN** its border, fill and height are unchanged, because `35:38` authors two
  states and neither is a focus state — unlike `27:44`, which has one

#### Scenario: A value longer than the field
- **WHEN** text longer than the field is entered
- **THEN** the field's height does not change and it does not overflow its parent
- **AND** the clear control stays fully visible

#### Scenario: Newlines do not make it two lines tall
- **WHEN** text containing a newline is pasted in
- **THEN** the field stays one line and its height does not change

#### Scenario: The search glyph is decorative
- **WHEN** the field is read by a screen reader
- **THEN** the leading glyph carries no separate semantics

### Requirement: SearchField owns a controller only when it is not given one

`SearchField` SHALL accept a `TextEditingController`. When none is supplied it
SHALL create one and dispose it; when one is supplied it SHALL NOT dispose it,
because the caller may still be using it.

#### Scenario: A supplied controller outlives the field
- **WHEN** a field is given a controller and then removed from the tree
- **THEN** the controller is still usable afterwards, which is the assertion —
  not the absence of an exception, since a missed disposal throws nothing

#### Scenario: An owned controller is disposed
- **WHEN** a field with no supplied controller is removed from the tree
- **THEN** its own controller is disposed, asserted by the field's own state
  rather than by nothing happening

#### Scenario: Replacing the controller
- **WHEN** the field is rebuilt with a different controller
- **THEN** it reads and reports the new one, and the old one is left alone

### Requirement: NumpadKey implements the authored variants, which are two and not four

`NumpadKey` SHALL implement the variant set of node `36:91` as it exists:
`Type=Digit, State=Default` and `Type=Action, State=Default`.

The set's description claims *"2 types x 2 states"* and
`docs/design-system/figma-map.md` records **four**. The variant set returns a
`state` union with one member. This requirement is written against the file, and
the discrepancy SHALL be recorded rather than resolved by inventing a state.

#### Scenario: Variant coverage is two, asserted as a literal
- **WHEN** the gallery catalog is inspected
- **THEN** exactly **two** key variants are registered, asserted as the literal
  two and not only against a type enum — an enum-derived count cannot fail when
  a member is added
- **AND** no invented state — pressed, disabled or focused — is registered as an
  authored variant

#### Scenario: A digit key shows a label, an action key shows a glyph
- **WHEN** a digit key is rendered
- **THEN** it draws its label in `headingH2` in `textPrimary`
- **AND** an action key draws a **22px** glyph instead of a label

#### Scenario: The key is well above the minimum target
- **WHEN** a key is rendered
- **THEN** its height is the authored **56**, which its own description
  explains: *"comfortably above the 44px minimum because this is the most-tapped
  control in the app"*

#### Scenario: A key with no callback is inert and silent
- **WHEN** a key with no callback is tapped
- **THEN** nothing happens and no exception is thrown

### Requirement: Numpad is a three-by-four grid whose rows fill their width

`Numpad` SHALL implement node `36:92`: four rows of three keys, laid out so the
pad spans the width it is given rather than a fixed width.

`36:92`'s description says *"Rows are FILL so the pad always spans the 353px
content column"*, and `08.05` places it across the full 393 instead, so neither
number SHALL be hard-coded.

#### Scenario: Keys 1 through 9, then the third-last cell, zero and the action
- **WHEN** the pad is rendered
- **THEN** the digits 1–9 appear in reading order across the first three rows
- **AND** the last row holds the third-last cell, then `0`, then the action key

#### Scenario: The pad spans the width it is given
- **WHEN** the pad is rendered at 353 and again at 393
- **THEN** every row spans the full width in both cases
- **AND** the three keys in a row are equal in width

#### Scenario: A narrow width
- **WHEN** the pad is rendered at **200** wide
- **THEN** the rows still fill that width, the keys are equal, and nothing
  overflows
- **AND** this is the scenario a hard-coded key width breaches: `36:77`'s
  standalone key is ~109 wide, and three of those plus two gaps need 343

#### Scenario: Every digit reports itself
- **WHEN** each digit key is tapped
- **THEN** the pad reports that digit to the caller

#### Scenario: The action key reports a delete, with the glyph the set has
- **WHEN** the action key is tapped
- **THEN** the pad reports a delete
- **AND** its glyph is `chevron-left`, as authored, because the 50-icon set
  (page `5:7`, and `MonetaIconName`'s 50 members) contains no backspace or
  delete glyph — recorded as an observation, not corrected

#### Scenario: The decimal key is the caller's, because a PIN has no decimals
- **WHEN** the pad is built for amount entry
- **THEN** the third-last cell is the authored decimal key and reports a decimal
- **AND** when the pad is built for a PIN, that cell is **empty** — not a key
  that looks live and does nothing — and no decimal can be reported
- **AND** the parameter has no default, so a caller must choose

#### Scenario: A pad with no callbacks does not throw
- **WHEN** every key of a pad with no callbacks is tapped
- **THEN** nothing happens and no exception is thrown

#### Scenario: Reading order under right-to-left text
- **WHEN** the pad is rendered under `TextDirection.rtl`
- **THEN** `1` is painted to the **left** of `3` — asserted on their positions,
  not their order in the widget tree, which a row reverses without reordering —
  because a keypad's digits are positional and not text

### Requirement: These five components take no raw design values from callers

Every component in this change SHALL keep design values out of its public API,
in keeping with the repository's rule that design-system widgets take domain
types.

This requirement is about the **API surface**, not about internal literals: a
component-local `static const` carrying an authored number that no token holds —
`36` for the chip's pill, `56` for a key, `5`/`6` for a dot — is the
repository's existing practice (`ListRow.minimumHeight`,
`MonetaOtpField.boxHeight`, `MonetaCheckbox.boxSize`) and is how these are
written, each with a row in `figma-map.md`.

#### Scenario: No colour, style or geometry parameters
- **WHEN** the public API of each of the five components is inspected
- **THEN** none accepts a `Color`, a `TextStyle`, an `EdgeInsets` or a radius
- **AND** each **variant property** is selected by an enum — `Tone`, `Size`,
  `Type`, `Selected` — while a **boolean component property** (`Badge`'s `dot`,
  `Chip`'s `leadingIcon`, `Chip`'s `selected`) is a `bool`, because the file
  authors no node for one of its values
- **AND** two components have no variant enum at all, because the design makes
  one wrong: `SearchField`'s state is derived from its text, and `Numpad` has a
  single variant

#### Scenario: Every colour and type style is the token's
- **WHEN** each component is rendered
- **THEN** the colours and text styles reaching the render tree equal the token
  values named in the requirements above, so a token change moves the component
- **AND** no component reads a colour from anywhere but `context.moneta`
