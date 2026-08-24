## Why

Two design-system components have API defects that block the Home overview, and
one of them is a direct violation of a rule this project wrote down and then broke.

`BalanceCard` takes `safeToSpendUntil` as a **pre-formatted `String`**
(`balance_card.dart:40`) and renders `"Safe to spend X until $safeToSpendUntil"`.
`CLAUDE.md` says: *"Design-system widgets take domain types, not pre-formatted
strings."* The card was shipped in `design-system-foundation` with a doc comment
arguing the opposite — "formatting a date is a locale concern, not a card
concern" — which is exactly the reasoning the rule exists to overrule. Every
caller now has to format that date, so two screens can disagree about how a date
is written, which is the failure the rule prevents.

`TransactionRow` has no masked form. The balance card can hide its figures; a row
cannot. A masked hero card sitting above an unmasked "−1,250,000 ₫" does not hide
anything, so masking is currently only as strong as the screen that has no list on
it.

The user-visible outcome is small and specific: a date on the balance card that is
formatted the same way everywhere in the app, and a mask control that actually
hides the amounts on a screen that shows a list.

## What Changes

- **`BalanceCard.safeToSpendUntil` becomes a `DateTime`.** The card formats it
  through the same `intl` pattern the rest of the app uses. **BREAKING** for
  callers. There are three construction sites, not one: `gallery_catalog.dart:68`
  and `:78`, and `balance_card_test.dart:24` and `:219`. All are updated here.
- **`TransactionRow` gains a masked form.** When masked it renders a fixed-width
  mask in place of the amount, matching how `BalanceCard` already masks: a fixed
  width rather than one dot per digit, because a mask that shrinks with the amount
  leaks its magnitude.
- **Non-amount content stays visible when masked** — the category disc, the title
  and the time of day. Masking is about money, not about hiding that a transaction
  happened.
- **The gallery gains the masked row variant**, so the variant is visible on the
  gallery route like every other variant.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `design-system/components`: the balance card's safe-to-spend input becomes a
  date rather than a formatted string, and the transaction row gains a masked
  form. Both are changes to what the components accept and render, not
  implementation details.

## Non-goals

- **No visual redesign.** Colours, spacing, type and layout are unchanged. This
  change is about what the components *accept*, not how they look.
- **No masking of times or titles.** Only monetary amounts.
- **No new Figma nodes.** `BalanceCard` masking already exists in Figma as the
  `State=Masked` variant, node `40:137` — read from the component's own
  description under node `40:161`, and added to `figma-map.md` by this change
  because it was cited without being tracked. The row's masked form has no Figma
  source, because the row itself is not in Figma — see ADR 0003.
- **No mask persistence.** Where the preference is stored belongs to the caller,
  and to `home-overview`.
- **No audit of every other component for the same violation.** Two are known and
  fixed here; a sweep is worth doing but is not this change.

## Impact

- **Modules touched:** `lib/design_system/organisms/balance_card.dart`,
  `lib/design_system/molecules/transaction_row.dart`, the gallery catalogue in
  `lib/app`, and the tests for all three.
- **Dependencies:** none added. `intl` is already used by `TransactionRow` for the
  time of day.
- **Breaking change:** yes, for `BalanceCard`'s constructor. Callers, verified by
  grep rather than assumed: `lib/app/gallery/gallery_catalog.dart` (two variants)
  and `test/design_system/organisms/balance_card_test.dart` (two pump helpers).
  An earlier draft of this proposal said "the only current caller is the gallery",
  which was false — the same over-claim this change exists to correct in
  `BalanceCard` itself, and the third time an audit has caught that pattern in
  these artifacts. `home-overview` is written against the new signature and is
  blocked on this change.
- **Gates affected:** none newly. Both components already have variant tests and
  both are inside `lib/design_system`, so `tool/check_design_tokens.dart` applies
  as it already did.
- **Prior art this corrects:** `design-system-foundation`, archived as
  `2026-08-24-design-system-foundation`. The violation was introduced there and
  went unnoticed because no test asserted the rule and no gate can express it.
