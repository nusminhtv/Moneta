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

- [ ] 3.1 Add migration `v2` creating `settings`, and a minimal
  `PreferencesStore` supporting one boolean key. Verify:
  `test/data/preferences_store_test.dart` covers write/read, absence, a malformed
  value as a storage failure, and durability across close and reopen; and
  `test/data/migrations_test.dart` asserts v1 rows survive the upgrade.

## 4. Onboarding

- [x] 4.1 ~~Download the six decorative illustration SVGs~~ — **not needed.**
  Reading them showed every value is a token: halo = the slot's `chart-N-subtle`,
  ring = `border-subtle`, accent dots = `chart-N` at 50%. Drawn natively in
  `OnboardingIllustration` instead, which keeps it under
  `check_design_tokens.dart` — a gate that cannot see inside an SVG.
- [ ] 4.2 Implement the controller: read the flag, record completion on finish or
  skip, fall back to showing on a failed read. Verify:
  `onboarding_controller_test.dart` covers first run, after finish, after skip,
  and a failing store.
- [x] 4.3 Implement the three slides and the splash, transcribing copy, spacing
  and type from `71:2`, `71:37`, `71:103` and `71:162`. Verify:
  `onboarding_screen_test.dart` asserts three slides, the indicator following
  swipes, Skip absent on the last slide, and the forward action finishing.
- [ ] 4.4 Wire the router to choose between onboarding and the shell at startup.
  Verify: `test/app/router_test.dart` covers both branches.

## 5. Close-out

- [ ] 5.1 Run the full gate, update `figma-map.md` with Button, PaginationDots and
  the onboarding screens. Verify: `bash tool/verify.sh --change onboarding-flow`.
- [ ] 5.2 Run on the simulator and commit a screenshot of each slide. Verify: the
  screenshots match the Figma frames side by side.
