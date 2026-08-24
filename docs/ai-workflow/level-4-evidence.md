# Level-4 evidence

Maps this repository's artifacts to the NUS *AI Coding Usage Level Framework*,
Level 4 — **"Workflow có framework và kiểm chứng"**.

Regenerate with `/moneta:evidence`. Gaps are listed as gaps; the framework's own
rule is that a single trial run does not raise a level, so a padded report would
fail it on its own terms.

**Snapshot:** 2 changes archived · 2 changes open and planned (`home-overview`,
`design-system-corrections`) · 28 tasks checkpointed · 31 commits · 37 verify runs
(20 pass, 17 fail) · 485 tests · 4 ADRs · 27 requirements archived · 8 gates ·
3 spec audits.

---

## 1. Uses a named framework end-to-end: spec → discuss → plan → execute → verify

**Framework:** [OpenSpec](https://github.com/Fission-AI/OpenSpec) v1.10.0,
`spec-driven` schema, configured for this project rather than left at defaults.

| Artifact | Where |
| --- | --- |
| Schema + project context + per-artifact rules + per-operation guidance | `openspec/config.yaml` |
| Change 1, all four artifacts | `openspec/changes/archive/2026-08-24-design-system-foundation/` |
| Change 2, all four artifacts | `openspec/changes/archive/2026-08-24-transactions-local-store/` |
| Resulting spec set | `openspec/specs/` — 27 requirements across 4 capabilities |
| Workflow rules the agent must follow | `CLAUDE.md` |

The config is where the framework stops being generic. `rules.specs` forces
boundary acceptance criteria (zero, negative, currency mismatch, empty, first
run); `rules.design` forces at least two options per non-obvious decision;
`rules.tasks` forces each task to name its own verification signal.

**Discuss** was the weakest link when this report was first written. It no longer
is — see criterion 8.

## 2. A task or refactor spanning multiple modules

`transactions-local-store` touches every layer in one change: `lib/core`
(`IdGenerator`, `TransactionDirection`), `lib/data` (database, migrations),
`lib/features/transactions/{domain,data,presentation}`,
`lib/design_system/molecules`, `lib/app` (shell + routing).

Two cross-module refactors were forced by the architecture gate rather than
chosen:

- `TransactionDirection` moved from the transactions feature into `lib/core`,
  because `design_system` may not import `features` and `TransactionRow` needs it.
- `AmountSlot` was extracted after the same overflow defect appeared in
  `BudgetCard` and `TransactionRow`, and `BudgetCard` was refactored onto it.

## 3. Trade-off comparison

Three ADRs, each scoring at least three options against weighted criteria and
each stating the strongest argument *against* its own conclusion:

| ADR | Decision | Options scored |
| --- | --- | --- |
| `docs/adr/0001-local-persistence-layer.md` | `sqflite` + hand-written SQL | sqflite · drift · Isar/Hive · defer |
| `docs/adr/0002-icon-delivery.md` | Committed SVG assets | SVG assets · icon package · generated font · hand-authored painters |
| `docs/adr/0003-transaction-row-layout.md` | Disc · text · trailing amount | four layouts |

Smaller trade-offs live in each change's `design.md` (8 decisions in change 2,
7 in change 1), each with the alternatives that were rejected and why.

## 4. Combines test, static analysis, logs and docs

`tool/verify.sh` is one command and six gates:

| Gate | What it enforces |
| --- | --- |
| `format` | `dart format --set-exit-if-changed` |
| `analyze` | `dart analyze --fatal-infos --fatal-warnings`, `very_good_analysis` + strict casts/inference/raw-types |
| `architecture` | `tool/check_architecture.dart` — layer boundaries, no cross-feature imports |
| `design-tokens` | `tool/check_design_tokens.dart` — no raw colours, text styles, insets or radii outside `tokens/` |
| `timezone` | `tool/check_timezone.dart` — the process zone is non-UTC, so local-time assertions can fail |
| `hooks` | `tool/check_hooks.sh` — every hook parses and no-ops cleanly |
| `test` | 485 tests |
| `coverage` | ≥70% overall, ≥85% on `core`, `*/domain/`, `*/data/` |

