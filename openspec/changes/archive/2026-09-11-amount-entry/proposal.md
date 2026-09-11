## Why

Typing an amount into the add-transaction sheet gives you `1500000`. No
grouping, no currency — reported from the screen, and the fix is not where it
looks.

**`Money.parse` cannot read what `Money.digits()` writes**, for the app's own
primary currency:

```
VND: digits() = "1.500.000"   parse("1.500.000") → FormatException
USD: digits() = "1,500.00"    parse("1,500.00")  → 150000 ✓
```

`Money.parse` strips commas and treats `.` as the decimal point — the en-US
convention — while `format` and `digits` are locale-aware and group VND with
dots, because `vi_VN` does. So the two halves of the same class disagree, and
they disagree on the currency almost every amount in this app is in. Grouped
VND could not be typed in even if the field offered it.

The user-visible outcome: amounts group as you type — `1.500.000` — and the
field says which currency it is in.

## What Changes

- **`Money.parse` becomes locale-aware.** It accepts the currency's own
  grouping separator as well as a comma, and treats only the currency's decimal
  separator as a decimal point. Grouping, when present, must be **well formed**
  — groups of three — so `1.5` in VND stays a `FormatException` rather than
  silently becoming 15. That case is already tested and keeps its answer.
- **`Currency` publishes what a locale decided**: its grouping separator, its
  decimal separator, and whether the symbol leads the number. All three are
  read from `NumberFormat`'s own symbols rather than transcribed, so a currency
  added later needs no table update.
- **The amount field groups as you type**, through a `TextInputFormatter` that
  regroups the digits after every edit and keeps the caret where the user put
  it.
- **The amount field shows the currency**, on the side the locale puts it —
  `₫` after for VND, `$` before for USD.

## Non-goals

- **No change to `format` or `digits`.** They were already right; the parser was
  the half that was wrong.
- **No multi-currency.** The sheet still uses `walletCurrencyProvider`'s single
  currency. This change makes the *entry* honest about which one that is.
- **No redesign of the add sheet.** It is still raw Material — a
  `DropdownButtonFormField`, an `InputDecoration`, a `ButtonSegment` — and does
  not use `AmountInput` (`36:76`), the component this project built for amount
  entry. That gap is real and is recorded rather than fixed here: replacing the
  sheet's chrome is a screen change against page 03, not a fix to a defect in
  `core`.
- **No decimal entry for VND.** A currency with no decimals accepts no decimal
  separator, which is what it already does.

## Capabilities

### Modified Capabilities

- `transactions`: what the amount field shows while it is being typed into, and
  that the parser accepts what the formatter produces.

## Impact

- **`lib/core/money.dart`** — `Money.parse`, and three getters on `Currency`.
  `lib/core` is a critical path at ≥85% coverage.
- **`lib/features/transactions/presentation/`** — the grouping formatter and
  the sheet's amount field.
- **`test/core/money_test.dart`** — the round-trip that could not have passed
  before, and the malformed-grouping cases.
- **One existing assertion is load-bearing and keeps its answer**:
  `Money.parse('1,250,000', Currency.vnd)` is 1,250,000 today even though `,`
  is not VND's separator. Commas stay accepted, because that is a shipped
  contract and a US keyboard is a real thing.
