# Level-4 evidence

Maps this repository's artifacts to the NUS *AI Coding Usage Level Framework*,
Level 4 — **"Workflow có framework và kiểm chứng"**.

Regenerate with `/moneta:evidence`. Gaps are listed as gaps; the framework's own
rule is that a single trial run does not raise a level, so a padded report would
fail it on its own terms.

**Snapshot:** 2 changes (both archived) · 28 tasks, all checkpointed · 25 commits
· 32 verify runs (16 pass, 16 fail) · 485 tests · 3 ADRs · 27 requirements in the
main spec set.

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

**Discuss** is the weakest link and is called out as such below.

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

The automation was itself improved from experience: `post_bash_dart.sh` exists
because the Edit/Write hook keys off `tool_input.file_path` and never saw files
written through a shell heredoc — two lint findings reached the gate that way.

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

### Corrections made to the plan mid-flight

- The specs said "six named text styles"; Figma has eight. Spec updated **before**
  any typography code was written.
- The proposal said 51 icons; the page holds 50. Proposal, spec, tasks and map
  corrected.
- Figma reports `letterSpacing: -1` for two styles while its CSS emits `-0.4px`
  and `-0.28px`. Resolved as a percentage and documented, not silently picked.

---

## Gaps — stated, not padded

1. **"Discuss" is the thinnest phase.** Artifacts were reviewed and revised, but
   the `spec-auditor` and `change-verifier` agents were *written and not run* —
   this session was configured not to spawn subagents. They are real assets and
   the workflow calls for them, but no audit output exists in the repo. **What
   would close it:** run `spec-auditor` on the next change before apply, and
   `change-verifier` before archive, and commit their reports.
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
   something this repo can currently show.
