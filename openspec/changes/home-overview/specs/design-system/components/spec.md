## Purpose

Adds the design-system components owned by `📱 02 Home & Dashboard` and requires
their full Figma variant sets to be implemented and visible in the gallery.

## ADDED Requirements

### Requirement: DateGroupHeader is implemented from node 29:71

`DateGroupHeader` SHALL implement the single variant authored at Figma node
`29:71`.

#### Scenario: Gallery coverage
- **WHEN** the gallery catalog is inspected
- **THEN** `DateGroupHeader` has one registered variant

### Requirement: EmptyState implements both HasAction variants

`EmptyState` SHALL implement the full Figma variant set from node `35:166`:
`HasAction=true` and `HasAction=false`.

#### Scenario: Action variant
- **WHEN** `HasAction=true` is rendered
- **THEN** the empty state includes its action affordance

#### Scenario: No-action variant
- **WHEN** `HasAction=false` is rendered
- **THEN** the empty state does not render an action affordance

### Requirement: Skeleton implements all four shapes

`Skeleton` SHALL implement the full Figma variant set from node `38:139`: `Line`,
`Circle`, `Card` and `Row`.

#### Scenario: Shape coverage
- **WHEN** the gallery catalog is inspected
- **THEN** all four skeleton shapes are registered and distinguishable

### Requirement: Banner implements all four tones

`Banner` SHALL implement the full Figma variant set from node `42:329`:
`Warning`, `Danger`, `Info` and `Success`.

#### Scenario: Tone coverage
- **WHEN** the gallery catalog is inspected
- **THEN** all four banner tones are registered and distinguishable
- **AND** each tone exposes more than colour alone where the design provides an
  icon or label

### Requirement: ListRow implements all five variants

`ListRow` SHALL implement the full Figma variant set from node `35:113`:
`Chevron`, `Value`, `Toggle`, `Badge` and `None`.

#### Scenario: Variant coverage
- **WHEN** the gallery catalog is inspected
- **THEN** all five list row variants are registered and distinguishable

### Requirement: SectionHeader is implemented from node 55:107

`SectionHeader` SHALL implement the single variant authored at Figma node
`55:107`.

#### Scenario: Gallery coverage
- **WHEN** the gallery catalog is inspected
- **THEN** `SectionHeader` has one registered variant

### Requirement: Home-owned components use home-owned gallery files

Every component added by this change SHALL be registered in
`gallery_catalog_home.dart` and described by `gallery_describe_home.dart`.

#### Scenario: Gallery completeness gate
- **WHEN** `test/app/gallery_test.dart` scans `lib/design_system`
- **THEN** no home-owned component is missing from the gallery
- **AND** no exemption is widened to hide a missing component
