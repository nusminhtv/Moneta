## 1. Token harvest and token layer

- [x] 1.1 Read the remaining token values out of Figma — the five unobserved
  `chart-N` / `chart-N-subtle` slots, the full radius and spacing scales, and all
  elevation effects — and record every value with its source node in
  `docs/design-system/figma-tokens.md`. Verify: every colour, radius, spacing and
  elevation token named in `specs/design-system/tokens/spec.md` has a row with a
  Figma node id. If a value cannot be read from Figma, stop and ask — do not
  interpolate the chart palette.
- [x] 1.2 Implement `lib/design_system/tokens/colors.dart` (surface, text, border,
  brand, semantic, 8-slot chart palette, brand gradient). Verify:
  `test/design_system/tokens/colors_test.dart` asserts every hex value from
  task 1.1 and that the chart palette has exactly 8 base + 8 subtle entries.
- [x] 1.3 Bundle the Inter and Plus Jakarta Sans font files, declare them in
  `pubspec.yaml`, and implement `lib/design_system/tokens/typography.dart` with
  the six named styles. Verify: `test/design_system/tokens/typography_test.dart`
  asserts family, size, weight, height and letter spacing for all six, and
  `flutter test` renders without a font-fallback warning.
- [x] 1.4 Implement `spacing.dart`, `radii.dart`, `elevation.dart`, `motion.dart`.
  Verify: `test/design_system/tokens/tokens_test.dart` asserts radius 18/24/pill
  and both shadow effects against the task 1.1 values.

## 2. Theme and shared domain

- [x] 2.1 Implement `MonetaTheme extends ThemeExtension<MonetaTheme>` in
  `lib/design_system/theme/`, a `BuildContext.moneta` accessor, and the
  `ThemeData` factory; wire it into `lib/app/app.dart`. Verify:
  `test/design_system/theme/moneta_theme_test.dart` reads every token group from a
  pumped widget's context, and asserts a test-supplied override reaches the widget.
- [x] 2.2 Add `SpendCategory` to `lib/core` carrying a chart-slot index and an icon
  name (no `Color` — `lib/core` stays Flutter-free), plus the design-system
  resolver from slot to colour. Verify: `test/core/spend_category_test.dart`
  asserts every category maps to a distinct slot in range, and
  `dart run tool/check_architecture.dart` passes.

## 3. Icons

- [x] 3.1 Export the 50 icons from Figma node `5:7` into `assets/icons/`, declare
  the directory in `pubspec.yaml`, and implement `MonetaIcons` (name → asset) and
  `MonetaIcon` (size and colour from tokens). Verify:
  `test/design_system/atoms/moneta_icon_test.dart` enumerates the catalogue,
  asserts 50 entries, loads each asset from the bundle so a missing file fails in
  CI, and asserts stroke weight 1.75 on every stroked icon.

## 4. Molecules

- [x] 4.1 Implement `ProgressBar` (fraction-driven, 3 derived colours × 2 sizes).
  Verify: `test/design_system/molecules/progress_bar_test.dart` asserts fill width
  is proportional at 0/0.5/1.0, clamps below 0 and above 1, and never exceeds the
  track width.
- [x] 4.2 Implement `CategoryIcon` (8 categories × 3 sizes) using `SpendCategory`.
  Verify: `test/design_system/molecules/category_icon_test.dart` asserts each
  category renders its own tint and glyph, and that the same category is identical
  across all three sizes apart from geometry.

## 5. Organisms

- [ ] 5.1 Implement `BalanceCard` (Default, Masked) on the gradient token, taking
  four `Money` values and an `onToggleMask` callback. Verify:
  `test/design_system/organisms/balance_card_test.dart` asserts formatted amounts
  with signs in Default, asserts **no digit** appears anywhere in the render tree
  in Masked, asserts the eye/eye-off icon swap, and asserts a zero balance renders
  as a formatted zero.
- [ ] 5.2 Implement `BudgetStatus.fromSpend` and `BudgetCard(spent, limit,
  category, ...)` with no `state` parameter. Verify:
  `test/design_system/organisms/budget_card_test.dart` is table-driven over 0%,
  79%, 80%, 100%, 101%, 400% and zero-limit-with-spend, asserting amount/note/bar
  colour and the expense border only above the limit; plus a long-name test
  asserting single-line ellipsis with the amount not displaced.
- [ ] 5.3 Implement `BottomNav` (4 destinations, centre FAB, bottom safe area).
  Verify: `test/design_system/organisms/bottom_nav_test.dart` asserts exactly one
  active destination per variant with all four colours checked, that the FAB
  reports a distinct callback and does not change the active destination, and that
  a `MediaQuery` bottom inset pushes the tab row up while the background extends
  through it.

## 6. Gallery and close-out

- [ ] 6.1 Add a `/gallery` route in `lib/app` rendering every component in every
  variant, labelled by Figma variant name. Verify:
  `test/app/gallery_test.dart` asserts one labelled entry per component per
  variant and that the count matches `docs/design-system/figma-map.md`.
- [ ] 6.2 Update `docs/design-system/figma-map.md` (widget paths, status, the
  resolved `display/amount-xl` letter-spacing ambiguity) and run the full gate.
  Verify: `bash tool/verify.sh --change design-system-foundation` passes, and the
  `change-verifier` agent returns SHIP with no unresolved blocking items.
