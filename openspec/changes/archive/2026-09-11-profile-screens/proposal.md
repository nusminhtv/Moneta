## Why

Page 08 has eleven screens and three are built. `settings-components` cleared
every *component* blocker on the page, so what remains is feature work — and for
four of these screens it is small feature work that makes an already-visible
screen tell the truth.

`08.01` is the clearest case. It shows `'Minh Tran'` and
`'minh.tran@example.com'` in demo mode and `'Moneta user'` / `'Not signed in'`
otherwise, with a comment calling them placeholders, and its Edit button goes
nowhere. `08.03` carries **three rows reading "Not built yet"** and a `Main
currency` row hard-coded to `VND`. One string store and four screens fix all of
it.

The user-visible outcome: **four more screens reachable from Profile**, taking
page 08 from 3 of 11 to 7 of 11, `08.01`'s identity becoming something the user
chose, and three dead rows on `08.03` becoming live ones.

## What Changes

### The enabler

- **`PreferencesStore` gains `readString`/`writeString`.** It is boolean-only
  today, and a name, an email and a currency are not booleans. The `settings`
  table already stores its values as TEXT, so **no migration** — the same
  table, the same columns, a second pair of accessors with the same `Result<T>`
  and `AppFailure` discipline. Absence stays distinct from a stored value
  (`Ok(null)` versus `Ok('')`).
- **`Credentials.isPlausibleEmail` moves to `lib/core/email.dart`.** `08.02`
  needs the same rule the auth screens use, and `features/settings` may not
  import `features/auth` — `tool/check_architecture.dart` forbids it. Writing a
  second rule is how two validators drift apart, so the one that exists moves to
  where both can reach it. `features/auth/domain/credentials.dart` delegates to
  it and keeps its own API, so no auth screen changes.

### The screens

1. **`08.11` Help & FAQ** (`102:1189`) — a `SearchField`, five local accordion
   items with the first expanded, and a `ListRow` to contact support. Searching
   filters; no result falls back to `EmptyState HasAction=True`.
2. **`08.02` Edit profile** (`100:276`) — `Avatar`, two `TextField`s, a `Select`
   for the main currency, a sticky save that the app-bar check duplicates.
   Writes the name and email `08.01` reads. An invalid email switches that field
   to `State=Error`.
3. **`08.10` Premium paywall** (`102:1044`) — three local plan cards with a
   `Badge` on the middle one, a `SectionHeader`, a local comparison table of
   `icon/check` and `icon/x`, a sticky CTA. **Nothing is purchasable** and the
   screen says so.
4. **`08.08` Manage categories** (`101:978`) — two `Chip`s filtering by
   **transaction direction**, and one row per category carrying its real
   transaction count and total for the month. Its Purpose asks for exactly that:
   *"see how much each one is actually used"*.

### The wiring these screens make honest

- `08.01`'s name, email and avatar initials come from the store; its **Edit**
  button opens `08.02`; its **Premium** row opens `08.10` (it has no `onTap`
  today) and its **Help & FAQ** row stops reading "Not built yet".
- `08.03`'s **Edit profile**, **Security** and **Help & FAQ** rows lose
  `available: false` where this change gives them a destination — Edit profile
  and Help & FAQ do; **Security stays unavailable**, see Non-goals.
- `08.03`'s **`Main currency`** row shows the stored currency instead of a
  hard-coded `VND`.
- `router.dart` and `SettingsRoutes` gain three routes.

## Non-goals

- **No purchases.** `08.10` renders and its CTA reports that purchases are
  unavailable in this build. A paywall whose button silently does nothing is
  worse than one that says so.
