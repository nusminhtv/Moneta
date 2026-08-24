## Context

Two corrections to shipped components, both blocking `home-overview`. Neither is a
visual change; both are about what the components accept and render.

The `BalanceCard` defect is worth naming precisely, because the mechanism matters
more than the fix. `CLAUDE.md` says design-system widgets take domain types. The
card was written with a doc comment arguing the opposite case — that formatting a
date is a locale concern rather than a card concern — and that argument is not
absurd, which is why it survived review. What defeats it is that the rule already
weighed it: the cost of pushing formatting to callers is that two callers diverge,
and there is no gate that can detect divergence after the fact. The
`spec-auditor` agent found this in a change that merely *planned* to use the card.

## Goals / Non-goals

**Goals**: `BalanceCard` takes a `DateTime`; `TransactionRow` gains a masked form
that hides the amount without leaking its magnitude or direction; the gallery
shows the new variant; existing behaviour otherwise unchanged.

**Non-goals**: visual redesign, masking non-money content, mask persistence, a
sweep of every other component for the same class of violation.

## Decisions

### D1 — The card formats the date with a shared helper, not its own pattern

**Options.** (a) `BalanceCard` calls `DateFormat` inline; (b) a shared formatter
in the design system that both the card and future callers use.

(a) is one line, and it is how `TransactionRow.formatTimeOfDay` already works —
a `static String formatTimeOfDay(DateTime, {String? locale})` on the widget,
exposed so tests and callers use the same formatting the row does. That precedent
is good and this should match it rather than invent a second convention.

**Chosen: (a), following the existing precedent.**
`BalanceCard.formatPeriodEnd(DateTime, {String? locale})`, static and public, using
`DateFormat('d MMM')` — the `31 Aug` form the card's own Figma fixture shows.

The conversion to local time happens there and nowhere else, matching D-for-time
in `TransactionRow`. If a third component needs the same pattern, that is the
signal to extract a shared formatter; two is not.

### D2 — The masked row hides the sign as well as the digits

Hiding `1,250,000` but leaving `−` still tells an onlooker that money went out. So
the masked form renders the mask alone, with no sign.

**Options.** (a) mask the digits, keep the sign and the colour; (b) mask digits and
sign, keep the direction colour; (c) mask digits and sign, and use a neutral
colour.

(a) and (b) both leak the direction — (b) leaks it through the income/expense
colour, which is the whole point of that colour existing. **(c).** The mask renders
in `textTertiary`, so a masked list reveals that transactions happened and nothing
about which way the money went.

This is stricter than `BalanceCard`'s existing masked state, which keeps its
income and expense *labels* — but those are static words, not per-transaction
facts. Recorded as a deliberate asymmetry rather than an inconsistency.

### D3 — The mask is a fixed width, reusing the card's approach

`BalanceCard._mask` formats a fixed placeholder magnitude and substitutes its
digits, so the mask's width does not track the real amount. The row does the same,
so the two masks look like one system and neither leaks magnitude.

**Options.** (a) one dot per digit; (b) a fixed-width mask.

(a) is what a naive `replaceAll(RegExp(r'\d'), '•')` on the real amount gives, and
it is what the first version of the card nearly shipped. It reveals the order of
magnitude, which is most of what someone glancing at a screen wants to know.
**(b).**

### D4 — `masked` is a boolean on the existing row, not a second widget

**Options.** (a) `TransactionRow(masked: true)`; (b) a separate
`MaskedTransactionRow`; (c) a `TransactionRowState` enum.

(b) duplicates layout and lets the two drift, which is exactly what the design
system exists to prevent. (c) is what Figma variant sets look like, and would be
right if there were three or more states — there are two.

**(a).** `masked` defaults to `false`, so every existing call site is unchanged.

### D5 — The gallery gains the variant; the catalogue's count assertion updates

`galleryCatalog` is a contract — a test asserts each section's variant count
against the enum that defines it. `TransactionRow` is not in the gallery at all
today, because it was added by `transactions-local-store` after the gallery
change. This change adds it with both forms, so the gallery stops silently
omitting a component.

That is scope creep by the letter of it, and it is included anyway: the gallery's
whole purpose is that a component's variants are visible, and adding a masked form
to a component the gallery does not show would make the omission worse.

## Risks / trade-offs

- **Breaking a shipped constructor.** Exactly one caller exists
  (`gallery_catalog.dart`), updated here. `home-overview` is written against the
  new signature. If a caller were missed, it would fail to compile rather than
  behave oddly, which is the failure mode to prefer.
- **Two mask implementations to keep in step.** `BalanceCard` and
  `TransactionRow` each have their own. Extracting a shared `maskFor(Currency)`
  helper is tempting; it is deferred because the two masks are used at different
  type scales and a shared helper would need to know about both. Noted so the
  third one triggers the extraction.
- **The asymmetry in D2** (row hides its direction, card keeps its labels) is a
  judgement that could read as inconsistency. Written down here so a reviewer can
  disagree with the reasoning rather than assume it was an oversight.
- **This change does not sweep for other violations of the domain-types rule.**
  Known unfixed exposure elsewhere is therefore possible. Listed as a non-goal
  rather than left implied.

## Verification plan

| Spec requirement | Verified by |
| --- | --- |
| The period end is a date, not a string | Compile-time: the constructor takes `DateTime`. Plus `balance_card_test` asserting the rendered text for a known date |
| The date is formatted consistently, in local time | `balance_card_test` — asserts `formatPeriodEnd` converts to local exactly once, matching the existing `formatTimeOfDay` test |
| Masked card still hides all four amounts | Existing `balance_card_test` no-digit test, unchanged, must still pass |
| The period end may show while masked | `balance_card_test` |
| A masked row hides its amount and its sign | `transaction_row_test` — no digit from the amount, and neither `+` nor `−` present |
| A masked row keeps non-money content and its height | `transaction_row_test` — disc, title and time present; row height equal to the unmasked row |
| The mask width does not depend on the amount | `transaction_row_test` — two very different amounts produce identical output |
| A masked row uses a de-emphasised colour | `transaction_row_test` — asserts the mask is neither the income nor the expense colour |
| Existing unmasked behaviour unchanged | The whole existing `transaction_row_test` and `balance_card_test`, minus the constructor change |
| The gallery shows both row forms | `test/app/gallery_test.dart` — the catalogue gains a `TransactionRow` section with two variants, count asserted |

Plus the standing gates.

## Open questions

None. The mask colour is `textTertiary`, chosen to match how the design system
already de-emphasises secondary text rather than by inventing a token.
