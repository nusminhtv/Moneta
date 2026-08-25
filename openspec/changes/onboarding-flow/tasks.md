## 1. Tokens

- [x] 1.1 Add Figma's twelve `space/*` values to `MonetaSpacing` under Figma's
  names, leaving the existing scale in place and marking it deprecated in its doc
  comment with the correct replacement named. Add `borderStrong` (18% white),
  `textSecondary` (`#9AA3B4`) and the `bodyLg` type style (Inter 400 16/24).
  Verify: `test/design_system/tokens/spacing_test.dart` asserts all twelve values
  against `docs/design-system/figma-tokens.md`, and the existing token tests still
  pass unchanged.

## 2. Atoms and molecules

- [x] 2.1 Implement `MonetaButton` from `13:2` — 5 styles × 3 sizes × 3 states,
  resolved through tables rather than branches. Verify:
  `test/design_system/atoms/moneta_button_test.dart` is table-driven over all 45
  combinations asserting background, foreground and height, plus that `Loading`
  renders a spinner at the same width as `Default` with the same label.
- [x] 2.2 Implement `MonetaPaginationDots` from `70:223`. Verify:
  `test/design_system/molecules/pagination_dots_test.dart` asserts the active dot
  is both wider and brand-coloured, that exactly one is active, and that width
  alone identifies position.

## 3. Storage

- [x] 3.1 Add migration `v2` creating `settings`, and a minimal
  `PreferencesStore` supporting one boolean key. Verify:
  `test/data/preferences_store_test.dart` covers write/read, absence, a malformed
  value as a storage failure, and durability across close and reopen; and
  `test/data/migrations_test.dart` asserts v1 rows survive the upgrade.
  The v1 → v2 assertion is `test/data/migrations_test.dart:181` — a real
  file-backed upgrade with a surviving row and an empty `settings` table.
  `test/data/database_test.dart` also gained a generic
  `schemaVersion → schemaVersion + 1` upgrade test, which does not touch
  `settings`; an earlier version of this note credited that file with the
  v1 → v2 proof, which was wrong. Three tests in that file hardcoded
  version 2 and broke on the bump; they are now written relative to
  `schemaVersion`, and the upgrade test had to move off `inMemoryDatabasePath`,
  where two opens are two different databases and the test proved nothing.

## 4. Onboarding

- [x] 4.1 ~~Download the six decorative illustration SVGs~~ — **not needed.**
  Reading them showed every value is a token: halo = the slot's `chart-N-subtle`,
  ring = `border-subtle`, accent dots = `chart-N` at 50%. Drawn natively in
  `OnboardingIllustration` instead, which keeps it under
  `check_design_tokens.dart` — a gate that cannot see inside an SVG.
- [x] 4.2 Implement the controller: read the flag, record completion on finish or
  skip, fall back to showing on a failed read. Verify:
  `onboarding_providers_test.dart` (9 tests) covers first run, completion
  recorded, an explicit `false`, a corrupt stored value, a failing read, a store
  that cannot be built, idempotent completion, and a failed write that does not
  crash the caller. Named `_providers_` not `_controller_`: it is two providers,
  not a Notifier, so a name promising a controller would have been misleading.
  The shared providers moved to `lib/data/app_providers.dart` — a second feature
  needed them and cross-feature imports are forbidden. That file then failed the
  85% coverage gate at 70%, exactly as the `home-overview` audit predicted; fixed
  by assigning `databaseFactory = databaseFactoryFfi` so the **production**
  provider bodies run, rather than overriding the providers and leaving the
  shipped code unexecuted.
- [x] 4.3 Implement the three slides and the splash, transcribing copy, spacing
  and type from `71:2`, `71:37`, `71:103` and `71:162`. Verify:
  `onboarding_screen_test.dart` asserts three slides, the indicator following
  swipes, Skip absent on the last slide, and the forward action finishing.
- [x] 4.4 Wire the router to choose between onboarding and the shell at startup.
  Verify: `test/app/router_test.dart` group `startup` — opens on the splash and
  not on a destination, a first run reaches the introduction, a returning run
  goes straight to the shell with Home active, and finishing records completion
  exactly once before landing on Home. `--dart-define=MONETA_INITIAL_ROUTE` was
  not taking effect, so `/splash` became the router's default, which is what the
  design specifies anyway.

  Two gaps found while closing this task, both now fixed:
  `router_test.dart` mentioned neither splash nor onboarding, so 4.4's stated
  verification did not exist; and `splash_screen.dart` sat at **0% coverage**
  (26 lines, carrying the first-run decision) because `features/*/presentation`
  is not in `tool/coverage_critical.txt`. `splash_screen_test.dart` now covers
  the brand copy, both decisions, that a fast read still waits out the minimum so
  the splash cannot flash, that a slow read holds it, that it hands over once,
  and that it stays silent after being navigated away from.

  Four mutations confirm these tests discriminate: inverting the first-run branch
  kills 3, dropping the completion write kills exactly the completion test,
  removing the minimum-duration wait kills the flash test, and removing the
  `mounted` guard kills the unmount test.

## 5. Close-out

