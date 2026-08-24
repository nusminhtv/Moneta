# 0003. Transaction row layout

- **Status:** Accepted
- **Date:** 2026-08-24
- **Change:** transactions-local-store

## Context

The transaction list needs a row component. The Figma file has no transaction
row, and no screen frames at all — it stops at a component library of organisms.
So unlike every other component so far, this one cannot be transcribed. It has to
be **designed**, from the existing tokens and the existing `CategoryIcon`.

That distinction matters for how the result should be read: `BalanceCard` being
different from Figma would be a bug, whereas this row being different from
someone's expectation is a decision to argue with. Writing it down is what makes
that argument possible.

Constraints that are not negotiable:

- The category disc must be `CategoryIcon`, so a category looks identical here,
  in a budget card and in a chart. Figma is explicit: *"pick a category, never a
  colour."*
- Every value must resolve through tokens; `tool/check_design_tokens.dart`
  enforces it.
- The row appears many times on screen and inside a scrolling list, so it must
  be cheap and must not grow vertically with content.
- The amount is the thing people scan for.

## Options considered

### Option A — Disc · (note / category, time) · signed amount, single line each

`CategoryIcon` at `sm` (32), then a two-line text column (primary line: note,
falling back to the category name; secondary line: time of day), then the signed
amount right-aligned in `amountMd`.

- Scanning: the amount is at a consistent right edge, so a column of amounts
  reads vertically. Matches `BudgetCard`, which puts its figure in the same place.
- Height: fixed at two lines, so the list scrolls predictably.
- Cost: the time is small and secondary, which is right for a list already
  grouped by day.

### Option B — Disc · note · amount, one line, category name dropped

Single line, no secondary text.

- Cheapest and densest.
- Loses the time entirely. Within a day group, "coffee 3 times" becomes
  indistinguishable without it, which is exactly when a person is checking.

### Option C — Two-line with the category name always shown as the secondary line

Primary line the note, secondary line the category name, time moved next to the
amount.

- Redundant: the disc already encodes the category, and the whole point of the
  colour-and-glyph binding is that it does. Showing the name too spends a line on
  information already on screen.

### Option D — Leading amount, trailing category

Amount first, reading left to right.

- Breaks the vertical scan: amounts are variable width, so a left-aligned column
  of them does not line up at the decimal, and comparing two rows becomes work.
  This is the standard reason ledgers right-align figures.

## Decision criteria

| Criterion | Weight | Why |
| --- | --- | --- |
| Scannability of amounts | high | The list's primary job |
| Consistency with existing components | high | `BudgetCard` already establishes disc-left, figure-right |
| Information density vs redundancy | medium | Screen is 393pt wide |
| Fixed row height | medium | Predictable scrolling, cheap layout |

## Decision

**Option A.**

- `CategoryIcon(size: sm)` — 32pt, matching a list density rather than a card's.
- Primary line: the note, or the category label when there is no note. `titleMd`,
  one line, ellipsised.
- Secondary line: time of day, `captionMd` in `textTertiary`.
- Trailing: signed amount in `amountMd`, income colour with `+`, expense colour
  with `−`.
- Vertical padding `spacing.xl` (12), horizontal `spacing.x3l` (16), matching
  `BudgetCard`'s internal rhythm.

The row takes `Money` and a direction, not a formatted string, so it cannot
disagree with the rest of the app about how money is written.

## Consequences

- Row height is fixed by its two text lines and the 32pt disc, so the list can
  scroll cheaply and a golden test is stable.
- When Figma eventually gains a real transaction row, this component is the thing
  to reconcile against it — and this ADR is the record of what was assumed in the
  meantime.
- The time is rendered in the device's local time zone while the instant is
  stored in UTC; the conversion happens at the presentation boundary and nowhere
  else.

## Strongest counter-argument

Two lines per row is a real density cost: on a 393×852 frame this fits roughly
ten rows per screen where a single-line row would fit sixteen. For someone
reviewing a month of spending, more rows per screen is genuinely more useful, and
Option B's objection — losing the time — could be answered by showing the time
only when a day group contains more than one transaction in the same category.
That is more machinery than this change should carry, but if user feedback says
the list feels sparse, Option B with conditional time is the thing to try.

## Revisit when

- Figma adds a transaction row or a screen frame that contains one, or
- the list gains inline editing or multi-select, which changes what a row must
  afford.
