# Brief — 📱 02 Home & Dashboard

You are implementing **📱 02 Home & Dashboard** in the Moneta repository, in
parallel with another agent who is implementing **📱 01 Onboarding & Auth**. This
document is the contract between you. Read all of it before writing code.

**Do not start until the parallel-foundation commit is on `main`.** Confirm with
`git log --oneline --grep "parallel foundation" -1`. It does not build components
— it creates the *seams* that let two agents add components without colliding:

- `lib/app/gallery/gallery_catalog.dart` now spreads three lists. `coreSections`
  stays shared; `authSections` and `homeSections` live in their own files with one
  owner each. You own `gallery_catalog_home.dart`.
- `test/app/gallery_test.dart`'s `_describe` was one switch, which is a
  compile-level collision rather than a merge conflict. It now chains
  `_describeCore(w) ?? describeAuth(w) ?? describeHome(w) ?? throw`. You own
  `test/app/gallery_describe_home.dart`.
- `docs/design-system/figma-map.md` now records all 45 component sets with node
  ids and variant counts, and the nine screen pages from the Screen Index.

So the only shared lines are two spreads and two `??` operators.

---

## 1. Your scope — six screens, exact node ids

From the file's own `🗂 Screen Index` (node `5:24`). These are read from Figma,
not inferred:

| ID | Screen | Node | Pri | Components used |
| --- | --- | --- | --- | --- |
| 02.01 | Home — default | `52:2` | P0 | AppBar, BalanceCard, BottomNav, BudgetCard, DateGroupHeader, IconButton, SectionHeader, TransactionRow |
| 02.02 | Home — empty | `52:372` | P0 | AppBar, BottomNav, EmptyState, ListRow |
| 02.03 | Home — loading | `52:547` | P0 | AppBar, BottomNav, Skeleton |
| 02.04 | Home — over-budget alert | `57:414` | P0 | AppBar, BalanceCard, Banner, BottomNav, BudgetCard, DateGroupHeader, SectionHeader, TransactionRow |
| 02.05 | Notifications — list | `57:622` | P1 | AppBar, BottomNav, ListRow, SectionHeader |
| 02.06 | Notifications — empty | `57:840` | P1 | AppBar, BottomNav, EmptyState |

Every screen has a **sibling annotation frame** giving Purpose, Components,
States, Data and accessibility rules. Read it before implementing the screen. It
is a written spec per screen and it is not optional.

### Components you build

Yours alone, with the node and the full variant count Figma authors. Build
**every** variant, not only the one your screen uses:

| Component | Node | Variants |
| --- | --- | --- |
| DateGroupHeader | `29:71` | 1 |
| EmptyState | `35:166` | 2 — HasAction true/false |
| Skeleton | `38:139` | 4 — Line, Circle, Card, Row |
| Banner | `42:329` | 4 — Warning, Danger, Info, Success |

**Plus two of the four components both flows need**, split so neither of us waits
on the other:

| Component | Node | Variants | Owner |
| --- | --- | --- | --- |
| ListRow | `35:113` | 5 — Chevron, Value, Toggle, Badge, None | **you** |
| SectionHeader | `55:107` | 1 | **you** |
| AppBar | `39:112` | 4 — LargeTitle, TitleBack, TitleActions, Transparent | auth agent |
| IconButton | `20:114` | 18 — 3 styles × 3 sizes × 2 states | auth agent |

**Ordering dependency, in both directions.** All six of your screens use `AppBar`
and 02.01 uses `IconButton`, so build your own four plus `ListRow` and
`SectionHeader` first, and rebase to pick up `AppBar`/`IconButton` when the auth
agent lands them. Their screens 01.10 and 01.12 need your `ListRow` and
`SectionHeader`, so land those early — they are the last two auth screens and the
auth agent is blocked on you for them. If you are going to be slow on `ListRow`,
say so rather than letting them discover it.

Already implemented and not yours to change: `BalanceCard` (`40:161`),
`BottomNav` (`39:243`), `BudgetCard` (`40:256`), `TransactionRow` (`29:70`),
`Button` (`13:2`), `ProgressBar` (`21:139`), `CategoryIcon` (`33:311`).

