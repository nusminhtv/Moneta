## 1. Tokens

- [x] 1.1 Add `radii.sm = 10` with `borderSm`, sourced to `36:167`, and correct
      the comment in `radii.dart` that says `radius-sm` appears in no node read.
      Add `typography.headingH2` (Plus Jakarta Sans SemiBold 22/28, -0.5) from
      `36:76`. Extend the token transcription tests to both.

## 2. CircularProgress — `25:272`

- [x] 2.1 `lib/design_system/atoms/moneta_circular_progress.dart`: 3 sizes × 3
      states, state derived through `BudgetStatus.fromFraction`, label derived
      from the same fraction, no label parameter. Painted natively — an arc is
      a `CustomPainter`, not an asset.
- [x] 2.2 Tests: colour parity with `MonetaProgressBar` at the same fractions,
      the three diameters, `Sm` has no label, over-budget caps the sweep and
      still reports the true percentage, NaN/-inf/negative do not throw.
- [x] 2.3 Gallery: 9 variants.

## 3. SegmentedControl — `36:167` / `36:168`

- [x] 3.1 `lib/design_system/molecules/moneta_segmented_control.dart`: item in
      both variants, control taking 2–4 labels and a selected index, equal
      widths, 44px hit target around a 36px segment.
- [x] 3.2 Tests: exactly one selected, equal widths independent of label length,
      `onChanged` index including re-selecting the current one, hit target.
- [x] 3.3 Gallery: 2 item variants plus the composed control.

## 4. StatTile — `35:137`

- [x] 4.1 `lib/design_system/molecules/stat_tile.dart`: 3 directions, takes
      `Money`, arrow **and** colour.
- [x] 4.2 Tests: each direction's arrow and colour, a mutation removing the
      arrow fails, two tiles fit 353 with a 12 gap, long value does not clip.
- [x] 4.3 Gallery: 3 variants.

## 5. AmountInput — `36:76`

- [x] 5.1 `lib/design_system/molecules/amount_input.dart`: both states, tabular
      figures, error requires a message by type, caret excluded from semantics.
- [x] 5.2 Tests: error carries a message, width stable across digit changes,
      currency glyph per `Money`, caret absent from the semantics tree.
- [x] 5.3 Gallery: 2 variants.

## 6. Record what was found

- [x] 6.1 `docs/design-system/figma-map.md`: mark the five components done with
      their nodes, and record the three authored-but-not-copied decisions
      (I10 label overrides, colour-only error, `Direction=Up` green on a
      spending tile) in the deviations table with what was observed.
