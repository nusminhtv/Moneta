## 1. Spec Reconciliation

- [x] 1.1 Replace the frozen, no-screen Home plan with the six real screens from
  the Screen Index: `52:2`, `52:372`, `52:547`, `57:414`, `57:622` and
  `57:840`. Remove database, migration and preferences tasks from this change.
  Verify: OpenSpec artifacts name every screen node and no requirement asks for
  persistence.
- [x] 1.2 Update ADR 0004 so it records that its data-backed overview decision no
  longer applies to this Figma-screen implementation. Verify: the ADR names the
  concrete Home nodes and does not direct this change to edit `lib/data`.

## 2. Shared Home Components

- [x] 2.1 Implement `ListRow` (`35:113`) with all five variants: `Chevron`,
  `Value`, `Toggle`, `Badge` and `None`. Register every variant in
  `gallery_catalog_home.dart` and describe the distinguishing properties in
  `gallery_describe_home.dart`. Verify:
  `test/design_system/molecules/list_row_test.dart` and
  `test/app/gallery_test.dart`.
- [x] 2.2 Implement `SectionHeader` (`55:107`) and register it in the home
  gallery files. Verify:
  `test/design_system/molecules/section_header_test.dart` and
  `test/app/gallery_test.dart`.

## 3. Home-Only Components

- [ ] 3.1 Implement `DateGroupHeader` (`29:71`) and register its single variant.
  Verify: `test/design_system/molecules/date_group_header_test.dart`.
- [ ] 3.2 Implement `EmptyState` (`35:166`) with `HasAction=true` and
  `HasAction=false`. Register both variants. Verify:
  `test/design_system/molecules/empty_state_test.dart`.
- [ ] 3.3 Implement `Skeleton` (`38:139`) with `Line`, `Circle`, `Card` and
  `Row` variants. Register every variant. Verify:
  `test/design_system/molecules/skeleton_test.dart`.
- [ ] 3.4 Implement `Banner` (`42:329`) with `Warning`, `Danger`, `Info` and
  `Success` variants. Register every variant. Verify:
  `test/design_system/organisms/banner_test.dart`.

## 4. Home Screens

- [ ] 4.1 Read the sibling annotation frame for Home -- default (`52:2`) and
  implement the default Home screen in `lib/features/home`. Verify the rendered
  screen uses the components named by the Screen Index: `AppBar`, `BalanceCard`,
  `BottomNav`, `BudgetCard`, `DateGroupHeader`, `IconButton`, `SectionHeader`
  and `TransactionRow`. If the screen requires a `Transfer` or `Pending`
  `TransactionRow`, stop and report it.
- [ ] 4.2 Read the sibling annotation frame for Home -- empty (`52:372`) and
  implement the empty Home screen. Verify it uses `AppBar`, `BottomNav`,
  `EmptyState` and `ListRow`.
- [ ] 4.3 Read the sibling annotation frame for Home -- loading (`52:547`) and
  implement the loading Home screen. Verify it uses `AppBar`, `BottomNav` and
  the authored `Skeleton` variants.
- [ ] 4.4 Read the sibling annotation frame for Home -- over-budget alert
  (`57:414`) and implement the over-budget Home screen. Verify it uses `AppBar`,
  `BalanceCard`, `Banner`, `BottomNav`, `BudgetCard`, `DateGroupHeader`,
  `SectionHeader` and `TransactionRow`. If the screen requires a `Transfer` or
  `Pending` `TransactionRow`, stop and report it.

## 5. Notifications Screens

- [ ] 5.1 Read the sibling annotation frame for Notifications -- list (`57:622`)
  and implement the notifications list screen in `lib/features/notifications`.
  Verify it uses `AppBar`, `BottomNav`, `ListRow` and `SectionHeader`.
- [ ] 5.2 Read the sibling annotation frame for Notifications -- empty
  (`57:840`) and implement the notifications empty screen. Verify it uses
  `AppBar`, `BottomNav` and `EmptyState`.

## 6. Wiring and Close-Out

- [ ] 6.1 Add `/notifications` and replace the Home placeholder only inside the
  HOME marker block in `lib/app/router.dart`. Verify `test/app/router_test.dart`
  covers `/`, `/notifications` and the active Home tab.
- [ ] 6.2 Update `docs/design-system/figma-map.md` with the implemented Home and
  notifications screens, append any newly observed component values, and record
  any deliberate deviations with node ids. Verify the map names every component
  this branch implemented.
- [ ] 6.3 Update `docs/ai-workflow/evidence-log.md` with this change's verify
  runs and commits. Verify the entries match `git log`.
- [ ] 6.4 Run the full gate. Verify:
  `bash tool/verify.sh --change home-overview` passes and its evidence file is
  cited in the final commit.
