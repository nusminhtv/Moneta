## 1. 08.03 Settings — List

- [x] 1.1 `lib/features/settings/presentation/settings_screen.dart` from
  `100:428`: four groups of `ListRow`s, presentational — values and callbacks
  in, no provider read.
  Verify: `test/features/settings/settings_screen_test.dart` asserts four
  section headers; that the trailing mapping holds for **every** row (D4); and
  that a row whose destination is unbuilt is visibly unavailable and does not
  navigate.
- [x] 1.2 The demo-mode toggle row and, in demo mode, the reset row (D2).
  Verify: the toggle reflects the stored setting; turning it on and off reports
  the change; reset is absent outside demo mode; reset asks before acting and
  declining changes nothing.

## 2. Composition

- [x] 2.1 `lib/app/settings_route_screens.dart` wires the screen to
  `DemoModeController`, and `lib/app/router.dart` points the Profile tab at it.
  Verify: `test/app/router_test.dart` reaches Settings from the Profile tab; the
  architecture gate stays green.
- [x] 2.2 Close `demo-data`'s group 7 as superseded (D1) — the provisional
  screen is not built, because the authored one now is.
  Verify: `demo-data`'s tasks say superseded and name this change.

## 3. Close-Out

- [x] 3.1 `docs/design-system/figma-map.md`: record page 08 — `08.03` built,
  `08.01` deferred behind `Avatar` (`21:121`), and the other nine deferred with
  what blocks each.
  Verify: the entry names every deferred screen and its blocker.
- [x] 3.2 Run the full gate.
  Verify: `bash tool/verify.sh --change profile-feature` passes.

## 4. 08.01 Profile — The Tab's Root

- [x] 4.1 `lib/features/settings/presentation/profile_screen.dart` from
  `100:2`: identity (Avatar 56 + names + ghost button), three **local** stat
  tiles, `SectionHeader`, the menu, and a large-title bar whose action is
  **sliders** rather than a bell (`100:266`).
  Verify: the avatar derives its initials from the name; the tiles are local and
  the source cannot reach `StatTile` at all; the three tiles share the row
  evenly; sign-out is the only label off `text/primary`; the action is sliders
  and opens Settings; and the figure count is asserted at three because
  `100:60` shows three. Five mutations fail.
- [x] 4.2 The Profile tab now lands on `08.01`, with `08.03` pushed from it.
  Verify: `bash tool/verify.sh --change profile-feature` passes.

