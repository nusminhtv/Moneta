# Moneta — project instructions

Local-first personal finance app. Flutter + Dart, SQLite, design-system-first from
Figma. Every change goes through OpenSpec; every change is verified by
`tool/verify.sh` before it is archived.

## The workflow is not optional

This repository runs **OpenSpec (spec-driven schema)** plus a project-local
verification gate. The full loop:

```
  spec ──► discuss ──► plan ──► execute ──► verify ──► archive
   │          │          │         │          │          │
/opsx:      spec-     tasks.md   /moneta:   tool/     /opsx:
propose    auditor    review    checkpoint  verify.sh  archive
           (agent)              per task    + change-
                                            verifier
```

Rules that hold for every task:

1. **No edits to `lib/` without an active OpenSpec change.** If asked to change
   behaviour with no change open, create one first (`/opsx:propose`). One-line
   typo fixes and comment edits are the only exception.
2. **Plan before executing, and get the plan reviewed.** After `/opsx:propose`,
   the artifacts are reviewed — by the user, and by the `spec-auditor` agent for
   anything spanning more than one module — and edited before `/opsx:apply`.
3. **One checkpoint per task.** Run `/moneta:checkpoint` at the end of each task
   in `tasks.md`: verify, self-review the diff, tick the task, commit. Do not
   batch a whole change into one commit.
4. **Verify means `tool/verify.sh`.** Not "tests pass". Not "it builds". The gate
   is format + analyze + architecture + design-tokens + hooks + test + coverage,
   and each run writes an evidence file to `docs/ai-workflow/verify-runs/`.
5. **Never weaken a gate to make it pass.** Changing a threshold, widening
   `_allowedImports`, or adding `// ignore:` to silence a real finding requires
   saying so explicitly and getting agreement first.
6. **Archive only after `change-verifier` says ship.**

## Reusable commands

| Command | Use |
| --- | --- |
| `/opsx:propose` | Open a change; generates proposal, specs, design, tasks |
| `/opsx:apply` | Implement the change's tasks |
| `/opsx:archive` | Fold the change's specs into the main spec set |
| `/moneta:verify` | Run the gate and drive failures to green |
| `/moneta:checkpoint` | Close out one task: verify → self-review → commit → log |
| `/moneta:figma-pull` | Bring a Figma node into the design system with a fidelity check |
| `/moneta:tradeoff` | Compare options and write an ADR |
| `/moneta:debug` | Hypothesis-driven debugging with real output |
| `/moneta:evidence` | Rebuild the Level-4 evidence report from repo artifacts |

Agents: `spec-auditor` (before apply), `change-verifier` (before archive),
`figma-fidelity` (after any Figma-derived widget).

Hooks (`.claude/hooks/`): `session_start` prints workflow state; `post_edit_dart`
analyzes each file written through Edit/Write; `post_bash_dart` analyzes after a
Bash command that wrote a `.dart` file (Edit/Write hooks cannot see heredocs);
`stop_verify_guard` refuses to end a turn that left `lib/` or `test/` modified
without a passing verify run.

The hooks are themselves gated: `tool/check_hooks.sh` parses every one and
asserts it exits 0 on a payload it should ignore. A hook that crashes is
indistinguishable from a hook with nothing to report, and one of them crashed on
every invocation for a whole change before this check existed.

## Architecture

```
lib/
  core/           pure Dart: Money, Result, Clock. Imports nothing from other layers.
  data/           database, migrations, shared DAO infrastructure.
  design_system/  tokens/ theme/ atoms/ molecules/ organisms/ — the only place
                  raw design values may appear.
  features/<f>/
    domain/       entities + repository interfaces. Depends on core only.
    data/         DAO + repository implementation.
    presentation/ screens, controllers (Riverpod), feature-local widgets.
  app/            composition root: router, theme wiring, providers.
```

Boundaries are machine-enforced by `tool/check_architecture.dart`:

- `core` → `core` only
- `data` → `core`, `data`
- `design_system` → `core`, `design_system`
- `features/<f>` → `core`, `design_system`, `data`, and its own feature
- `app` → anything
- **cross-feature imports are forbidden.** Share via `core` or `data`.

## Non-negotiables in the code

- **Money is never a `double`.** Use `lib/core/money.dart` (integer minor units).
  A `double` amount anywhere in domain or data is a bug.
- **Repositories return `Result<T>`**, they do not throw for expected failures.
  Expected failures are `AppFailure(kind: storage | validation | notFound)`.
- **`DateTime` is stored and compared in UTC.** Inject `Clock`; never call
  `DateTime.now()` outside `SystemClock`.
