# design-system/tokens Specification

## Purpose
Defines the single vocabulary of design values — colour, type, space, radius,
elevation and motion — that every Moneta surface resolves against, so that a
value can only change in one place and every screen changes with it.

## Requirements

### Requirement: Tokens are the only source of design values

The application SHALL resolve every colour, text style, spacing, corner radius,
elevation and animation duration through the token layer. No raw design value
SHALL appear in any widget outside the token and theme definitions.

#### Scenario: A widget needs a surface colour
- **WHEN** any widget outside the token layer needs a background colour
- **THEN** it reads it from the theme's Moneta token extension
- **AND** the static-analysis gate rejects a literal `Color(0x…)`, `Colors.*`,
  inline `TextStyle(`, literal `EdgeInsets` or `BorderRadius.circular` in that file

#### Scenario: A design value has no token
- **WHEN** a design requires a value that no token expresses
- **THEN** a token is added to the token layer and used from there
- **AND** the addition is recorded, so the design system converges rather than
  accumulating one-off exceptions

### Requirement: Colour tokens

The token layer SHALL expose the Figma colour set under stable names, grouped by
role: surface, text, border, brand, semantic and chart.

#### Scenario: Surface, text and border roles resolve to the Figma values
- **WHEN** the canvas, surface, raised-surface, track, primary-text,
  tertiary-text, on-brand-text and subtle-border tokens are read
- **THEN** they resolve to `#06070A`, `#0A0C11`, `#0F1218`, `#232935`, `#F6F8FB`,
  `#7C8595`, opaque white and 6%-opacity white respectively

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
- **AND** no other gradient is defined anywhere in the application

### Requirement: Typography tokens

The token layer SHALL expose one text style for each named text style read from
the Figma design, each with its family, weight, size, line height and letter
spacing, and SHALL expose no style that was not read from Figma.

Previously this requirement said "exactly the eight named text styles". That
count was wrong, and this change made it visibly wrong: implementing the
onboarding slides needed `body/lg` (Inter 400, 16/24), which the slide bodies and
the splash tagline both use.

**How this was found, because it matters more than the fix.** The count was not
noticed. `test/design_system/tokens/typography_test.dart` was edited from
`hasLength(8)` to `hasLength(9)` in commit `973a0d0` so it would pass, and the
requirement was left alone — a gate adjusted to fit the code, which CLAUDE.md
rule 5 forbids and which was supposed to require saying so first. The
`change-verifier` agent caught it before archive. Stating a count in a
requirement was the underlying mistake: the design has thirteen styles and the
implementation deliberately carries a subset, so any fixed number is a number
that goes stale the next time a screen is built.

#### Scenario: Display and heading styles use the display family
- **WHEN** the extra-large amount, medium amount and level-1 heading styles are
  read
- **THEN** all three use Plus Jakarta Sans, at 40/44 bold, 20/26 semibold and
  28/34 bold respectively

#### Scenario: Text styles use the text family
- **WHEN** the title, body, medium-label, small-label and caption styles are read
- **THEN** all five use Inter, at 16/22 semibold, 14/20 regular, 14/18 medium,
  12/16 medium and 12/16 regular respectively

#### Scenario: The large body style is available for slide and splash copy
- **WHEN** the large body style is read
- **THEN** it is Inter at 16/24 regular, as `body/lg` in Figma

#### Scenario: Negative letter spacing is resolved from percent to pixels
- **WHEN** a style whose Figma letter spacing is reported as `-1` is read
- **THEN** the value applied is −1% of that style's font size — −0.4 at 40px and
  −0.28 at 28px — not an absolute −1

#### Scenario: A style not in Figma is not invented
- **WHEN** a surface needs a text style outside the defined styles
- **THEN** the closest defined style is used, or a new token is added
  deliberately with its Figma source recorded — an ad-hoc size is not introduced
  at the call site

#### Scenario: A style is implemented that Figma does not author
- **WHEN** a text style exists in the token layer with no Figma source recorded
  in `docs/design-system/figma-tokens.md`
