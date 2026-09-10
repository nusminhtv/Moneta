## Why

The Profile tab is a placeholder, and `demo-data`'s toggle has nowhere to live —
it is a callable operation with tests and no control on screen. `📱 08 Profile &
Settings`' Settings list (`100:428`) is the authored home for exactly that kind
of switch, and it needs no component that does not already exist.

So this change builds the settings router and, on it, the demo-mode switch —
which is what turns fifteen months of generated ledger from a test fixture into
something a person can look at.

## What Changes

- **08.03 Settings — list.** Four grouped sections of `ListRow`s. Annotation
  `100:716`: *"The router for the whole flow. Grouped so that a user hunting for
  one switch scans four short lists instead of one long one."*
- **The demo-mode switch**, as a `ListRow` with a **Toggle** trailing, plus
  reset behind a confirmation. This closes `demo-data`'s group 7, which had
  planned a provisional screen while Figma was unreadable — the authored screen
  exists now, so the provisional one is not built at all.
- **The Profile tab points at Settings** for the moment, because `08.01` is
  deferred (below).
- **A `settings` capability**: what the list contains, which trailing each row
  takes and why, and how the demo switch behaves.

## Non-goals

Deferred, named rather than dropped, under an explicit instruction to skip
blockers and revisit:

- **08.01 Profile — default** (`100:2`). Needs `Avatar` (`21:121`, 12 variants),
  an authored component set that is not built. Building it is a design-system
  change with its own full-variant obligation, not part of a settings list.
- **08.02 Edit profile, 08.04 Security, 08.05 Change PIN, 08.06 Notifications,
  08.07 Currency & language, 08.08 Manage categories, 08.09 Edit category,
  08.10 Premium paywall, 08.11 Help & FAQ.** Nine screens, several blocked on
  unbuilt components — `Numpad` (`36:92`) for 08.05, `SearchField` for 08.11,
  `Chip` (`17:65`) for 08.08. The rows that lead to them are built and their
  destinations are not, which the spec states rather than hides.
- **Any real authentication, biometrics or purchase.** The rows exist; the
  flows behind them do not.

## Capabilities

### New Capabilities

- `settings`: the grouped list, the trailing-variant mapping that is its
  information design, and the demo-mode switch.

### Modified Capabilities

- `demo-data`: the provisional settings surface it specified is replaced by the
  authored one. Its requirement about the controls being reachable is unchanged
  in substance — the surface is simply `100:428` rather than an invented screen.

## Impact

- **Modules touched:** `lib/features/settings/presentation` (new),
  `lib/app/settings_route_screens.dart` and `lib/app/router.dart`,
  `docs/design-system/figma-map.md`.
- **Dependencies:** none. **Schema migration:** none. **New components:** none.
- **Gates:** architecture, design tokens, tests, coverage.
- **Figma nodes consumed:** screen `100:428`, annotation `100:712`,
  `ListRow` `35:113`. Read 2026-09-10.
