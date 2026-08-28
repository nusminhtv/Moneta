## ADDED Requirements

### Requirement: Small corner radius

The token set SHALL carry `radius-sm = 10`, transcribed from Figma node
`36:167`, which binds `--radius-sm` on both of its variants.

`lib/design_system/tokens/radii.dart` documents `radius-sm` as deliberately
absent because it "does not appear in any node read". That was accurate when
written — the nodes read at the time were the balance card, banner and checkbox.
It is not accurate now. The comment SHALL be corrected to say where the value
was found, not deleted, so the reasoning survives.

#### Scenario: The radius is available as a BorderRadius
- **WHEN** `MonetaRadii.figma()` is constructed
- **THEN** `sm` is 10
- **AND** `borderSm` is a `BorderRadius.circular(10)`

#### Scenario: The absence comment no longer claims the value is unseen
- **WHEN** `radii.dart` is read
- **THEN** it does not assert that `radius-sm` is absent from every node read
- **AND** it names `36:167` as the source

### Requirement: Heading H2 type style

The token set SHALL carry `heading/h2`: Plus Jakarta Sans SemiBold, 22px,
line height 28, letter spacing -0.5, transcribed from Figma node `36:76`.

#### Scenario: The style matches the Figma definition
- **WHEN** `MonetaTypography.figma()` is constructed
- **THEN** `headingH2` has `fontSize` 22, `height` 28/22, `letterSpacing` -0.5
- **AND** its `fontWeight` is `w600` and its family is Plus Jakarta Sans
