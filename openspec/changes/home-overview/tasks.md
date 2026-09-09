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

- [x] 3.1 Implement `DateGroupHeader` (`29:71`) and register its single variant.
  Verify: `test/design_system/molecules/date_group_header_test.dart`.
- [x] 3.2 Implement `EmptyState` (`35:166`) with `HasAction=true` and
  `HasAction=false`. Register both variants. Verify:
  `test/design_system/molecules/empty_state_test.dart`.
- [x] 3.3 Implement `Skeleton` (`38:139`) with `Line`, `Circle`, `Card` and
  `Row` variants. Register every variant. Verify:
  `test/design_system/molecules/skeleton_test.dart`.
- [x] 3.4 Implement `Banner` (`42:329`) with `Warning`, `Danger`, `Info` and
  `Success` variants. Register every variant. Verify:
  `test/design_system/organisms/banner_test.dart`.

## 4. Home Screens

- [x] 4.1 Annotation `52:362` read. Reconcile the default Home screen in
  `lib/features/home` against it. The screen already exists; these four things are
  what the annotation changed:
  1. Add the **budgets section** — a `SectionHeader` with an action plus the
     `BudgetCard` entries authored at `52:125` and `52:143`. Home currently shows
     none.
  2. Raise the recent-list cap from four to **five** (`homeRecentLimit`). The
     annotation states the cap; the frame drawing four is one instance of it.
  3. **Safe-to-spend** becomes balance minus each current-period budget's
     unspent remainder, computed in `lib/app`, not the total balance passed
     through. Over **every** budget, never a display-capped subset. Omit the
     scheduled-bills term and record it as a deviation — do not invent the
     concept.
  4. **Quick actions** become Add, Transfer, Budgets, Goals per `52:66`–`52:105`,
     with Transfer and Goals rendered disabled because those features do not
     exist.

  Verify the rendered screen uses `AppBar`, `BalanceCard`, `BottomNav`,
  `BudgetCard`, `DateGroupHeader`, `IconButton`, `SectionHeader` and
  `TransactionRow`. **Check the variant of each `TransactionRow` instance on
  `52:2` (`52:177`, `52:214`, `52:246`, `52:276`) first**: if any is `Transfer` or
  `Pending`, stop and report it per D4 rather than implementing it.
- [x] 4.2 Read the sibling annotation frame for Home -- empty (`52:372`) and
  implement the empty Home screen. Verify it uses `AppBar`, `BottomNav`,
  `EmptyState` and `ListRow`.
- [x] 4.3 Annotation `52:630` read. Fix the loading Home screen against it. Two
  defects in the merged `_HomeLoading`:
  1. It renders **no app bar**. The annotation requires that *"AppBar and
     BottomNav render immediately; only the content area is skeletonised"* — as
     built, the bar appears when data lands, which is the layout jump the
     annotation exists to prevent. Assert the bar is present in both states and
     does not change height across the transition.
  2. Its skeleton composition is `Card x1, Line x1, Row x3`. The authored
     composition is **`Card x3, Circle x4, Line x6, Row x4`**, verified against
     the geometry of `52:564`–`52:594`: one card for the balance, four circles and
     four lines for the quick actions, two lines for the section headings, two
     cards for the budget cards, four rows for the transactions.

  Verify it uses `AppBar`, `BottomNav` and the authored `Skeleton` variants at
  those counts.
- [x] 4.4 Annotation `57:612` read. Implement the over-budget Home screen — this
  state does not exist in any form today, and `Banner` appears nowhere in
  `lib/features/home`. What the annotation pins:
  - **Trigger**: any active budget for the current period exceeding 100% of its
    limit. Below that, Home shows its default state.
  - **Ordering**: the over-limit `BudgetCard` sorts before on-track ones.
  - **Banner copy**: names the **worst category only**, even when several are
    over. Do not enumerate them.
  - **No quick-actions row** — `57:414` authors none, unlike `52:2`.

  Verify it uses `AppBar`, `BalanceCard`, `Banner`, `BottomNav`, `BudgetCard`,
  `DateGroupHeader`, `SectionHeader` and `TransactionRow`, and that the alert is
  not carried by colour alone. Check the `TransactionRow` variants on `57:517` and
  `57:551` as in 4.1; if either is `Transfer` or `Pending`, stop and report it.

  **Closed 2026-09-09, after the Figma outage lifted.** This sat implemented but
  unticked because the task's own verification step could not be performed: the
  variants of `57:517` and `57:551` were unreadable while access was down, and
  ticking would have claimed a check nobody made.

  Check performed: `57:517` is `Category=Shopping` and `57:551` is
  `Category=Food`, **both `Type=Expense`**. Neither is `Transfer` nor `Pending`,
  so the stop condition did not fire and the screen never needed the two
  unbuilt variants.

