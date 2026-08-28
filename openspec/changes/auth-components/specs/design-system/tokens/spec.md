## MODIFIED Requirements

### Requirement: Colour tokens

The token layer SHALL expose the Figma colour set under stable names, grouped by
role: surface, text, border, brand, semantic and chart. Each role SHALL carry
every member the design authors for it, and every member SHALL have its row in
`docs/design-system/figma-tokens.md` naming the node it was read from.

The previous wording listed the surface, text and border members by name in a
single scenario. That reads as the complete set and is not: building the auth
text field needed `border-default`, `border-focus` and `text-disabled`, none of
which were in it, and `text-secondary` had already been added after being wrongly
recorded as *not observed*. A scenario that enumerates an open set goes stale the
next time a screen is built — the same defect as the typography requirement that
once said "exactly the eight named text styles". Membership is now enforced by
`test/design_system/tokens/token_provenance_test.dart` rather than restated here.

#### Scenario: Surface, text and border roles resolve to the Figma values
- **WHEN** the surface tokens are read
- **THEN** canvas, surface, raised-surface and track resolve to `#06070A`,
  `#0A0C11`, `#0F1218` and `#232935`
- **AND** the primary, secondary, tertiary, disabled and on-brand text tokens
  resolve to `#F6F8FB`, `#9AA3B4`, `#7C8595`, `#3D4553` and opaque white
- **AND** the subtle, default, strong and focus border tokens resolve to 6%, 10%
  and 18% white and `#9A83FB`

Values stay pinned here. An earlier draft replaced them with "the value recorded
in `figma-tokens.md`", which reads like tightening and is the opposite: the
provenance check asserts a *row exists*, never that the value matches it, so four
values the main spec had pinned would have become unpinned inside a change that
did not announce it.

#### Scenario: A role gains a member
- **WHEN** a screen needs a colour in an existing role that the token layer does
  not expose
- **THEN** the token is added with its `figma-tokens.md` row
- **AND** no requirement needs amending, because none enumerates the role's
  members

#### Scenario: Semantic money colours are distinct and named by meaning
- **WHEN** the income, expense, warning and info base tokens are read
- **THEN** they resolve to `#22D19A`, `#F4515C`, `#FFA92B` and `#2E9BFF`
- **AND** they are named by meaning (income/expense/warning/info), not by hue, so
  a caller cannot pick "green" for something that is not income

#### Scenario: Each semantic colour has a subtle companion for tinted surfaces
- **WHEN** the income, expense, warning and info subtle tokens are read
- **THEN** they resolve to `#072A22`, `#2E0F13`, `#2E1E05` and `#06203A`
- **AND** a tinted surface always pairs its subtle background with the matching
  base colour as a border, so the tone survives greyscale rather than relying on
  hue alone

#### Scenario: The chart palette has eight slots, each with a subtle companion
- **WHEN** the chart palette is read
- **THEN** it exposes exactly eight base colours and eight matching subtle
  background tints, addressable by index
- **AND** each category maps to a fixed slot, so a category renders identically
  in every list, chart and detail surface

#### Scenario: The brand gradient is a single defined token
- **WHEN** a surface needs the brand gradient
- **THEN** it reads one gradient token whose stops are the violet-600,
  violet-500 and mint-600 values at the Figma angle
- **AND** that token writes no fresh literals; it reads the brand palette
  constants, so a palette change propagates

The clause "no other gradient is defined anywhere in the application" is removed
from this scenario. It was false: `Logo` (`70:205`) has its own, and Figma's note
on that node calls it "the second and last hardcoded gradient in this system", so
the design always had two while the requirement recorded one. The correct bound
is stated in its own scenario below rather than as an aside here — an absolute
buried in an AND-clause is how the claim that Figma contains no screen frames
survived three rounds.

#### Scenario: The mark gradient is the only other one
- **WHEN** the brand mark needs its gradient
- **THEN** it reads a second gradient token whose stops are the violet-500 and
  mint-500 values at the mark's authored angle
- **AND** no third gradient is defined anywhere in the application

## ADDED Requirements

### Requirement: Disabled and focus states have their own tokens

The token layer SHALL expose a disabled text colour and a focus border colour as
named tokens, rather than leaving callers to dim or tint an existing one.

A component that fakes a disabled state by applying opacity to the enabled colour
produces a different result on every background it sits on, and the design
authors a specific value.

#### Scenario: A disabled control reads one token
- **WHEN** any component renders a disabled label, value or helper
- **THEN** it reads the disabled text token
- **AND** it does not apply opacity to the enabled colour to approximate it

#### Scenario: A focused control is distinguishable by width alone
- **WHEN** a control takes focus
- **THEN** the focus border token is applied **and** the border width changes
- **AND** the width difference alone identifies the focused control, without
  reference to its colour

### Requirement: Border widths are tokens

The token layer SHALL expose the border widths the design authors — hairline,
emphasis and focus — as named tokens.

`tool/check_design_tokens.dart` does **not** see a raw border width: its rules
match `Color(0x`, `Colors.*`, `TextStyle(`, `EdgeInsets.*` with a literal, and
`BorderRadius.circular(<digit>)`. A hardcoded `BorderSide(width: 2)` passes every
gate. This requirement exists because nothing else would catch it, and because
the repo's only `// design-token-ignore` was added for exactly this gap.

#### Scenario: A component draws a border
- **WHEN** any component draws a border
- **THEN** its width comes from a border-width token
- **AND** no `// design-token-ignore` is added for a border width

#### Scenario: The three widths are distinct
- **WHEN** the hairline, emphasis and focus widths are read
- **THEN** they are three different values, so a state change expressed as a
  width change is perceptible
