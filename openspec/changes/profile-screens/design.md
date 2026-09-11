## Context

See `proposal.md` — Why. Constraints that shape the approach, each checked
against the code rather than assumed:

- **`PreferencesStore` is boolean-only.** `readBool`/`writeBool` parse the
  literal text `true`/`false` and treat anything else as a storage failure. The
  `settings` table's `value` column is TEXT, so strings need accessors, not a
  migration.
- **Screens are pure; `lib/app/` wires.** `insights_route_screens.dart` is the
  pattern: the screen takes data and callbacks, a `ConsumerWidget` in `lib/app/`
  supplies them. This is what lets `08.08` show real per-category totals without
  `features/settings` importing `features/transactions`, which
  `tool/check_architecture.dart` forbids.
- **`08.01` and `08.03` already exist**, and both show placeholders: `08.01`'s
  name and email, and `08.03`'s `Main currency` row hard-coded to `VND`, plus
  three rows reading "Not built yet". Their layouts do not change; their
  sources do.
- **`Credentials.isPlausibleEmail` exists** in `features/auth/domain` and
  already rejects every case `08.02` needs to reject. `features/settings` cannot
  import it.
- **`SpendCategory.isIncome` is documented as a display hint only**, and
  `incomeCategories` is `{salary}`. It is not the basis for `08.08`'s filter.
- **The gate pins `TZ=Asia/Ho_Chi_Minh`**, so a month boundary computed in UTC
  is indistinguishable from a correct one unless a test is written to
  discriminate.
- `tool/check_design_tokens.dart` scans all of `lib/` for `EdgeInsets.*` with a
  digit, inline `TextStyle(`, `BorderRadius.circular(` with a digit, `Color(0x`
  and `Colors.`. Naming a `static const` does **not** exempt the line that uses
  it if the literal is still there — see Risks.
- Coverage: `tool/coverage_critical.txt` matches on the `/domain/` and `/data/`
  path substrings at **≥85%**, so both new directories under
  `features/settings` are critical paths.

### Three things found while planning that removed `08.04` and `08.05`

They are recorded here because the reason a screen is deferred is worth more
than the fact of it:

1. **`ListRow` has no `enabled` flag.** Its constructor takes `title`,
   `accessory`, `subtitle`, `leadingIcon`, `value`, `badgeLabel`, `toggled`,
   `onTap`, `onToggle`, `destructive`, and there is no disabled treatment
   anywhere in the widget. `08.04`'s unavailable rows therefore need a
   design-system variant against `35:113` — a new variant, a per-variant test,
   a gallery entry, a describer case and a map row.
2. **`MonetaOtpField` renders the literal characters.** A PIN typed into
   `08.05` would be displayed in plaintext, and the component has no masked
   variant. Shoulder-surfing is the one threat a UI PIN actually addresses.
3. **Erase all data cannot work as it was drafted.** In real mode
   `activeDatabaseProvider` returns *the control database object itself* —
   deliberately, so the file is not opened twice. `AppDatabase.deleteFile()`
   deletes the file, and that file holds the `settings` table. So "erase the
   ledger" in real mode also destroys the profile, `onboarding_complete`,
   `demo_mode` and all four notification preferences, and leaves
   `preferencesStoreProvider` holding a closed connection until it and
   `controlDatabaseProvider` are invalidated. That is a design question about
   what "all data" means, not an implementation detail.

And a fourth, which is why the PIN itself is out: **a PIN that gates nothing is
a stored value nothing reads** — the defect `08.06` already recorded when a
notification switch had nothing behind it. Gating needs a lock screen and a
router redirect.

## Goals / Non-Goals

Design-level goals beyond the proposal's scope:

- Keep every screen a pure widget with no `Ref`, so each is testable by pumping
  it with data — the property that made `08.01`, `08.03` and `08.06` cheap.
- Put arithmetic in `domain`. `08.10`'s 31% and `08.08`'s totals both have
  boundaries, and a boundary tested through a widget is tested badly.
- Make a row that cannot act **unable to be built as one that can**, rather
  than disabled.

Non-goals at design level:

- Animation, goldens, and any settings framework. Four screens, each with the
  rows it has.

## Decisions

### D1 — `readString`/`writeString` beside the boolean pair, not instead of it

**Chosen:** add two methods; `readBool` keeps rejecting non-boolean text.

Alternatives:

- *A generic `read<T>`/`write<T>`.* Rejected: the boolean accessors' value is
  that they are **strict** — a value that does not parse is a storage failure,
  not a silent `false`. A generic accessor either loses that or reinvents it
  per type.
- *One JSON blob for the profile.* Rejected: the table is a key/value store, and
  a blob makes one corrupt byte lose three fields instead of one.

A boolean key read by `readString` returns the literal `'true'` rather than an
error, because the column is TEXT and that *is* what is in it.

### D2 — The profile is three preference keys; its store is `data`, not `domain`

**Chosen:** `profileName`, `profileEmail`, `profileCurrency` as
`PreferenceKey`s, read and written by a `ProfileStore` in
**`features/settings/data/`**.