## 5. Notifications Screens

- [x] 5.1 Annotation `57:830` read. Implement the notifications list screen in
  `lib/features/notifications` — the feature directory does not exist yet. What
  the annotation pins beyond the component list:
  - **`AppBar/TitleBack`**, and the Home tab stays the active destination: this is
    a Home sub-screen, and the annotation calls a wrong active tab here *"a real
    defect, not a nitpick"*. The same fallback that keeps Budgets on Home applies.
  - Both `SectionHeader`s render **without an action**.
  - **Accessory follows actionability**: actionable notifications get
    `ListRowAccessory.chevron`, informational ones get `.none` — three and two
    respectively as authored. Derive it from the notification so that a chevron
    with nowhere to go is not representable.
  - **Grouped `Today` / `Earlier`, newest first**, by **local** day from the
    injected `Clock`. The gate pins `TZ=Asia/Ho_Chi_Minh`, so write the test to
    discriminate: a notification late on the local day whose UTC timestamp falls
    on another date must still land under `Today`.

  Read state stays out per D3. **That decided where notifications come from.**
  They cannot be stored, so they are *derived* in `lib/app` from budgets and the
  ledger on every read — which also means a notification disappears when the
  fact behind it stops being true.

  Reading the frame answered the content-model question the annotation summary
  could not. The five rows come from five different sources, and only three have
  a feature behind them: budget over limit (`57:662`), income received
  (`57:688`) and budget period ending (`57:773`). The other two need Accounts
  (`57:718`, a failed sync) and Goals (`57:740`, funding progress); both are
  left out rather than seeded, and `NotificationKind` is an enum so each becomes
  one case plus one derivation when those features land.

  Verify it uses `AppBar`, `BottomNav`, `ListRow` and `SectionHeader`.
- [x] 5.2 Read the sibling annotation frame for Notifications -- empty
  (`57:840`) and implement the notifications empty screen. Verify it uses
  `AppBar`, `BottomNav` and `EmptyState`.

## 6. Wiring and Close-Out

- [x] 6.1 Add `/notifications` and replace the Home placeholder only inside the
  HOME marker block in `lib/app/router.dart`. Verify `test/app/router_test.dart`
  covers `/`, `/notifications` and the active Home tab.
- [x] 6.2 Update `docs/design-system/figma-map.md` with the implemented Home and
  notifications screens, append any newly observed component values, and record
  any deliberate deviations with node ids. Verify the map names every component
  this branch implemented. This must additionally record:
  - The **fourth component page**, `🧩 Components / Charts` (`5:12`):
    `ChartLegendItem` `47:47` (9 variants), `DonutChart` `47:48`, `BarChart`
    `48:34`, `LineChart` `48:76`, `Sparkline` `48:94`. This closes the map's own
    open question — `BarChart` was not a screen-local frame, it was on a page
    never queried — and unblocks Budgets `04.07`. `5:13` is a separator page, so
    the library is four component pages, not three.
  - **Safe-to-spend omits scheduled bills**, naming annotation `52:362`, so the
    partial figure is not later mistaken for the authored one.
  - The **annotation-versus-frame corrections**: the recent-list cap of five, and
    the loading state's app bar.
  - Frame **`145:3776`**, a second frame named identically to `52:2` at 1215px
    tall — observed, not acted on, candidate for the twelve deliberate mistakes.
- [x] 6.3 Update `docs/ai-workflow/evidence-log.md` with this change's verify
  runs and commits. Verify the entries match `git log`.
- [x] 6.4 Run the full gate. Verify:
  `bash tool/verify.sh --change home-overview` passes and its evidence file is
  cited in the final commit.