- **THEN** verification fails

#### Scenario: The type set grows with a screen
- **WHEN** a new screen needs a Figma style the token layer does not yet expose
- **THEN** the style is added along with its row in `figma-tokens.md`
- **AND** no requirement needs amending, because none states a count

### Requirement: Spacing, radius, elevation and motion tokens

The token layer SHALL expose a spacing scale, the Figma radius set, the Figma
shadow effects and motion values, each addressable by name.

#### Scenario: Radii match the Figma set
- **WHEN** the medium, large, extra-large and pill radius tokens are read
- **THEN** they resolve to 14, 18, 24 and a fully-rounded value

#### Scenario: Elevation and glow are reusable effects
- **WHEN** the level-3 elevation and brand-glow effect tokens are read
- **THEN** they resolve to the Figma shadow definitions — 55%-black at offset
  (0, 12) with 32 blur, and 35%-brand at offset (0, 0) with 24 blur

#### Scenario: Motion is expressed as tokens, not literals
- **WHEN** a widget animates
- **THEN** its duration and curve come from motion tokens

#### Scenario: A token with no Figma source is marked as such
- **WHEN** a token exists that could not be read from the design file — motion
  values, for which the file defines nothing
- **THEN** it is documented as not Figma-derived, so a later design review knows
  which values are the design's and which are ours

### Requirement: Tokens are reachable from any build context

The token set SHALL be reachable from any widget's build context through the
application theme, and SHALL be overridable in tests without rebuilding the app.

#### Scenario: A widget reads tokens from context
- **WHEN** a widget inside the application is built
- **THEN** the full token set is available from its build context

#### Scenario: A test pumps a widget in isolation
- **WHEN** a test renders a single design-system widget
- **THEN** it can supply the token set directly, and the widget renders with the
  real production values rather than Material defaults

### Requirement: Every Figma-derived token has a recorded source

Every value in the token layer that is derived from Figma SHALL have a row in
`docs/design-system/figma-tokens.md` naming the node it was read from, and this
SHALL be enforced by a check that reads that file.

A value **not** derived from Figma SHALL be marked as such in code and given a
prose entry in `figma-tokens.md` saying so and why. Today the motion tokens are
the only such values: no transition or easing appears in any node read, so they
come from Material's standard durations and curves. The requirement is scoped to
Figma-derived values precisely because of them — an unqualified "every value
SHALL have a row" would have been false the moment it was folded in, since
`lib/design_system/tokens/motion.dart` ships five values that deliberately have
no row.

This exists because the invented spacing scale reached production, and because
this change added `border-strong` and `body/lg` without recording either.
`figma-tokens.md` states the contract in its own first line and nothing read the
file: an eleventh text style with no row passed every token test.

**Two rounds of review were needed to get this requirement right**, which is the
point worth keeping. The first version asserted an enforcement that did not
exist — the same defect it was written to fix, one level down. The second version
had a cross-check so loose that an undocumented colour called `primary` borrowed
the row for `text-primary`, and a text style called `xl` borrowed a row from the
*spacing* table. The check is now scoped by kind and covers colours, type,
radius and the Figma-named spacing steps.

#### Scenario: A Figma-derived value is added without provenance
- **WHEN** a colour, text style, radius or `space/*` step is added and
  `figma-tokens.md` has no row for it under the matching section
- **THEN** verification fails, naming the value

#### Scenario: A value cannot borrow another kind's row
- **WHEN** a value's name coincides with a documented token of a different kind
- **THEN** it is still reported as undocumented

#### Scenario: The cross-check cannot pass vacuously
- **WHEN** the document is reformatted so its tables no longer parse
- **THEN** verification fails, rather than reporting nothing to check

#### Scenario: A value cannot be found in Figma
- **WHEN** a needed value is not present in the design
- **THEN** it is either recorded as *not observed* and left unimplemented, or
  implemented from a named non-Figma source, marked as such in code, and
  explained in `figma-tokens.md` — never guessed at silently
