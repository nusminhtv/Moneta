## Why

`📱 04 Budgets` (`5:17`) has seven screens and not one of them can be built. All
seven instance components the design system does not have: the overview needs a
period switcher and a ring, both budget details need KPI tiles, and the create
flow needs the hero amount entry.

The page number in `docs/design-system/figma-map.md` was wrong until 2026-08-28
— it listed `5:17` as "02 Budgets" — which is why this gap was not visible
earlier. The node id was right; the page number was not.

This change builds the components only. No budget domain, no table, no
repository, no screen. Those follow in `budgets-feature`, where the harder
question — what a budget *is* when the app has no accounts yet — gets decided.

## What Changes

Four components, each with the **full variant set** Figma authors:

| Component | Node | Variants |
| --- | --- | --- |
| `CircularProgress` | `25:272` | 9 — 3 states × 3 sizes |
| `SegmentedItem` | `36:167` | 2 — selected, unselected |
| `SegmentedControl` | `36:168` | 1 — composes 2–4 items |
| `StatTile` | `35:137` | 3 — Up, Down, Flat |
| `AmountInput` | `36:76` | 2 — Default, Error |

Two tokens the design binds and this repository does not have:

- `radii.sm = 10`, bound by `36:167`. `lib/design_system/tokens/radii.dart`
  currently carries a comment saying `radius-sm` "does not appear in any node
  read, and inventing it would put a value in the design system that the design
  file has never seen." That was true when written and is now false. The comment
  is corrected rather than deleted.
- `typography.headingH2` — Plus Jakarta Sans SemiBold 22/28, tracking -0.5,
  bound by `36:76`'s currency glyph.

Three things Figma authors that this change deliberately does **not** copy:

1. **`CircularProgress` has no TEXT property.** Its percentage labels — 62%, 88%,
   100% — are direct instance overrides, which annotation `04.01` flags as
   ledger entry I10. The Dart component takes a fraction and derives the label,
   so a ring reading 88% next to a bar reading 62% is not expressible.
2. **`AmountInput`'s error state "differs by colour only"** — Figma's own
   component description says so. Colour alone fails greyscale and fails a
   red-green viewer. The Dart component requires a message in the error state,
   so the state always carries a non-colour signal.
3. **`StatTile` maps `Direction=Up` to income green**, and its own default sample
   reads "Spent this month / +12.4% vs last month" in green — spending 12.4%
   more than last month, coloured as good news. The component keeps the authored
   mapping, because direction is the caller's choice and a tile is not only ever
   about spending. The sample is recorded in the map as a candidate for the
   file's twelve deliberate mistakes; it is not silently "fixed" here.

## Impact

- `lib/design_system/atoms/` — `moneta_circular_progress.dart`
- `lib/design_system/molecules/` — `moneta_segmented_control.dart`,
  `stat_tile.dart`, `amount_input.dart`
- `lib/design_system/tokens/` — `radii.dart`, `typography.dart`
- `lib/app/gallery/` — five new sections
- No `lib/features/`, no `lib/data/`, no migration. Nothing user-visible changes
  until `budgets-feature`.
