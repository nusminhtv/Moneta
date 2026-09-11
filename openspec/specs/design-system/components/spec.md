# design-system/components Specification

## Purpose
Defines the behaviour of Moneta's shared UI components — what each one shows, the
full set of states it must support, and which state decisions the component owns
rather than delegating to its caller.

## Requirements

### Requirement: Components own derived state, callers do not

A component whose appearance depends on data SHALL compute that appearance from
the data it is given. A caller SHALL NOT be able to select an appearance that
contradicts the data.

#### Scenario: Budget colour follows spend, not a caller's choice
- **WHEN** a budget component is given a spent amount and a limit
- **THEN** it selects its own colour: income colour below 80% of the limit,
  warning colour from 80% up to the limit, expense colour above the limit
- **AND** its public interface offers no way to pass a colour or a state name

#### Scenario: Category appearance follows the category
- **WHEN** a component displays a spend category
- **THEN** the tint and glyph are determined by the category alone
- **AND** the same category renders identically everywhere it appears

### Requirement: Components accept domain types

A component that displays a monetary amount SHALL accept the money type, not a
pre-formatted string, so that formatting cannot diverge between callers.

#### Scenario: An amount is passed as money
- **WHEN** a component displays an amount
- **THEN** its interface takes the money type and formats it internally
- **AND** the rendered text matches that currency's formatting rules

#### Scenario: Two currencies are mixed
- **WHEN** a component is given amounts in different currencies for the same
  calculation
- **THEN** the failure is raised rather than silently rendering a wrong total

### Requirement: Full variant coverage

Every component derived from a Figma component set SHALL implement every variant
in that set. A partially implemented component set is not complete.

#### Scenario: Every Figma variant is reachable
- **WHEN** a Figma component set defines N variants
- **THEN** all N are reachable through the component's public interface
- **AND** each has a test asserting its distinguishing visual property

### Requirement: Balance card

The balance card SHALL present a total balance, a safe-to-spend line and income
and expense totals for the period, on the brand gradient, with a control that
hides every figure.

#### Scenario: Default state shows the figures
- **WHEN** the card is shown with balance, safe-to-spend, income and expense
  amounts
- **THEN** all four are rendered with the amount and label type styles on the
  brand gradient
- **AND** income is prefixed with a plus sign and expense with a minus sign

#### Scenario: Masked state hides every figure
- **WHEN** the card is masked
- **THEN** no digit from any of the four amounts is present in the rendered output
- **AND** the labels, the gradient and the layout are unchanged
- **AND** the mask control shows the inverse icon

#### Scenario: Masking is reversible from the card
- **WHEN** the mask control is activated
- **THEN** the card reports the request to its caller
- **AND** the card does not itself decide to persist the preference

#### Scenario: A zero balance is a normal state
- **WHEN** the balance is zero
- **THEN** it renders as a formatted zero, not as an empty or placeholder card

### Requirement: Budget card

The budget card SHALL present one category's spend against its limit, with a
progress bar and a status note, and SHALL make its over-limit state survive
greyscale.

#### Scenario: Under 80% of the limit
- **WHEN** spend is below 80% of the limit
- **THEN** the amount, note and bar use the income colour
- **AND** the card border is the subtle border colour

#### Scenario: At or above 80% but at or below the limit
- **WHEN** spend is at least 80% of the limit and does not exceed it
- **THEN** the amount, note and bar use the warning colour

#### Scenario: Above the limit
- **WHEN** spend exceeds the limit
- **THEN** the amount, note and bar use the expense colour
- **AND** the card border is the expense colour, so the state is distinguishable
  without relying on hue

#### Scenario: The bar never overflows its track
- **WHEN** spend is far above the limit
- **THEN** the bar fills its track exactly and does not paint outside it

#### Scenario: A zero limit does not break the bar
- **WHEN** the limit is zero
- **THEN** the bar renders empty rather than dividing by zero
- **AND** the card is treated as over limit when any amount has been spent

#### Scenario: A long category name truncates
- **WHEN** the category name is longer than the available width
- **THEN** it truncates with an ellipsis on a single line
- **AND** the amount on the right is not displaced or clipped

### Requirement: Bottom navigation

The bottom navigation SHALL present four destinations plus a central add action,
indicate exactly one active destination, and reserve the device's bottom safe area.

#### Scenario: Exactly one destination is active
- **WHEN** the bar is shown for a destination
- **THEN** that destination's icon and label use the brand-on-surface colour and
  every other destination uses the tertiary text colour
- **AND** exactly one destination is in the active state

#### Scenario: The add action is not a destination
- **WHEN** the central add action is activated
- **THEN** it reports an add request, distinct from destination selection
- **AND** activating it does not change which destination is active

#### Scenario: Selecting a destination reports it
- **WHEN** a destination is activated
- **THEN** the bar reports that destination to its caller and does not navigate
  by itself

