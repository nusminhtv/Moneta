## Purpose

Defines the single vocabulary of design values — colour, type, space, radius,
elevation and motion — that every Moneta surface resolves against, so that a
value can only change in one place and every screen changes with it.

## ADDED Requirements

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
- **WHEN** the surface, raised-surface, track, primary-text, tertiary-text,
  on-brand-text and subtle-border tokens are read
- **THEN** they resolve to `#0A0C11`, `#0F1218`, `#232935`, `#F6F8FB`, `#7C8595`,
  opaque white and 6%-opacity white respectively

#### Scenario: Semantic money colours are distinct and named by meaning
- **WHEN** the income, expense and warning tokens are read
- **THEN** they resolve to `#22D19A`, `#F4515C` and `#FFA92B`
- **AND** they are named by meaning (income/expense/warning), not by hue, so a
  caller cannot pick "green" for something that is not income

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

The token layer SHALL expose exactly the six named text styles present in the
Figma design, each with its family, weight, size, line height and letter spacing.

#### Scenario: Amount styles use the display family
- **WHEN** the extra-large and medium amount styles are read
- **THEN** both use Plus Jakarta Sans, at 40/44 bold and 20/26 semibold
  respectively

#### Scenario: Text styles use the text family
- **WHEN** the title, medium-label, small-label and caption styles are read
- **THEN** all four use Inter, at 16/22 semibold, 14/18 medium, 12/16 medium and
  12/16 regular respectively

#### Scenario: A style not in Figma is not invented
- **WHEN** a surface needs a text style outside the six defined styles
- **THEN** the closest defined style is used, or a new token is added
  deliberately — an ad-hoc size is not introduced at the call site

### Requirement: Spacing, radius, elevation and motion tokens

The token layer SHALL expose a spacing scale, the Figma radius set, the Figma
shadow effects and motion values, each addressable by name.

#### Scenario: Radii match the Figma set
- **WHEN** the large, extra-large and pill radius tokens are read
- **THEN** they resolve to 18, 24 and a fully-rounded value

#### Scenario: Elevation and glow are reusable effects
- **WHEN** the level-3 elevation and brand-glow effect tokens are read
- **THEN** they resolve to the Figma shadow definitions — 55%-black at offset
  (0, 12) with 32 blur, and 35%-brand at offset (0, 0) with 24 blur

#### Scenario: Motion is expressed as tokens, not literals
- **WHEN** a widget animates
- **THEN** its duration and curve come from motion tokens

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