**`TransactionRow` is implemented at 2 of its 4 authored variants** — `Transfer`
and `Pending` are missing because the domain has no concept for either, and
`Full variant coverage` in the spec set says a partial set "is not complete". Two
of your screens render it. If 02.01 or 02.04 shows a transfer or a pending row in
Figma, **stop and raise it** — completing that component is a domain decision, not
a UI one, and it is not in your scope to invent.

**Read `docs/design-system/figma-map.md` first.** It now carries the complete
45-component library with node ids and variant counts, read on 2026-08-25.

---

## 2. The Figma trap that has cost this project the most

`get_metadata` **without** a `nodeId` returns an incomplete page list — three
pages. That listing is **not** the file. This project twice concluded from it
that the file "has no screen designs", wrote that into requirements and ADRs, and
planned two whole changes on it. It was false both times.

Always query a concrete node. Pages step by 3 from `5:7` to `5:25`.

**Never write that this file lacks a design.** If you cannot find something, say
it was not found and name exactly what you queried.

The file is a **training file**: its Cover claims 74 screens, 37 variant sets and
**twelve deliberate mistakes**, with an answer key at `🔧 Utilities / Known
Deviations`. If a value looks wrong, it may be one of the twelve. Record it as an
observation with the node id; do not silently "fix" it, and do not silently copy
it either.

---

## 3. File ownership

### Yours — the other agent will not touch these
```
lib/features/home/**
lib/features/notifications/**
lib/design_system/molecules/date_group_header.dart
lib/design_system/molecules/empty_state.dart
lib/design_system/molecules/skeleton.dart
lib/design_system/molecules/list_row.dart
lib/design_system/molecules/section_header.dart
lib/design_system/organisms/banner.dart
lib/app/gallery/gallery_catalog_home.dart      # created empty in PHASE0
test/app/gallery_describe_home.dart            # created in PHASE0
test/features/home/**
test/features/notifications/**
test/design_system/molecules/{date_group_header,empty_state,skeleton,list_row,section_header}_test.dart
test/design_system/organisms/banner_test.dart
openspec/changes/home-overview/**
```

### Theirs — do not open these
```
lib/features/auth/**
lib/design_system/atoms/{icon_button,checkbox,divider,logo}.dart
lib/design_system/molecules/{text_field,select}.dart
lib/design_system/organisms/{app_bar,otp_field}.dart
lib/app/gallery/gallery_catalog_auth.dart
test/app/gallery_describe_auth.dart
lib/data/database/**            # schema is single-writer, see §4
openspec/changes/auth-screens/**
```

### Shared — append only, never restructure
```
lib/app/router.dart                            # add routes inside the HOME block marker
lib/app/gallery/gallery_catalog.dart           # one line: the spread of your list
test/app/gallery_test.dart                     # one line: the delegate to your describer
docs/design-system/figma-map.md                # add rows, do not rewrite sections
docs/design-system/figma-tokens.md             # add rows only if you add a token
openspec/specs/**                              # only via your change's delta specs
```
Each shared file has `// --- HOME: add below ---` markers. Stay inside yours.
A conflict inside a marker block is a two-line resolve; restructuring the file is
a day.

---

## 4. Reserved values — collision would be silent and bad

| Thing | Yours | Theirs |
| --- | --- | --- |
| Route prefixes | `/notifications`, and the existing `/` home tab | `/auth/*`, `/setup/*` |
| OpenSpec capability | `home`, `notifications` | `auth` |
| OpenSpec change | `home-overview` (revise the existing one) | `auth-screens` |
| Feature dirs | `lib/features/home`, `lib/features/notifications` | `lib/features/auth` |
| Git branch | `home-dashboard` | `auth-screens` |
| **Database schema** | **none — see below** | v3 |

**You may not change `schemaVersion` or add a migration.** The schema is
single-writer and the auth agent owns it, because storing a PIN hash forces a
migration on their side. Two agents both writing `const int schemaVersion = 3`
produces two different migrations numbered 3 and a corrupted upgrade path on real
devices — it would not show up in tests, because each branch is self-consistent.

If you genuinely need persistence (e.g. notification read-state), **stop and ask
the user**. Do not work around it with SharedPreferences or a JSON file; this app
is SQLite-only by design.