#### Scenario: The bar respects the bottom safe area
- **WHEN** the bar is rendered on a device with a bottom inset
- **THEN** the tab row sits above the inset and the bar's background extends
  through it

### Requirement: Progress bar

The progress bar SHALL render a fraction of a track, with the fill colour derived
from the fraction, in the sizes the design defines.

#### Scenario: The fill is proportional
- **WHEN** the bar is given a fraction
- **THEN** the filled width is that fraction of the track width

#### Scenario: Out-of-range fractions are clamped
- **WHEN** the bar is given a fraction below zero or above one
- **THEN** it renders empty or full respectively, and never paints outside the
  track

### Requirement: Icons

The application SHALL render the Figma icon set from the exported vector assets,
addressable by name, at the sizes the design uses.

#### Scenario: An icon is requested by name
- **WHEN** an icon name from the Figma set is requested
- **THEN** the corresponding exported vector is rendered at the requested size
  and tinted with the requested colour

#### Scenario: The icon set is complete
- **WHEN** the icon catalogue is enumerated
- **THEN** it contains every icon present on the Figma iconography page — 50 —
  and each entry resolves to an asset that exists in the bundle

#### Scenario: Every stroked icon keeps the design stroke weight
- **WHEN** any icon drawn with strokes is inspected
- **THEN** its stroke weight is 1.75, the weight the design is drawn at
- **AND** a re-export at a different weight fails verification rather than
  shipping

#### Scenario: A multi-colour brand mark is not tinted
- **WHEN** an icon that carries its own colours is rendered with a requested tint
- **THEN** the tint is ignored and the icon's own colours are preserved
- **AND** every other icon in the set does honour the requested tint

#### Scenario: An unknown icon name is not substituted
- **WHEN** an icon is looked up by a name that is not in the set
- **THEN** the lookup reports absence rather than returning a placeholder icon

### Requirement: Component gallery

The application SHALL provide a route that renders every design-system component
in every variant, so fidelity can be checked against Figma in a running app.
Coverage SHALL be enforced by a check that reads the source tree, not by a list
maintained by hand.

The requirement's substance is unchanged. What changed is that it is now
enforceable: the guard asserted a hardcoded list of six component names, so a
component missing from the gallery could not fail it. Button (45 variants),
PaginationDots, OnboardingIllustration and TransactionRow were all absent while
the test passed — TransactionRow since before this change.

#### Scenario: The gallery covers everything
- **WHEN** the gallery route is opened
- **THEN** it renders every implemented component in every variant, grouped by
  component, with each variant labelled by its Figma variant name

#### Scenario: A new component is not added to the gallery
- **WHEN** a public widget class is declared under
  `lib/design_system/{atoms,molecules,organisms}` and no gallery section covers it
- **THEN** verification fails, naming the file

#### Scenario: A component is deliberately not in the gallery
- **WHEN** a widget renders nothing of its own — a layout constraint with no
  Figma node
- **THEN** it may be exempted, and the exemption SHALL state its reason in the
  test

#### Scenario: A variant must build what its label says
- **WHEN** a gallery variant's label names a style, size, state or position
- **THEN** the widget it builds SHALL match that label, and no two variants of a
  component SHALL build the same thing

Counting variants is not the same as rendering different ones. Pointing all 45
Button variants at a single primary/md/normal button, labels untouched, passed
the whole gallery suite — the exact defect a gallery exists to expose.

### Requirement: Transaction row

The design system SHALL provide a row presenting one transaction: its category,
its note or category name, the time of day, and its signed amount.

Its Figma source is node **`29:70`**, which authors four variants.

The previous wording of this requirement said "Figma contains **no** transaction
row and no screen frames, so this component's layout is a decision this project
makes". Both halves were false. `get_metadata` without a node id returns an
incomplete page list, that list was read as the file, and the conclusion was
written into a requirement and an ADR. Node `29:70` is a transaction row with
four variants, and `5:14` is twelve finished screens. The requirement is corrected
here rather than left to be discovered a third time.

The implementation still diverges from `29:70` — disc 32 against 40, height 56
against ≥64, gutter 16 against 20, no `· account` meta line, and the Transfer and
Pending variants absent because the domain has no concept for either. That
reconciliation is **not** in this change; it is recorded in
`docs/design-system/figma-map.md` as outstanding.

#### Scenario: An expense row
- **WHEN** a row shows an expense
- **THEN** the amount is prefixed with a minus sign and uses the expense colour

#### Scenario: An income row
- **WHEN** a row shows income
- **THEN** the amount is prefixed with a plus sign and uses the income colour

#### Scenario: The category is shown by its disc
- **WHEN** a row is rendered
- **THEN** the category's tint and glyph come from the shared category binding,
  so a category looks the same here as in a budget card or a chart

