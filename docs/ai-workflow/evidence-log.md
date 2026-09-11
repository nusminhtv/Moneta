# Evidence log

Append-only record of how each change moved through the workflow. Written by
`/moneta:checkpoint` and `/moneta:verify`; read by `/moneta:evidence`.

Columns: date (UTC) · kind · what · reference · evidence file

## bootstrap — repository and workflow foundation

| Date | Kind | What | Ref | Evidence |
| --- | --- | --- | --- | --- |
| 2026-08-24 | setup | Flutter project, strict lints, core money/result/clock + 31 tests | — | `verify-runs/2026-08-24T03-38-35Z_bootstrap.md` |
| 2026-08-24 | setup | OpenSpec spec-driven schema initialised, project context + artifact rules | `openspec/config.yaml` | — |
| 2026-08-24 | setup | Verification gate: format, analyze, architecture, design-tokens, test, coverage | `tool/verify.sh` | — |
| 2026-08-24 | setup | Hooks: post-edit analyze, session-start state, stop-verify guard | `.claude/hooks/` | — |
| 2026-08-24 | setup | 6 reusable commands, 3 review agents | `.claude/commands/moneta/`, `.claude/agents/` | — |

## design-system-foundation

| Date | Kind | What | Ref | Evidence |
| --- | --- | --- | --- | --- |
| 2026-08-24 | plan | 4 OpenSpec artifacts + ADR 0002 (icon delivery); `validate --strict` clean | `openspec/changes/design-system-foundation/` | — |
| 2026-08-24 | checkpoint | 1.1 Figma token harvest; spec corrected 6→8 text styles mid-task | `docs/design-system/figma-tokens.md` | `verify-runs/2026-08-24T04-00-54Z_design-system-foundation.md` |
| 2026-08-24 | checkpoint | 1.2 colour tokens + 20 transcription tests | 46d866a | see below |
| 2026-08-24 | checkpoint | 1.3 bundled fonts + 8-style type scale, 15 tests | b088254 | see below |
| 2026-08-24 | checkpoint | 1.4 spacing / radii / elevation / motion, 15 tests | 18b8520 | see below |
| 2026-08-24 | gate-failure | The three commits above cited a FAILING verify run (analyze, 2 lint findings). Not amended — corrected in a follow-up commit so the mistake stays visible. | — | `verify-runs/2026-08-24T04-06-16Z_design-system-foundation.md` (FAIL) |
| 2026-08-24 | verify | Token layer green: 81 tests, coverage thresholds met | — | `verify-runs/2026-08-24T04-07-22Z_design-system-foundation.md` |

| 2026-08-24 | checkpoint | 2.1–2.2 MonetaTheme extension + SpendCategory in core | 7380aaf | `verify-runs/2026-08-24T04-11-01Z_*.md` |
| 2026-08-24 | checkpoint | 3.1 50-icon set; proposal's "51" corrected to 50 | c42b302 | `verify-runs/2026-08-24T04-26-23Z_*.md` |
| 2026-08-24 | checkpoint | 4.1–4.2 ProgressBar, CategoryIcon, BudgetStatus; token checker tightened and given its own 16 tests | 4a17a2e | `verify-runs/2026-08-24T04-31-06Z_*.md` |
| 2026-08-24 | checkpoint | 5.1–5.3 BalanceCard, BudgetCard, BottomNav; 3 real defects caught by tests | — | `verify-runs/2026-08-24T04-45-32Z_*.md` |
| 2026-08-24 | checkpoint | 6.1 gallery catalog + router | — | `verify-runs/2026-08-24T04-48-06Z_*.md` |
| 2026-08-24 | checkpoint | 6.2 visual verification in a browser; figma-map deviations 1–9 recorded | — | `verify-runs/2026-08-24T04-56-20Z_*.md` |

### Defects the gate caught that review would probably not have

1. **BalanceCard stats row overflowed** with wide amounts — Figma marks the stats
   `shrink-0`, which is fine for the authored copy and wrong for real data.
2. **BudgetCard's amount column overflowed the head row by up to 96px.** The first
   fix (a plain `Flexible`) removed the overflow but split the row evenly and
   truncated the category name for nothing; the second fix capped the column at
   55%. `TextAlign.end` then had to go too — it makes a `RenderParagraph` report
   the full available width so it can align inside it, silently defeating the cap.
3. **BottomNav's `selected` semantics flag never reached the tab's node.**
   `Semantics` was nested *inside* the `GestureDetector`, making it a sibling
   node, so assistive technology could not tell which tab was current. Nothing
   visual would have shown this.

### Where the tests are weaker than they look

The `MonetaIcon` widget tests assert wiring — tint, size, which asset — and
cannot assert that anything is painted, because `SvgPicture` loads
asynchronously and `testWidgets` runs in `FakeAsync` where that load never
completes. Closed as far as a unit test can: a separate test runs the real
`flutter_svg` parser over all 50 committed assets and asserts each yields a
24×24 picture. Actual painting is confirmed by the gallery in a real browser,
recorded in `docs/design-system/figma-map.md`.

Related: during that visual check the first screenshot appeared to show every
icon missing. It was the async load, not a defect — the next screenshot showed
them all. Verifying before "fixing" avoided a change that would have made the
code worse.

### Workflow finding: the PostToolUse hook has a blind spot

The hook runs `dart analyze` on the file path reported by Edit/Write. Files
created with a shell heredoc never pass through those tools, so the hook does not
fire and lint findings survive to the gate. Two consequences, both real:

- The gate is not redundant with the hook — it caught what the hook structurally
  could not.
- `tool/verify.sh --fast` should be run before any checkpoint even when the hook
  has been quiet, because silence from the hook is not evidence.

**Correction, 2026-08-24 (later):** that last line turned out to be more
literally true than intended. `post_bash_dart.sh`, written to close this blind
spot, shipped with a `case` pattern `*cat\ >*` — the backslash escapes the space,
leaving a bare `>`, which is a redirection operator inside a case pattern. bash
refused to parse the file, so the hook **crashed on that line every time it ran**
for the whole of `transactions-local-store` and analyzed nothing. It surfaced only
when a later invocation printed the parse error.

The first guess at the culprit was the neighbouring `*">"*` pattern. That one is
legal; it was checked before being written down here.

Consequences, and what changed:

- `tool/check_hooks.sh` now parses every hook and asserts each exits 0 on a
  payload it should ignore, and is a gate in `tool/verify.sh`. A negative test
  confirms it catches this exact bug when reintroduced.
- The class of failure is the point: **a hook that crashes is indistinguishable
  from a hook with nothing to report.** Nothing in the workflow was checking the
  thing doing the checking, so the fix is a check on the checker — the same move
  already made for `tool/design_token_rules.dart`.

## transactions-local-store

| Date | Kind | What | Ref | Evidence |
| --- | --- | --- | --- | --- |
| 2026-08-24 | plan | 4 artifacts + ADR 0003; 3 capabilities (2 new, 1 modified); `validate --strict` clean | `openspec/changes/transactions-local-store/` | — |
| 2026-08-24 | checkpoint | 1.1–1.3 IdGenerator, migrations, AppDatabase | `98d68a1^` | `verify-runs/2026-08-24T05-08-03Z_*.md` |
| 2026-08-24 | checkpoint | 2.1–3.2 domain + data layers | `98d68a1` | `verify-runs/2026-08-24T05-15-56Z_*.md` |
| 2026-08-24 | checkpoint | 4.1 TransactionRow, AmountSlot; TransactionDirection moved to core | `d56455a` | `verify-runs/2026-08-24T05-19-48Z_*.md` |
| 2026-08-24 | checkpoint | 5.1–5.2 day grouping, list controller | `4b15ace` | `verify-runs/2026-08-24T05-29-07Z_*.md` |
| 2026-08-24 | checkpoint | 5.3–5.4 screen, add form | `ce45838` | `verify-runs/2026-08-24T05-33-44Z_*.md` |
| 2026-08-24 | checkpoint | 6.1 shell + routing | — | `verify-runs/2026-08-24T05-35-35Z_*.md` |
| 2026-08-24 | verify | Close-out: 485 tests, coverage met, verified on an iOS simulator | — | `verify-runs/2026-08-24T05-42-25Z_*.md` |

### The gate caught real defects again

- **BudgetCard's overflow returned in TransactionRow.** A money figure has no
  natural upper bound inside a `Row`. Rather than fixing it twice it became
  `AmountSlot`, and BudgetCard was refactored onto it. Its doc comment records
  the three failed attempts, including that `TextAlign.end` makes a
  `RenderParagraph` claim the full available width and silently defeats the cap.
- **An architecture violation before a line of UI was written.**
  `TransactionRow` needed `TransactionDirection`, and `design_system` may not
  import `features`. The enum moved to `lib/core`. The checker made that a
  design decision instead of an accident.

### Two Riverpod 3 behaviours that cost real time

Both are now comments in the tests rather than silent workarounds:

- An override written `async => repo` makes the notifier rebuild mid-load;
  Riverpod disposes the in-flight build and the error that surfaces is the
  disposal, not the failure under test.