- **Custom analysis** the analyzer cannot express: two purpose-built checkers,
  and `tool/design_token_rules.dart` has **16 tests of its own** — including the
  exact false positive that prompted tightening it.
- **Logs and run output:** every gate run writes a timestamped record to
  `docs/ai-workflow/verify-runs/`. 32 exist; 16 failed. The failures are kept.
- **Docs as artifacts:** `docs/design-system/figma-tokens.md` (every token with
  its Figma node), `figma-map.md` (node → widget, plus 9 recorded deviations),
  three ADRs, this log.
- **CI runs the same gate**, plus `openspec validate --all --strict`
  (`.github/workflows/verify.yml`).

## 5. Uses checkpoints

28 tasks, each closed by a checkpoint: gate → self-review the diff → tick the
task → commit citing the task and the evidence file. 25 commits, each naming its
task and its verify run.

The rule is enforced, not just documented: `.claude/hooks/stop_verify_guard.sh`
refuses to end a turn that left `lib/` or `test/` modified without a passing
verify run.

**Where it was broken:** three commits (`46d866a`, `b088254`, `18b8520`) cite a
run that *failed*. History was left intact and corrected in `4f8ce28` rather than
amended away.

## 6. Reusable commands, instructions and automation

| Asset | Count | Path |
| --- | --- | --- |
| Slash commands | 6 | `.claude/commands/moneta/` — verify, checkpoint, figma-pull, tradeoff, debug, evidence |
| Review agents | 3 | `.claude/agents/` — spec-auditor, change-verifier, figma-fidelity |
| Hooks | 4 | `.claude/hooks/` — session-start state, post-edit analyze, post-Bash analyze, stop-verify guard |
| Gate + checkers | 6 | `tool/` |
| Project instructions | 1 | `CLAUDE.md` |
| Framework config | 1 | `openspec/config.yaml` |
| CI | 1 | `.github/workflows/verify.yml` |

The automation was itself improved from experience, twice:

- `post_bash_dart.sh` exists because the Edit/Write hook keys off
  `tool_input.file_path` and never saw files written through a shell heredoc —
  two lint findings reached the gate that way.
- `tool/check_hooks.sh` exists because `post_bash_dart.sh` then shipped with a
  bash syntax error and **crashed on every invocation for an entire change**,
  which is indistinguishable from a hook that found nothing. Nothing was checking
  the thing doing the checking. It is now a gate, with a negative test proving it
  catches that bug.

## 7. At least two recent medium-size tasks applied end-to-end

| | `design-system-foundation` | `transactions-local-store` |
| --- | --- | --- |
| Tasks | 14/14 | 14/14 |
| Artifacts | proposal, 2 specs, design, tasks | proposal, 3 specs, design, tasks |
| Modules | core, design_system, app | core, data, features/transactions, design_system, app |
| ADR | 0002 | 0003 |
| Tests added | 254 | 231 |
| Verify runs | 13 | 11 |
| Archived | yes | yes |

### Defects the gate caught that review would plausibly have missed

1. `BalanceCard`'s stats row overflowed with wide amounts (Figma marks them
   `shrink-0`, which is fine for the authored copy and wrong for real data).
2. `BudgetCard`'s amount column overflowed the head row by up to 96px; the first
   fix removed the overflow but truncated the category name for nothing.
3. `BottomNav`'s `selected` semantics flag never reached the tab's node —
   `Semantics` was nested inside the `GestureDetector`, making it a sibling.
   Nothing visual would have shown this.
4. The design-token checker's own rule was wrong, flagging
   `BorderRadius.circular(size.fillRadius)`. Tightened rather than silenced, and
   given tests.
5. `post_bash_dart.sh` had a bash syntax error and crashed on every invocation
   for a whole change. Nothing was checking the hooks, so it was invisible;
   `tool/check_hooks.sh` is now a gate.

## 8. Adversarial review, and what it caught

`spec-auditor` ran on `home-overview` before any code was written. Both passes
returned `NOT READY`.

