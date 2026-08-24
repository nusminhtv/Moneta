## 1. Balance card takes a date

- [ ] 1.1 Change `BalanceCard.safeToSpendUntil` to a `DateTime` and add
  `static String formatPeriodEnd(DateTime, {String? locale})` using the `d MMM`
  form the card's Figma fixture shows, following the precedent
  `TransactionRow.formatTimeOfDay` already set. Update
  `lib/app/gallery/gallery_catalog.dart`, the only caller. Verify:
  `test/design_system/organisms/balance_card_test.dart` asserts the rendered
  safe-to-spend line for a known date, that `formatPeriodEnd` converts to local
  time exactly once, and that the existing masked no-digit test still passes
  unchanged; the project compiles with no other caller edits.

## 2. Transaction row gains a masked form

- [ ] 2.1 Add `masked` (defaulting to `false`) to `TransactionRow`, rendering a
  fixed-width mask in place of the amount, with no sign, in `textTertiary`.
  Verify: `test/design_system/molecules/transaction_row_test.dart` asserts, in a
  new group, that no digit from the amount appears, that neither `+` nor `−`
  appears, that the mask is neither the income nor the expense colour, that two
  very different amounts produce identical rendered text, that the disc, title and
  time remain, and that the masked row's height equals the unmasked row's.
- [ ] 2.2 Confirm every existing `TransactionRow` call site and test is unaffected
  by the new parameter. Verify: the full suite passes with no edits to existing
  row assertions, and `masked` is absent from every current call site.

## 3. Gallery and close-out

- [ ] 3.1 Add a `TransactionRow` section to `galleryCatalog` with both forms,
  labelled `State=Default` and `State=Masked` to match the naming the other
  sections use. Verify: `test/app/gallery_test.dart` asserts the new section has
  exactly two variants and that the component list's expected order is updated —
  the catalogue is a contract, so the count assertion must be extended rather
  than loosened.
- [ ] 3.2 Record the asymmetry from design decision D2 — a masked row hides its
  direction while the masked card keeps its income and expense labels — in
  `docs/design-system/figma-map.md` under recorded deviations, and note that the
  row's masked form has no Figma source. Verify: the deviation table has the new
  row and names the reason.
- [ ] 3.3 Run the full gate and confirm both masked forms on a simulator
  screenshot of the gallery route. Verify:
  `bash tool/verify.sh --change design-system-corrections` passes, and the reply
  states whether the two masks read as one system or look like two different
  treatments — if the latter, that is a finding, not a pass.
