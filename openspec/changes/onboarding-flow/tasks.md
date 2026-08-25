## 1. Tokens

- [x] 1.1 Add Figma's twelve `space/*` values to `MonetaSpacing` under Figma's
  names, leaving the existing scale in place and marking it deprecated in its doc
  comment with the correct replacement named. Add `borderStrong` (18% white),
  `textSecondary` (`#9AA3B4`) and the `bodyLg` type style (Inter 400 16/24).
  Verify: `test/design_system/tokens/spacing_test.dart` asserts all twelve values
  against `docs/design-system/figma-tokens.md`, and the existing token tests still
  pass unchanged.

## 2. Atoms and molecules

- [x] 2.1 Implement `MonetaButton` from `13:2` — 5 styles × 3 sizes × 3 states,
  resolved through tables rather than branches. Verify:
  `test/design_system/atoms/moneta_button_test.dart` is table-driven over all 45
  combinations asserting background, foreground and height, plus that `Loading`
  renders a spinner at the same width as `Default` with the same label.
- [x] 2.2 Implement `MonetaPaginationDots` from `70:223`. Verify:
  `test/design_system/molecules/pagination_dots_test.dart` asserts the active dot
  is both wider and brand-coloured, that exactly one is active, and that width
  alone identifies position.

## 3. Storage

- [x] 3.1 Add migration `v2` creating `settings`, and a minimal
  `PreferencesStore` supporting one boolean key. Verify:
  `test/data/preferences_store_test.dart` covers write/read, absence, a malformed
  value as a storage failure, and durability across close and reopen; and
  `test/data/migrations_test.dart` asserts v1 rows survive the upgrade.
  The upgrade assertion landed in `test/data/database_test.dart` (`upgrades an
  existing database forward, preserving rows`) rather than a new file — it needed
  the `AppDatabase` harness already there. Three tests in that file hardcoded
  version 2 and broke on the bump; they are now written relative to
  `schemaVersion`, and the upgrade test had to move off `inMemoryDatabasePath`,
  where two opens are two different databases and the test proved nothing.

## 4. Onboarding

- [x] 4.1 ~~Download the six decorative illustration SVGs~~ — **not needed.**
  Reading them showed every value is a token: halo = the slot's `chart-N-subtle`,
  ring = `border-subtle`, accent dots = `chart-N` at 50%. Drawn natively in
  `OnboardingIllustration` instead, which keeps it under
  `check_design_tokens.dart` — a gate that cannot see inside an SVG.
- [x] 4.2 Implement the controller: read the flag, record completion on finish or
  skip, fall back to showing on a failed read. Verify:
  `onboarding_providers_test.dart` (9 tests) covers first run, completion
  recorded, an explicit `false`, a corrupt stored value, a failing read, a store
  that cannot be built, idempotent completion, and a failed write that does not
  crash the caller. Named `_providers_` not `_controller_`: it is two providers,
  not a Notifier, so a name promising a controller would have been misleading.
  The shared providers moved to `lib/data/app_providers.dart` — a second feature
  needed them and cross-feature imports are forbidden. That file then failed the
  85% coverage gate at 70%, exactly as the `home-overview` audit predicted; fixed
  by assigning `databaseFactory = databaseFactoryFfi` so the **production**
  provider bodies run, rather than overriding the providers and leaving the
  shipped code unexecuted.
- [x] 4.3 Implement the three slides and the splash, transcribing copy, spacing
  and type from `71:2`, `71:37`, `71:103` and `71:162`. Verify:
  `onboarding_screen_test.dart` asserts three slides, the indicator following
  swipes, Skip absent on the last slide, and the forward action finishing.
- [x] 4.4 Wire the router to choose between onboarding and the shell at startup.
  Verify: `test/app/router_test.dart` group `startup` — opens on the splash and
  not on a destination, a first run reaches the introduction, a returning run
  goes straight to the shell with Home active, and finishing records completion
  exactly once before landing on Home. `--dart-define=MONETA_INITIAL_ROUTE` was
  not taking effect, so `/splash` became the router's default, which is what the
  design specifies anyway.

  Two gaps found while closing this task, both now fixed:
  `router_test.dart` mentioned neither splash nor onboarding, so 4.4's stated
  verification did not exist; and `splash_screen.dart` sat at **0% coverage**
  (26 lines, carrying the first-run decision) because `features/*/presentation`
  is not in `tool/coverage_critical.txt`. `splash_screen_test.dart` now covers
  the brand copy, both decisions, that a fast read still waits out the minimum so
  the splash cannot flash, that a slow read holds it, that it hands over once,
  and that it stays silent after being navigated away from.

  Four mutations confirm these tests discriminate: inverting the first-run branch
  kills 3, dropping the completion write kills exactly the completion test,
  removing the minimum-duration wait kills the flash test, and removing the
  `mounted` guard kills the unmount test.

## 5. Close-out

- [x] 5.1 Run the full gate, update `figma-map.md` with Button, PaginationDots and
  the onboarding screens. Verify: `bash tool/verify.sh --change onboarding-flow`.
  The map also gained the pages actually inspected (`5:14`, `5:17`, `29:70`,
  `107:75`) in place of the stale claim that no screen frames were reachable, a
  `Screens implemented` section naming the four nodes and the eight screens on
  that page still unbuilt, and a duplicate `PaginationDots` row was removed.
- [x] 5.2 Run on the simulator and commit a screenshot of each slide. Verify: the
  screenshots match the Figma frames side by side.
  **Partially done, and the shortfall is recorded rather than papered over.**
  Committed: `splash-ios.png`, `onboarding-slide-1-ios.png`,
  `second-launch-home-ios.png`, plus the uninstall → launch → external-write →
  relaunch sequence proving the introduction shows exactly once and that the real
  platform plugin applied migration v2 (`user_version` = 2, `settings` present,
  empty until completion).
  **Not done:** slides 2 and 3 on device. Tap injection was unavailable —
  the native simulator integration needs `sudo xcode-select -s` and the
  AppleScript fallback needs assistive access, neither grantable from this
  session. Those slides are covered by widget tests but their type and spacing
  have not been compared against `71:103` and `71:162` on a real device.
  A misnamed `onboarding-01-02-ios.png` was removed: it showed slide 1 only,
  while its name implied two slides.