| Pass | Findings | Class of problem |
| --- | --- | --- |
| 1 | 11 | Claims that were false, and reasoning that was reverse-engineered |
| 2 | 4 | Requirements correct in prose, ambiguous in the clause a test would have to fail against |
| 3 | 1 + 4 | A requirement and a clause both correct, in a verification *environment* where the clause could not fail |

The third class is the one self-review is least likely to catch, because
everything on the page is right. It was found on a test that had not been written
yet — and turned out to already be true of a shipped one.

Reports: `docs/ai-workflow/audits/2026-08-24-home-overview-spec-audit.md` and
`…-audit-2.md`.

Every load-bearing claim was verified against the code before being accepted —
including writing a probe file and running the architecture checker, and reading
`lcov.info` to confirm a coverage number. Nothing was taken on the agent's word.
One second-pass finding was **stale** (it read the repository before a commit) and
is recorded as such rather than acted on.

What the audits caught that self-review had not:

- A proposal claim that was load-bearing and false (`lib/features/transactions is
  not modified`).
- An ADR whose conclusion was right and whose stated reason was reverse-engineered
  — twice, the second time in the very document that dissects the first instance.
- A task that could not pass its own coverage gate, and would have failed only at
  the full gate because `--fast` skips coverage.
- A spec and a design disagreeing by one millisecond in a way that would have made
  a just-recorded transaction vanish from the balance.
- A test assertion that passed for both the right and the wrong answer.
- An assertion that could not be written at all (`dart:mirrors` is unavailable in
  Flutter tests).
- A **shipped** test that had been decoration since `transactions-local-store`:
  local-time assertions cannot fail under UTC, and CI runs UTC while this machine
  runs +07. Fixed as a gate (`tool/check_timezone.dart`) rather than a test edit,
  so the class cannot recur.
- The same unverified "the only caller / not modified" claim, **three times** in
  three different artifacts. Always plausible, always load-bearing, always one
  `grep` from being checked. Worth naming as a personal failure pattern rather
  than three separate mistakes.

This is the criterion the framework calls *discuss*, and it is the one that
produced the highest-value findings per unit of effort in the whole project.

### Corrections made to the plan mid-flight

- The specs said "six named text styles"; Figma has eight. Spec updated **before**
  any typography code was written.
- The proposal said 51 icons; the page holds 50. Proposal, spec, tasks and map
  corrected.
- Figma reports `letterSpacing: -1` for two styles while its CSS emits `-0.4px`
  and `-0.28px`. Resolved as a percentage and documented, not silently picked.

---

## Gaps — stated, not padded

1. ~~**"Discuss" is the thinnest phase.**~~ **Closed** — see criterion 8.
   `spec-auditor` has now run twice on `home-overview`, both times returning
   `NOT READY`, with both reports committed under
   `docs/ai-workflow/audits/`. `change-verifier` is still unexercised, because no
   change has reached archive since; that half of the gap stands.
2. **No second author.** Everything here is one operator plus one agent. Level 5
   ("nhân rộng năng lực AI cho team") needs assets other people use, coaching,
   and a tech lead confirming project-level impact. None of that is evidenced.
3. **No golden tests.** Layout is asserted structurally, and `flutter test`
   renders with a metrics-only placeholder font, so real type metrics are only
   checked by eye. `design.md` flags this; the tests are honest about it.
4. **Two of 14 Figma component sets remain**, deliberately deferred so each
   arrives with a real caller. AppBar, AccountCard, GoalCard, Dialog, Snackbar,
   Banner, BottomSheet, Logo, PaginationDots, OtpField, StatusBar are unbuilt.
5. **No performance evidence.** ADR 0002's counter-argument predicts SVG
   rasterisation could cost in a long scrolling list. Nothing profiles it.
6. **One CI claim is unverified.** `.github/workflows/verify.yml` has never run —
   there is no remote. It runs the same script locally, but "CI is green" is not
   something this repo can currently show. The third audit found a real
   consequence of that: CI's UTC default silently disarmed a class of test, and
   nothing would have reported it.
