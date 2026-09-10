## Context

See `proposal.md` — Why. What constrains the approach:

- `appDatabaseProvider` (`lib/data/app_providers.dart:34`) hardcodes one path and
  every repository provider watches it. Swapping that one provider swaps the
  whole application, which is why the file-per-mode option is cheap.
- **Preferences live in the database.** `PreferencesStore` reads the `settings`
  table of whatever connection it is given, and `PreferenceKey` has one member,
  `onboardingComplete`. A demo flag stored there would be stored in the file the
  flag selects.
- `tool/check_architecture.dart`: `lib/data` may import only `core` and `data`.
  A seeder must create `Transaction` and `Budget`, which live in their features,
  so a seeder cannot live in `lib/data`.
- Repositories return `Result<T>` and validate before writing. Money is integer
  minor units. `DateTime` is UTC with an injected `Clock`. A seeder that
  bypasses any of these produces data the application itself would reject.
- `📱 08 Profile & Settings` is unbuilt and its Figma page has never been read,
  and at the time of writing the Figma MCP connection cannot read the file at
  all.

## Goals / Non-Goals

Goals:

- A demo ledger that is a *place to try the app*, not a screenshot: everything
  editable, everything countable, reset when you want it back.
- Impossible to confuse with real data — by construction where possible, and by
  a visible indication where not.
- Deterministic, so a screenshot and a test are both reproducible.

Non-goals:

- **A settings screen from Figma.** The screen this adds is a functional
  affordance for two controls. It is not `08.xx` and must not be mistaken for
  it; `profile-feature` builds the real one and absorbs these two controls.
- **Multiple demo profiles**, or choosing the dataset's size or currency in the
  UI. One dataset, one seed.
- **Seeding the real database**, ever, under any flag.
- **Faking accounts.** There is no accounts feature yet, so the dataset contains
  no account data and Home's "add an account" checklist row stays as it is.

## Decisions

### D1 — Separate database file, not a flagged column

**Chosen:** demo data lives in `moneta_demo.db`; real data stays in
`moneta.db`. The toggle changes which one the application uses.

Alternatives:

- *An `is_demo` column on every table, filtered by every query.* Rejected. It
  makes "show me real data" a thing every query has to remember, and the failure
  mode is dummy money inside a real balance — in a personal-finance app, the
  most expensive bug this change could introduce. It also needs a migration
  touching every table, for a feature that adds no real column.
- *A read-only in-memory overlay merged by a repository decorator.* Rejected on
  the user's own requirement: manual entry must work in demo mode, and overlay
  data cannot be edited or deleted. It also needs a decorator per repository,
  which is more code than a second file.

The separation being the *file* is what makes "never mixed" checkable rather
than diligent.

### D2 — A control database and an active data database

The demo flag cannot live in the database the flag selects. So there are two
roles:

- **control** — always `moneta.db`. Holds `settings`. Never swapped.
- **active data** — `moneta.db` or `moneta_demo.db`, chosen by the flag. Holds
  transactions, budgets and everything else a ledger contains.

When demo mode is off the two roles are the same file, and the same connection
serves both rather than the file being opened twice.

**Every preference is control-scoped**, not just the demo flag. Considered and
rejected: a per-key scope declaration, so a future ledger-scoped setting could
opt in. There is no such setting today, and `onboardingComplete` — the only
existing key — is clearly about the person and not the ledger. A distinction
with one possible value is machinery, and it has a concrete cost: if
`onboardingComplete` were data-scoped, turning demo mode on would re-show the
introduction, because the demo database has never seen it.

The consequence to keep in mind: the demo database's `settings` table exists
(the migration set is shared) and stays empty. That is asserted, so a preference
quietly landing there is caught.

### D3 — The seeder writes through the repositories

**Chosen:** the seeder calls `TransactionRepository.add` and
`BudgetRepository.add` — the same methods the application's own forms call. No
direct table writes.

Two things follow, and both are the point:

1. The dataset is **provably enterable by hand.** Demo data cannot be data the
   app would refuse, so a screen can never be reviewed against data a user could
   not have produced.
2. The seeder cannot drift from the schema, because it does not know the schema.
   A migration that adds a column needs no seeder change.

Alternative: raw `INSERT`s in a batch. Faster, and rejected — it duplicates
schema knowledge in a second place and would let the dataset contain, say, a
negative amount or a non-UTC timestamp that the repository would have caught.

**Cost, stated plainly:** ~1,200 sequential repository calls. If that measures
slower than about two seconds on a debug build, the fix is to wrap the seed in a
single database transaction — still through the repositories, just not
committing 1,200 times. Measuring comes before optimising, and the number goes
in the evidence log either way.

### D4 — Determinism: an explicit generator, not `dart:math`

