# spec-auditor — `home-overview`, second pass

- **When:** 2026-08-24
- **Agent:** `spec-auditor`, resumed with its own first-pass context
- **Verdict: `NOT READY` — narrowly, four items rather than eleven**

The agent was asked to go through its own eleven minimum fixes and mark each
RESOLVED / PARTIAL / NOT ADDRESSED, and specifically to check whether anything was
now merely *asserted* fixed in prose while the requirement still let two
implementations disagree. That framing is what found the remaining problems.

## Its own eleven

| # | Finding | Second-pass verdict |
| --- | --- | --- |
| 1 | Cross-feature typing; provider relocation; false Impact claim | RESOLVED |
| 2 | ADR 0004's deciding argument | RESOLVED — "an honest deciding argument", one overstatement left (see F) |
| 3 | Pin the derived-value rules | **PARTIAL** — 3 of 4; currency and the now-boundary still ambiguous |
| 4 | Missing boundary criteria | **PARTIAL** — very-large-totals was a disjunction both implementations satisfy |
| 5 | `safeToSpendUntil` | **PARTIAL** — right date required, time zone unstated |
| 6 | Masking scope | RESOLVED |
| 7 | Refresh on record | RESOLVED |
| 8 | Pin `recentLimit` | RESOLVED |
| 9 | `check_design_tokens` in design.md | RESOLVED |
| 10 | Figma node; remove duplication | RESOLVED |
| 11 | Task structure | **PARTIAL** — one unimplementable signal, one task still bundled |

## The four that mattered, all verified before acting

### D — a task that could not pass its own gate

`coverage_critical.txt` contains the bare substring `/data/` and
`check_coverage.dart` matches with `.contains`, so moving providers into
`lib/data/app_providers.dart` subjects them to the **85%** threshold. The committed
`lcov.info` shows `appDatabaseProvider`'s body at zero hits — nothing constructs
it, because every widget test overrides `transactionRepositoryProvider` wholesale.

Verified from the lcov directly: lines 13, 16 and 22 hit; 28–33 at zero. The new
file would be 8 lines with 3 hit — **37.5%**.

So task 1.1's instruction *"if a test needs editing beyond its import lines, stop
and say why"* would have been triggered by its own gate. Worse, `--fast` skips
coverage, so it would have failed only at the end — the least visible way to
violate the project's own rule that the gate passes after every task.

Fixed by adding task 1.2: a test that constructs `appDatabaseProvider` and asserts
disposal closes the connection — the behaviour it exists for and that nothing
checked. The escape hatches were rejected: editing `coverage_critical.txt` or
adding a coverage-ignore are both weakenings under rule 5.

### B — inclusive in the spec, exclusive in the design

The spec said balance is the net of transactions "**at or before** now". The design
said `TransactionQuery.build(end: clock.nowUtc())`, and that `end` is **exclusive**
(`transaction_query.dart:82`, `!utc.isBefore(end)`).

Not academic: `AddTransactionSheet` stamps `occurredAt` from the same clock, so
under a fixed clock a just-recorded transaction occurs at exactly `now` and would
drop out of the balance — failing the refresh-on-record requirement for a reason
the spec called correct.

Fixed by bounding at `now + 1ms` (the store's smallest unit, since `occurred_at` is
epoch milliseconds), with the reason written at the call site, plus a task
asserting the exactly-at-now case. The alternative — teaching `TransactionQuery` an
inclusive-end mode — was rejected as a change to another capability for one
caller's convenience.

### A — one failure kind with two mutually exclusive obligations

The design classified a currency mismatch as `validation` and the spec required it
to render the error state — while the same spec required that a `validation`
failure is unreachable and "caught by test rather than rendered". Two
implementations could disagree and both cite the spec. Ownership was doubled too:
the guard was assigned to the assembler in one task and to `HomeSnapshot` in
another.

Fixed: it is a **storage** failure, because the bad data came from the store rather
than from a caller. One owner — the assembler, checking before construction, which
is what lets `HomeSnapshot` keep an ordinary constructor instead of a
`Result`-returning factory.

### C — a date whose time zone was unstated, with a test that could not tell

`lastDayInclusive` had to be "the final day of the current month", and the period
end is held in UTC. For UTC+7 the month ends at 31 Aug 17:00 UTC: subtract a day
then convert to local → 31 August, correct; compute the day in UTC → 30 August,
wrong. The task asserted only that it "falls inside the period" — and 30 August is
also inside the period, so the test passed for both answers.

Fixed: the requirement says *local* day and names the UTC+7 example; the task
asserts it in a zone ahead of UTC, where the wrong calculation fails.

## Also fixed

- **F** — ADR 0004's criteria table still weighted "derivation behind the 85% gate"
  as high while three of Home's derivations stay in `lib/app` under *either*
  option. Since v2 spends a section dissecting exactly that error, leaving it in
  the table was the one place the rewrite still argued backwards. ADR is now at
  v2.1.
- **G** — a failed database *open* is not a failed preference *read*; the existing
  precedent for that path throws rather than returning `Result`. Now specified: an
  unopenable database is one failure, reported by the read that needed data.
- Very-large-totals changed from "exact **or** a failure" (which both
  implementations satisfy) to exact and stable across two reads.
- The unimplementable "a test asserts the type exposes no field from another
  feature" replaced — `dart:mirrors` is unavailable in Flutter tests, so it would
  have asserted a hand-written list against itself. The real signal is the
  architecture gate plus compilation, and that is now what it says.
- Refresh-on-record split out of the routing task; the gate split from the
  device session. Tasks: 15 → 18.
- One finding was **stale**: the agent reported `design-system-corrections` did not
  exist. It read the repository before that change was committed. Its other points
  under that heading were valid and are fixed — the blocking boundary is task 4.3
  rather than 4.2, and ADR 0003 needs the row's masked variant recorded, since the
  row has no Figma source and a masked form is therefore a new *designed* variant.

## What the second pass says about the first

Every one of the first pass's structural findings held. What the second pass added
was a different class of problem: the first round's fixes were *correct in prose
and still ambiguous in the requirement*. Three of four product decisions had that
shape. That is the failure mode worth remembering — a revision that reads as
resolved because the reasoning is now written down, while the clause a test would
have to fail against is unchanged.