---

## 5. The change `home-overview` is already open, and its premise is false

`openspec/changes/home-overview/` exists with 18 tasks and **0 done**. It was
planned before anyone had found the real screens, on the premise that Figma had
no screen designs — so its layout decisions are invented, not transcribed.

Your first job is to **revise it, not to implement it**: run `/opsx:update
home-overview` (or edit the artifacts directly) so `proposal.md`, `specs/`,
`design.md` and `tasks.md` describe the six real screens above, each naming its
node id. Delete tasks that only existed to invent a layout. Then implement.

Related: `docs/adr/0004-cross-feature-overview-screens.md` is flagged
**PREMISE SUSPECT** for the same reason. Read it, then either re-decide it against
the real design or record that it no longer applies.

---

## 6. The non-negotiables

These are enforced by machine, and by a reviewer who will run mutations against
your tests. From `CLAUDE.md`:

- **Money is never a `double`.** Use `lib/core/money.dart` — integer minor units.
  A `double` amount anywhere in domain or data is a bug.
- **Repositories return `Result<T>`**; they do not throw for expected failures.
  Expected failures are `AppFailure(kind: storage | validation | notFound)`.
  "Shows an error" is not a specification; name the `AppFailure` kind.
- **`DateTime` is stored and compared in UTC.** Inject `Clock`; never call
  `DateTime.now()` outside `SystemClock`.
- **No raw design values outside `lib/design_system/tokens|theme`.** No
  `Color(0x…)`, `Colors.*`, inline `TextStyle(`, `EdgeInsets.*(` with literals,
  `BorderRadius.circular(`. A genuine exception needs `// design-token-ignore`
  plus a reason on the line.
- **Design-system widgets take domain types**, not pre-formatted strings.
- **Every Figma component's full variant set is implemented**, not just the
  variant your screen needs. `Banner` has Warning/Danger/Info/Success — build all
  four even though 02.04 uses one.
- **No cross-feature imports.** `lib/features/home` may not import
  `lib/features/transactions`. Share through `lib/core` or `lib/data`.
  `tool/check_architecture.dart` enforces this and will fail your build.

Use the **new** spacing scale: `MonetaSpacing.spaceBase` etc. The instance scale
(`theme.spacing.md`) is deprecated and its values are **wrong** — invented before
anyone read Figma's real `space/*` collection at `107:75`. Every doc comment on it
names its replacement.

---

## 7. What "done" means here

**Done is `bash tool/verify.sh --change home-overview` passing.** Not "tests
pass", not "it builds". The gate is eight steps: timezone, format, analyze
(`--fatal-infos`), architecture, design-tokens, hooks, test, coverage. Each run
writes an evidence file to `docs/ai-workflow/verify-runs/` — cite its path in
every commit.

**Never weaken a gate to make it pass.** Changing a threshold, widening
`_allowedImports`, adding `// ignore:`, or deleting a check requires saying so
explicitly and getting agreement first. This repo has had two undisclosed gate
weakenings and both were caught by review, not by the gate; they are written up in
`docs/ai-workflow/evidence-log.md`. Do not add a third.

**One commit per task.** Run the equivalent of `/moneta:checkpoint` at the end of
each task in `tasks.md`: verify, self-review the diff, tick the task, commit. Do
not batch the whole change into one commit.

Commit format:
```
<type>(home-overview): <what>

Task: <task from tasks.md>
Verify: <docs/ai-workflow/verify-runs/… path>
```

**Never `git push` to `main`.** Push your own branch only; the user merges.

---

## 8. Testing bar — read this, it is where the time goes

Coverage: `lib/core`, every `*/domain/`, every `*/data/` need ≥85% line coverage;
project total ≥70%. But coverage is not the bar — **a test that asserts the
implementation back to itself does not count**, and a reviewer will mutate your
code to check.

Concretely, these all passed a full green suite in this repo and were real bugs:

- A component **ignored its own parameter** — the test asserted `findsOneWidget`
  on a key that always exists. Assert the *identity* of what was rendered.
- A test compared a rendered value to the constant it was checking
  (`expect(rect.width, dot.size)` where `dot` is the same list). Assert against a
  literal read from Figma.
