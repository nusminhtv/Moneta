## ADDED Requirements

### Requirement: The brand has a subtle tint

`MonetaColors` SHALL expose `brandSubtle`, the brand's low-emphasis background
tint, transcribed from Figma's `brand/subtle` variable.

Every other semantic colour in this set already has one — `incomeSubtle`,
`expenseSubtle`, `warningSubtle`, `infoSubtle`. The brand's was missing, and
`Avatar` (`21:121`) binds it on all twelve variants, so the first component to
need it would otherwise have had to write the literal.

#### Scenario: The token exists and carries the authored value
- **WHEN** the dark colour set is inspected
- **THEN** `brandSubtle` is `#1A1236`, as `21:106`'s bound variable states

#### Scenario: It is part of the subtle family
- **WHEN** the semantic colours are inspected
- **THEN** every semantic colour that has a base has a subtle counterpart, the
  brand included

#### Scenario: It interpolates like every other colour
- **WHEN** two colour sets are interpolated
- **THEN** `brandSubtle` is interpolated too, not dropped

#### Scenario: It is distinguishable from the surfaces it sits on
- **WHEN** `brandSubtle` is compared with `canvas`, `surface` and
  `surfaceRaised`
- **THEN** it differs from each, because a tint identical to its background is
  not a tint