CLAUDE.md says `domain/` "Depends on core only", and a `PreferencesStore`-backed
store does not. `tool/check_architecture.dart` keys only on the top-level
`features` segment and would **not** catch a store placed in `domain` — the rule
is documented but unenforced, so the layer is a decision to get right by hand.
The pure types (`Profile`, the FAQ entries, the plans, `CategoryUsage`) stay in
`domain`.

Control-scoped, because `preference_key.dart` already documents that every
preference lives in the control database: a ledger-scoped name would mean
turning demo mode on renamed the user.

Alternative: a `profile` table with a migration. Rejected for one row of three
short strings — the `settings` table exists for this, and a migration is a
permanent cost for no gain.

### D3 — The email rule moves to `lib/core`, and auth delegates

**Chosen:** `lib/core/email.dart` holds the rule; `Credentials.isPlausibleEmail`
becomes a one-line delegation and keeps its name and its `emailError` message.

Alternatives:

- *A second rule in `features/settings/domain`.* Rejected: two validators that
  are supposed to agree and can silently stop agreeing. The auth rule already
  rejects `a@b` (its domain has no dot) and accepts
  `user+tag@sub.domain.co.uk`, which is exactly what `08.02` wants.
- *Move the whole of `Credentials` to core.* Rejected: password length and the
  six-digit code rule are auth's business, and moving them would drag auth's
  vocabulary into `core` for no caller.

The check that this is a move and not a rewrite: **auth's existing tests pass
unmodified.**

### D4 — `08.11`'s content is a typed list in `domain`

**Chosen:** a `FaqEntry` value type and a constant list, with search and
diacritic folding as pure functions over it.

Alternatives:

- *Hard-code the items in the widget.* Rejected: search and folding have
  boundaries, and they are testable as functions and awkward as a widget.
- *Load them from an asset.* Rejected: `rootBundle` inside `testWidgets` hangs
  under `FakeAsync` (CLAUDE.md), and the content is neither localised nor
  user-editable.

Diacritic folding is an explicit table for Vietnamese's vowels, not a general
Unicode normaliser: `dart:core` has no NFD normalisation and a package for five
FAQ entries is not justified. The table is a decision with a boundary, so it is
tested directly rather than through the screen.

**Dropped from an earlier draft:** a requirement that "the answers do not
contradict the app". There is no observable link between an FAQ string and app
behaviour — a test could only assert the constant against itself, which is this
session's recurring defect. The answers are still written from the annotation;
the unfalsifiable requirement is gone.

### D5 — A row that cannot act is built without the action

`08.08`'s rows must not be tappable, and `08.09` is the screen that would make
them so.

**Chosen:** build them with no tap callback at all, and assert on the
**semantics tree** that no row exposes a button or a tap action.

Alternatives:

- *A disabled row.* Rejected: `ListRow` has no such variant (see Context), and
  adding one for a screen that will get a real destination later is the wrong
  order.
- *A source scan for `onTap`.* Rejected, and worth naming: a source scan cannot
  see a `GestureDetector`, an `InkWell`, a callback passed through a variable,
  or `ListRowAccessory.toggle`, which routes activation through `onToggle`
  instead. It is the "check that cannot see what it forbids" defect this session
  already shipped once.

### D6 — `08.10`'s saving is derived, and the rounding mode is part of the rule

**Chosen:** `PremiumPlan` values carrying `Money` prices; the yearly saving
computed as `(1 - yearly / (monthly * 12)) * 100`, **rounded**.

Annotation `102:1185`: *"59,000 ₫ × 12 = 708,000 ₫ against 490,000 ₫ yearly,
which is the 31% the badge claims. The claim is arithmetic, not marketing."*

The exact value is **30.79%**. `round` gives 31 and matches the badge; `floor`
gives 30 and contradicts it. So the mode is stated in the requirement rather
than left to whichever function gets typed — an earlier draft called this
"arithmetic" and left the mode out, which is how the claim could have shipped
as 30.

Degenerate prices return **absent**, not a number: a zero monthly price would
divide by zero, and a yearly price above twelve monthly payments would produce a
negative "saving", which is not a saving.

Alternative: a `'SAVE 31%'` string. Rejected — it is the one number on the
screen that can be wrong while looking right.

### D7 — Category usage is a pure function in `domain`, wired in `lib/app/`

**Chosen:** `CategoryUsage` (a category, a count, a `Money`) and a pure function
from entries to a sorted list; the entries come from the transaction repository
through a provider in `lib/app/`.

Alternatives:

- *A query in `lib/data/`.* Rejected for now: `lib/data` holds the database and
  shared DAO infrastructure, and category usage is feature knowledge. `lib/app/`
  may import anything and already does this for insights. If a second feature
  needs the same query, that is when it moves.
- *Reuse `InsightsSummary`.* Rejected: it lives in `features/insights/domain`
  and a cross-feature import is forbidden. The arithmetic is small enough that
  duplicating it is cheaper than the shared-module churn — and it is stated
  here so that a future reader knows the duplication is deliberate.

**The filter is `TransactionDirection`, not `SpendCategory.isIncome`.**
`lib/core/spend_category.dart` says of `isIncome`: *"the direction of a
transaction is a property of the transaction, not of its category. This getter
is a display hint only."* `incomeCategories` is `{salary}` alone, so filtering by
it would list one row and hide every income-direction `gift`.