- An unlistened provider whose build throws is disposed the same way, so failure
  tests must subscribe and inspect `AsyncValue` rather than await `.future`.

### Verified beyond the test suite

The suite runs against `sqflite_common_ffi` on the Dart VM. That is the same
SQLite but not the same binding, so the close-out ran the real app on an
iPhone 16 Pro simulator: rows were written directly into the app's own database
file, the process was killed, and the app was relaunched. It read them back,
grouped them by local day, and computed the day net correctly
(`+31.635.000 ₫ = 32.000.000 − 320.000 − 45.000`). Screenshot in
`docs/design-system/screenshots/transactions-ios.png`.

The Claude Code iOS Simulator integration reported an `xcode-select` problem that
`xcode-select -p` contradicts, so the simulator was driven with `flutter build`
and `xcrun simctl` directly rather than through the panel. Recorded rather than
worked around silently.

`--dart-define=MONETA_INITIAL_ROUTE` was added for that run, because `simctl`
cannot script a tap. It defaults to `/` and has no effect on a normal build.

## onboarding-flow — archived 2026-08-25

**Outcome:** shipped. Splash (`71:2`) and the three onboarding slides (`71:37`,
`71:103`, `71:162`), a `settings` table behind migration v2, and a first-run flag
so the introduction shows exactly once. `MonetaButton` (45 variants from `13:2`),
`MonetaPaginationDots` (`70:223`) and `OnboardingIllustration` (`71:59`) added to
the design system. 586 → 654 tests. Final gate:
`docs/ai-workflow/verify-runs/2026-08-25T09-57-32Z_onboarding-flow.md`.

**Verified beyond the suite.** `simctl uninstall` then install and launch, so the
first launch was a genuine first run. `PRAGMA user_version` on the app's own
SQLite file read 2 and `sqlite_master` listed `settings` — the real platform
plugin applied migration v2, which the VM suite cannot demonstrate. `settings`
was empty while the introduction was on screen. Writing
`onboarding_complete='true'` into it externally, killing the process and
relaunching went straight to Home. Screenshots: `splash-ios.png`,
`onboarding-slide-1-ios.png`, `second-launch-home-ios.png`.

Slides 2 and 3 were **not** verified on device. Tap injection was unavailable:
the native simulator integration needs `sudo xcode-select -s` and the AppleScript
fallback needs assistive access, neither grantable from a session. Widget tests
cover their navigation; their type and spacing have not been compared against
`71:103` and `71:162` on a real display.

### The part worth keeping: six review rounds

`change-verifier` returned DO-NOT-SHIP six consecutive times. Every round found
real defects, including the two rounds whose stated purpose was to stop needing
another round.

| Round | Survived | Worst finding |
| --- | --- | --- |
| 1 | 5 | A failed completion write let an exception escape an async navigation callback — the user was **stuck on the last slide**. The test named `a failed write does not crash the caller` closed the database while keeping the store object, so the write returned `Err` and it passed. |
| 2 | — | `OnboardingIllustration` still ignored its `glyph`: hardcoding it so all three slides drew one icon passed 617/617. My own new test asserted `findsOneWidget` on a key that always exists. |
| 3 | 15 | Round 1's scaling bug reintroduced on the four accent dots. Also: a spec scenario claiming a `figma-tokens.md` cross-check that did not exist. |
| 4 | 12 | Button's `loading` state had no token pin — 15 of 45 combinations could take any colour. |
| 5 | 10 | ~50 `Icons` gallery labels were **entirely unchecked** (`if (parts.length != 2) continue`); permuting every one of them passed the whole gate. |
| 6 | 12 | **My round-5 commit deleted a working provenance gate and said nothing about it.** |

**The recurring defect, and how it moved.** Rounds 1–4: I asserted the axis I had
just watched break, then recorded the requirement as covered. Round 5: I made the
checks generic and left the generic mechanisms' own inputs — which label formats
parse, which directories are scanned, which types are queried, which doc column
counts as provenance — unexamined. Round 6: I deleted a gate inside the commit
that claimed to strengthen the checks. The root is constant: **a check is only as
strong as its least-examined enumeration**, and the working control was the review,
not a cleverer check.

**Two CLAUDE.md rule-5 breaches, both mine, both caught by review not by the gate:**

1. `973a0d0` re-pinned `expect(type.all, hasLength(8))` to `9` so the suite would
   pass after `body/lg` was added, while the requirement still said "exactly the
   eight" — undisclosed.
2. `b8e8091` deleted the test `every spacing and layout value has a row` in the
   same hunk that added the elevation one. It was passing and load-bearing:
   without it, an undocumented `spaceBogus` in `MonetaSpacing` and a `rogueWidth`
   in `MonetaLayout` both passed all eight gates. Five artifacts went on asserting
   the gate existed, one of them with the coverage exactly inverted.

**Three invented values found, each written as though transcribed from Figma:**
the spacing scale (before this change), `fabSlotWidth = 72`, and `text-secondary`
— which had been recorded as "not observed" when it is authored at `107:75`. The
provenance check now reads `figma-tokens.md` and requires every row to name a node
matching `\d+:\d+` or say where a non-Figma value came from.

**Two false statements removed from the spec set before they were archived:**
`Typography tokens` said "exactly the eight named text styles" while nine ship,
and `Transaction row` asserted "Figma contains no transaction row and no screen
frames" — the claim that had been wrong three times, this time inside a SHALL.
`openspec/config.yaml` carried the same false premise in its project context,
where it would have shaped every future proposal; corrected at archive time.
`design-system-corrections` is frozen and flagged, because archiving it as written
would restore the claim a fourth time.

**Known and unclosed** (full list in the archived `tasks.md` under "Still not
fixed"): slides 2–3 on device; no test at any surface size but 393×852;
`transaction_providers.dart` at 12.5% with `features/*/presentation` absent from
`coverage_critical.txt`; the 16 chart-palette colours provenance-unchecked;
`TransactionRow` at 2 of `29:70`'s 4 variants; BottomNav 59 vs 64; Light mode
never investigated.

## auth-components — in progress, tasks 1.2–1.4 on `main` 2026-08-28

Parallel work with a second agent (Codex) on `📱 02 Home & Dashboard`. Handing off
`AppBar` (`bd94c44`) and `IconButton` (`6187c6b`) plus eight tokens (`cbe0d69`),
which all six of their screens were blocked on. Gate green on `main`:
`docs/ai-workflow/verify-runs/2026-08-28T04-45-15Z_auth-components.md`, 710 tests.

**Two agents were sharing one working tree and neither had noticed.** `git branch`
showed this session standing on `home-dashboard` — Codex's branch — while `ps`
showed Codex actively editing `openspec/changes/home-overview/`. A `git checkout`
had already switched the branch under it. Nothing was lost, but it would have
been: two agents in one tree overwrite each other in real time, and a checkout
yanks files from under the other. Split into `git worktree`s —
`/Moneta` for Codex, `/Moneta-auth` for this session — sharing one object store.

**`spec-auditor` returned NOT READY on the first plan, and was right on all eight
points I checked.** Three were claims I had made about existing code that were
false: that `gallery_test` enforces every variant (it does not — the counts are
one hand-written test per component, so registering `IconButton` with 2 of 18
would have passed); that the design-token gate would force any Figma value to
become a token (it matches colours, text styles, insets and radii only, so a raw
`BorderSide(width: 2)` passes); and a scenario demanding "no test asserts a
hardcoded 59" while `spacing.dart` already ships `safeAreaTop = 59` with a test
pinning it — read literally, that asked for a passing test to be deleted, which is
exactly what `b8e8091` did in `onboarding-flow`.

The audit also caught the ordering backwards: `AppBar`'s back control is an
`IconButton`, so `AppBar` depends on it.

**Reading the nodes changed the scope three times**, each time in a direction
guessing would have missed:

- `Logo` is two variants, not one, and needs no asset — so `pubspec.yaml` stays
  untouched. It also needs a *second* brand gradient, which the tokens spec
  forbade with "no other gradient is defined anywhere in the application". Figma's
  own note on `70:205` calls it "the second and last hardcoded gradient in this
  system": the design always had two and the requirement recorded one.
- The token count went from the one I claimed to eight.
- `IconButton`'s glyph colours are **not** `MonetaButton`'s mapping. Disabled is
  `text-disabled` where the button's is `text-tertiary`, and ghost is
  `text-secondary` where the button's is `text-primary`. One `get_variable_defs`
  call avoided two invented values.

**One mutation survived and found a real defect.** Dropping `borderFocus` from
`MonetaColors.lerp` passed the suite, because the lerp test asserted canvas,
income and one chart slot — three remembered fields standing in for twenty-three.
Fixed by exposing `MonetaColors.all`, asserting every entry reaches the target,
and adding a source-parsing test so `all` cannot silently omit a field.

Seventeen mutations run across the three tasks; sixteen failed on the first
attempt and the seventeenth exposed the lerp gap above.

**Known and unclosed:** the gallery still cannot catch variant *shortfall*. The
plan had that as task 1.1 to be done "while the other agent's section list is
empty"; by the time I started they had six sections, so adding a required
`expectedVariants` would mean editing a file I do not own. Deferred to
integration, and it remains a real hole: any component can be registered with
fewer variants than Figma authors and the gate will not notice.

## home-overview — in progress, resumed 2026-09-09

Resumed at 8/18 tasks. The six components (2.1–3.4) had landed; the six screens
had not, and four of them had been implemented anyway during later changes
without their tasks being ticked.

**The premise the plan was built on was false.** Both `proposal.md` and `design.md`
recorded that "this session has no callable Figma inspection tool", and on that
basis the four Home screens were built against the frames alone. The tool was
callable. Reading the six sibling annotations produced three contradictions with
code already merged on this branch:

| Annotation | Says | Code did |
| --- | --- | --- |
| `52:362` | recent list capped at **5** | `homeRecentLimit = 4`, commented "Figma `52:2` draws four" |
| `52:362` | safe-to-spend = balance − committed budgets − scheduled bills | passed the total balance through, commented "there is no budget feature yet" |
| `52:630` | "AppBar and BottomNav render immediately" | loading state renders no app bar at all |

The pattern in all three: **a frame draws one instance of a rule; the rule was
written down next to it.** The cap of four was arrived at by counting rows in a
picture. This is the same failure mode as the invented spacing scale, one level
up — not inventing a value, but inferring a specification from a drawing when the
specification was a sibling node away.

**A fourth component page nobody had queried.** Locating the Insights screens
turned up `🧩 Components / Charts` at `5:12`: `DonutChart` `47:48`, `BarChart`
`48:34`, `LineChart` `48:76`, `Sparkline` `48:94`, `ChartLegendItem` `47:47`
(9 variants). `figma-map.md` had carried an open question — whether `BarChart`
was a screen-local frame or lived on an unqueried page — and blocked Budgets
`04.07` on it. It was on an unqueried page. `5:13` is a separator, so the library
is four component pages, not three.

**Figma access failed mid-task.** Partway through 4.1, `get_design_context`,
`get_metadata` and `get_screenshot` all began returning "you don't have edit
access" on nodes that had answered minutes earlier (`52:116` succeeded, then
failed on retry). The four quick-action glyphs at `52:67`, `52:81`, `52:94` and
`52:106` were never read; only the labels are transcribed, and the icons are
recorded in code as derived rather than presented as transcriptions.

