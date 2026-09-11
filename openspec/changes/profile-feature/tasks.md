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

## 5. 08.06 Settings — Notifications

- [x] 5.1 `lib/features/settings/presentation/notification_settings_screen.dart`
  from `101:618`: four groups, six rows — four Toggle and **two Value**,
  because `101:862` says *"a time is not a boolean. This is the mapping mistake
  from 08.03 seen from the other side."*
  Verify: the four group headings are the authored ones; the two time rows are
  Value with no `onToggle`; the defaults are mixed; the whole row is the tap
  target.
- [x] 5.2 The switches **actually silence notifications**, via
  `lib/app/notification_preferences.dart` and a gate in
  `notificationsProvider`.
  Verify: each kind is gated by its own switch; silencing one leaves the others
  audible; every `NotificationKind` is covered. Five mutations fail.
- [x] 5.3 Two fixes to `ListRow` that `35:70`'s description required — a 56px
  minimum and the whole row as the tap target.
  Verify: title-only rows clear 56px; tapping a toggle row's title toggles it.

## 6. Still Deferred, With Blockers

- [ ] 6.1 `08.02` Edit profile (`100:276`) — Avatar now exists, but there is no
  identity to edit: no accounts feature, no stored profile.
- [ ] 6.2 `08.04` Security (`100:729`) — every row leads to auth or biometrics
  that do not exist, so the screen would be disabled rows.
- [ ] 6.3 `08.05` Change PIN (`101:488`) — `Numpad` (`36:92`) and `OtpField`
  both exist now (`settings-components`, 2026-09-11). What remains is a **PIN
  store**: somewhere to keep a PIN and something that asks for it.
- [ ] 6.4 `08.07` Currency & language (`101:863`) — needs multi-currency;
  `walletCurrencyProvider` is a single fixed `Currency.vnd`.
- [ ] 6.5 `08.08` Manage categories (`101:978`) — `Chip` (`17:65`) exists now.
  What remains: categories are a fixed enum in `lib/core`, so rename, reorder
  and archive have nowhere to persist. The screen's *usage* half — real counts
  and totals per category, which its Purpose asks for — needs nothing new.
  Note `Chip` now occupies 44px against the file's 34, so the filter row's
  layout shifts; recorded in `figma-map.md`.
- [ ] 6.6 `08.09` Edit category (`102:794`) — same store, plus a colour
  override that every chart and `CategoryIcon` must read. `SpendCategory`'s
  `chartSlot` is a fixed enum property, so this is an app-wide resolution layer,
  not a screen.
- [ ] 6.7 `08.10` Premium paywall (`102:1044`) — no purchases.
- [ ] 6.8 `08.11` Help & FAQ (`102:1189`) — `SearchField` exists now, and the
  answers are static content the annotation says restate the product's own
  behaviour. **Nothing blocks this screen any more.**

