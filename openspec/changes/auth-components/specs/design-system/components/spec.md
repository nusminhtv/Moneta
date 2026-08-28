## ADDED Requirements

### Requirement: App bar

The design system SHALL provide a top app bar covering the full variant set of
Figma node `39:112`: `LargeTitle`, `TitleBack`, `TitleActions` and `Transparent`.

Figma draws a 59px `StatusBar` (`39:2`) inside every variant, because Figma has
no operating system. The bar SHALL take its top offset from the device's own top
inset, not from a constant.

`MonetaLayout.safeAreaTop` remains a valid token — Figma authors 59 and the token
transcribes it — but the app bar SHALL NOT read it. The distinction matters: a
bar that reads the token looks token-driven in review and is still wrong on any
device whose inset is not 59.

#### Scenario: The bar height matches the variant
- **WHEN** `LargeTitle` is rendered
- **THEN** its bar is 96px tall below the top inset
- **AND** the other three variants are 56px

#### Scenario: The top offset follows the device inset
- **WHEN** the bar is rendered under a top inset of 20, and again under 47
- **THEN** the bar's content begins at 20 and at 47 respectively
- **AND** neither inset is 59 or 34, so a bar hardcoding either device constant
  fails both cases

#### Scenario: Transparent shows what is behind it
- **WHEN** the `Transparent` variant is rendered over a coloured surface
- **THEN** it paints no background of its own and the surface shows through
- **AND** every other variant paints the canvas colour

#### Scenario: A back affordance appears only where the design has one
- **WHEN** `TitleBack` or `Transparent` is rendered
- **THEN** a back control is present with a hit area of at least 44×44
- **AND** `LargeTitle` and `TitleActions` have none

#### Scenario: The title truncates rather than displacing the actions
- **WHEN** the title is longer than the space available
- **THEN** it renders on one line with an ellipsis
- **AND** the action controls occupy the same rectangle as with a short title

#### Scenario: An empty title does not collapse the bar
- **WHEN** the title is an empty string
- **THEN** the bar keeps its variant height and the actions keep their position

#### Scenario: The action count varies without breaking the layout
- **WHEN** a variant is rendered with zero, one and two actions
- **THEN** the bar keeps its height and the title is neither clipped nor
  overflowing in any of the three

### Requirement: Icon button

The design system SHALL provide an icon-only button covering the full variant set
of Figma node `20:114`: three styles (filled, tonal, ghost) × three sizes
(sm, md, lg) × two states (default, disabled) — 18 combinations.

The glyph SHALL be supplied as a `MonetaIconName`, not as a widget, so a caller
cannot pass an arbitrary picture and bypass the icon set.

#### Scenario: Every combination resolves
- **WHEN** each of the 18 combinations is built
- **THEN** it renders at the size its variant defines
- **AND** its background, its border and its glyph colour are read off the render
  tree and match the value for that combination
- **AND** the table those values come from is separately pinned to named tokens,
  exhaustively over style × size × state

Both halves are required. Asserting the rendered value against the table that
produced it leaves the wiring unchecked, which is how a button shipped with its
label colour repointed to an unrelated token and 617 tests still passed.

#### Scenario: A disabled icon button is inert
- **WHEN** a disabled icon button is activated
- **THEN** no callback fires

#### Scenario: The small size does not stand alone as a touch target
- **WHEN** the `sm` size is rendered
- **THEN** it is 36×36
- **AND** `md` is 44×44 and `lg` is 52×52, so only `sm` falls below the 44px
  minimum and its documentation says it must sit inside a ≥44px row

#### Scenario: The accessible label describes the action, not the glyph
- **WHEN** an icon button is given the label "Search transactions" and the
  `search` glyph
- **THEN** exactly one semantics node carries "Search transactions"
- **AND** no semantics node carries the glyph's own name

### Requirement: Text field

The design system SHALL provide a text field covering the full variant set of
Figma node `27:44`: `Default`, `Focused`, `Filled`, `Error` and `Disabled`.

The field SHALL derive its own visual state from its inputs — text content, focus,
an error message, and whether it is enabled — rather than accepting a `state`
parameter. A caller must not be able to render an error border on a field with no
error, or a filled field holding no text.

