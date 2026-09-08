# Design — budgets-feature

## Spend is computed, never stored

A `budgets` row holds the limit and nothing about spend. Every read sums the
matching transactions.

The alternative — a `spent_minor` column kept up to date by the transaction
repository — is faster and wrong the first time anything edits or deletes a
transaction outside that path: a restore from backup, a future import, a bug.
The failure mode is a budget that quietly disagrees with the list of
transactions under it, which is exactly the class of bug that produced the Home
staleness report a few commits ago. Two sources of truth again.

Cost: the overview sums transactions per budget on each read. On a local SQLite
database holding one person's spending that is a scan of a few thousand rows
behind an index on `(category, occurred_at)`. If it ever stops being fast, the
fix is a cache with an invalidation rule, not a second source of truth.

## Rollover carries exactly one window

Annotation `04.04` says *"Rollover changes next period's limit, not this
one's"*, and stops there. It does not say whether an unspent September and an
unspent October both reach November.

Recursive accumulation means every read walks every window since the budget was
created. That is unbounded work on a screen that renders on every app open, and
it grows without limit for a budget the user keeps. Single-step carry is bounded
at two window computations and is explainable in one sentence to the user.

So: one window deep, and `BudgetProgress` reports the carried amount separately
rather than folding it into the limit. A user seeing "5,000,000" where they set
"4,000,000" with no explanation would reasonably think the app is broken.

This is a real fork, not a transcription judgement — see
`docs/adr/0004-rollover-depth.md`.

## The threshold correction

`budget-components` wired three widgets to `BudgetStatus.nearLimitThreshold`, a
constant. Annotation `04.04` says the threshold is per budget. The fix is a
parameter with the old constant as its default, so:

- every existing call site keeps its current behaviour and its current tests,
- the widgets still *derive* status rather than accepting one,
- and a budget can move its own boundary.

What is deliberately **not** done: passing a `BudgetStatus` into the widgets.
That would make the warning colour a caller's choice, which is the thing
`budget_status.dart` exists to prevent.

## Daily allowance rounds down

`(limit - spent) / days remaining` rarely divides evenly. Rounding up produces
an allowance the user cannot actually spend every day without going over, which
is worse than a slightly conservative number. `Money` is integer minor units, so
the rounding is explicit rather than a float artefact.

Days remaining is at least 1: on the last day of the window the answer is "all
of it", not a division by zero.

## Why the create flow writes nothing until the end

Two steps, one write. A partially-created budget row with a null limit would
need every reader to handle it, and there is no draft the user asked to keep.
The flow holds its state in the route and commits once.

## 04.07 is not attempted

`BarChart` (`67:712`) is instanced on the history screen and appears on none of
the three component pages. The options were: query more pages, or approximate a
chart. Approximating is how the invented spacing scale happened — a plausible
component, consistently applied, wrong. It is recorded as blocked.