**Chosen:** the generator carries its own small linear-congruential sequence
with a fixed seed.

`Random(seed)` is *not* documented to produce the same sequence across Dart
releases, so a dataset built on it can change under an SDK upgrade — and the
symptom would be a test failing for a reason nowhere in the diff. A dozen lines
of arithmetic buys a dataset that is byte-stable forever.

**Anchored to the clock, not to a calendar.** The dataset spans the fifteen
whole months up to the current month, taken from the injected `Clock`. So the
app always looks current, and a test with a `FixedClock` gets a fixed dataset.
Nothing is dated in the future, which is asserted: a transaction tomorrow would
break every "this month" aggregate.

### D5 — The generator is pure; only the seeder touches the database

The generator is a function from a clock to a list of domain objects, with no
I/O. The seeder takes that list and writes it.

This is what makes the interesting half testable without a database: category
coverage, budget states reachable, the >8 categories the donut's fold needs, the
no-future-dates rule, determinism — all assertions about a returned list.

Both live in `lib/app/demo/`, because a seeder must import two features and
`lib/app` is the only layer allowed to. It is genuinely composition, so this is
the composition root's work rather than a hole in the rules.

### D6 — Reset deletes the file, not the rows

**Chosen:** reset closes the connection, deletes `moneta_demo.db`, then reopens
— which runs the shared migration set from nothing — and reseeds.

Alternative: `DELETE FROM` every table. Rejected: it needs a list of tables kept
in step with the migrations by hand, which is the drift D3 exists to avoid, and
it leaves behind whatever a future migration adds that the list forgets.

Deleting the file makes reset identical to a first run, which is also the state
easiest to reason about. The connection must be closed first, which is why the
swap requirement in `storage/local-database` says so explicitly.

### D7 — Seeding happens once, on first activation

**Chosen:** the demo database is seeded when demo mode is turned on and the
demo database contains no transactions. Not on every launch, and not on every
toggle.

Otherwise a transaction added in demo mode would vanish on the next launch, and
"manual entry works in demo mode" would be true only until you closed the app —
which is the kind of half-working that is worse than not having the feature.

### D8 — The demo indication reuses `MonetaBanner`

`MonetaBanner` (`42:329`) already exists with an `info` tone. Demo mode shows
one on the application's main surfaces, so nothing new is designed for it.

It needs to be **not dismissible** — its whole job is to stop a user reading
dummy figures as their own, and a dismissible warning is one a user dismisses.
Checked rather than assumed: `MonetaBanner` has no dismiss affordance at all
(`tone`, `title`, `message`, `onTap`), so this is a property of the existing
component and **not** a deviation to record. If a later change adds a dismiss
to `MonetaBanner`, this use must opt out, and that is the note the tasks
carry.

### D9 — The dataset's shape is invented, and that is fine here

Category weights, amount ranges and the merchant-ish labels are made up. They
come from nowhere in Figma and nowhere in the repository.

That is the one place in this project where inventing values is correct, because
the values *are* the dummy data — there is no source of truth for what a
fictional person spent on coffee. What still has to be true is structural, and
that is what the spec constrains: every category present, totals unequal, all
three budget states reachable, more than eight categories in the current month,
amounts whole and positive.

Recorded explicitly so nobody later mistakes the weight table for a
transcription.

## Risks / Trade-offs

- **The toggle leaves a stale connection open, and reads hit the old file** →
  the requirement says the previous connection is closed before the new one
  serves anything, and the test asserts a write after the swap lands in the new
  file while the old file's row count is unchanged.
- **Seeding is slow enough to look like a hang** → measured, reported, and if
  it is, wrapped in one transaction. The toggle also has to not appear finished
  before seeding is.
- **A user turns demo mode on, adds real transactions by mistake, turns it off,
  and believes they lost data** → the indication (D8) exists for exactly this,
  and reset is the only destructive action, offered only in demo mode.
- **`profile-feature` builds `08.xx` Settings and the provisional screen
  lingers** → the screen is named for what it is, `figma-map.md` records it as
  provisional and unauthored, and this change's tasks include the note that
  absorbing it is `profile-feature`'s work.
- **Coverage:** the generator is pure and lands in `lib/app`, which is outside
  `tool/coverage_critical.txt`. Its tests are the substance of this change, so
  the tasks require them regardless of what the gate would let pass — the same
  gap `home_route_screen.dart` is already recorded as having.

## Migration Plan

Nothing to migrate. The real database's schema, version and contents are
untouched, and an install that never enables demo mode is byte-identical to one
on the current build. Rolling back is deleting `moneta_demo.db` and the one
preference row.

## Open Questions

- Whether `08.xx` Settings authors a demo or developer section at all. Cannot be
  answered while the Figma connection is on the View-seat account, and does not
  block this change: the two controls exist and move.