- [x] 5.1 Run the full gate, update `figma-map.md` with Button, PaginationDots and
  the onboarding screens. Verify: `bash tool/verify.sh --change onboarding-flow`.
  The map also gained the pages actually inspected (`5:14`, `5:17`, `29:70`,
  `107:75`) in place of the stale claim that no screen frames were reachable, a
  `Screens implemented` section naming the four nodes and the eight screens on
  that page still unbuilt, and a duplicate `PaginationDots` row was removed.
- [x] 5.2 Run on the simulator and commit a screenshot of each slide. Verify: the
  screenshots match the Figma frames side by side.
  **Partially done, and the shortfall is recorded rather than papered over.**
  Committed: `splash-ios.png`, `onboarding-slide-1-ios.png`,
  `second-launch-home-ios.png`, plus the uninstall → launch → external-write →
  relaunch sequence proving the introduction shows exactly once and that the real
  platform plugin applied migration v2 (`user_version` = 2, `settings` present,
  empty until completion).
  **Not done:** slides 2 and 3 on device. Tap injection was unavailable —
  the native simulator integration needs `sudo xcode-select -s` and the
  AppleScript fallback needs assistive access, neither grantable from this
  session. Those slides are covered by widget tests but their type and spacing
  have not been compared against `71:103` and `71:162` on a real device.
  A misnamed `onboarding-01-02-ios.png` was removed: it showed slide 1 only,
  while its name implied two slides.

## 6. Remediation after pre-archive review

The `change-verifier` agent returned **do-not-ship** on the first archive
attempt, with five blocking findings. All five are fixed below. Each was verified
independently before being acted on — the agent has been wrong before, and one of
its own findings (a mutation it reported as caught) turned out to need a second
look.

- [x] 6.1 **A failed completion write no longer traps the user.**
  `completeOnboardingProvider` awaited a store that throws when the database
  cannot open, inside an async navigation callback — the exception escaped and
  `context.go` never ran, so the last slide simply stopped responding. D5's
  reasoning covered the read and was never extended to the write. The existing
  test `a failed write does not crash the caller` closed the database while
  keeping the store object, so `writeBool` returned `Err` and it passed; it read
  as coverage of this case and was not. Verify: a new test overriding the store
  provider to throw; removing the guard fails it.
