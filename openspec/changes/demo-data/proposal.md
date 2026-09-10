## Why

A fresh install has nothing in it. Home shows its first-run checklist, Budgets
shows an empty wallet, and Budget detail's whole point — spend against a limit
over time — has nothing to draw. Every screen that exists to *summarise* data
can only be reviewed by hand-entering months of transactions first, which nobody
does, so the screens that most need looking at are the ones least visible. The
Insights screens, when `insights-feature` builds them, will be worse: a donut
and a line chart with no history are blank by definition.

A demo mode with a substantial seeded dataset makes every screen reviewable in
one tap, and — because the demo lives in its own database — does it without ever
mixing dummy money into a real ledger.

## What Changes

- **A new `demo-data` capability.** A deterministic dataset covering roughly
  fifteen months: about 1,200 transactions across the seven expense categories
  with realistic weightings, salary on a monthly cycle, and budgets of all three
  periods including one over its limit and one near it. `SpendCategory` declares
  eight categories, `salary` being the income one — not nine, and no new
  category is added here.
- **A demo toggle.** On, the application reads and writes `moneta_demo.db`; off,
  `moneta.db`. Flipping it rebuilds the provider graph onto the other database.
- **Real data is never touched.** No dummy row is ever written to the real
  database, and no schema column is added to tell the two apart, because the
  separation is the file rather than a flag a query can forget.
- **Manual entry keeps working in both modes.** A transaction or budget added
  while demo mode is on lands in the demo database and behaves exactly like any
  other — it is editable, deletable and counted. This is what makes demo mode a
  place to *try* the app rather than a screenshot.
- **The demo dataset can be reset.** Reseeding wipes and regenerates the demo
  database. The real database has no such action and must not acquire one.
- **The demo flag moves out of the swapped database.** It lives in a control
  database that the toggle never swaps. Storing it in the `settings` table of
  the database being swapped makes the toggle undo itself: turning demo on
  writes `true` to the real database and then reads `false` from the demo one.
- **A provisional settings surface** carrying the toggle and the reset, reachable
  from Home. Explicitly provisional: `📱 08 Profile & Settings` is unbuilt and
  its Figma page is unread, so this is a functional affordance and not an
  attempt at the authored design. `profile-feature` absorbs it.

Not breaking for stored data: the real database's schema, version and contents
are unchanged, and an install that never turns demo on is byte-identical to one
on the current build.

## Non-goals

Each is out of scope for a reason, not for convenience.

- **A settings screen from Figma.** `📱 08 Profile & Settings` is unbuilt, its
  page has never been read, and the Figma connection is currently on an account
  that cannot read the file. The surface this adds is two controls and a route,
  named as unauthored, for `profile-feature` to absorb.
- **Exercising the donut's eight-segment fold.** It cannot be reached from
  category data: seven categories can carry expense and the cap is eight.
  Reaching it means adding categories to `lib/core/spend_category.dart`, which
  is a change about categories, not about demo data. `donut_chart_test.dart`
  already covers the fold with its own data.
- **Seeding notifications.** They are derived from budgets and transactions at
  read time (`lib/app/notification_providers.dart`) and never stored, so there
  is nothing to seed. The dataset produces them as a consequence.
- **Accounts.** There is no accounts feature, so no account data is invented and
  Home's "add an account" checklist row is left exactly as it is.
- **Multiple demo profiles**, or choosing the dataset's size, currency or seed
  from the UI. One dataset, one seed.
- **A `Toggle` design-system atom.** `25:198` is authored with four variants and
  unbuilt; building it needs the Figma file, and this change does not need a new
  atom — see design D12.
- **Seeding the real database**, ever, under any flag.

## Capabilities

### New Capabilities

- `demo-data`: what the seeded dataset must contain, that it is deterministic,
  that it is written through the same repositories as manual entry, that demo
  and real data are never mixed, and how the toggle and the reset behave.

### Modified Capabilities

- `storage/local-database`: today's requirement is a single database opened
  once per process. It becomes a **control** database that is always the same
  file, plus an **active data** database that the demo toggle chooses; opening
  is still once per file, and swapping closes the connection it replaces.
- `storage/preferences`: preferences currently live in the one database. The
  requirement gains the distinction the toggle needs — settings that select
  *which* database is active must be stored in the control database, and
  therefore survive the swap.

## Impact

- **Modules touched**, named because this change spans four of them:
  - `lib/data/app_providers.dart` — the control/active split and the demo flag.
  - `lib/data/database/app_database.dart` — a delete API, which reset needs and
    which does not exist today. This file is inside the ≥85% coverage band.
  - `lib/data/preferences/preference_key.dart` — the `demoMode` key.
  - `lib/app/demo/` (new) — the generator, the seeder and the controller.
  - `lib/app/budget_providers.dart` and
    `lib/features/transactions/presentation/transaction_providers.dart` — both
    watch the database provider directly and both move to the active one.
  - `lib/app/router.dart` and the route wrappers — the demo indication is
    injected here, because a feature may not import `lib/app`.
  - `lib/features/settings/presentation/` (new) — the provisional screen, as a
    callback-only widget.
  - `lib/features/transactions/presentation/transaction_list_controller.dart` —
    pending undo must not survive a ledger change.
  - `docs/design-system/figma-map.md` — to record the unauthored surface and the
    banner deviation.
- **Why the seeder lives in `lib/app`:** it must write `Transaction` and
  `Budget`, whose domain types belong to their features, and
  `tool/check_architecture.dart` forbids `lib/data` from importing a feature.
  `lib/app` is the composition root and may import anything, which is what a
  seeder is.
- **Dependencies:** none added. No `shared_preferences`: the control database
  already gives durable key/value storage, and adding a second persistence
  mechanism to hold one boolean would be the more expensive answer.
- **Schema migration:** none to the existing schema. The demo database is
  created by the *same* migration set, so it cannot drift from the real one.
- **Gates affected:** architecture (a new directory under `lib/app` and a new
  feature directory), design tokens (the provisional screen), tests and
  coverage — the generator is pure and belongs in the ≥85% band — through
  `bash tool/verify.sh --change demo-data`.
- **Figma nodes consumed:** none. This change is not derived from the file, and
  the one screen it adds is deliberately not an implementation of `08.xx`.
