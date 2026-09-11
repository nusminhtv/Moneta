Ordered so the gate is green after every task.

## 1. Core

- [ ] 1.1 `Currency.groupSeparator`, `decimalSeparator` and `symbolLeads`,
  derived from `NumberFormat`'s symbols. Verified by `test/core/money_test.dart`:
  VND groups with `.` and has no decimal separator; USD groups with `,` and
  decimals with `.`; `symbolLeads` asserted **against `format()`'s own output**
  for every currency, so the derivation and the formatter cannot drift.
  **Mutation:** hard-code `symbolLeads` to true → the VND case must fail.
- [ ] 1.2 `Money.parse` takes the locale's separators, and grouping must be
  well formed (D1, D2). Verified by the same file: a round-trip over
  **`Currency.values`**; `1.500.000` VND and `1,500.00` USD; `1,250,000` VND
  still 1,250,000; `1.5` VND still a `FormatException`; `1.50.000`, `1,23,456`,
  `.500`, `1.500.00` all refused; `abc`, `''`, `12.345` USD still refused;
  `-5.00` and ungrouped `1500000` unchanged.
  **Mutation:** restore the comma-stripping parser → the round-trip must fail.
  **Mutation:** accept separators anywhere → the `1.5` case must fail.

## 2. The field

- [ ] 2.1 A grouping `TextInputFormatter` in
  `features/transactions/presentation`, regrouping the whole part and counting
  the caret in digits (D4, D5). Verified by
  `test/features/transactions/amount_input_formatter_test.dart`: `1500000`
  becomes `1.500.000`; deleting regroups; a mid-string insert keeps the caret
  with its digit; `12.` keeps its decimal point; an empty value stays empty.
  **Mutation:** put the caret at the end → the mid-string test must fail.
- [ ] 2.2 The sheet's amount field uses it and shows the currency on the side
  the locale puts it. Verified by
  `test/features/transactions/add_transaction_test.dart`: typing `1500000`
  shows `1.500.000`; submitting stores 1,500,000 đồng — **the round-trip in
  use, not merely held**; the symbol is a suffix for VND and a prefix for USD.
  **Mutation:** drop the formatter → the display test must fail.

## 3. Close-out

- [ ] 3.1 Record in `docs/design-system/figma-map.md` that the add sheet is
  still raw Material and does not use `AmountInput` (`36:76`), so the gap is
  written where a reader finds it rather than left in a proposal that gets
  archived. Verified by `rg` for the new text.
- [ ] 3.2 Full `tool/verify.sh --change amount-entry` green with its evidence
  file, every mutation recorded in `docs/ai-workflow/evidence-log.md`, and
  `change-verifier` consulted. Verified by the gate's summary and the verdict.
