# spec-auditor — third pass, both open changes

- **When:** 2026-08-24
- **Agent:** `spec-auditor`, resumed twice with its own accumulated context
- **Verdicts:** `home-overview` **NOT READY** (one fix) · `design-system-corrections`
  **NOT READY** (four fixes)

Third pass over `home-overview` and the first over `design-system-corrections`.
Of the six targeted items from pass two, five were confirmed resolved. The
remaining one is the finding that made this pass worth running.

## The one that mattered: a test whose power came from an environment variable

The `lastDayInclusive` requirement was written precisely, with the wrong answer
named and a task demanding the assertion be made "in a zone ahead of UTC". None of
that established the zone. Measured:

| | Zone | Right answer | Wrong answer | Test can tell? |
| --- | --- | --- | --- | --- |
| This machine | +07 | 31 Aug | 30 Aug | yes |
| `verify.yml` (`ubuntu-latest`) | UTC | 30 Aug | 30 Aug | **no** |

So the assertion would have discriminated locally and passed for a broken
implementation in CI — green in the gate that guards merges, and a direct
contradiction of the comment in `verify.yml` claiming CI and the local loop never
disagree about what "done" means.

Worse, this was not a future problem. The shipped test
`converts UTC to local exactly once` compared `formatTimeOfDay(i)` with
`formatTimeOfDay(i.toLocal())` — identical strings under UTC — so it had been
decoration since `transactions-local-store`.

**Fixed as a gate rather than as a test edit.** `tool/verify.sh` exports
`TZ=Asia/Ho_Chi_Minh` (the target locale, ahead of UTC, no DST) and
`tool/check_timezone.dart` is the eighth gate, failing if that stops taking
effect. The shipped test was rewritten to assert the local time explicitly and to
assert it is *not* the UTC time of day; it now passes under +07 and **fails** under
UTC, which is what makes it an assertion.

## `home-overview` — the rest

| Item | Verdict |
| --- | --- |
| D, coverage of the moved providers | RESOLVED — derivation, measurement and rejected escape hatches all present |
| B, the now-boundary | RESOLVED for every reachable case; one sub-millisecond over-inclusion, now recorded |
| A, currency failure kind | RESOLVED — one kind, one owner, `HomeSnapshot` keeps an ordinary constructor |
| C, `lastDayInclusive` | **was open** — see above |
| F, ADR 0004 v2.1 | RESOLVED, "no third backwards argument" |
| G and the minor items | PARTIAL — one missing task signal, now added |

Two further corrections from this pass:

- **The `+1 ms` bound over-includes by under a millisecond.** `DateTime` is
  microsecond-resolution while the store truncates to milliseconds, so an
  occurrence at `now + 300µs` is "strictly later than now" by the spec's wording
  and is included by the bound. Accepted and documented rather than fixed, because
  microsecond arithmetic against a millisecond store is precision the storage
  cannot honour. Recorded so nobody "corrects" it.
- **ADR 0004's revisit trigger fired at birth.** It said to reconsider if the
  assembler "starts making decisions rather than translating" — and the assembler
  is born with three. Reworded to a fourth. ADR is at v2.2.

## `design-system-corrections` — first audit

The agent called it a strong change and then found the same over-claim this
project keeps making.

**"The only current caller is the gallery" was false.** `BalanceCard` is
constructed at four sites, not two: `gallery_catalog.dart:68` and `:78`, and
`balance_card_test.dart:24` and `:219`. So task 1.1's "the existing masked
no-digit test still passes **unchanged**" could not hold.

This is the **third** time an audit has caught an unverified "the only caller /
not modified" claim in these artifacts. The pattern is worth naming: the claim is
always plausible, always load-bearing, and always one `grep` from being checked.

**An unfalsifiable scenario.** "the safe-to-spend date **may** still be shown" —
a permissive clause no test can fail, and the component currently does the
opposite. Decided: the masked card omits the date, matching Figma's `40:137`
masked text and the existing behaviour.

**The gallery section would have dropped a variant.** Two entries labelled
`State=Default` / `State=Masked` lose the income/expense distinction that
`figma-map.md` records as this component's variant set — and defeat this change's
own argument, since "the mask hides direction" is only checkable by seeing an
expense row, an income row and a masked row together. Now three variants, labelled
by what they are rather than in Figma's `State=` form, because the archived gallery
requirement says variants are labelled by their *Figma* name and this component has
no Figma node.

**An unsourced node.** `40:137` was cited in the proposal but tracked nowhere. It
is real — it comes from the component description under `40:161` — and is now in
`figma-map.md`.

**One question answered in the change's favour.** No delta is needed on the
archived "Full variant coverage" requirement: it is scoped to components derived
from a *Figma component set*, and `TransactionRow` has none. Routing the new
designed variant to ADR 0003 instead is correct. The agent noted the consequence:
nothing in the spec set then requires a *designed* component's variant set to be
complete, and the gallery requirement is the only backstop — which is exactly why
finding 3 mattered.

## What three passes say about the process

Each pass found a different class of problem, and the classes got subtler:

1. **Pass one** — claims that were false and reasoning that was reverse-engineered.
2. **Pass two** — requirements correct in prose, ambiguous in the clause a test
   would have to fail against.
3. **Pass three** — a requirement and a clause both correct, and a *verification
   environment* in which the clause could not fail.

The third is the one self-review is least likely to catch, because everything on
the page is right.