Label, value and helper SHALL be separate inputs; the field SHALL NOT accept a
single pre-formatted string.

#### Scenario: The field clears the touch target
- **WHEN** any state is rendered
- **THEN** the field body is 52px tall, which clears the 44px minimum unaided

#### Scenario: An error is signalled by width as well as colour
- **WHEN** the field is given an error message
- **THEN** the border colour changes **and** the border width changes from the
  default width
- **AND** the helper text resolves to the expense token
- **AND** border width alone distinguishes the error state from the default one,
  so the state survives greyscale

This is Figma's own instruction on `27:3`: "Error state colours the border and the
helper text together — never colour alone."

#### Scenario: The focused state is distinct by width as well as colour
- **WHEN** the field takes focus
- **THEN** its border width changes from the default width and its border colour
  resolves to the focus token
- **AND** the brand glow effect is applied

#### Scenario: Filled is distinguishable from default
- **WHEN** the field holds text
- **THEN** the value renders in the primary text token
- **AND** with no text the placeholder renders in the tertiary text token

#### Scenario: A disabled field is not merely dimmed
- **WHEN** the field is disabled
- **THEN** its background, border, label, value and helper each resolve to the
  disabled-state tokens rather than to the enabled token at reduced opacity
- **AND** it does not accept input

#### Scenario: Label and helper are optional and reserve no space when absent
- **WHEN** the field is built without a label
- **THEN** the field body's top edge is the widget's top edge
- **AND** the widget's height is smaller than the same field built with a label

#### Scenario: Long text does not overflow the field
- **WHEN** the label, the value and the helper are each far longer than the field
  is wide, including a single unbroken word
- **THEN** nothing overflows and the field body keeps its height

### Requirement: OTP field

The design system SHALL provide a one-time-code field covering the full variant
set of Figma node `70:263`: `Empty`, `Partial` and `Complete`.

Its length SHALL be a parameter. Filled-ness SHALL be derived from the code
entered, never passed in.

#### Scenario: Filled state is derived from the code
- **WHEN** the field is given a code shorter than its length
- **THEN** it reports itself partial
- **AND** a code of exactly its length reports complete, and an empty one empty
- **AND** a caller cannot render a complete field holding an incomplete code

#### Scenario: A filled position differs from an empty one by content
- **WHEN** a partially filled code is rendered
- **THEN** each filled position renders its character and each empty position
  renders none
- **AND** the two are therefore distinguishable without colour

#### Scenario: A code longer than the field is refused, not truncated silently
- **WHEN** a code longer than the field's length is supplied
- **THEN** the field reports a validation failure rather than displaying a
  truncated code as complete

#### Scenario: The value round-trips
- **WHEN** the field reports its value
- **THEN** it returns the characters entered so far as one string, in order

### Requirement: Select

The design system SHALL provide a select control covering the full variant set of
Figma node `38:131`: `Placeholder` and `Value`.

The control SHALL render the closed state and expose an activation callback. It
SHALL NOT own the picker that opens: `BottomSheet` (`59:211`) is unimplemented,
and choosing how a screen presents its options is a screen decision.

#### Scenario: Placeholder and value are visually distinct
- **WHEN** no selection has been made
- **THEN** the placeholder text uses the tertiary text token
- **AND** a chosen value uses the primary text token

#### Scenario: The control takes a domain value
- **WHEN** the select is constructed
- **THEN** it accepts the selected item and a function producing its label, not a
  pre-formatted display string

#### Scenario: Activation is delegated
- **WHEN** the control is activated
- **THEN** its callback fires and the control itself presents nothing

#### Scenario: A disabled select is inert
- **WHEN** a disabled select is activated
- **THEN** no callback fires

### Requirement: Checkbox

The design system SHALL provide a checkbox covering the full variant set of Figma
node `25:229`: three states (unchecked, checked, indeterminate) × enabled and
disabled — six combinations.

#### Scenario: The three states differ by mark, not only by tint
- **WHEN** each state is rendered
- **THEN** checked draws a check glyph, indeterminate draws a horizontal bar, and
  unchecked draws neither
