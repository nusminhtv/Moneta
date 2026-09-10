## ADDED Requirements

### Requirement: Avatar implements all twelve authored variants

`Avatar` SHALL implement the full variant set from node `21:121`: three types —
image, initials and icon — at each of four sizes, 24, 32, 40 and 56.

#### Scenario: Variant coverage
- **WHEN** the gallery catalog is inspected
- **THEN** all twelve variants are registered and distinguishable

#### Scenario: Every size is the authored diameter
- **WHEN** a variant is rendered at a size
- **THEN** it is that many logical pixels square, and circular

#### Scenario: Every type sits on the brand's subtle tint
- **WHEN** any variant is rendered
- **THEN** its background is `brandSubtle`

### Requirement: Initials wear the authored type style for their size

The type style SHALL be the one `21:121` binds for that size, which is **not**
a single style scaled: 24 and 32 use `label/sm`, 40 uses `label/md`, and 56 uses
`title/md`.

#### Scenario: Each size's style
- **WHEN** the initials variants are rendered at 24, 32, 40 and 56
- **THEN** their text styles are `label/sm`, `label/sm`, `label/md` and
  `title/md` respectively

#### Scenario: Initials are the brand's on-surface colour
- **WHEN** an initials variant is rendered
- **THEN** its text is `brandOnSurface`

#### Scenario: Initials are derived from a name, not passed as a string
- **WHEN** a display name is supplied
- **THEN** the initials shown are derived from it
- **AND** a name with one word yields one initial, a name with several yields
  two

#### Scenario: A name that yields nothing falls back
- **WHEN** the name is empty or has no letters
- **THEN** the icon type is shown instead of an empty circle

#### Scenario: Initials do not overflow their circle
- **WHEN** initials are rendered at the smallest size
- **THEN** the text stays inside the circle

### Requirement: The icon type carries the authored glyph size and colour

The glyph SHALL be `icon/user` at the size `21:121` binds for that avatar size —
14, 18, 22 and 28 — in `textSecondary`.

The sizes are four transcribed values, not a formula: 14, 18 and 22 are
`size / 2 + 2`, and 28 is `size / 2`. A formula fitted to the first three is
wrong at 56.

#### Scenario: Each size's glyph
- **WHEN** the icon variants are rendered at 24, 32, 40 and 56
- **THEN** their glyphs are 14, 18, 22 and 28 logical pixels

#### Scenario: The glyph is not the brand colour
- **WHEN** an icon variant is rendered
- **THEN** its glyph is `textSecondary`, which is what `21:120`'s exported
  stroke carries — not `brandOnSurface`, which is what the initials use

### Requirement: The image type takes an image and ships no loading

The image type SHALL accept an `ImageProvider` from the caller and SHALL NOT
fetch, cache or decode anything itself.

`21:121`'s description: *"Image variants are placeholders — apply a real image
fill on the instance."*

#### Scenario: A supplied image fills the circle
- **WHEN** an image is supplied
- **THEN** it fills the circle and is clipped to it

#### Scenario: No image supplied
- **WHEN** the image type is selected with no image
- **THEN** the initials are shown if a name is available, and the icon
  otherwise, rather than an empty circle
