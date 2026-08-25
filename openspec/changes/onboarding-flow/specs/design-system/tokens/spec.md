## Purpose

The four token values this change added, and the correction to a requirement that
had frozen the type set at a count the design does not support.

## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Every token has a recorded Figma source

Every value in the token layer SHALL have a row in
`docs/design-system/figma-tokens.md` naming the Figma node it was read from. A
value with no such row SHALL NOT be added.

This exists because the invented spacing scale reached production, and because
this change added `border-strong` and `body/lg` without recording either — the
same failure in miniature. `figma-tokens.md` states this contract in its own
first line; nothing enforced it.

#### Scenario: A value is added without provenance
- **WHEN** a token is added and `figma-tokens.md` has no row for it
- **THEN** the change is not complete, whatever the gate says

#### Scenario: A value cannot be found in Figma
- **WHEN** a needed value is not present in the design
- **THEN** it is recorded as *not observed* and left unimplemented, rather than
  guessed at
