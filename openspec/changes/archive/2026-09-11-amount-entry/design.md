## Context

See `proposal.md` — Why. What the code actually does today, measured rather than
assumed:

- `Money.parse` (`lib/core/money.dart:19`) does
  `input.trim().replaceAll(',', '')` and then matches
  `^(-)?(\d+)(?:\.(\d+))?$`. Commas are grouping, `.` is the decimal point —
  the en-US convention, hard-coded.
- `Money.format` and `Money.digits` go through `NumberFormat` with
  `currency.defaultLocale`, so VND (`vi_VN`) groups with `.`.
- Probed: `Money.parse(Money(1500000, vnd).digits(), vnd)` **throws**;
  the USD equivalent round-trips.
- **`Money.parse` has exactly one caller**: `add_transaction_sheet.dart:38`.
  The blast radius of changing it is that file plus `test/core/money_test.dart`.
- The amount field is a raw Material `TextField` with
  `decoration: InputDecoration(labelText: 'Amount')` — no formatter, no
  currency, and no `AmountInput`.
- `lib/core` is a critical path at ≥85% (`tool/coverage_critical.txt`).

## Goals / Non-Goals

- Make the parser agree with the formatter **for every currency**, asserted over
  `Currency.values` rather than for the two that exist today.
- Keep every currently-passing assertion in `money_test.dart` passing, including
  `Money.parse('1,250,000', Currency.vnd)`. That is a shipped contract.
- Not to redesign the add sheet. See Non-goals in the proposal.

## Decisions

### D1 — The parser takes the locale's separators, plus a comma

**Chosen:** grouping separators are `{currency.groupSeparator} ∪ {','}` minus
the decimal separator; the decimal separator is the currency's own, and only
for currencies that have decimals.

| Currency | Groups on | Decimal |
| --- | --- | --- |
| VND (0 decimals) | `.` and `,` | none |
| USD (2 decimals) | `,` | `.` |

Alternatives:

- *Only the locale's separator.* Rejected: it breaks
  `Money.parse('1,250,000', Currency.vnd)`, which passes today, and someone
  typing on a US keyboard is a real thing.
- *Strip every non-digit and hope.* Rejected: it would turn `1.5` VND into 15
  silently. That case is already tested as a `FormatException` and stays one.

### D2 — Grouping, when present, must be well formed

**Chosen:** a separator is only accepted where it separates groups of three —
`^\d{1,3}(?:<sep>\d{3})*$` for the whole part. Ungrouped digits are still fine.

This is what keeps `1.5` (VND) a failure without a special case for it: `5` is
not a group of three. It also refuses `1.50.000` and `1,23,456`, which are
typos, not amounts.

Alternative: accept separators anywhere and ignore them. Rejected — it is the
"strip and hope" option under another name, and it makes a typo produce a
plausible wrong number, which is the worst outcome for a money field.

### D3 — The separators are derived, not transcribed

**Chosen:** read `NumberFormat(locale: …).symbols.GROUP_SEP` and
`DECIMAL_SEP`, and derive `symbolLeads` by asking `format()` where it put the
symbol.

Alternative: a table on the enum. Rejected: a table is a second source of truth
for something `intl` already knows, and it would be wrong the day a currency is
added without someone remembering to update it. `symbolLeads` in particular is
asserted **against `format()`'s own output** in the test, so the derivation and
the formatter cannot drift.

### D4 — The input formatter regroups the digits and counts the caret in digits

**Chosen:** a `TextInputFormatter` that strips the separators, regroups, and
places the caret by counting **digits** before it rather than characters.

Inserting a separator shifts every character after it, so a
character-index caret jumps by one every time a group closes — the classic
defect of this control. Counting digits is invariant under regrouping.

It lives in `features/transactions/presentation` rather than `design_system`,
because `design_system`'s gallery test scans that directory for public classes
and a formatter is not a component — it would need an exemption to explain away.
If a second screen needs it, that is when it moves.

### D5 — The decimal tail is left alone

**Chosen:** group the whole part only; pass the decimal part through untouched,
including a trailing separator while someone is mid-type (`12.`).

Without this the field fights the user: `12.` would be regrouped to `12` and the
decimal point they just typed would vanish.

## Risks / Trade-offs

- **A locale whose grouping is a non-breaking space** (fr_FR) would need the
  parser to strip it. Neither currency here uses one; the parser reads whatever
  `NumberFormat` reports rather than assuming, so it would work, and the
  round-trip test over `Currency.values` is what would catch it if it did not.
- **`Money.parse`'s contract widens**, so something that used to throw now
  parses. Every widened case is a scenario in the spec; every case that still
  throws is asserted too, including the four malformed-grouping ones.
- **Coverage**: `lib/core` is ≥85% and the new getters are small; each is
  directly tested rather than covered incidentally by the sheet's widget test.

## Verification

| Requirement | Test file | What catches a regression |
| --- | --- | --- |
| Round-trip for every currency | `test/core/money_test.dart` | a loop over `Currency.values`, not a VND case |
| Locale separator, comma, `1.5` refused | same | literal expectations per currency |
| Malformed grouping refused | same | four cases, each named |
| Separators and `symbolLeads` derived | same | `symbolLeads` asserted against `format()`'s output |
| Field groups as typed, caret holds | `test/features/transactions/amount_input_formatter_test.dart` | caret asserted by digit index after a mid-string insert |
| Field shows the currency on the right side | `test/features/transactions/add_transaction_test.dart` | prefix for USD, suffix for VND |
| What is displayed is what is saved | same | the grouped text submitted, the stored `Money` asserted |

Mutations, each run and recorded: revert the parser to comma-stripping (the
round-trip must fail); accept separators anywhere (the `1.5` case must fail);
place the caret at the end (the mid-string test must fail); hard-code `symbol`
as a prefix (the VND case must fail).

## Migration Plan

None. No schema, no stored format. `Money.parse` only widens what it accepts,
and nothing persists its input.

## Open Questions

None.