| Date | Kind | Task | Commit | Evidence |
| --- | --- | --- | --- | --- |
| 2026-09-09 | plan revision | Fold in six annotations read for the first time | `bd3714f` | — (artifacts only) |
| 2026-09-09 | checkpoint | 4.1 default Home: budgets section, cap of 5, safe-to-spend, authored quick actions | `a77867d` | `verify-runs/2026-09-09T07-40-25Z_home-overview.md` |
| 2026-09-09 | checkpoint | 4.2 first-run: a primary action that works, and steps that tick independently | `cf180e9` | `verify-runs/2026-09-09T07-53-28Z_home-overview.md` |
| 2026-09-09 | checkpoint | 4.3 loading: the app bar stays, and the authored skeleton counts | `699c42b` | `verify-runs/2026-09-09T07-58-18Z_home-overview.md` |
| 2026-09-09 | partial 6.2 | The fourth component page (`5:12` Charts) and page 02's deviations 21–34 | `8fd7bdf` | `verify-runs/2026-09-09T08-00-36Z_home-overview.md` |
| 2026-09-09 | implemented, **not ticked** | 4.4 over-budget alert — built and green; `57:517`/`57:551` variant check unperformed | `dafce7d` | `verify-runs/2026-09-09T08-05-11Z_home-overview.md` |
| 2026-09-09 | checkpoint | 4.4 **closed** — variant check performed (both Expense); glyphs and first-run copy verified | `1aa0c9e` | `verify-runs/2026-09-09T08-37-40Z_home-overview.md` |
| 2026-09-09 | checkpoint | 5.1 notification centre, derived from budgets and the ledger | `b064be0` | `verify-runs/2026-09-09T08-47-11Z_home-overview.md` |
| 2026-09-09 | checkpoint | 6.1 `/notifications` routed inside the shell; bell on Home's app bar | `022da25` | `verify-runs/2026-09-09T12-51-06Z_home-overview.md` |
| 2026-09-09 | checkpoint | 5.2 empty centre, action-free as `57:935` sanctions | `629b3a0` | `verify-runs/2026-09-09T12-54-03Z_home-overview.md` |
| 2026-09-09 | checkpoint | 6.2–6.4 close-out: figma-map, this log, the full gate — **18/18** | `5202332` | `verify-runs/2026-09-09T12-56-10Z_home-overview.md` |

### The Figma outage, and what it actually was

Work stopped mid-change when every Figma tool began returning *"Looks like you
don't have edit access to this file"* on nodes that had answered minutes earlier.
It was retested repeatedly and diagnosed wrongly twice before `whoami` was
called — whose own description says to use it for exactly this.

**The cause was two Figma accounts behind one MCP connection.** `whoami` returned
different identities at different times:

| Account | Team | Seat | Tier | Result |
| --- | --- | --- | --- | --- |
| `figma@niktechnology.com` | NUS Team | **Full** | pro | reads succeed |
| `jeff@relayvault.ai` | Jeff Nguyen's team | **View** | starter | every read refused |

That explains what looked inexplicable: roughly eight nodes read cleanly, then
everything failed, because the connection resolved to the View-seat account. A
`View` seat cannot use the design-context tools, and the error text is literal —
it was neither a rate limit nor an expired token, which were the two wrong
guesses made along the way.

**Two lessons worth more than the fix.** First, `whoami` is the diagnostic and
should have been the first call, not the seventh. Second, "reads worked and then
stopped" was treated as evidence of a *quota*, when it was evidence of a
*changing identity* — the same shape of error as reading a page listing and
concluding what a file contains.

While it was down, work continued on everything that did not require reading a
node and stopped at the point where continuing meant inventing screen copy. That
line held: no copy was fabricated, and when access returned every guessed value
was checked. The four quick-action glyphs guessed during the outage — `plus`,
`repeat`, `target`, `award` — all turned out to match `10:29`, `10:63`, `10:20`
and `11:83`. Being right is not the same as having verified, which is why they
were labelled derived until they were.

### What the annotations were worth