- **No PIN, and `08.05`/`08.04` are not in this change.** A PIN has to *gate*
  something, and nothing in this app locks. Shipping a stored PIN that nothing
  reads is precisely the defect `08.06` already recorded — a preference no code
  consults — so it would contradict this change's own reasoning. Gating needs a
  lock screen and a router redirect, and that is its own change. Three further
  things were found while planning and belong with it: `ListRow` has **no
  `enabled` flag**, so `08.04`'s unavailable rows need a design-system variant
  against `35:113`; `MonetaOtpField` renders the literal characters, so a PIN
  would be displayed in plaintext as it is typed; and **Erase all data cannot
  work as drafted** — in real mode `activeDatabaseProvider` returns the
  *control* database object itself, so deleting that file destroys the `settings`
  table with the profile, the onboarding flag and every notification
  preference. All three are recorded in `figma-map.md` rather than discovered
  later.
- **No category editing** — `08.09` stays deferred. Rename, reorder, archive and
  custom colours need a per-category override layer that `CategoryIcon`, the
  donut and every chart must read, and `SpendCategory.chartSlot` is a fixed enum
  in `lib/core`. `08.08` ships its **usage half**: the counts are real, the rows
  are not tappable, and the authored drag handle is absent.
- **No currency conversion, and no currency *picker*.** `08.02` shows the
  stored currency and `08.03` reads it, but the `Select` **opens nothing** and
  therefore ships **disabled**: choosing one is `08.07`'s job and `08.07` is not
  built. An inert control is worse than an absent one — the standard this change
  applies to `08.10`'s call to action — so it reads disabled rather than
  swallowing taps. Nothing can write `profileCurrency` from the UI yet, which is
  stated here rather than discovered. `08.07` stays deferred: a formatting
  preference has to reach every amount in the app, which is a formatter threaded
  through every screen, not a settings page.
- **No new components and no design-system changes.** All the components these
  four screens instance are built, and none needs a new variant. (An earlier
  draft of this proposal assumed `ListRow.enabled` existed; it does not, which
  is why `08.04` is out of scope rather than quietly bringing a design-system
  change with it.)
- **No shake animation**, which `08.05`'s annotation authors — it is not in
  this change because `08.05` is not.

## Capabilities

### New Capabilities

- `profile`: the identity and category-usage behaviour these screens rest on —
  what is stored, what is derived from the ledger, and what each screen must
  refuse to claim.

### Modified Capabilities

- `storage`: `PreferencesStore` gains string accessors, and their failure
  behaviour is a requirement rather than an implementation detail.

## Impact

- **`lib/core/email.dart`** — new, holding the address rule that
  `features/auth` currently owns.
- **`lib/features/auth/domain/credentials.dart`** — delegates to it. Its own
  tests still pass unchanged, which is the check that the move is behaviour-
  preserving.
- **`lib/data/preferences/`** — `preferences_store.dart` (string accessors),
  `preference_key.dart` (profile name, email, currency).
- **`lib/features/settings/domain/`** — pure types over `core`: the FAQ
  entries and their search, the premium plans and the derived saving, category
  usage and the month window.
- **`lib/features/settings/data/`** — the profile store, which is backed by
  `PreferencesStore` and therefore is **not** `domain`. Note it lands in the
  `≥85%` critical-coverage set by virtue of the `/data/` path.
- **`lib/features/settings/presentation/`** — four screens plus the local
  accordion, plan cards and comparison table.
- **`lib/app/`** — `settings_route_screens.dart`, `router.dart`, and providers
  for the profile and for category usage.
- **Tests that change rather than being added**:
  `test/features/settings/profile_screen_test.dart` (identity is no longer a
  constant), `test/features/settings/settings_screen_test.dart` (three rows stop
  being unavailable), `test/app/router_test.dart` and
  `test/app/settings_route_test.dart` (three new routes),
  `test/features/auth/credentials_test.dart` (unchanged assertions, moved rule).
- **`docs/design-system/figma-map.md`** — page 08's table, one deviation per
  screen that ships less than the file draws, and the three blockers found for
  `08.04`/`08.05`.
- **Modules touched**: `core`, `data`, `features/settings`, `features/auth`
  (one file), `app`. No `design_system`.
