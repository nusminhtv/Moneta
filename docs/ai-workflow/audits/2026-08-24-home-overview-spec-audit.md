# spec-auditor — `home-overview`

- **When:** 2026-08-24
- **Agent:** `spec-auditor` (`.claude/agents/spec-auditor.md`)
- **Target:** `openspec/changes/home-overview/` (4 artifacts) + `docs/adr/0004-cross-feature-overview-screens.md`
- **Verdict: `NOT READY`**

This is the first audit artifact in the repository. `level-4-evidence.md` listed
"discuss is the thinnest phase — the agents were written and never run" as gap #1;
this closes it, and the result justifies the gap having been called out.

## Independently verified before acting

The audit was not taken at face value. Five load-bearing claims were checked
against the code:

| Claim | Verification | Result |
| --- | --- | --- |
| `features/home` cannot hold `List<Transaction>` | Wrote a probe importing it, ran `tool/check_architecture.dart` | **Confirmed** — 1 violation, exit 1 |
| Providers Home needs live in `features/transactions/presentation` | `grep '^final .*Provider'` | **Confirmed** — `clockProvider`, `walletCurrencyProvider`, `appDatabaseProvider` all there |
| `BalanceCard` takes a pre-formatted `String`, against CLAUDE.md | `balance_card.dart:40` vs `CLAUDE.md:104` | **Confirmed** — a violation shipped in change 1 |
| The DAO sums across currencies | `buildSummaryStatement` has no currency predicate; `summarise` stamps the wallet currency | **Confirmed** — latent wrong-total bug in archived code |
| `DateTimeRange` in the ADR's port is a Material type | Found in `flutter/lib/src/material/date.dart` | **Confirmed** |

## Findings that change the design

### Blocking — the proposal's central claim is false

`proposal.md` states "**`lib/features/transactions` is not modified** — Home reads
it through the port, which is the point." It is load-bearing and it is wrong:

- `HomeSnapshot.recent` as `List<Transaction>` is a cross-feature import.
  ADR 0004 chose the port precisely to avoid this edge, then designed a payload
  that reintroduces it. Home needs its own recent-item type and a mapper — no
  task, no design decision, no ADR line.
- `clockProvider`, `appDatabaseProvider` and `walletCurrencyProvider` sit in
  `features/transactions/presentation`. Home needs all three and may not import
  them, so they must move to `lib/data` or `lib/app` — editing the transactions
  feature and every test that overrides them.

### Blocking — ADR 0004's deciding argument does not hold

The ADR says the port wins on the coverage gate, not on flexibility. Both halves
fail:

1. `tool/coverage_critical.txt` is a substring list. Adding `lib/app/` to it is
   *tightening* a gate, which CLAUDE.md rule 5 explicitly permits. A deciding
   factor that a one-line config edit dissolves is not a deciding factor.
2. The argument names "period-bounds **and masking** logic", but under the chosen
   option masking lives in `features/home/presentation/`, which matches neither
   `/domain/` nor `/data/` — the same exposure Option A was rejected for.
3. A sixth option was never considered: `HomePeriod` and `HomeSnapshot` as pure
   value types in `features/home/domain`, built by a provider in `lib/app` that
   reads the repository directly — **no port, no fake, no override**. Identical
   coverage properties, none of the cost. Because it is missing, the ADR never has
   to answer why a port beats it.

### Contradictions inside the change

- `specs/home/spec.md` scopes masking to the four hero figures; `tasks.md` verifies
  "no digit **anywhere** in the tree". `TransactionRow` renders an amount and a
  time, so both cannot hold.
- ADR 0004 types the port `load(DateTimeRange)`; `design.md` D1 makes `HomePeriod`
  the parameter. And `DateTimeRange` is Material, while `config.yaml` defines
  `domain/` as "core only".
- `design.md` D6 says formatting stays in the design system; `BalanceCard`
  requires a pre-formatted `safeToSpendUntil` string, which no artifact mentions
  at all. The period end is *exclusive*, so "until 1 Sep" vs "until 31 Aug" is the
  exact off-by-one the spec makes a requirement about elsewhere.

### Requirements that are not falsifiable

- "a bounded number of the most recent transactions" — the bound is never given,
  so a test can only assert `recentLimit` against itself.
- "a transaction's instant" — `Transaction` has two (`occurredAt`, `createdAt`).
  Two implementations disagree on every backdated transaction.
- "the net of every transaction ever recorded" — silent on future-dated rows, and
  the archived transactions spec's own rationale ("a balance that includes money
  not yet spent is wrong") argues for the reading this spec does not state.
- "logs and falls back to revealed" — no logging surface exists in `lib/`.
- `tasks.md` 5.1: "navigating away and back preserves nothing it should not."

### Acceptance criteria `config.yaml` demands and the specs omit

Currency mismatch, very-large/all-time totals, negative amounts (or an explicit
"cannot occur"), and concrete `AppFailure` kinds — including that
`TransactionQuery.build` returns **validation**, which the adapter can receive and
`tasks.md` collapses to "a storage failure" without spec authority.

Also missing: the Figma node and variants, which `config.yaml` requires for any UI
requirement.

### Requirements already owned by the archived spec set

Six overlaps, each needing an ownership decision rather than a copy: masked-card
behaviour (`design-system/components`), newest-first ordering, inclusive/exclusive
range semantics, the empty-vs-error state trio, storage-failure reporting, and row
preservation on upgrade (`storage/local-database`).

### Task structure

`tasks.md` 5.2 is four unrelated jobs plus a design decision that may reopen task
2.2; 4.1 bundles two independent subsystems; 4.2 cannot pass as written; 2.1
prescribes the implementation so its test can only re-assert the chosen
expression; and a spec scenario has a verification file in `design.md` with no
task owning it.

## Consequence

`home-overview` is **not implemented**. No code was written. The artifacts and
ADR 0004 need revision first, and four of the fixes are product decisions rather
than corrections.

A separate defect was surfaced that belongs to already-archived code, not to this
change: `TransactionDao.summarise` sums `amount_minor` across rows without a
currency predicate and stamps the wallet currency onto the result, so a
mixed-currency store yields a silently wrong total. Tracked separately.
