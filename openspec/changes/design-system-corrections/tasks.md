> ## ⛔ FROZEN — 2026-08-25
>
> This change was planned on a false premise: that the Figma file contains no
> screen designs. It contains 74 screens, and the project never opened them
> because `get_metadata` without a `nodeId` returns an incomplete page list.
>
> Do not implement any of the tasks below. The `figma-fidelity` agent is
> reconciling what has already been built against the real designs; this change
> is reopened, revised or discarded once that lands.
>
> See `docs/design-system/figma-map.md` for the correction.

## 1. Balance card takes a date

- [ ] 1.1 Change `BalanceCard.safeToSpendUntil` to a `DateTime` and add
  `static String formatPeriodEnd(DateTime, {String? locale})` using the `d MMM`
  form the card's Figma fixture shows, following the precedent
  `TransactionRow.formatTimeOfDay` already set. Update
  `lib/app/gallery/gallery_catalog.dart`, the only caller. Verify:
  `test/design_system/organisms/balance_card_test.dart` asserts the rendered
  safe-to-spend line for a known date, and that `formatPeriodEnd` renders the
  **local** date — asserted so it fails if the conversion is skipped, which the
  gate's pinned `TZ=Asia/Ho_Chi_Minh` makes possible (a UTC run cannot tell).

  Note what this task actually changes: the test file constructs `BalanceCard` at
  two places (`:24`, `:219`), so both must be updated. The existing masked
  no-digit assertion is unchanged in *substance* but its surrounding constructor
  call is not — an earlier draft claimed the test "still passes unchanged", which
  was false.

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

- [ ] 3.1 Add a `TransactionRow` section to `galleryCatalog` with **three**
  variants: expense, income, and masked. Two would drop the income/expense
  distinction that `figma-map.md` records as this component's variant set and that
  the spec keeps as separate scenarios — and it would defeat this change's own
  point, since D2's claim that the mask hides direction is only checkable by
  seeing an expense row, an income row and a masked row together.

  Label them by what they are (`Expense`, `Income`, `Masked`) rather than in
  Figma's `State=` form: the archived gallery requirement says variants are
  "labelled by its **Figma** variant name", and this component has no Figma node,
  so borrowing Figma-shaped names would imply a source that does not exist.
  Verify: `test/app/gallery_test.dart` asserts the new section has exactly three
  variants with those labels, and the component-order assertion is extended rather
  than loosened.
- [ ] 3.2 Update `docs/adr/0003-transaction-row-layout.md` with the masked form:
  the row has no Figma source, so a masked variant is a *new designed variant* and
  belongs in the ADR that decided the row's design, not only in the change log.
  Record what is masked, what is not, and why the mask is neutral-coloured. Verify:
  ADR 0003 has a revision-history entry and the masked form is described there.
- [ ] 3.3 Record the asymmetry from design decision D2 — a masked row hides its
  direction while the masked card keeps its income and expense labels — in
  `docs/design-system/figma-map.md` under recorded deviations, and note that the
  row's masked form has no Figma source. Verify: the deviation table has the new
  row and names the reason.
- [ ] 3.4 Run the full gate and confirm both masked forms on a simulator
  screenshot of the gallery route. Verify:
  `bash tool/verify.sh --change design-system-corrections` passes, and the reply
  states whether the two masks read as one system or look like two different
  treatments — if the latter, that is a finding, not a pass.