- **No raw design values outside `lib/design_system/tokens|theme`.** No
  `Color(0x…)`, `Colors.*`, inline `TextStyle(`, `EdgeInsets.*(` with literals,
  or `BorderRadius.circular(`. `tool/check_design_tokens.dart` enforces this.
  A genuine exception needs `// design-token-ignore` plus a reason on the line.
- **Design-system widgets take domain types**, not pre-formatted strings.
- **Every Figma component's full variant set is implemented**, not just the
  variant the current screen needs.

## Testing expectations

- `lib/core`, every `*/domain/`, every `*/data/` → ≥85% line coverage (enforced,
  see `tool/coverage_critical.txt`). Project total ≥70%.
- Database tests run on the VM via `sqflite_common_ffi` — no simulator needed.
- Design-system widgets: one test per variant asserting token-derived values
  actually reach the render tree, plus goldens where layout is the point.
- Boundary cases are required, not optional: zero, negative, very large amounts,
  empty lists, currency mismatch, empty first-run database.
- A test that asserts the implementation back to itself does not count as coverage.
  The one sanctioned exception is the token layer: those tests are *transcription*
  checks against Figma values, and transcription is exactly what can go wrong there.
- **The gate pins `TZ=Asia/Ho_Chi_Minh`** (`tool/verify.sh`, enforced by
  `tool/check_timezone.dart`). Local-time assertions cannot fail under UTC — a
  function that forgets `.toLocal()` returns the identical answer, and a
  "last local day" calculation done in UTC coincides with the correct one. So any
  test about local time must be written to discriminate, and it only can because
  the zone is ahead of UTC. Do not remove the `TZ` export: CI runs UTC by default,
  so losing it turns those tests green for broken code in the gate that guards
  merges.
- **`flutter test` renders with a metrics-only placeholder font** in which every
  glyph is exactly `fontSize` wide. Any assertion about how wide a *string* is
  measures that font, not the design — so assert font-independent structure
  (a child stays inside its parent, a column respects its cap, nothing overflows)
  and leave real type metrics to goldens run on a fixed platform.
- **Pumping a second, structurally identical widget tree reuses the first one's
  `ProviderScope`.** A helper that pumps `ProviderScope(overrides: […], child:
  MaterialApp(…))` once per case looks like it gives each case its own
  container; Flutter's element tree reconciles the two and **keeps the first
  case's overrides**. Every later case then asserts against the first case's
  data and passes for code that has none of the behaviour. This is how a Home
  test covering loading / loaded / error passed a mutation that gave the error
  arm a different greeting. Tear the tree down between cases —
  `await tester.pumpWidget(const SizedBox.shrink());` — or give each scope a
  distinct `key`.
- **Never `await` real I/O inside `testWidgets`.** Its body runs in a `FakeAsync`
  zone, so a real future — `rootBundle.loadString`, a file read, a socket — never
  completes and the test **hangs indefinitely instead of failing**. Use plain
  `test()` with `TestWidgetsFlutterBinding.ensureInitialized()`, or wrap the I/O in
  `tester.runAsync(...)`. This cost a 7-minute stall during
  `design-system-foundation`; a hang looks like a slow machine, not a bug.

## Figma

File key `kEYXQUyhXLZITkNxAHRVlf`. It is a **training file**: its Cover claims 74
screens, 37 variant sets and **twelve deliberate mistakes**, and points at a
`📁 Screen Index` page and a `🔧 Utilities / Known Deviations` answer key.

**`get_metadata` without a `nodeId` returns an incomplete page list.** It reports
three pages (Cover, Foundations, Organisms). That is not the file. Passing a
concrete node id reaches pages it never listed — `5:14` is
`📱 01 Onboarding & Auth` with twelve finished screens. Do not conclude anything
about what the file contains from the page listing; query a node.

Every screen has a sibling **annotation frame** giving `Purpose`, `Components`,
`States` and `Data` — a written spec per screen, including accessibility rules.
Read the annotation before implementing the screen.

The component library is also larger than the Organisms page shows. Screens use
`Button/Primary`, `Button/Secondary`, `TextField/Filled`, `TextField/Error`,
`Checkbox`, `Divider/Subtle`, `Select`, `ListRow`, `SectionHeader` — none of which
appear on `🧩 Components / Organisms`.

**Never claim this file lacks a design.** That claim has been made twice and was
wrong twice. If something cannot be found, say it was not found and name what was
queried.

Implemented nodes are tracked in `docs/design-system/figma-map.md`. Check it
before implementing anything: the component may already exist.

## Commit convention

```
<type>(<change-name>): <what>

Task: <task from tasks.md>
Verify: <docs/ai-workflow/verify-runs/… path>
Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```

Never `git push` — that is the user's decision.

## Reporting

State what you ran and what it output. If a gate failed, show it. If you skipped
something, say so and why. "Should work" is not a result.