- A lookup table was asserted directly and never through the widget, so the table
  was right and the wiring was broken. Assert on the **render tree**.
- A geometry test ran at one width, where the scale factor is 1.0, so unscaled and
  scaled were indistinguishable. Test at more than one size.
- A persistence test wrote `false → true → false` and asserted `false`, which ends
  where it starts, so dropping every write but the first still passed.

Before you call a task done, mutate the thing you just wrote and confirm a test
fails. If nothing fails, your test does not test it.

### Traps specific to this codebase

- **Never `await` real I/O inside `testWidgets`.** Its body runs in a `FakeAsync`
  zone, so `rootBundle.loadString`, a file read or a socket **never completes** —
  the test hangs indefinitely instead of failing. Use plain `test()` with
  `TestWidgetsFlutterBinding.ensureInitialized()`, or `tester.runAsync(...)`.
  This cost a 7-minute stall that looked like a slow machine.
- **`flutter test` renders with a metrics-only placeholder font** where every
  glyph is exactly `fontSize` wide. Any assertion about how wide a *string* is
  measures that font, not the design. Assert font-independent structure (a child
  stays inside its parent, a column respects its cap, nothing overflows) and leave
  real type metrics to goldens.
- **The gate pins `TZ=Asia/Ho_Chi_Minh`** and `tool/check_timezone.dart` enforces
  it. Local-time assertions cannot fail under UTC — a function that forgets
  `.toLocal()` returns the identical answer. Write local-time tests so they
  discriminate. Do not remove the `TZ` export.
- **`pumpAndSettle` does not drain a plain `Timer`.** With no animation scheduled
  it returns after the first pump. Pump the duration explicitly.
- **Riverpod:** overrides bind by object identity, not by library. A
  `ProviderScope` may not change its *number* of overrides between pumps in one
  test. An `async =>` override makes a notifier rebuild mid-load and Riverpod
  disposes the in-flight build.
- Database tests run on the VM via `sqflite_common_ffi` — no simulator needed. To
  make production provider bodies execute (and count for coverage), assign
  `databaseFactory = databaseFactoryFfi` in `setUpAll` rather than overriding the
  providers; overriding leaves the shipped code unexecuted.

Boundary cases are required, not optional: zero, negative, very large amounts,
empty lists, currency mismatch, empty first-run database. 02.02 and 02.06 are
literally the empty cases — they are not an afterthought, they are two of your six
screens.

---

## 9. Two mechanical rules that keep our branches mergeable

**The gallery is enforced.** `test/app/gallery_test.dart` scans every `.dart`
file under `lib/design_system` and fails if a class there is not in the gallery
catalog or in an explicit exemption list with a stated reason. So every component
you build must be registered, in **every** variant, in
`lib/app/gallery/gallery_catalog_home.dart` (your file).

**The describer must learn your types.** The same test asserts that no two
variants of a component render the same widget, using a `_describe` function.
PHASE0 splits it so you own `test/app/gallery_describe_home.dart`. Add a case for
each component you build, naming its identifying properties. If you forget, the
test throws and tells you.

Do not "fix" either of these by widening an exemption. They exist because a
hardcoded six-name list once let four components go missing while the suite
stayed green.

---

## 10. Merge protocol

1. Branch from `main` **after** PHASE0 lands: `git checkout -b home-dashboard`
2. Work only in your files (§3). Commit per task (§7).
3. Rebase on `main` daily: `git fetch && git rebase origin/main`. Conflicts should
   only be inside marker blocks. If you hit a conflict anywhere else, **stop and
   report it** — it means an ownership rule was broken and guessing at the
   resolution is how a silent regression gets in.
4. Before handing over: full `tool/verify.sh` green, every task ticked, and a
   short note of anything you left undone. **Say what is not done.** A list that
   reads complete and is not is worse than a short honest one — six review rounds
   on the last change were mostly spent discovering that.
5. Do not merge to `main` yourself.

---

## 11. Reporting

State what you ran and what it output. If a gate failed, show it. If you skipped
something, say so and why. **"Should work" is not a result.**

If you find something wrong with this brief — a node id that does not resolve, a
component that turns out to be shared, a reserved value that collides — say so
before working around it.
