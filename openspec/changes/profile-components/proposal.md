## Why

`08.01 Profile` is the Profile tab's root and the tab currently lands on
`08.03 Settings` instead, because `Avatar` (`21:121`) does not exist. `08.02
Edit profile` is blocked on the same component. Building it unblocks the two
most visible screens on page 08.

Reading `21:121` also turned up a gap in the token set: every Avatar variant
fills `var(--brand-subtle, #1a1236)`, and `MonetaColors` has **no
`brandSubtle`**. It has `incomeSubtle`, `expenseSubtle`, `warningSubtle` and
`infoSubtle` — the brand's subtle tint is the one missing from the family.

## What Changes

- **`brandSubtle` added to `MonetaColors`** — `#1A1236`, read from `21:106`'s
  bound variable. A token, not a literal in a widget.
- **`MonetaAvatar`** (`21:121`) at its **full** authored variant set: 3 types
  (image, initials, icon) × 4 sizes (24, 32, 40, 56), all twelve.
- Registered in the gallery at all twelve, with a count test.

## Non-goals

- **Image loading.** `21:121`'s description: *"Image variants are placeholders —
  apply a real image fill on the instance."* So the image type takes an
  `ImageProvider` the caller supplies and ships no network or asset loading of
  its own, and no placeholder shimmer.
- **`Badge`, `Chip`, `SearchField`, `Numpad`** — the other four unbuilt page-08
  components. Each blocks a different screen and each is its own variant set;
  naming them here is what stops this change growing into all of page 08.
- **Any screen.** `profile-feature` composes these.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `design-system/components`: adds `Avatar`.
- `design-system/tokens`: adds the brand's subtle tint, completing the
  `*Subtle` family.

## Impact

- **Modules touched:** `lib/design_system/tokens/colors.dart`,
  `lib/design_system/atoms/moneta_avatar.dart` (new), the gallery catalog and
  describer, `docs/design-system/figma-map.md`.
- **Dependencies:** none. **Schema migration:** none.
- **Gates:** the token transcription tests (`colors_test.dart`,
  `token_provenance_test.dart`), gallery completeness, design tokens,
  architecture, tests, coverage.
- **Figma nodes consumed:** `21:121` and all twelve symbols; icon `11:20`. Read
  2026-09-10.
