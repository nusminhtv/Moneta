## Why

The Home tab and notifications flow have real Figma screens. The previous
`home-overview` proposal was frozen because it said the opposite and then planned
database, preference and layout work from that false premise.

This revision is based on the Screen Index at node `5:24`, which lists six
screens for `📱 02 Home & Dashboard`:

| ID | Screen | Node | Priority |
| --- | --- | --- | --- |
| 02.01 | Home -- default | `52:2` | P0 |
| 02.02 | Home -- empty | `52:372` | P0 |
| 02.03 | Home -- loading | `52:547` | P0 |
| 02.04 | Home -- over-budget alert | `57:414` | P0 |
| 02.05 | Notifications -- list | `57:622` | P1 |
| 02.06 | Notifications -- empty | `57:840` | P1 |

Each screen has a sibling annotation frame in Figma that must be read before its
layout is implemented. This repository does not currently contain those
annotation contents, and this session has no callable Figma inspection tool; the
node ids above are the exact queries required before final screen construction.

The user-visible outcome is a Home tab that matches the four Home states, a
notifications route that matches the two notification states, and a gallery that
shows every home-owned component variant.

## What Changes

- Implement these home-owned design-system component sets in full:
  - `DateGroupHeader` (`29:71`), 1 variant.
  - `EmptyState` (`35:166`), 2 variants: `HasAction=true` and `HasAction=false`.
  - `Skeleton` (`38:139`), 4 variants: `Line`, `Circle`, `Card`, `Row`.
  - `ListRow` (`35:113`), 5 variants: `Chevron`, `Value`, `Toggle`, `Badge`,
    `None`.
  - `SectionHeader` (`55:107`), 1 variant.
  - `Banner` (`42:329`), 4 variants: `Warning`, `Danger`, `Info`, `Success`.
- Register every variant in `lib/app/gallery/gallery_catalog_home.dart` and teach
  `test/app/gallery_describe_home.dart` how to distinguish them.
- Implement `lib/features/home` for the four Home screens listed above, using the
  existing `BalanceCard`, `BudgetCard`, `BottomNav` and `TransactionRow` widgets
  where the Figma Screen Index names them.
- Implement `lib/features/notifications` for the notifications list and empty
  screens, using `ListRow`, `SectionHeader`, `EmptyState`, `BottomNav` and the
  shared `AppBar` once the auth branch lands it.
- Add routes only in the `HOME` marker block: `/` remains the Home tab and
  `/notifications` is the notifications route.
- Reconcile ADR 0004 against the actual screens: the old database-backed
  cross-feature overview decision no longer applies to this change.

## Capabilities

### New Capabilities

- `home`: Home default, empty, loading and over-budget alert states from nodes
  `52:2`, `52:372`, `52:547` and `57:414`.
- `notifications`: notification list and empty states from nodes `57:622` and
  `57:840`.

### Modified Capabilities

- `design-system/components`: adds full variant coverage for `DateGroupHeader`,
  `EmptyState`, `Skeleton`, `ListRow`, `SectionHeader` and `Banner`.

## Non-goals

- No database schema changes, migrations, preferences table or persistence work.
- No notification read-state until the user explicitly approves a persistence
  design.
- No changes under `lib/features/auth`, `lib/data/database`, auth-owned
  design-system files, `gallery_catalog_auth.dart` or
  `gallery_describe_auth.dart`.
- No completion of `TransactionRow`'s missing `Transfer` or `Pending` variants.
  If nodes `52:2` or `57:414` require either one, this change stops for a domain
  decision instead of inventing it.
- No widening, weakening or bypassing verification gates.

## Impact

- **Modules touched:** home-owned design-system components, `lib/features/home`,
  `lib/features/notifications`, home gallery catalog/describer, Home marker
  blocks in app routing and gallery tests, and `openspec/changes/home-overview`.
- **Dependencies:** none expected.
- **Schema migration:** none. The database schema remains single-writer for the
  auth branch.
- **Gates affected:** design-token checks for new UI code, gallery completeness,
  architecture, tests and coverage through `bash tool/verify.sh --change
  home-overview`.
- **Figma nodes consumed so far:** Screen Index `5:24` as recorded in
  `docs/ai-workflow/parallel-brief-home-dashboard.md` and component inventory in
  `docs/design-system/figma-map.md`. The six sibling annotation frames still need
  live Figma access before implementation can claim visual fidelity.
