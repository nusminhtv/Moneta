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
   is format + analyze + architecture + design-tokens + test + coverage, and each
   run writes an evidence file to `docs/ai-workflow/verify-runs/`.
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

## Figma

File key `kEYXQUyhXLZITkNxAHRVlf`. Pages: `🎨 Foundations / Iconography` (51
icons + rules), `🧩 Components / Organisms` (14 component sets with variants).
There are **no screen designs in the file** — screens are composed from the
component library, and any screen layout is therefore a *decision to record*
(ADR or `design.md`), not something read off the canvas.

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
