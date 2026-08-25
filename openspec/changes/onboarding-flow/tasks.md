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
- [x] 7.4 **The gallery guard now checks variant *counts*, and sees three more
  declaration forms.** (Counts, not variants — round 3 was right to pull that
  wording up. Checking that a variant *builds* what its label says is 8.4 below.) Trimming Button from 45 variants to 2 passed the whole
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

## 8. Remediation after the third review

Third do-not-ship, same pattern a third time: each round's fix asserted something
narrower than the requirement it claimed to enforce, and this file then recorded
the narrower thing as done. Fifteen mutations survived round 2 — including a
straight reintroduction of round 1's scaling bug on the four accent dots, and two
ways to satisfy round 2's brand-new provenance gate vacuously.

The pattern is worth naming rather than just fixing again: **I keep writing the
assertion that would have caught the specific bug I just saw, then describing it
as covering the requirement.** The dots were outside "both axes scale by the same
factor". `fontSize` was outside "label style". Presence was outside "every
variant". Colours and type were outside "every token".

- [x] 8.1 **Round 1's bug, reintroduced on the dots, is now caught.** The dots'
  `top` could go back to unscaled with the suite green: concentricity was
  asserted for ring, halo and glyph only, and the dots were checked at the design
  width alone, where the scale factor is 1.0 and unscaled is indistinguishable
  from scaled. Position and diameter of all four are now pinned to Figma literals
  at 353, 280 and 240px. Five surviving mutations now fail: unscaled dot `top`,
  opacity 0.5→1, a dot moved to (0,0), `haloSize` 212→190, and dots 1–3 ignoring
  `chartSlot` (only dot 0's fill was ever checked). The opacity assertion also
  compared against the constant it was checking — the same self-referential trap
  I had rewritten four lines above it.
- [x] 8.2 **Four Button table entries pinned.** `lg`'s label style could be
  repointed to another 16px style, losing its semibold, because round 2 pinned
  `fontSize` only. `horizontalPadding` and `iconSize` were pinned nowhere, and
  the icon test asserted the rendered size against the enum it came from. The
  tertiary border was asserted `isNotNull`, and the disabled tertiary border not
  at all. All five mutations now fail. My first attempt at the padding test
  compared overall rendered widths, which cannot work — `pumpButton` constrains
  the button to 353px — so it now reads the `Padding` widget out of the tree.
- [x] 8.3 **The provenance check is kind-scoped and covers spacing and radius.**
  Round 2's version could be satisfied by borrowing an unrelated row: an
  undocumented colour called `primary` matched `text-primary`, and a text style
  called `xl` matched the `xl` row of the *spacing* comparison table. It also
  checked only colours and type — so the invented spacing scale, the very thing
  the requirement cites as its motivation, was outside it. Now parses the doc by
  section, matches within kind, and covers colours, type, radius and the
  Figma-named `space/*` steps. Three probes now fail.
- [x] 8.4 **The gallery checks that a variant builds what its label says.**
  Pointing all 45 Button variants at one primary/md/normal button, labels
  untouched, passed everything. Also widened the class regex: `final class` is
  this repo's house style and `^class` missed every one — the fourth and fifth
  declaration form after round 2 closed three.
- [x] 8.5 **The tokens requirement no longer ships false.** "Every value in the
  token layer SHALL have a row in `figma-tokens.md`" would have been false the
  instant it folded in: `motion.dart` ships five values that deliberately have
  none, and the untouched sibling requirement in the main spec set explicitly
  blesses that. Scoped to Figma-derived values, with the non-Figma case stated as
  its own rule rather than left as a contradiction between two requirements.
- [x] 8.6 **`design-system-corrections` flagged so archiving it cannot restore the
  false claim.** Its frozen delta still MODIFIES `Transaction row` with "Figma
  contains no transaction row and no screen frames". Archiving it after this
  change would have put that back into the authoritative specs a third time and
  dropped the new `The divergence from Figma is recorded, not silent` scenario.
  Two rounds missed this; it is not in `onboarding-flow`'s own files, which is
  presumably why.
- [x] 8.7 **Residue.** `typography.dart`'s header still said "The eight named text
  styles" — the count the delta removed from the requirement. The Button
  requirement listed the fifth style as `danger` while the enum, the gallery
  label and the code all say `destructive`. New scenarios added for the size
  table, the border table and label/widget agreement, so the specs now describe
  what the tests check rather than more than they check.

## Still not fixed

Previously headed "the accurate list". It was not — round 4 found eleven
categories missing from it. Dropping the adjective: this is what I know about, and
the last three reviews each found something that was not on it.

**Verification gaps:**
- Slides 2 and 3 never seen on device. Tap injection unavailable here: the native
  simulator integration needs `sudo xcode-select -s` and the AppleScript fallback
  needs assistive access.
- No test at any surface size other than 393×852. The placeholder test font makes
  measured overflow at smaller sizes uninterpretable, so this needs goldens on a
  fixed platform rather than another widget test.
- `lib/features/transactions/presentation/transaction_providers.dart` at 12.5%
  (1/8 lines). `features/*/presentation` is not in `tool/coverage_critical.txt`
  at all — the same blind spot that let `splash_screen.dart` reach 0%.
- `OnboardingIllustration` untested at an out-of-range `chartSlot`, and under an
  unbounded-width parent, where `width: double.infinity` under a `LayoutBuilder`
  would throw. Not reachable from the current screen.
- `MonetaPaginationDots` untested at `count: 1` and at a negative `activeIndex`.
- The `Swiping matches the buttons` scenario's **AND** clause — that the forward
  action still finishes on the last slide — is not reached *by swiping*.
- Elevation tokens are not covered by the provenance check, though its parser can
  read the section. Colours, type, radius, static spacing and layout are.

**Requirements not fully satisfied:**
- `Full variant coverage` in the main spec set says a partially implemented set
  "is not complete". `TransactionRow` ships 2 of `29:70`'s 4 variants. The
  divergence is documented; the SHALL is not met.
- `MonetaButton` ships `leadingIcon`, `trailingIcon` and `expand`, and
  `MonetaPaginationDots` a `semanticLabel`, that no requirement asks for and no
  gallery variant renders — so "every component in every variant" does not reach
  that API.

**Values in code never read from Figma** — the table in
`docs/design-system/figma-map.md` under "Values used in code with no recorded
inspection". Pinning them in tests stops them drifting; it does not verify them.
The dot positions are listed there; the ring/halo/glyph placements (45.5/3,
70.5/28, 140.5/98) were not, and now are.

**Fidelity divergences recorded but not reconciled:** `TransactionRow` vs `29:70`
(disc 32/40, height 56/≥64, gutter 16/20, no `· account`, no Transfer or
Pending); BottomNav renders 59 against Figma's 64; BalanceCard stat labels use
`captionMd` where Figma authors `label/sm`; no tabular figures on amount styles;
the deprecated invented spacing scale still used by every pre-existing widget;
`figma-map.md` still missing roughly 36 components across three pages; Light mode
never investigated.

**Cosmetic:** `_Spinner` is a static ring, not an animation. Its 2px stroke
carries a `// design-token-ignore` with a reason; removing the annotation still
passes `check_design_tokens.dart`, so it documents a CLAUDE.md rule about raw
values in `atoms/` rather than silencing a gate finding.

**Not machine-guarded:** the ⛔ warning on `design-system-corrections` is prose.
Nothing stops someone archiving that change and restoring the false Transaction
row claim; it depends on the warning being read.

## 9. Remediation after the fourth review

Twelve mutations survived round 3, and the diagnosis was the same for the fourth
time: *I keep asserting the axis I just watched break, then recording the
requirement as covered.* Dots-fill fixed but not dots-opacity. `normal` and
`disabled` pinned but not `loading`. Button's labels checked but not the other
nine sections'. `final Color` scanned but not `static const Color`.

So this round the fix is not another axis. **Every check below is exhaustive by
construction** — it enumerates from the enum, the catalog or the file rather than
from a hand-written list, so there is no next axis to forget.

- [x] 9.1 **The gallery checks are now one pass over every section.** Ten
  hand-written per-section tests became two generic ones: no two variants of any
  component may build the same widget, and a label that names a property must
  match the widget built. Both walk `galleryCatalog`, so a new section is covered
  the moment it is added. Backed by `_describe`, a `switch` with **no default** —
  adding a component without teaching it about the new type is a compile error,
  which is what stops the coverage silently narrowing again. Four mutations now
  fail: BudgetCard's three states collapsed, all 24 CategoryIcon variants
  collapsed, and two `Slot=N` labels swapped (twice — the first fix skipped
  digit-valued claims, so `Slot=4` was not checked at all).
- [x] 9.2 **The class scan matches every class, not widget-looking superclasses.**
  `class MonetaStepDots extends MonetaPaginationDots` walked past a
  `\w*(?:Widget|State)` pattern — the third superclass pattern to be widened and
  then evaded. It now matches **every** class declaration in those directories;
  each must be either in the gallery or in an `exempt` set with a stated reason.
  A widget can extend anything, so no superclass pattern can be made
  exhaustive; requiring an explicit decision can.
- [x] 9.3 **The provenance check reads every declaration form and every kind it
  can parse.** It matched one form per kind, so a `static const Color`, a
  `TextStyle` getter, a `TextStyle` left out of `all`, and a length not prefixed
  `space` were each invisible — four separate probes walked past. It now matches
  `final`, `static const`, initialised fields and getters, and covers colours,
  type, radius, the static spacing scale and `MonetaLayout`. Turning it on
  immediately found four real gaps: `violet600`, `violet500`, `mint600` and
  `violet900Canvas`, the gradient stops, documented in prose but in no row.
  Two matcher holes closed as well: a text style renamed to a bare `sm` borrowed
  the row for `label/sm`, so the group cross-product is now gated on the field
  name containing a hyphen unless the kind has exactly one group (colour, radius
  and spacing have bare field names — `canvas`, `pill`, `space0` — and one prefix
  each, so there is nothing there to borrow from).
- [x] 9.4 **`fabSlotWidth = 72` had no source, and the layout requirement was
  false.** The requirement added in 8.5 says every Figma-derived value has a row;
  `MonetaLayout` had no check at all, and the doc's layout table was keyed by
  prose ("Screen frame", "FAB") so no check could have read it. Re-keyed by the
  Dart identifier, and `fabSlotWidth` is now recorded as **not observed —
  derived** (56 plus 8 clearance each side) both in the doc and in its own doc
  comment. That is the third value found to be invented after being written as
  though transcribed.
- [x] 9.5 **The full Button state matrix and the full border table are pinned.**
  `loading` was the one state with no token pin, so its foreground and background
  could be anything across 15 of 45 combinations. The border test enumerated
  three styles by hand and omitted `secondary`. Both now iterate
  `MonetaButtonStyle.values` × `MonetaButtonState.values`.
- [x] 9.6 **The illustration's cluster position and all four dot opacities are
  pinned.** Concentricity does not pin position: translating ring, halo and glyph
  down 12px or left 20px kept them concentric and passed. The absolute
  placements are now asserted at two widths, the "and centres" half of the
  wide-screen scenario is tested, and the opacity check reads all four dots
  instead of the first.

**Where this leaves it.** Twelve of twelve round-4 mutations now fail, and I
re-ran every earlier round's mutations too. But three rounds of "this one is
fixed" should discount that claim on its own: the honest summary is that the
checks are now generic rather than enumerated, which is the first structural
change in four rounds rather than another patch, and the surviving-mutation count
is the only number that has stayed honest — it went 5 → 15 → 12 → 0 against the
attacks tried.