#### Scenario: A row without a note
- **WHEN** a transaction has no note
- **THEN** the category name is shown in its place rather than blank space

#### Scenario: A long note
- **WHEN** the note is longer than the available width
- **THEN** it truncates on one line with an ellipsis
- **AND** the amount is neither displaced nor clipped

#### Scenario: The row takes domain types
- **WHEN** the row is constructed
- **THEN** it accepts the transaction's money value and direction, not a
  pre-formatted string, so formatting cannot diverge from the rest of the app

#### Scenario: The divergence from Figma is recorded, not silent
- **WHEN** the implementation differs from `29:70`
- **THEN** each difference is listed in `docs/design-system/figma-map.md`

### Requirement: Button

The design system SHALL provide a button covering the full variant set of Figma
node `13:2`: five styles (primary, secondary, tertiary, ghost, destructive) × three
sizes (sm, md, lg) × three states (default, disabled, loading).

Variants SHALL be resolved through lookup tables rather than conditional
branches, so an unhandled combination is a compile error rather than a fallback.

#### Scenario: Every combination resolves
- **WHEN** each of the 45 combinations is built
- **THEN** each renders without throwing, at the height its size defines
- **AND** its background, its label colour and its label type style are asserted
  **on the rendered widget**, not on the lookup table

The emphasis is the correction. The tables were asserted directly and were
correct; nothing checked they were wired to anything. Repointing the label colour
to an unrelated token, and collapsing `lg`'s label style onto `sm`'s, each passed
the entire suite.

#### Scenario: Loading does not resize the button
- **WHEN** a button enters the loading state
- **THEN** its width is unchanged, because the label is still laid out and hidden
  rather than removed

#### Scenario: A disabled button is inert
- **WHEN** a disabled or loading button is activated
- **THEN** no callback fires

#### Scenario: The size table cannot drift
- **WHEN** a size's height, horizontal padding or icon size changes
- **THEN** verification fails against the authored values

Padding and icon size were pinned nowhere: `sm`'s padding could go from 14 to 40,
and every icon size collapse to 24, with the whole suite green. The icon test
compared the rendered size to the enum it came from — the implementation against
itself. Note that pinning them here stops them drifting; it does **not** make
them verified against Figma. `docs/design-system/figma-map.md` records that these
particular numbers were never read from a node.

#### Scenario: Only the bordered style has a border
- **WHEN** any style is rendered in the normal or disabled state
- **THEN** only `tertiary` has one, and its colour is the strong border token
  when interactive and the subtle one when disabled

### Requirement: Pagination dots

The design system SHALL provide a pagination indicator from Figma node `70:223`
in which the active position differs from the inactive ones **in width as well as
in colour**, so position is legible without colour perception.

#### Scenario: Position is readable in greyscale
- **WHEN** the indicator is rendered at any position
- **THEN** exactly one dot is active
- **AND** width alone identifies which

### Requirement: Onboarding illustration

The design system SHALL provide the decorative illustration from Figma node
`71:59` — a hairline ring, a filled halo, a centre glyph and four accent dots —
themed by a chart-palette slot rather than by a colour passed in.

It SHALL be drawn from tokens rather than shipped as an image, so
`tool/check_design_tokens.dart` can see inside it. That gate cannot inspect an
SVG.

#### Scenario: Geometry holds at any width
- **WHEN** the illustration is rendered narrower than the 353px Figma authors
- **THEN** the ring, halo and glyph remain concentric
- **AND** both axes scale by the same factor

This scenario exists because they did not. Only horizontal positions were scaled,
so the three were concentric at exactly 353px and at no other width — about 20px
apart at 280px wide. The component had no test file at all; its 100% line
coverage came from another test rendering it in passing.

#### Scenario: A wide screen does not get a magnified illustration
- **WHEN** the available width exceeds 353px
- **THEN** the illustration holds its authored size and centres

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
  for `Chip`, two for `NumpadKey`, and `SearchField`'s two derived states
- **AND** `Numpad`, whose authored set is one variant, is registered **twice**:
  the authored decimal cell and the empty cell `08.05` needs. The second is not
  an authored variant, it is this change's own parameter (see the `Numpad`
  requirement), and it is registered so the deviation is reviewable in the
  gallery rather than only readable in the map
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
**34** for the chip's pill, `56` for a key, `5`/`6` for a dot — is the
repository's existing practice (`ListRow.minimumHeight`,
`MonetaOtpField.boxHeight`, `MonetaCheckbox.boxSize`) and is how these are
written, each with a row in `figma-map.md`.

It is verified by a **source check over each constructor's parameter block**,
guarded by a counterfeit, because `tool/check_design_tokens.dart` matches five
constructs in a file's body and cannot see a parameter list at all. All five
components have one.

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