- [x] 6.2 **`OnboardingIllustration` geometry fixed, and given the test file it
  never had.** Only horizontal positions were scaled, so ring, halo and glyph
  were concentric at exactly 353px and nowhere else — about 20px apart at 280.
  It also never scaled down its band height, and now never scales *up*, so a
  tablet gets the authored illustration centred rather than a magnified one.
  Its 100% line coverage came from the screen test rendering it in passing:
  mutating it to ignore `chartSlot` entirely changed nothing anywhere.
  Verify: `onboarding_illustration_test.dart`, 16 tests, concentricity asserted
  at five widths. Three mutations caught (ignore `chartSlot`, shrink a dot,
  unscale the glyph's top). My first version of the dot-size test compared the
  rendered width to the same constant it was checking and could not fail —
  rewritten against Figma's literals.
- [x] 6.3 **Button foreground and label style now asserted on the rendered
  widget.** Both went through the static lookup tables and never through the
  widget. Repointing the label colour to `colors.income`, and collapsing `lg`'s
  label style onto `sm`'s, each passed the entire suite. `tasks.md` 2.1 claimed
  the 45-combination loop asserted "background, foreground and height"; it
  asserted height and did-not-throw. Verify: the loop now reads the rendered
  `Text`'s style; three mutations caught. Trailing-icon branch covered too — it
  was the component's only unexecuted code.
- [x] 6.4 **The gallery guard can now fail.** It asserted a hardcoded list of six
  component names, so the requirement "renders every component in every variant"
  was unenforceable: Button (45 variants), PaginationDots, OnboardingIllustration
  and TransactionRow were all missing while it passed. Replaced with a scan of
  `lib/design_system/{atoms,molecules,organisms}` for public widget classes.
  `AmountSlot` is exempted with a stated reason; `MonetaIcon` maps to the `Icons`
  section. All four components added — including TransactionRow, which predates
  this change. Verify: deleting a section from the catalog fails the guard.
- [x] 6.5 **Spec deltas written for the three capabilities that had none.**
  The change modified `design-system/components`, `design-system/tokens` and
  storage, and carried a delta only for `onboarding`. Archiving as it stood would
  have shipped the 45-variant Button, PaginationDots, OnboardingIllustration,
  schema v2 and `PreferencesStore` as behaviour with no requirement anywhere.
  Also corrected two false statements now in the authoritative spec set: the
  typography requirement said "exactly the eight" text styles while nine are
  implemented — and the guard test had been edited from 8 to 9 in `973a0d0` to
  make it pass, which is CLAUDE.md rule 5 and was not disclosed. The requirement
  no longer states a count, because the count goes stale every time a screen is
  built. And the `Transaction row` requirement asserted "Figma contains no
  transaction row and no screen frames" — the twice-wrong claim, embedded in a
  SHALL. Verify: `openspec validate onboarding-flow --strict`.
- [x] 6.6 **Non-blocking findings cleared.** The frame-stability test asserted the
  forward button's rect, but that button sits below an `Expanded` and cannot move
  — making the Skip slot's height conditional on `isLast`, the exact 44px jump
  the slot prevents, passed it; now asserted on the `PageView` and the
  illustration. (A flat `height: 0` does *not* fail the new test, and correctly
  so: every slide shifts equally, so the frame is still stable. My earlier
  wording invited the stronger reading.)
  `MonetaButton` was using the deprecated invented spacing scale, the risk
  `design.md` named and left to review. `border-strong` and `body/lg` were used
  in shipped UI for a whole change without a row in `figma-tokens.md`, whose own
  first line requires one; a typography test comment claimed four missing styles
  were recorded there and they were not. `figma-map.md` still carried the "no
  screen frames" claim and still listed `text-secondary` as not observed. The
  unused `readBoolOr` and its 20 lines of tests are gone. `design.md` named two
  test files that do not exist. A new section lists every value in code with no
  recorded Figma inspection, rather than implying all of them are transcriptions.

**Not fixed, deliberately:** slides 2 and 3 still unverified on device (5.2);
`_Spinner` is a static ring rather than an animation, and its 2px stroke now
carries a `// design-token-ignore` with a reason — removing that annotation still
passes `check_design_tokens.dart`, so it documents a CLAUDE.md rule about raw
values in `atoms/` rather than silencing a gate finding; no test at a surface size
other than 393×852; `transaction_providers.dart` sits at 12.5% coverage after
this change edited it; and the values listed in `figma-map.md` under "no recorded
inspection" have not been re-read from Figma.

## 7. Remediation after the second review

`change-verifier` returned do-not-ship again — not because the first round was
faked (it broke each fix to check) but because three findings were the same
species as the ones just closed, and two scenarios I had just written into the
spec set claimed enforcement that did not exist. That is the more useful result
of the two rounds: the first found bugs in the code, the second found that my
*fixes* had the same blind spot as the code.

- [x] 7.1 **`OnboardingIllustration` still ignored its `glyph`.** Hardcoding it so
  all three slides drew the same icon passed 617/617. My own new test asserted
  `findsOneWidget` on a key that always exists, and
  `onboarding_screen_test.dart`'s `every slide shows its own title, body and
  glyph` asserted the title only — body and glyph were in the name and in no
  assertion. Now asserts the rendered `MonetaIcon.icon`, its size and its colour,
  and the screen test checks each slide's body text and the illustration's glyph
  and chart slot. Verify: the hardcode mutation now fails.
- [x] 7.2 **Three of five Button styles' label colour was asserted against
  itself.** The 45-loop compares the rendered colour to `foregroundFor(...)`,
  which catches a broken wiring and nothing else. Repointing
  secondary/tertiary/ghost to `colors.income` passed all 617 tests; only primary
  and disabled were pinned to a token. Now every style's normal and disabled
  label colour is pinned by name, plus a test that a new style cannot be added
  without pinning it. Verify: the repoint mutation now fails.
- [x] 7.3 **The `figma-tokens.md` cross-check now exists.** The tokens delta
  written in 6.5 says a token with no row in that file fails verification.
  Nothing read the file — adding a text style with no row passed 269 token tests.
  That is 6.5's own defect one level down: a requirement asserting an enforcement
  that isn't there. `token_provenance_test.dart` parses the doc's tables and
  checks every shipped text style and colour against them, with vacuity guards so
  a reformat that breaks the parsing fails loudly instead of passing green.
  Verify: renaming `bodyLg` to an undocumented name fails it.
- [x] 7.4 **The gallery guard now checks variants, and sees three declaration
  forms it missed.** Trimming Button from 45 variants to 2 passed the whole
  suite: the scan checked presence only, while `gallery_catalog.dart`'s own
  comment claimed each count was enum-derived — true of the six original sections
  and none of the four added. Counts now derived for all four. The scan also
  missed a generic `class Foo<T> extends StatelessWidget`, a `dart format`-wrapped
  `extends` clause, and any widget in a subdirectory; confirmed by probe, all
  three now caught, probes removed.
- [x] 7.5 **The proposal's bookkeeping matches its deltas.** It declared one new
  capability and one modified while the change ships four, and still listed six
  SVG assets that task 4.1 dropped. It also described the preferences store as
  "the existing preferences work — which does not exist yet": a new capability
  written up as an existing one, which is plausibly how it came to have no delta.
- [x] 7.6 **Two over-claims in section 6 corrected** — the height-0 mutation
  sentence, and 3.1 crediting the wrong file with the v1 → v2 upgrade proof.

**Still not fixed, in one place rather than implied:** slides 2 and 3 unverified
on device; `_Spinner` static; no test at a surface size other than 393×852;
`transaction_providers.dart` at 12.5% coverage, outside `coverage_critical.txt`;
`OnboardingIllustration` untested at an out-of-range `chartSlot` and under an
unbounded-width parent; and every value in `figma-map.md`'s "no recorded
inspection" table still unread from Figma.