Thirteen of the twenty findings recorded for page 02 came from annotation frames,
not from the screen frames — and the four screens built before those annotations
were read all needed correcting. Two contradicted merged code outright
(`homeRecentLimit = 4`, safe-to-spend as the raw balance), one described a defect
the implementation had introduced (the loading state's missing app bar), and one
required a whole missing section (`BudgetCard x2` on Home).

The recurring shape: **a frame draws one instance of a rule, and the rule was
written down next to it.** `homeRecentLimit = 4` was justified in a comment
reading "Figma `52:2` draws four". It does draw four. The annotation beside it
said the cap is five.

The reverse also happened once, which is why the rule is not "annotations always
win": `57:612` says the over-budget screen has the "same layout as 02.01", but
`57:414` authors no quick-actions row. There the frame won, because "same layout
as" describes where a cap of five specifies.

## insight-components — in progress, opened 2026-09-10

Five components derived from page 07's six annotation frames: `ChartLegendItem`
`47:47`, `DonutChart` `47:48`, `LineChart` `48:76`, `BottomSheet` `59:211` and
`Radio` `25:238`. `BarChart` `48:34` and `Sparkline` `48:94` sit on the same
Charts page and are deliberately out of scope — the first belongs to Budgets
`04.07`, the second is instanced nowhere on page 07 — and annotation `77:587`
forbids a horizontal bar chart outright: *"ProgressBar is reused as the bar mark
rather than adding a HorizontalBarChart component."*

| Date | Step | Task | Commit | Evidence |
| --- | --- | --- | --- | --- |
| 2026-09-10 | checkpoint | 1.1 ChartSeries value type | `2e564b5` | `docs/ai-workflow/verify-runs/2026-09-10T01-43-14Z_insight-components.md` |
| 2026-09-10 | checkpoint | 2.1 + 2.2 ChartLegendItem and its nine gallery slots | `1147f4e` | `docs/ai-workflow/verify-runs/2026-09-10T01-49-42Z_insight-components.md` |
| 2026-09-10 | checkpoint | 3.1 DonutChart ring, centre and painted-arc assertions | `c425af2` | `docs/ai-workflow/verify-runs/2026-09-10T01-59-46Z_insight-components.md` |
| 2026-09-10 | checkpoint | 3.2–3.5 cap, fold, unsuppressible legend, boundaries, gallery count | `6d849b3` | `docs/ai-workflow/verify-runs/2026-09-10T02-06-54Z_insight-components.md` |
| 2026-09-10 | checkpoint | 6.1 MonetaRadio, four variants (colours derived, not transcribed) | `e4b370d` | `docs/ai-workflow/verify-runs/2026-09-10T02-11-41Z_insight-components.md` |
| 2026-09-10 | checkpoint | 6.2 RadioRow and RadioGroup, the group rule where the group is | `8920a74` | `docs/ai-workflow/verify-runs/2026-09-10T02-16-29Z_insight-components.md` |
| 2026-09-10 | checkpoint | 6.3 Radio gallery count tests | `59ee0e9` | `docs/ai-workflow/verify-runs/2026-09-10T02-18-23Z_insight-components.md` |
| 2026-09-10 | checkpoint | 5.1 MonetaBottomSheet, sized by its content | `61760e6` | `docs/ai-workflow/verify-runs/2026-09-10T02-22-08Z_insight-components.md` |
| 2026-09-10 | checkpoint | 5.2 BottomSheet gallery registration | `b30fedd` | `docs/ai-workflow/verify-runs/2026-09-10T02-23-34Z_insight-components.md` |
| 2026-09-10 | checkpoint | 7.2 deviation 12 resolved by annotation `81:498` | `69a769a` | `docs/ai-workflow/verify-runs/2026-09-10T02-25-12Z_insight-components.md` |
| 2026-09-10 | partial | 7.1/7.3 provenance and deviations 41–44 recorded; both tasks stay open | (this commit) | `docs/ai-workflow/verify-runs/2026-09-10T02-26-59Z_insight-components.md` |

### Two tasks, one checkpoint, and why

2.1 (the widget) and 2.2 (its gallery registration) were committed together.
They cannot be separate checkpoints: `gallery_test.dart` asserts that every
class declared under `lib/design_system` is either in the gallery or in a live
exemption list, so a widget committed without its section fails the gate, and a
checkpoint requires a passing gate. Splitting them would have meant exempting
`ChartLegendItem` for one commit and un-exempting it in the next — a temporary
hole in the check that catches exactly this.

### D4's rationale was false, and this is how it was caught

`design.md` D4 said a shared mutated `Paint` is what made
`MonetaCircularProgress`'s colour requirement untestable, "because a recording
canvas keeps the reference, so `paints..arc(color:)` sees the last colour on
every entry". The donut's own mutation run is what exposed it: the mutation
*predicted to pass* — reverting the painter to one shared, mutated `Paint` —
**passed**, leaving all nine donut tests green.

Two probes settled it. A throwaway two-arc painter mutating one `Paint`
reports both colours correctly to an ordered `paints`, and reverting
`MonetaCircularProgress`'s painter to a shared instance leaves all fourteen of
its own tests passing. In this Flutter version the recording canvas does not
alias the `Paint`.

So the ring's requirement was unguarded for the plain reason that **no test
asserted what reached the canvas at all**. `budget-components` added the missing
assertion and rewrote the painter in one commit, and credited the fix to the
rewrite. The assertion was the fix. Corrected in three places — D4, the Context
section that repeated it, and the comment in
`moneta_circular_progress_test.dart` that stated the same false cause — and the
fresh-`Paint` rule kept on the narrower ground that a painter outlives one
`paint()` call.

This is the second time in this project that a fix has been credited to the
wrong half of a two-part commit. The pattern to watch: when a commit changes
both the code and its test, the mutation that proves which half mattered has to
be run against the *old* code, not the new.

### What the donut's own nodes said

- `47:62`'s legend rows carry slots **7, 4, 2, 8, 6, 3, 5, Other** — Food &
  drink is `Slot=7`, and `chart/1` is never used. The ring's exported fills
  agree (`#AA7705`, `#027ED8`, `#769200`), so ring and legend are consistent;
  what the file does *not* do is colour by rank. `DonutChart` therefore honours
  each caller's slot and ranks only the order, so a category keeps one colour
  across every screen that charts it.
- Ring thickness reads 39.5182 off `47:50`'s path and is implemented as
  **39.5**. The trailing `0.0182` is Figma's arc-to-path conversion. Rounding
  also made it assertable: `Paint.strokeWidth` is a 32-bit float, so 39.5182
  comes back as 39.5181999206543 and the `paints` matcher rejects it.
- A segment gap exists and is not in any style: measured 0.898° at twelve
  o'clock and 1.099° between the first two segments, implemented as **1°** and
  suppressed below two visible segments, since a notch in an otherwise complete
  circle reads as missing data.
- The track behind the segments is an **addition**. `47:49` has eight ellipses
  and no track, because its sample fills the circle; the spec's "empty ring with
  no segments" needs something to be the ring.

### Four tasks in one checkpoint — a deviation, stated

3.2, 3.3, 3.4 and 3.5 are committed together. That breaks "one checkpoint per
task", and it is a real deviation rather than a technicality: all four are
test-only additions to one file for one component, and I wrote them in sequence
before committing. Splitting them afterwards would produce three commits whose
verify evidence describes the final state rather than the state each commit
leaves behind, which is the thing a checkpoint is for. Recorded rather than
tidied away; the remaining groups (4, 5, 6) go back to one commit per task.

### The legend row has a real upper bound, and it is not fixable

3.4's near-maximum scenario surfaced a genuine defect, not in the donut but in
`ChartLegendItem`: at 2^61 minor units the row overflows by 47px. `47:2` pins
the percentage and the amount (`shrink-0`) and flexes only the label, so once
the label reaches zero width the row is over-subscribed and `RenderFlex`
reports it.

There is no arrangement of a 353px row that can show an unbounded amount. Making
the amount flexible does not fix it either — `RenderFlex` gives each flexible
child `freeSpace / totalFlex` and does not hand a loose child's leftover back to
its sibling, so a flexible amount would leave the row un-flush and shrink the
label in the normal case. The only real choice is which part is lost, and the
design already answers that: the label goes first.

So the scenario is split. The arithmetic is asserted at 2^61 without rendering,
and a separate widget test asserts the largest magnitude the authored row does
hold (~10^15 minor units, past any real ledger). The bound is recorded in
`figma-map.md` rather than papered over with a test that avoids the question.

### Figma access flipped again, mid-change, and what was done about it

Access failed at task 4.1. `whoami` first this time, not seventh: the MCP
connection is authenticated as **jeff@relayvault.ai, seat View, tier starter**
— the account that cannot read this file — instead of the NIK Technology
Full/pro account. Same root cause as the 2026-09-09 outage: two accounts behind
one connection. Restoring it is the file owner's action, not a retry.

Work was re-ordered rather than stopped, and the line was drawn where the
transcription runs out:

| Task | Node | Decision |
| --- | --- | --- |
| 6.x `Radio` | `25:238` | **Built.** Geometry (22×22, four variants) is transcribed in `proposal.md`; colour roles are *derived from `25:229`*, the Checkbox set beside it on the same page, and marked derived. |
| 5.x `BottomSheet` | `59:211` | **Built.** Geometry fully transcribed in `proposal.md`: 393 wide, 20px handle area with a 40×4 grab handle, 60px header, 44×44 close, bottom safe inset. |
| 4.x `LineChart` | `48:76` | **Held.** Only counts are recorded — three gridlines, two series, 9×9 markers, a 353×140 plot. Gridline placement, axis-label layout and the plot's own colours are not, and this change's own proposal names the alternative: *"the alternative is approximating a chart, which is how this repository's invented spacing scale happened."* |

The distinction that decided it: a *derived* value is one this design system
already answers elsewhere and a fidelity pass can confirm; an *invented* value
is one nothing in the repository constrains. Radio's fill colour is the first.
A gridline's y position is the second.

### What the group rule does and does not guarantee

`MonetaRadioGroup` computes each row's `selected` as `option.value == selected`,
so no two **distinct** values can both read selected. It cannot make two options
carrying the *same* value differ, and the test says so out loud rather than
asserting a guarantee the type does not give: two `_Period.weekly` options do
both light up, and that is the caller's error.

The spec scenario reads "two radios in one group cannot both report selected".
Taken literally that is false for duplicated values, so the test records the
real boundary instead of quietly testing something weaker.

One defect was found by asking a question the spec does not: the atom refuses
taps when it is already selected, and it sits inside the row's opaque
`GestureDetector`. If the atom absorbed the hit without acting, the 44px square
over the *selected* control would be the one dead spot on the row. It does not —
the row's detector wins — and there is now a test that would fail if that
changed.

### Why 7.1 and 7.3 are recorded but not ticked

Both ask for something that includes `LineChart`: 7.1 marks *five* components
done, and 7.3 records two accessibility deviations, one of which is the axis
that cannot be doubled. Four components and one deviation exist; the fifth and
the second do not.

The findings were written into `figma-map.md` anyway rather than held in this
session — provenance for derived values is exactly what gets lost when a change
pauses — and the tasks stay `[ ]`, because ticking a task whose specified
content is partly absent is the failure mode the apply workflow names outright.

Remaining: 4.1–4.4 (`LineChart`), 7.1 and 7.3 (their `LineChart` halves), 7.4
(this log, kept current as each checkpoint lands) and 7.5 (the full gate plus
`figma-fidelity` against `47:48` and `48:76`, which needs file access).

## demo-data — in progress, opened 2026-09-10

A demo mode: a toggle that points the app at a second SQLite file seeded with
about fifteen months of generated ledger data, with real data untouched and
manual entry still working.

| Date | Step | Task | Commit | Evidence |
| --- | --- | --- | --- | --- |
| 2026-09-10 | propose | four artifacts, `openspec validate` clean | `76e106a` | — |
| 2026-09-10 | audit | `spec-auditor`: NOT READY, 11 required fixes | — | — |
| 2026-09-10 | checkpoint | 1.1 control/active database split | `29debb0` | `docs/ai-workflow/verify-runs/2026-09-10T07-37-43Z_demo-data.md` |
| 2026-09-10 | checkpoint | 1.2 `demoMode` key, every preference control-scoped | `84293c3` | `docs/ai-workflow/verify-runs/2026-09-10T07-40-04Z_demo-data.md` |
| 2026-09-10 | checkpoint | 1.3 the toggle-undoes-itself guard | `c98f740` | `docs/ai-workflow/verify-runs/2026-09-10T07-44-23Z_demo-data.md` |
| 2026-09-10 | checkpoint | 1.4 real ledger untouched, end to end | `ca3d574` | `docs/ai-workflow/verify-runs/2026-09-10T07-47-12Z_demo-data.md` |
| 2026-09-10 | checkpoint | 2.1 in-flight state does not cross ledgers | `6623f58` | `docs/ai-workflow/verify-runs/2026-09-10T07-52-09Z_demo-data.md` |
| 2026-09-10 | checkpoint | 3.1–3.5 the dataset generator | `fcd1c62` | `docs/ai-workflow/verify-runs/2026-09-10T07-59-44Z_demo-data.md` |
| 2026-09-10 | checkpoint | 4.1–4.4 seeding through the repositories | `6cfd444` | `docs/ai-workflow/verify-runs/2026-09-10T08-05-06Z_demo-data.md` |
| 2026-09-10 | checkpoint | 5.1 the demo-mode controller | (this commit) | `docs/ai-workflow/verify-runs/2026-09-10T08-11-45Z_demo-data.md` |

### The spec-auditor earned its place in the workflow

Eleven findings, and I verified every load-bearing one against the source before
acting. All six I checked held.

**Two were fatal to the spec as written.**

1. **An impossible requirement.** I required "more than eight categories in the
   current month, so the eight-segment cap and the neutral `Other` fold are both
   visible". `SpendCategory` declares **eight** categories and `salary` is the
   only income one, so at most **seven** can carry expense — against a cap of
   eight. The fold is unreachable from category data, and task 2.2's test could
   not have been written. The proposal also said "nine spend categories", which
   is simply wrong. Requirement replaced with what the dataset *can* show, and
   D14 records the impossibility rather than quietly reaching for a ninth
   category, which would be a `lib/core` change smuggled in under a demo-data
   proposal.

2. **A contradiction between the two specs I wrote in the same sitting.**
   `storage/local-database` said a switch "SHALL close the connection it
   replaces"; `design.md` said that connection *is* the control connection when
   demo mode is off. Closing it would take down the settings store holding the
   flag — and the very next thing after a toggle is a read of the flag the
   toggle just wrote. The requirement now names the demo connection
   specifically, with a scenario that fails if the control connection is ever
   closed by a swap.

**Others acted on:** production ids come from `Random.secure()`, so my
determinism requirement was false in production while every test passed — the
generator now takes an `IdGenerator` parameter (D4a). D3's fail-fast contradicted
D7's "seed if there are no transactions": a seed failing after row one leaves
transactions and would never retry, so there is a seed-completion marker, and it
cannot be a preference because preferences are control-scoped and shared (D7,
extended). A stale scenario I copied forward said the schema is "at v2 with both
tables" — it is v3 with three. The proposal had no `## Non-goals`, which
`openspec/config.yaml` requires.

**The best finding was a hole in the flagship guarantee.** `PendingUndo` holds a
deleted `Transaction` in memory for five seconds and restores it through the
ordinary repository. Delete a demo transaction, turn demo mode off inside the
window, press undo — and a demo record lands in the real ledger. The file
separation does not cover in-flight state. That is now a requirement of its own
(D11) and task 2.1, ahead of all the dataset work.

Also restructured: the capability's first requirement — real data untouched end
to end — had been task 7.2, the *last* task. It is now 1.4, and it gates the
rest.

### 1.1: two mutations, one of which found a real hole

The provider split went in and the gate passed at 1404 tests. Then three
mutations:

| Mutation | Result |
| --- | --- |
| demo-off returns a second `AppDatabase` on the real path instead of the shared instance | fails |
| the control connection is also closed on a swap | **survived** |
| `preferencesStoreProvider` bound to `activeDatabaseProvider` | **survived** |

The second was my test's fault, and it is the useful kind. **Riverpod is lazy:**
the test flipped the flag but never *read* `activeDatabaseProvider`, so the demo
branch was never built, no `onDispose` was ever registered, and the assertion
about the control connection could not fail. Reading the provider while demo
mode is on fixed it, and the mutation now fails.

The third is expected at 1.1 and is exactly what task 1.3 exists for — the
toggle-undoing-itself guard, which is not written yet. Recorded rather than
treated as covered, because 1.1's own verify line does not claim it.

### 1.3 closed the mutation 1.1 could not, and hit the FakeAsync trap doing it

The mutation that survived 1.1 — `preferencesStoreProvider` bound to
`activeDatabaseProvider` — now fails three behavioural tests plus a source-level
check. The assertion that makes it work is **re-resolving the store after the
swap**: a test that holds the store obtained beforehand reads from the
still-open control connection and passes even with the store bound to the
database that moves. That is the precise shape the auditor flagged, and the
first draft of this test would have had it.

I also wrote these as `testWidgets` and **the run hung** rather than failing.
`CLAUDE.md` says exactly why: a `testWidgets` body runs inside a `FakeAsync`
zone, so real database I/O never completes, and a hang looks like a slow machine
rather than a bug. It cost one 120-second timeout instead of the seven minutes
it cost during `design-system-foundation`, because the warning was already
written down. Plain `test()`, and the file now says so at the top.

### 2.1: the auditor's best finding, reproduced and then closed

The hole was real and the test reproduced it before the fix went in: with
`pendingUndo` carried across a ledger change, deleting a demo transaction,
leaving demo mode inside the five-second window and pressing undo writes a demo
record into the real ledger. Two of the three tests failed on the unfixed code.
The file separation cannot catch this, because the record never went to a file —
it was in memory the whole time.

The fix is one parameter: `build()` loads with `keepPendingUndo: false`,
`refresh()` keeps it. `build` reruns whenever `transactionRepositoryProvider`
changes, and that rebuilds when the active ledger changes, so the drop happens
exactly on a swap.

**Two things this cost, both worth recording.**

*A test-harness trap that looked like a product bug.* My row-count helper opened
a second `AppDatabase` on the same path and closed it. sqflite defaults to
`singleInstance`, so it handed back the connection the app was already using and
the close took the app's connection down — three tests failed for a reason that
had nothing to do with the code under test. Helpers now query the container's
own active connection.

*An unguarded default I introduced myself.* A mutation hardcoding
`pendingUndo: null` — undo never surviving even a refresh — passed the two new
cross-ledger tests **and all 172 tests in `test/features/transactions`**. No
existing test ever refreshes while an undo is open, because `delete` refreshes
*before* it opens the window. Changing the filter within five seconds of a
deletion does, and there is now a test for it. Both halves of the parameter are
guarded; both mutations fail.

### The dataset, measured

**1,174 transactions, 14 salary payments and 3 budgets** at the 2026-09-17
anchor, across fifteen months. Pure generation, no database involved.

### Group 3: six mutations, two survivors, and one of them mattered

| Mutation | Result |
| --- | --- |
| future dates allowed | fails |
| per-month category coverage dropped | fails |
| salary day randomised | fails |
| over-budget budget made comfortable | fails |
| the seed offset by one | **survived — equivalent** |
| the LCG replaced by `_state + 1` | **survived — a real gap, now closed** |

The seed survivor is equivalent with respect to the spec: no requirement pins a
*particular* dataset, only that the same seed reproduces it and that a different
seed changes it, both of which still hold. Recorded as equivalent rather than as
a gap.

The counter survivor was real, and interesting. `_state = _state + 1` satisfies
**every** assertion in the `DemoRandom` group — it replays from a seed, it
advances, it covers `between`'s full range — and every dataset-level test too,
because cycling through all residues uniformly hits each category in exact
proportion to its share. What it breaks is the one thing dummy data exists for:
amounts march upward in lockstep and categories cycle in order, which a reviewer
sees immediately and the suite could not. The new assertion is objective rather
than a claim about realism: over 200 draws the sequence must decrease at least a
quarter of the time. A counter never decreases.

### Two things the tests forced changes to

*Category coverage was probabilistic.* The spec requires every expense category
in the current month; at a 4% share, `gift` was simply absent from a 17-day
month and the test failed. The generator now guarantees at least one transaction
per expense category per month, current month included. A guarantee that holds
for one seed and breaks on the next tuning of the weight table is not one.

*A source-level check that failed on its own rationale.* The "no global clock or
random source" check grepped for `SystemIdGenerator` and `Random.secure` — both
of which the class doc *names*, to explain why they are not used. It now strips
comments first, and the guard-the-guard test asserts both halves: that the
stripper removes prose and that it does not remove code.

### A mutation harness that silently did nothing

The first run of these six reported every mutation as surviving. The shell
helper never forwarded its arguments to `python3 -c`, so no edit was applied —
and "mutation did not apply" is indistinguishable from "test did not catch"
unless something says so. Python's traceback did. This is the second form of the
trap `figma-map.md` records for `dart format`: **verify the edit landed before
believing the result.** The assertion inside the helper is what turned six
false negatives into six visible errors.

### 4.3: the measurement, and 4.4 not needed

Against a real file on the Dart VM, seeding the full fifteen-month dataset:

| Step | Records | Time |
| --- | --- | --- |
| generate (pure) | 1,177 | **13 ms** |
| seed through the repositories | 1,177 | **584 ms** |

The budget was two seconds. So **4.4 is not needed** and is ticked as such with
the number that says so, rather than performed because it was written down. That
matters more than the milliseconds: 4.4 would have threaded a
transaction-scoped executor through two repository constructors — a cross-feature
API change — and the task's own rule was to measure first. This is the
measurement deciding it.

### What the marker tests recorded that a reader would otherwise assume

`seedOnce` retries a failed seed, because the marker is only written after every
record lands. But **retrying does not recover**: the rows from the failed
attempt are still there, so the retry collides on duplicate ids and fails too.
The answer is reset, which deletes the file. There is a test named for exactly
that, because "a failed seed is retried" reads like "it heals itself" and it
does not.

Three mutations, all failing: marking before seeding instead of after, skipping
the already-seeded check, and the marker reading *any* row under its key as
seeded rather than only its own value.

### 5.1: a source-level check earned its keep on my own code

Task 3.1's check asserts `demo_dataset.dart` constructs no id source, because
the generator's whole claim is that both sources of non-determinism arrive as
parameters. Writing the controller, I added `demoIdGenerator()` — a
`SystemIdGenerator` with a seeded `Random` — to that very file, and **the check
failed the gate**. It was right: choosing a deterministic id source is the
seeder's business, not the generator's. The function moved to
`demo_seeder.dart` and the check's reason now records why.

That is the second time in this change a guard written for a hypothetical caught
the person who wrote it.

### The order the controller does things, and what a failed seed leaves behind

Preference first, flag second, seed last. The preference is the durable answer;
everything after it can be redone.

So a failed seed leaves demo mode **on** with an unseeded ledger, deliberately.
The marker was never written, so the next activation retries, and meanwhile the
screens show an empty ledger under the demo banner — which the spec calls an
empty ledger rather than an error. Rolling the preference back instead would
hide a storage failure behind a toggle that silently refused to move.

`seedIfNeeded` also refuses outright when demo mode is off, and returns a
*validation* failure rather than a storage one. It is the single call in this
change that could write generated data into a real wallet, so it checks its own
precondition instead of trusting its caller — and there is a test that seeds
nothing and asserts the real ledger is still empty.

Four mutations, all failing: the real-ledger guard removed, absence read as a
stored true, a corrupt stored value swallowed, and the preference never written.

### insight-components resumed and finished its charts, 2026-09-10

Figma access returned (NIK Technology, Full/pro), so `LineChart` was built from
`48:76` rather than from the counts `proposal.md` had recorded. Tasks 4.1–4.4,
7.1 and 7.3 are done; 7.2 was already done; 7.5's fidelity pass runs against
`47:48` and `48:76` now that the file is readable.

Six mutations on the chart. Four failed immediately. **Two survived, and both
were my tests' fault rather than equivalent mutants** — the same lesson this
project keeps relearning, that a test naming a property is not the same as a
test asserting it:

| Survivor | Why it survived | Fix |
| --- | --- | --- |
| a negative value plotted below the baseline | the clamp lived in the painter, and the test compared the plot's height to itself, then asserted `math.min(0, -5) == -5` — a tautology | the value→position mapping moved to a public `fractionsOf`, asserted directly: the negative month sits at zero, and fractions are measured from zero rather than from the data's minimum |
| the marker's surface ring drawn at radius zero | the test counted four `drawCircle` calls, which a zero-radius ring satisfies | radii asserted in the ordered `paints` sequence, plus the ring asserted larger than the mark |

The clamp mutation also had to be re-run: `dart format` had collapsed the target
expression onto one line between writes, so the first attempt reported
`NOT FOUND` instead of silently passing. The assertion inside the mutation
helper is what made that visible — the trap `figma-map.md` records, caught by
the guard put there for it.

## insights-feature — four of six screens, 2026-09-10

Opened and applied under an explicit instruction to move fast and skip
blockers. `07.01`, `07.02`, `07.03` and `07.05` are built; `07.04` and `07.06`
are deferred and named in the proposal's Non-goals rather than left as silence.

Gate: **1552 tests, all 8 checks green.**

### The coverage gate caught what the test count hid

The first gate run passed 1542 tests and **failed coverage**:
`insights_entry.dart` at 20% and `insights_summary.dart` at 83.6%, against the
85% the critical band requires. The value types' equality and `MonthlyFlow.net`
had no direct tests — the screens exercised them incidentally, which is not the
same thing. Ten tests later both are over. Worth recording because "1542 tests
pass" is exactly the sort of number that reads as done.

### A rule whose two halves contradicted each other

Annotation `77:587` says *"ProgressBar is reused as the bar mark rather than
adding a HorizontalBarChart component; one series means one hue, so every bar is
the same colour and rank is carried by length and order."*

`MonetaProgressBar` derives its colour from the fraction. 07.03's longest bar is
full by construction, so reusing the component literally would paint it in the
**near-limit warning** colour while shorter bars came out green — the sentence's
first half defeats its second. `80:407` breaks the tie: every fill on `77:440`
is `chart/1`.

Resolved by adding `MonetaProgressBar.series`, which takes a `ChartSlot` rather
than a `Color` for the reason `ChartLegendItem` does. That is a
`lib/design_system` change the proposal said this change would not make, so it
is recorded as added scope in `tasks.md` group 7 rather than slipped in.

### Two numbers that differ, and the screen shows both

07.03's bar length is share of the **largest** category; its percentage label is
share of the **total**. `77:587` carries rank by length, so the top bar must be
full — a share-of-total fraction would leave it a third full and waste
two-thirds of the width. Food at 6.76M of 16.28M reads "42%" beside a full bar,
and there is a test asserting the label is 42% and *not* 100%.

### Two test defects found by the tests themselves

*An assertion that could not fail.* The "period changes the data, not the
layout" test collected a `List<String>` per period and asserted
`seen.toSet()` had one entry. `List` compares by identity, so four identical
lists gave four set entries and the assertion failed on correct code — the
inverse of the usual problem, and it would have passed on *broken* code had the
comparison been the other way round. Joined to a string, plus an explicit
assertion of the expected shape.

*A real overflow.* The cash-flow month row overflowed by 79px: at a realistic
salary, "32,000,000 ₫ in · 16,280,000 ₫ out" is wider than the phone.
`77:383`'s own proportions fixed it — month 136 of 321, figures 177, so flex 3:4
with both sides ellipsised.

### The fidelity pass on the charts

Run once Figma was readable. `ChartLegendItem` faithful, `DonutChart` faithful
with notes, `MonetaLineChart` **divergent** — and correctly so: I had read "9px
end markers with a 2px surface ring" as a 9px disc *plus* a ring, giving an 11px
mark with a 1px ring. `48:84`'s exported SVG says 9px is the **outer** diameter,
the disc is **7px**, and the ring is **`canvas`** (`#06070A`), not `surface`.
Both fixed, both asserted by radius in the ordered `paints` sequence.

It also improved two provenance notes: the donut's ring thickness is exactly
39.52 (inner radius 0.62 × 104), and `47:48`'s **description was readable all
along** and states the ~2px segment gap that this change recorded as "no style
carries it". Remaining cosmetic divergences — label overhang, a 4-vs-8 gap,
label centring, marker inset — are recorded in `figma-map.md` and not fixed,
under the same instruction to keep moving.

### The finding worth more than the screens

`SpendCategory.chartSlot` is Food 7, Transport 4, Shopping 2, Bills 8,
Entertainment 6, Health 3, Gifts 5 — **exactly** the slots `47:62`'s legend
rows carry. Deviation 42 recorded that order as arbitrary. It is not: each
category owns its slot, and `chart/1` is missing from the donut's sample because
it belongs to `salary`, which is income. `33:311`'s description says as much —
*"Colour and glyph are baked in together — pick a category, never a colour."*
Deviation 42 corrected.

## profile-feature — Settings, and the demo switch finally has a home

`08.03` built from `100:428`; the Profile tab points at it. Ten of the eleven
page-08 screens are deferred with the blocker for each recorded in
`figma-map.md` — `Avatar`, `Numpad`, `Chip` and `SearchField` are all authored
and unbuilt, and several screens have no behaviour behind them at all.

Gate: **1561 tests, all 8 checks green.**

### The provisional screen was never built

`demo-data` group 7 planned one while Figma was unreadable. Access returned, so
the authored screen got built instead and group 7 is ticked **superseded** with
this change named. Two screens for one control would have been the wrong answer
to a temporary outage.

### The information design is enforced by the type

`100:728` names the mistake this screen exists to avoid, so `SettingsRow` has
three constructors and **derives** its accessory: `push` → chevron, `toggle` →
toggle, `value` → value. There is no accessory parameter to get wrong.

The test asserts it as an invariant over every row — a row that toggles must not
also navigate, a row that navigates must carry a chevron — rather than checking
each row individually, because the failure mode being guarded is *a new row
added with the wrong trailing*, and per-row assertions pass for that.

### Two things the tests caught

A row whose destination does not exist was passing its `onTap` through, so
tapping "Edit profile" would have navigated to nothing. It now drops the handler
when `available` is false, and there is a test for both directions — the
unavailable row reports nothing, the available one still works.

And an ambiguous finder: the group heading "Security" and a row titled
"Security" both render as `Text`, so `find.text` matched two widgets. The
fixture now uses distinct strings, which is a fixture problem rather than a
product one but would have read as a flaky test later.

### The demo data was tuned by looking at what it actually said

The generator passed every test and produced a month that read badly:

```
before   spend 24.5M   income 0 ₫
         Bills 43% · Shopping 27% · Food 9% · Health 6% · Transport 6% ...
after    spend 9.8M    income 32.0M
         Shopping 23% · Bills 22% · Food 21% · Transport 15% · Health 9% ...
```

Two real defects, neither of which any assertion covered because neither is
wrong — only implausible:

**Income read 0 ₫ for the current month.** Payday was the 25th and the demo
anchor is the 17th, so the newest point on the cash-flow chart's income line sat
on the baseline and Insights reported no income at all. Payday moved to the 5th,
and the test now pins the boundary *both* ways — a clock on the 3rd has one
salary fewer, a clock on the 6th does not.

**Bills were 43% of spending and food 9%**, because a 1.9M ceiling on a
12%-frequency category beats a 420k ceiling on a 34% one. The ceilings were cut
so food is near the top, which is also the shape `47:62`'s own sample has.

The notes are now merchant-flavoured — Highlands Coffee, Grab Bike, Shopee, EVN,
CGV, Pharmacity, Tết lucky money — because a demo of a finance app is much
easier to read when the rows look like somewhere you have been. Still invented,
still recorded as invented, and no test depends on any particular string.

One test bug found while fixing this: `isNot(contains(9))` on transaction months
matched September **2025**, which a fifteen-month window from September 2026 also
contains. Year and month now, which is the assertion that was meant.

### Demo mode did not survive a restart, and nothing said so

`DemoModeController.hydrate()` existed, had tests, and **was never called.**
The preference was written durably and never read back at launch, so turning the
switch on, closing the app and reopening it landed on the real ledger with the
switch showing off. No test covered it because every test built its own
container and called `hydrate` directly.

Fixed with `StartupRouteScreen` in `lib/app`, which hydrates and then shows the
splash — the splash itself lives in `features/onboarding` and may not import
`lib/app/demo`.

That immediately broke four router tests, and they were right to break:
`preferencesStoreProvider` **throws** when the database cannot be opened, by
design, so a screen can render an error state. On the startup path a throw is
different — it leaves the splash unable to leave. `hydrate` is now the one
method here that catches, returning `Err` and leaving demo mode off, which is
the safe direction. A mutation narrowing the catch to `on Never` fails.

### A defect a user saw and no test did

The donut's centre total touched the ring. The cause is in the design file:
`47:58` places a **140-wide** centre block inside a hole that is **129** across
at its widest and about **113** across the top and bottom edges of a 62-tall
block. The authored box overhangs the arcs by construction, and Figma's sample
hides it because "26,000,000 ₫" is short. A real VND total is not.

Fixed by deriving `centreWidth` from the ring's geometry rather than
transcribing 140, and by scaling the total with `BoxFit.scaleDown` instead of
ellipsising it — this component already holds that a clipped amount is a lost
amount, and that goes double for the total.

**The guard took three attempts, and the first two are the interesting part.**

1. `lessThanOrEqualTo(innerRadius)` — passed for a box whose corners sit
   *exactly on* the circle. Removing the 8px margin leaves it precisely
   tangent, and tangency is still touching. The mutation survived.
2. Measuring the **total's own box** instead of the centre block — also
   survived. The total is scaled to fit, so its box hugs the scaled text and is
   always comfortably inside; the block keeps its full width and height
   whatever the figure says. I was measuring the one thing that could not fail.

Both are the same error wearing different clothes: an assertion on the wrong
object, or at the wrong strictness, reads like a guarantee and holds nothing.
The third version measures the block's furthest **corner** and requires real
clearance, and all three mutations fail against it — the authored 140 restored,
the margin removed, the block's height ignored.

Worth noting how this arrived: a person looked at the screen. Every chart test
in this change asserts colours, order, sweeps, folds and boundaries, and not one
of them asked whether the text fitted in the hole.

## profile-components — Avatar, and a hole in the token set

`Avatar` (`21:121`) at all twelve variants, which unblocks `08.01` and `08.02`.
Gate: **1601 tests, all 8 checks green.** Seven mutations, all failing.

### The token set was missing a member and no test could have said so

Every Avatar variant fills `var(--brand-subtle, #1a1236)`. `MonetaColors` had
`incomeSubtle`, `expenseSubtle`, `warningSubtle`, `infoSubtle` — and no
`brandSubtle`. Four of five families complete, the fifth simply absent.

The existing test asserted the four by name, so it could not notice a fifth was
missing. The new one iterates the families and asserts each base has a subtle
counterpart, which fails if another is ever added without one. That is the
difference between a test that checks what exists and one that checks what
should.

Added as a token with a provenance row rather than a `design-token-ignore` in
the first component to need it — the alternative was a second ignore when `Chip`
or the paywall needs the same tint.

### Two tables that a formula nearly fits

Initials style by size: `label/sm`, `label/sm`, `label/md`, `title/md`. Glyph
size by size: 14, 18, 22, 28.

The glyph numbers are the trap. Three of the four are exactly
`diameter / 2 + 2` — and the fourth is `diameter / 2`, so a formula fitted to
the small sizes gives 30 at 56 where the file says 28. A test now asserts both
halves: that the first three *do* fit the formula and that 56 *does not*, so the
next reader sees why it is a table.

### An assumption caught by reading the export

I wrote the icon variant's glyph as `brandOnSurface`, because the initials use
it and it looked like the brand's avatar. `21:120`'s exported SVG is
`stroke="#9AA3B4"` — `textSecondary`. Fixed before it shipped, and there is now
an explicit `isNot(brandOnSurface)` assertion so the assumption cannot come
back.

### One accessibility defect the test found

The first version announced **"Minh Tran, MT"** — the container's label plus the
initials' own semantics, merged. A screen reader would read the name and then
spell two letters of it. The initials are decoration; the container carries the
label, so the content is excluded from the tree.

## profile-feature — 08.01 and 08.06, and two defects in ListRow

Gate: **1636 tests, all 8 checks green.** Ten mutations across the two screens,
all failing.

### A component's own description named two defects

`35:70`: *"56px minimum so the whole row is the tap target — never make just
the trailing control tappable."*

Both halves were violated. Title-only rows came out at **~46px**, under the
authored minimum *and* under the 44px platform target — and every settings
screen in this app is built from them. And a toggle row's row area carried a
separate `onTap`, so the row had two actions and only the 52×32 switch toggled.

An existing, passing test asserted that second behaviour — row tap calls
`onTap`, switch tap calls `onToggle`. It encoded what the description forbids,
so it was replaced rather than accommodated, with the reasoning in the test
body. A toggle row now has one action.

### The mapping mistake, from the other side

`08.03`'s lesson was that the trailing variant *is* the information design.
`101:862` is the same lesson inverted: *"Two rows here are Value, not Toggle,
because they carry a time the user can change. A time is not a boolean."*

So `SettingsRow.value` learned to accept an optional `onTap` — a Value row
*shows state*, which does not mean the state cannot be edited — and the two time
rows are asserted to have no `onToggle` at all.

### A default that silently removed a shipped feature

`08.06`'s frame has one switch off, and it is "Goal milestone reached" — a goals
feature this app does not have. I mapped **income** onto that off state, and
two existing `notifications_route_test.dart` tests failed: income notifications
already ship, and an off-by-default switch had just silenced them.

The honest off switch is the one with nothing behind it. "80% of a budget used"
ships off, because nothing derives an 80% warning yet — which both tells the
truth and gives the mixed defaults `101:856` asks for.

### The screen is six rows of an authored seven, and says so

The seventh is "Monthly report ready", and the app produces no monthly report. A
switch that silences a notification which cannot be sent is a switch that does
nothing. Two more rows are renamed to the kinds `NotificationKind` actually has.
All four group headings are kept as authored so the gap stays visible.

**A test that lied about itself, caught before commit.** It was named "four
groups, seven rows, five toggles and two values" and asserted **six and four**.
The name and the assertion disagreed, which is the same defect this log keeps
recording in other forms. Renamed to what it checks, with the shortfall and its
reason in the body.

### And the switches are wired, not just stored

`101:850` is the whole point of the screen: *"so a user can silence one category
without silencing everything."* `notificationsProvider` filters by the
preferences, and `allows()` switches exhaustively over `NotificationKind`, so
adding a kind is a compile error rather than a notification that quietly ignores
its switch.


## settings-components — the five sets page 08 was missing

### Badge: the tone that is not a pair

`17:32` is five tones × two sizes, and four of them follow one rule — a
`*Subtle` fill with the matching text colour. `Neutral` does not: it fills with
`surfaceRaised` and writes in `textSecondary`, because there is no neutral
semantic family to be subtle about.

That is why the mapping is written out per tone instead of derived from the
token names. A convention with one exception is one nobody can rely on, and the
exception would have been silent — a name-derived lookup would have asked for
`neutralSubtle`, got nothing, and fallen back to whatever the author chose.

**M1 — swap `Success` and `Danger` fills.** Four tests fail (both sizes of both
tones). The table asserts the *pair*, so a single swapped fill cannot hide
behind a correct label colour.

**M2 — make `Neutral` an `infoSubtle` pair.** Three fail, including the one
named for it: the `Neutral` row asserts `isNot(anyOf(the four subtle fills))`,
so the specific wrong answer is named rather than left to the table.

A third check guards the table itself — the ten pairs must be ten *distinct*
pairs. Without it, two tones resolving to the same colours would leave every
per-tone test passing.

### The dot is not the accessibility cue

`17:32`'s description says *"Never rely on tone alone — pair with the dot or
with text."* The dot is drawn in the **label's own colour**, so it carries
nothing a colour-blind or greyscale reader can use; it is a shape, not a second
channel of information about which tone this is.

So the label is what actually discharges the rule, and it is required and
asserted non-empty. `''` would satisfy "has a label" while defeating its whole
purpose. The dot stays a `bool` defaulting to on, matching the Figma property's
default — it is a boolean *component property*, not a variant axis, and the file
authors no node for a dotless Success/Sm.

### Chip: the description hands the touch target to somebody else

`17:65`'s own description: *"36px tall — must sit inside a >=44px scroll row to
meet the touch target."* That is an accessibility rule delegated to every
caller, and a rule enforced by a sentence in a Figma description is a rule with
no enforcement at all — the same shape as `ListRow`'s 56px minimum, which three
shipped screens had already broken.

So the chip owns it: it **occupies 44** and **paints 34**, exactly as
`MonetaCheckbox` and `MonetaRadio` already do with `hitSize` against `boxSize`.
Both numbers are measured in the test, and they must differ — the point is that
the box is bigger than the thing drawn in it.

The hit layer covers the full 44, not the painted 34. A box that is 44 tall
whose middle 34 is the only part that responds would satisfy a height assertion
and miss the rule in the hand.

**One invention, stated.** An input chip's close control takes a 44px square at
the trailing end, which on a one-character label would leave the select area
below 44. So an input chip has a minimum width of two touch targets. It is not
authored, and it changes no authored instance: `08.08`'s two chips are
`Type=Filter`, which has no close control and no minimum. A test asserts that
too, so the minimum cannot quietly start applying to filter chips.

**M3 — give the selected chip the unselected border.** Four tests fail. The
three selected colours are asserted *as a set*, so a single swapped border
cannot hide behind a correct fill and label; a fourth test guards the pair
itself, requiring the two states to share no colour at all.

**M4 — drop the hit box so the chip is 34 tall.** Two fail: the height pair and
the tap-area partition.

### The stroke convention, settled by measurement

Two descriptions in this change state a height their own frame contradicts —
`Chip` says 36 against a 34 frame, `SearchField` says 48 against a 50 frame. The
first attempt at explaining that used one rule for the chip and the opposite for
the search field, which is exactly the failure a reading is supposed to prevent.

Measured instead: `DecoratedBox` wrapping `Padding` paints the border **inside**
the box and adds nothing to it (34.0 for `8 + 18 + 8`), where `Container` with
`padding:` inflates the child by the border on every side (36.0). Figma draws
these strokes inside the frame, so one rule reproduces both frames exactly —
and both descriptions are wrong by two, in opposite directions, which is why no
single fudge could have satisfied them.

### SearchField: a 44px target that ate the authored height

The clear control's glyph is 18, which is not a touch target, so it sits inside
a `minTouchTarget` box — the decision `BottomSheet`'s close control already
took. Built content-driven, that 44px box became the tallest thing in the row
and the field came out **70 tall**: `13 + 44 + 13`. The authored 50 was simply
gone, and the height test said so on the first run.

So the height is **fixed** — the line box plus the padding either side —
computed from the platform's `TextScaler` rather than assuming 1.0. Fixed is
what lets a 44px control sit beside a 24px line without moving the box; taking
the scaler is what stops fixed from meaning frozen. A test asserts 50 at 1.0 and
*greater than* 50 at 1.3, with the clear control still 44 at both.

The off-scale **13** is authored, not rounded. `13 + 24 + 13` is the 50 that
`102:1213` measures; 12 would give the 48 the component's description claims.
Two sources agree on 13 and one on 12, and the two that agree are the ones that
were measured.

**M5 — accept a `state` parameter.** The source check fails. It is scoped to the
constructor's parameter block, because the widget's own `createState` and its
`State` subclass both contain the word and a whole-file check would fail against
a *correct* implementation — the guard-the-guard assertions pin the slice.

**M6 — shrink the clear control to its 18px glyph.** Three fail: the target
measurement and both height tests.

**M7 — dispose the supplied controller too.** The ownership test fails with *"A
TextEditingController was used after being disposed"*. The assertion is that a
caller's controller still **works** after the field is unmounted, not that
nothing threw — a missed disposal throws nothing at all, so "no exception" would
have passed for either behaviour. The owned direction is checked the other way
round, by reaching the field's own controller through the `EditableText` it built
and requiring `addListener` to throw afterwards.

**M8 — honour `enabled` in the decoration but not in the input.** The disabled
test fails, because it types into the field and asserts the text did not change
rather than only reading the colour.

`MonetaTextField` has the same clear-control defect this component avoided — its
trailing icon's `GestureDetector` wraps only the 24px glyph. Out of scope here
and left as it is; recorded so it is a known defect rather than an unknown one.

### Numpad: a keypad that mirrored itself under right-to-left text

The RTL scenario was written expecting to be boring, and it failed on the first
run: a plain `Row` mirrors under `TextDirection.rtl`, so `1` was painted at the
top **right** and `3` at the top left.

That is wrong, and not a matter of taste. Every phone dialer and system keypad
keeps `1` at the top left in right-to-left locales, because a keypad's digits
are **positional** — a mirrored pad makes a memorised PIN wrong. The rows now
pin `textDirection: TextDirection.ltr`, with the reason in the code.

The assertion is on **positions**, not tree order: a `Row` reverses what it
paints without reordering its children, so an order assertion over the widget
tree would have passed for both the mirrored and the correct pad. That is the
same class of mistake this log keeps recording — asserting the thing that cannot
fail.

### The variant count that only a literal could catch

`36:91`'s description claims *"2 types x 2 states"* and this map recorded
**four**. The set has two: `Type=Digit, State=Default` and `Type=Action,
State=Default`. Built as authored; the map is corrected rather than the
component inflated. A candidate for the file's twelve deliberate mistakes.

**M9 — add a `pressed` member to the key-type enum *and* register a catalog
variant for it.** The literal `hasLength(2)` fails while
`hasLength(NumpadKeyType.values.length)` **passes**, because the catalog is
built from the enum. That is the whole argument for pinning counts both ways,
demonstrated rather than asserted: the enum-derived count is what let a wrong
number sit in this file.

**M10 — fix the key width at `36:77`'s standalone 109.** All three width cases
fail, including 200, which is the one that would overflow. `36:92`'s description
says *"Rows are FILL so the pad always spans the 353px content column"* and
`08.05` puts it across 393, so neither number is in the code.

### The decimal key a PIN cannot use

`36:92` is authored **for amount entry** and its third-last cell is a decimal
key. `08.05` reuses the pad for a six-digit PIN. A decimal key there is either
silently dropped or typed into the PIN, and a key identical to the nine beside
it that does nothing is a defect — the first bug report would be "the dot key is
broken".

So the cell is a required parameter with **no default**: the authored decimal
key, or an empty cell. A test asserts the PIN pad renders eleven keys rather
than twelve, that nothing can report a decimal, and that the other keys do not
move. Recorded as a deviation from `36:92`, its cause a reuse the file does not
anticipate.

`36:77` also carries `radius/md` on a key with **no fill**, and the set has no
pressed state to reveal it, so nothing paints inside the rounded box. Kept as a
constant and asserted, so the authored number is recorded rather than quietly
lost.