- **AND** the three are therefore distinguishable in greyscale

#### Scenario: Indeterminate reports itself
- **WHEN** the checkbox is indeterminate
- **THEN** it reports indeterminate rather than checked or unchecked

#### Scenario: A disabled checkbox does not change
- **WHEN** a disabled checkbox is activated
- **THEN** no callback fires and its state is unchanged

#### Scenario: The checkbox is reachable as a touch target
- **WHEN** the checkbox is rendered
- **THEN** its drawn box is 22×22 and its interactive area is at least 44×44

### Requirement: Divider

The design system SHALL provide a divider covering the full variant set of Figma
node `21:126`: two orientations (horizontal, vertical) × two tones (subtle,
default).

#### Scenario: Orientation determines which dimension is the hairline
- **WHEN** a horizontal divider is rendered inside a bounded parent
- **THEN** it is one logical pixel tall and fills the available width
- **AND** a vertical divider is one logical pixel wide and fills the available
  height

#### Scenario: The two tones are different tokens
- **WHEN** the subtle and default tones are rendered
- **THEN** they resolve to different border tokens

#### Scenario: An unbounded cross axis does not throw
- **WHEN** a horizontal divider is placed in a parent with unbounded width
- **THEN** it renders at an intrinsic width rather than throwing a layout error

### Requirement: Logo

The design system SHALL provide the brand logo from Figma node `70:205`, in both
the forms it authors: the mark alone, and the mark with the wordmark.

The mark's gradient is the second and last hardcoded gradient in this system, per
Figma's own note on `70:205`, because Figma cannot bind a variable to a gradient
stop. Its stops SHALL be read from the brand palette tokens rather than written
as fresh literals.

#### Scenario: Both forms are available
- **WHEN** the logo is rendered with and without the wordmark
- **THEN** the mark is present in both
- **AND** the wordmark text is present in one and absent in the other

#### Scenario: The mark scales without distortion
- **WHEN** the mark is rendered at a size other than its authored 48px
- **THEN** it remains square

#### Scenario: The logo is announced as the product name
- **WHEN** a screen reader reaches the logo
- **THEN** exactly one semantics node carries the label `Moneta`
- **AND** no descendant contributes a default image or icon semantics node

### Requirement: Status bar is not implemented

The design system SHALL NOT provide a `StatusBar` widget, despite Figma node
`39:2` existing and being listed in the Screen Index as a component used by four
auth screens.

#### Scenario: No status-bar widget exists
- **WHEN** the classes declared under `lib/design_system` are enumerated
- **THEN** none of them is a status bar

#### Scenario: A screen needs the top safe area
- **WHEN** a screen needs the space the status bar occupies
- **THEN** it reads the device inset through the platform
- **AND** no widget paints a clock, signal bars or a battery

The deviation and its reasoning SHALL be recorded in
`docs/design-system/figma-map.md`, so a later reader does not file it as missing
work.

## MODIFIED Requirements

### Requirement: Component gallery

The application SHALL provide a route that renders every design-system component
in every variant, so fidelity can be checked against Figma in a running app.
Coverage SHALL be enforced by a check that reads the source tree, not by a list
maintained by hand.

Each section SHALL declare the number of variants its Figma node authors, and a
single check SHALL assert that its registered variants match that number.

The requirement's substance is unchanged; what changes is that variant *shortfall*
becomes visible. The existing count checks are one hand-written test per
component and cover only those that predate this change, so a new component
registered with 2 of its 18 variants passes the whole gate. Absence and
duplication were already caught; shortfall was not, and a per-component test is
enumerated by hand and stops at the last component someone remembered.

#### Scenario: The gallery covers everything
- **WHEN** the gallery route is opened
- **THEN** it renders every implemented component in every variant, grouped by
  component, with each variant labelled by its Figma variant name

#### Scenario: A section registers fewer variants than its node authors
- **WHEN** a section's registered variant count differs from the count it
  declares for its Figma node
- **THEN** verification fails, naming the component

#### Scenario: A new component is not added to the gallery
- **WHEN** a public widget class is declared under `lib/design_system` and no
  gallery section covers it
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