The period is **a whole calendar month in the local zone**, from an injected
`Clock`. The test discriminates: a transaction at `2026-08-31T18:00Z` is
`2026-09-01T01:00` in `Asia/Ho_Chi_Minh` and must be **included**, which a
UTC-boundary implementation gets wrong and which the gate's pinned `TZ` makes
observable.

A currency mismatch **within one category** throws `ArgumentError`, because
`Money.operator+` does and `DonutChart` already relies on that. The screen
surfaces it rather than rendering a wrong total.

## Risks / Trade-offs

- **A local frame drifts from the file** → each local frame's authored numbers
  are named `static const` with a `figma-map.md` row, as `08.01`'s `_StatCard`
  already is.
- **`check_design_tokens.dart` on three screens' worth of local layout** →
  every inset comes from `MonetaSpacing` or a named constant *whose literal is
  in the declaration, not at the use site*, which is what keeps the checker
  quiet. No `// design-token-ignore` is expected; if one turns out to be needed
  it is raised rather than added.
- **`08.08`'s totals could disagree with the Insights donut** → both derive
  from the same repository and the same kind of window. They are **not**
  asserted equal to each other, which would test two implementations instead of
  one requirement.
- **The email move breaks auth** → the check is that auth's existing tests pass
  unmodified. If any needs changing, the move is not behaviour-preserving and
  stops.
- **Erasing the profile is impossible from these screens** → deliberate.
  `08.04` is out of scope precisely because "all data" is unresolved.
- **`check_architecture.dart`** → `features/settings` imports `core`,
  `design_system`, `data` and itself; the wiring lives in `app`; `features/auth`
  gains an import of `core`, which is allowed. The temptation this design
  avoids is importing `features/transactions` for `08.08`.

## Verification

| Requirement | Test file | What catches a regression |
| --- | --- | --- |
| String accessors: round-trip, absence, replace, odd strings, 10k, failure | `test/data/preferences_store_test.dart` | absent is `Ok(null)` and stored-empty is `Ok('')`; quote/newline/emoji/diacritic; length asserted exactly |
| Boolean key read as string | same | asserts the literal `'true'`, and that the reverse still fails |
| Email rule moved, behaviour unchanged | `test/core/email_test.dart`, `test/features/auth/credentials_test.dart` | auth's file **unmodified**; permissive and rejected cases as a table |
| Profile saved, read, control-scoped | `test/features/settings/profile_store_test.dart`, `test/app/settings_route_test.dart` | asserted **with demo mode on**, not after a round trip |
| Currency reaches `08.03` | `test/app/settings_route_test.dart` | the row shows the stored code, not `VND` |
| `08.02` three inputs, both actions, email error, empty name | `test/features/settings/edit_profile_screen_test.dart` | field counts; one callback from two controls; `AppFailure(kind: validation)` |
| `08.02`/`08.01` long name | same + `profile_screen_test.dart` | `maxLines`/`overflow` asserted on the widget, not a width |
| `08.11` chevrons per item | `test/features/settings/help_screen_test.dart` | each item's glyph against its own state |
| `08.11` search, folding, empty state, clear | same + `test/features/settings/faq_search_test.dart` | `du lieu` → `dữ liệu`; `xyzzy` → `EmptyState` |
| `08.10` saving is 31, computed | `test/features/settings/premium_plan_test.dart` | changing a price changes it; `round` vs `floor` pinned; zero and inverted prices give absent |
| `08.10` one selected; negatives not `expense` | `test/features/settings/premium_screen_test.dart` | selection invariant; the two glyph colours asserted to differ |
| `08.10` the action refuses honestly | same | activating reports unavailable and stores nothing |
| `08.08` counts, totals, sort, zero rows, boundaries | `test/features/settings/category_usage_test.dart` | literal expected counts; `(1 << 61) - 1`; `ArgumentError` on mixed currency |
| `08.08` the local-month boundary | same | the `2026-08-31T18:00Z` case, which fails under a UTC boundary |
| `08.08` direction filter, one chip, no buttons, 44px row | `test/features/settings/manage_categories_screen_test.dart` | semantics tree asserted for absence of tap actions; the literal 44 |
| Routes and the three dead rows | `test/app/router_test.dart`, `test/app/settings_route_test.dart` | navigating to each; no row reads "Not built yet" that now has a destination |

Every task carries a **mutation**. Three traps are pre-named from this session's
four repeats: no expected value may be derived from the implementation's own
constant; a colour must be asserted on the object that carries it, and against
the alternative it must differ from; a bound must be two-sided.

## Migration Plan

None. No schema change: `readString`/`writeString` use the `settings` table
migration v2 already created, and a key with no row reads as absent by the
store's existing contract. The email move is behaviour-preserving by
construction. Rolling back is reverting the commits; stored profile rows would
simply be unread.

## Open Questions

None that change these specs, this approach or this task breakdown. What
`08.04`'s "all data" should mean, and what a PIN should gate, are real open
questions — which is why those screens are not in this change.
