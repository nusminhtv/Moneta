# Figma → Flutter map

Source of truth: Figma file `kEYXQUyhXLZITkNxAHRVlf`
("Moneta — Personal Finance App").

**Check this table before implementing anything from Figma.** If a node already
has a widget, extend it; do not create a second implementation.

## ⚠️ This map is incomplete, and was twice wrong about why

The file's Cover states it is a training file with **74 screens**, 37 variant
sets, 119 variables and **twelve deliberate mistakes**, and points at a
`📁 Screen Index` page and a `🔧 Utilities / Known Deviations` answer key.

Two corrections, in order, because the reasoning matters more than the conclusion:

1. This document first asserted **"the file contains no screen frames"**. False.
2. It was then corrected to **"our access reaches only three pages"**. Also false.

Both came from the same mistake: `get_metadata` with no `nodeId` returns three
pages, and that was treated as the file's contents. Querying a concrete node
reaches pages the listing never showed — `5:14` is `📱 01 Onboarding & Auth`,
twelve finished screens, each with an annotation frame specifying its purpose,
components, states and data.

**So the design was there the whole time.** Screen layouts this project recorded
as its own decisions — see ADR 0003 and ADR 0004 — were decided against a design
that existed and was never opened. Those ADRs are not merely provisional; their
stated premise is false and they need reconciling against the real screens.

The component inventory below is likewise a floor, not a ceiling. Screens
reference `Button/Primary`, `Button/Secondary`, `TextField/Filled`,
`TextField/Error`, `Checkbox`, `Divider/Subtle`, `Select`, `ListRow` and
`SectionHeader`, none of which are on the Organisms page. `text-secondary`
(`#9aa3b4`) is recorded as "not observed" in `figma-tokens.md` and appears in
every annotation frame.

Method note for anyone extending this map: **query nodes, do not enumerate pages.**

## What this map has actually inspected



| Page | Node | Contents |
| --- | --- | --- |
| `🎨 Foundations / Iconography` | `5:7` | 50 icons (24×24, stroke weight 1.75, incl. `brand-google`, `brand-apple`) + sizing/colour/swapping rules |
| `🧩 Components / Organisms` | `5:11` | 14 component sets, listed below |
| `📱 01 Onboarding & Auth` | `5:14` | 12 screens, each with a sibling annotation frame |
| `📱 04 Budgets` | `5:17` | 7 screens, `04.01`–`04.07`. Listed here as *02* until 2026-08-28; the frames inside are named `04.xx`, so the page number was wrong, not the node id. |
| `📱 02 Home & Dashboard` | `5:15` | 6 screens, `02.01`–`02.06`, each with a sibling annotation frame. Read 2026-09-09. |
| `🧩 Components / Charts` | `5:12` | **the fourth component page** — 5 component sets, listed below. Never queried before 2026-09-09. |
| — | `29:70` | `TransactionRow`, 4 variants — a component the Organisms page does not list |
| — | `107:75` | the real `space/*` variable collection, 12 values |

The `🗂 Screen Index` is at **`5:24`** and lists nine screen pages: 01 Onboarding
& Auth (12), 02 Home & Dashboard (6), 03 Transactions (14), 04 Budgets (7),
05 Accounts & Cards (6), 06 Goals (6), 07 Insights & Reports (6),
08 Profile & Settings (11), 09 System States (6) — 74 screens, matching the
Cover's claim. Each row gives the screen's node id, priority and the components
it uses; read the table rather than guessing which components a screen needs.

## The full component library, read 2026-08-25

The three component pages, queried by node id. This closes the "~36 components
unmapped" gap that this file carried since the first Figma pass — the pages were
never missing, they were never queried. `get_metadata` with no `nodeId` still
returns only three pages; `5:9` and `5:10` are not among them.

**Atoms — page `5:9`**

| Component | Node | Variants |
| --- | --- | --- |
| Button | `13:2` | 45 (5 styles × 3 sizes × 3 states) — **done** |
| Badge | `17:32` | 10 (5 tones × 2 sizes) |
| Chip | `17:65` | 6 (3 types × selected) |
| IconButton | `20:114` | 18 (3 styles × 3 sizes × 2 states) |
| FAB | `20:125` | 2 (Standard, Extended) |
| Avatar | `21:121` | 12 (3 types × 4 sizes) |
| Divider | `21:126` | 4 (2 orientations × 2 tones) |
| ProgressBar | `21:139` | 6 (3 states × 2 sizes) — **done** |
| Toggle | `25:198` | 4 |
| Checkbox | `25:229` | 6 (3 states × disabled) |
| Radio | `25:238` | 4 |
| CircularProgress | `25:272` | 9 (3 states × 3 sizes) — **done** |
| CategoryIcon | `33:311` | 24 (8 categories × 3 sizes) — **done** |
| GoalRing | `94:132` | 8 percentages |

**Molecules — page `5:10`**

| Component | Node | Variants |
| --- | --- | --- |
| TextField | `27:44` | 5 states |
| TransactionRow | `29:70` | 4 types (Expense, Income, **Transfer**, **Pending**) — 2 of 4 done |
| DateGroupHeader | `29:71` | 1 |
| SearchField | `35:38` | 2 |
| ListRow | `35:113` | 5 (Chevron, Value, Toggle, Badge, None) |
| StatTile | `35:137` | 3 directions — **done** |
| EmptyState | `35:166` | 2 (HasAction true/false) |
| AmountInput | `36:76` | 2 — **done** |
| NumpadKey | `36:91` | 4 |
| Numpad | `36:92` | 1 |
| SegmentedItem | `36:167` | 2 — **done** |
| SegmentedControl | `36:168` | 1 — **done** |
| TabItem | `38:109` | 4 (2 styles × selected) |
| Tabs | `38:110` | 1 |
| Select | `38:131` | 2 |
| Skeleton | `38:139` | 4 shapes (Line, Circle, Card, Row) |
| SectionHeader | `55:107` | 1 |
| AmountSlot | — | ours, no Figma source |

**Organisms — page `5:11`**

| Component | Node | Variants |
| --- | --- | --- |
| StatusBar | `39:2` | 1 |
| AppBar | `39:112` | 4 (LargeTitle, TitleBack, TitleActions, Transparent) |
| BottomNav | `39:243` | 4 — **done** |
| BalanceCard | `40:161` | 2 — **done** |
| AccountCard | `40:209` | 4 types |
| BudgetCard | `40:256` | 3 — **done** |
| GoalCard | `40:257` | 1 |
| Dialog | `42:284` | 3 kinds |
| Snackbar | `42:305` | 3 tones |
| Banner | `42:329` | 4 tones |
| BottomSheet | `59:211` | 1 |
| Logo | `70:205` | 1 |
| PaginationDots | `70:223` | 3 — **done** |
| OtpField | `70:263` | 3 |
| OnboardingIllustration | `71:59` | themed per slot — **done** |

45 component sets. Seven are implemented. `TransactionRow` is implemented at 2 of
its 4 authored variants, which `Full variant coverage` in the spec set does not
allow — recorded as outstanding.

## Component sets in Figma

| Component | Node | Variants | Widget | Status |
| --- | --- | --- | --- | --- |
| StatusBar | `39:2` | — | | not started |
| Button | `13:2` (Atoms) | 5 styles × 3 sizes × 3 states = 45 | `design_system/atoms/moneta_button.dart` | done |
| PaginationDots | `70:223` | Active=1/2/3 | `design_system/molecules/pagination_dots.dart` | done — geometry (dot 7, active 22, gap 7) **not recorded against a node inspection**; see below |
| OnboardingIllustration | `71:59` | themed per chart slot | `design_system/molecules/onboarding_illustration.dart` | done — drawn natively, all values are tokens |
| AppBar | `39:112` | LargeTitle, TitleBack, TitleActions, Transparent | | not started |
| BottomNav | `39:243` | Home, Transactions, Insights, Profile | `design_system/organisms/bottom_nav.dart` | done |
| BalanceCard | `40:161` | Default, Masked (`40:137`) | `design_system/organisms/balance_card.dart` | done |
| AccountCard | `40:209` | Bank, Cash, E-wallet, Credit | | not started |
| BudgetCard | `40:256` | OnTrack, NearLimit, Over | `design_system/organisms/budget_card.dart` | done |
| ProgressBar | `21:139` | Under/Near/Over × Sm/Md | `design_system/molecules/progress_bar.dart` | done |
| CategoryIcon | `33:311` | 8 categories × Sm/Md/Lg | `design_system/molecules/category_icon.dart` | done |
| TransactionRow | **none — designed** | expense / income / masked | `design_system/molecules/transaction_row.dart` | done ([ADR 0003](../adr/0003-transaction-row-layout.md)) |
| AmountSlot | **none — internal** | — | `design_system/molecules/amount_slot.dart` | done |
| GoalCard | `40:257` | — | | not started |
| Dialog | `42:284` | Informational, Confirm, Destructive | | not started |
| Snackbar | `42:305` | Success, Error, Info | | not started |
| Banner | `42:329` | Warning, Danger, Info, Success | | not started |
| BottomSheet | `59:211` | — | | not started |
| Logo | `70:205` | — | | not started |
| OtpField | `70:263` | Empty, Partial, Complete | | not started |

## Screens implemented

From `📱 01 Onboarding & Auth` (`5:14`). Copy, glyph and chart slot were
transcribed from the frame, not invented; each slide's annotation frame was read
first.

| Screen | Node | Implementation | Status |
| --- | --- | --- | --- |
| Splash | `71:2` | `features/onboarding/presentation/splash_screen.dart` | done |
| Onboarding 1 — "Every account in one place" | `71:37` | `onboarding_slide.dart` + `onboarding_screen.dart` | done |
| Onboarding 2 — "Budgets that warn you early" | `71:103` | same | done |
| Onboarding 3 — "Save for what matters" | `71:162` | same | done |

The remaining eight screens on that page — sign-in, sign-up, forgot password, OTP,
PIN set, PIN confirm, PIN unlock, biometric — are **not implemented**. They need
the `TextField`, `OtpField` and `Checkbox` sets, and an `AuthService` seam.

## Foundations

| Figma | Node | Implementation | Status |
| --- | --- | --- | --- |
| Icon set (50) | `5:7` | `assets/icons/*.svg`, `lib/design_system/atoms/moneta_icon_name.dart`, `moneta_icon.dart` | done |
| Colour tokens | various | `lib/design_system/tokens/colors.dart` | done |
| Type scale (8 styles) | various | `lib/design_system/tokens/typography.dart` | done |
| Radii / elevation / spacing | various | `tokens/radii.dart`, `elevation.dart`, `spacing.dart` | done |
| Motion | *absent from Figma* | `tokens/motion.dart` — Material-derived, marked not-Figma-derived | done |

## Components with no Figma source

One component exists that Figma does not describe:

- **`AmountSlot`** — purely internal layout machinery, introduced after the same
  overflow defect appeared in two components. It has no visual identity of its own,
  which is also why the gallery-completeness check exempts it by name.

**`TransactionRow` was listed here and should not have been.** This said "the
file has no transaction row and no screen frames". Both halves are false: node
`29:70` is a transaction row with four variants, and `5:14` is twelve finished
screens. [ADR 0003](../adr/0003-transaction-row-layout.md) scored three layout
alternatives against a premise that did not hold, and is flagged accordingly.
The implementation still diverges from `29:70` — disc 32 vs 40, height 56 vs ≥64,
gutter 16 vs 20, no `· account` meta line, Transfer and Pending absent — and that
reconciliation is outstanding, not done.

## Values used in code with no recorded inspection

These are implemented and asserted, but the assertions compare the code to
literals in a test rather than to anything read from Figma and written down. That
is the exact condition that produced the invented spacing scale — a plausible
number, consistently applied, wrong.

| Value | Where | Status |
| --- | --- | --- |
| `dotSize 7`, `activeDotWidth 22`, `gap 7` | `pagination_dots.dart` | no node inspection recorded |
| `fabSlotWidth 72` | `spacing.dart` (`MonetaLayout`) | **not observed — derived**, and now labelled as such in both the code and `figma-tokens.md`. Figma authors the FAB and the bar but no slot width. Found by the provenance check on its fourth revision. |
| Button paddings 14 / 20 / 24, icon sizes 16 / 20 / 24, heights 36 / 44 / 56 | `moneta_button.dart` | heights are quoted from `13:2`'s annotation in code; the paddings and icon sizes are not |
| CircularProgress stroke widths 6 (Md) and 10 (Lg) | `moneta_circular_progress.dart` | **not observed — derived**. Figma exports the arcs as SVG assets, so the diameters are readable from the node and the stroke widths are not. The ratio matches the exported arcs by eye; nothing was measured. |
| CircularProgress stroke width **4 (Sm)** | `moneta_circular_progress.dart` | **not observed — derived**, and it was missing from this table until 2026-09-09 while 6 and 10 were listed. It reaches the painter through `strokeWidth ?? 4`, a default whose null *also* encodes "no label" — so someone who measures Sm's real stroke and writes `sm(48, 4)` would silently give Sm a percentage label it is not meant to have. Worth separating those two meanings before the value is corrected. |
| Illustration `bandHeight 268`, `haloSize 212`, `ringSize 262`, `glyphSize 72`, the ring/halo/glyph placements (45.5/3, 70.5/28, 140.5/98) and the four dot positions | `onboarding_illustration.dart` | transcribed from the exported SVGs, not re-verified against `71:59` after the rewrite |

Listing them is not the same as fixing them. Re-reading these nodes is
outstanding work.

## Recorded deviations and resolved ambiguities

| # | What | Resolution |
| --- | --- | --- |
| 1 | `display/amount-xl` and `heading/h1` report `letterSpacing: -1` in Figma's style summary, but their CSS emits `-0.4px` and `-0.28px` | The summary value is a **percentage**. Implemented as absolute −0.4 and −0.28. Details in `figma-tokens.md`. |
| 2 | The proposal said 51 icons | The page holds **50**. Corrected in the proposal, spec and tasks rather than shipping a catalogue that quietly disagreed with the spec. |
| 3 | `brand-google` carries four colours; every other icon is monochrome | `MonetaIconName.preservesColour` marks it, and `MonetaIcon` skips tinting for it. Tinting would flatten Google's mark into one colour. |
| 4 | Chart *base* colours are not emitted as Figma variables | Read from each exported glyph's `stroke` and visually confirmed against a screenshot of `33:311`, since a light-mode export would have given plausible-but-wrong values. |
| 5 | Figma has no `radius-sm`, `elevation/1` or `elevation/2` on any node read | Left unimplemented rather than invented. **`text-secondary` was wrongly on this list**: it is authored at `107:75` and is now implemented and used throughout the onboarding screens. The entry recorded a search that had not looked in the right place, in the same way the page listing was mistaken for the file. |
| 6 | BalanceCard's two stats are `shrink-0` in Figma | Made flexible with single-line ellipsis. The authored copy fits, but real balances vary in width and an overflowing row is a rendering bug, not an overflow. |
| 7 | BudgetCard's amount column is `shrink-0` in Figma, which overflows the head row once an amount is wide enough | Capped at 55% of the row width, single line, ellipsised. A plain `Flexible` would have split the row evenly and truncated the category name for nothing. |
| 8 | BottomNav tab icons are 23px in Figma, while the icon canvas is 24px everywhere else | Kept at 23 — reproducing the file rather than tidying it. Exposed as `MonetaBottomNav.tabIconSize` and asserted, so it reads as deliberate. |
| 9 | Figma's masked balance is `•• ••• ••• ₫` (space-separated); ours renders `••.•••.••• ₫` | Ours builds the mask by substituting digits in a **formatted** amount, so it inherits the locale's own separators (vi_VN uses `.`). Keeping Figma's literal spaces would have been wrong for any other locale. Dot count and width are fixed either way, so no magnitude leaks. |

## Visual verification

The gallery was run in a browser at a mobile viewport and compared against the
Figma canvas. Confirmed rendering correctly: the brand gradient and its angle,
`radius-xl` on the hero card, Plus Jakarta Sans at 40/44 for the balance, the
signed income and expense figures, the eye / eye-off swap, the masked state
hiding every digit, the amber `chart/7` category disc with its coffee glyph, the
income-green progress fill, and `radius-lg` plus the subtle border on the budget
card.

One thing worth recording, because it nearly became a false bug report: the first
screenshot showed the icons missing. They were not missing — `SvgPicture` loads
asynchronously and the screenshot was taken before the assets resolved. The
second screenshot showed all of them. Checking before "fixing" avoided a change
that would have made the code worse.

## Verified on device

### The introduction shows once — `onboarding-flow`

Three screenshots from an iPhone 16 Pro simulator (iOS 18.6), taken around a
deliberate uninstall so the first launch was a genuine first run:

| Screenshot | What it shows |
| --- | --- |
| `splash-ios.png` | `71:2` — the brand splash on a fresh install |
| `onboarding-slide-1-ios.png` | `71:37` — slide 1, with Skip, the illustration, the indicator and `Next` |
| `second-launch-home-ios.png` | the second launch going straight to Home, no introduction |

The sequence, with what each step proved:

1. `simctl uninstall` then install and launch. `PRAGMA user_version` on the app's
   own SQLite file read **2**, and `sqlite_master` listed `settings` alongside
   `transactions` — the real platform plugin applied migration v2, which the VM
   test suite (`sqflite_common_ffi`) cannot demonstrate.
2. `SELECT * FROM settings` returned **no rows** while the introduction was on
   screen. Nothing is recorded before the user finishes.
3. Wrote `onboarding_complete='true'` into that table externally, killed the
   process and relaunched. It went to Home. The flag is read from durable storage
   at startup, not from anything held in memory.

**What these screenshots do not show:** slides 2 and 3 on device. Tap injection
was unavailable on this machine — the native simulator integration needs
`sudo xcode-select -s`, and the AppleScript fallback needs assistive access, and
neither is something this session could grant itself. Slides 2 and 3 are covered
by `onboarding_screen_test.dart` (the indicator following both taps and swipes,
Skip disappearing on the last slide, the label becoming `Get started`) but their
type and spacing have **not** been compared against `71:103` and `71:162` on a
real device. Recording this rather than implying three verified slides.

### The gallery was stretching every fixed-size component

`gallery-stretch-before-ios.png` and `gallery-stretch-after-ios.png`, iPhone 16
Pro simulator, launched straight into `/gallery` with
`--dart-define=MONETA_INITIAL_ROUTE=/gallery`.

`GalleryScreen` wrapped every variant in `SizedBox(width: contentWidth)` — a
**tight** constraint. So `IconButton` sm, which is 36×36 in `20:114`, rendered
353 wide, and so had every small `Button` since the gallery was built. The
before shot is the first render of `IconButton` after it was implemented; the
defect is in the component the gallery exists to display accurately.

Nothing caught it, for two reasons worth keeping:

1. Every component's own test pumps it through `pumpMonetaWidget`, which wraps
   the child in a `Center`. Constraints there are **loose**, so stretching cannot
   occur — the harness made the defect unreachable.
2. The first fix was worse than no fix. The test hand-rolled an
   `Align + ConstrainedBox` and asserted *that*, so reverting `gallery_screen`
   to its fixed width left the suite green. It asserted its own fix. The frame is
   now `GalleryVariantFrame`, a real widget the test renders, and both
   directions are mutated: a fixed width fails, and removing the max width fails
   too (which would starve full-width cards).

Found by taking a screenshot, not by the 711 tests that were passing at the time.

### Transactions list

`docs/design-system/screenshots/transactions-ios.png` — the transactions list on
an iPhone 16 Pro simulator (iOS 18.6), reading rows written directly into the
app's own SQLite file, after the process was killed and relaunched.

What that screenshot confirms beyond what the test suite can:

- The real `sqflite` platform plugin opens the database and applies migration v1
  (the test suite runs against `sqflite_common_ffi` on the Dart VM — same SQLite,
  different binding).
- Day grouping and per-day nets are right against real data:
  `+31.635.000 ₫` for Mon 24 Aug is `32.000.000 − 320.000 − 45.000`.
- Category discs match their Figma chart slots on a real display — transport
  sky, food amber, salary mint, shopping violet.
- The note fallback works: the salary row has no note and shows `Salary`.
- Times render in the device's local zone while storage is UTC.


## What Budgets needs before it can be built

Queried `5:17` on 2026-08-28. Its seven screens instance five components the
design system does not have:

| Component | Seen on | Note |
| --- | --- | --- |
| `SegmentedItem` | `04.01`, `04.04` | period switcher, 3 up in a 44px track |
| `CircularProgress` | `04.01` (72), `04.05`/`04.06` (120) | two sizes |
| `StatTile` | `04.05`, `04.06` | 170.5 x 98, two per row |
| `AmountInput` | `04.04` | 353 x 116 |
| `BarChart` | `04.07` | 337 x 223 |

None appear on `🧩 Components / Organisms`, which is consistent with the rest of
the file: the library is larger than that page shows. There is also no budget
domain, no table and no repository — Budgets is a feature to build, not a set of
screens to draw.

### Added by `budget-components`, 2026-08-28

| # | What | Resolution |
| --- | --- | --- |
| I10 | `CircularProgress` has no TEXT property; its 62% / 88% / 100% are typed onto each instance. Annotation `04.01` names this as ledger entry I10 — one of the file's own recorded deviations. | Not copied. The Dart component takes a fraction and derives the arc, the colour and the label, and exposes no way to set the label. A ring whose number contradicts its sweep is not expressible. |
| 11 | `AmountInput`'s own Figma description says the error variant *"differs by colour only"*. | Not reproduced. `AmountInput.error` requires a message, so the type makes "error with no message" unrepresentable. Colour alone fails greyscale and fails a red-green viewer. |
| 12 | `StatTile`'s `Direction=Up` maps to income green, and its own sample reads "Spent this month / +12.4% vs last month" in green — spending more, coloured as good news. | Mapping kept as authored: direction is the caller's choice, and income up in green is correct. Changing it would make every correct use wrong to fix one wrong sample. **Resolved 2026-09-10 by annotation `81:498`**, which states the rule: *"delta colour follows MEANING, not sign"*. The existing decision was right and the sample is the error — a green "+12.4% spent" is a rise in spending coloured as good news, which is precisely a delta coloured by sign. No longer a candidate: the annotation is the file's own statement of the rule, so the sample contradicts the file, not this implementation. `StatTile` needs no change; a caller charting a rise in spending passes `StatDelta.down`, which is what `budget_detail_screen.dart` already does — its "Over by" tile is `StatDelta.down`, and "Left to spend" flips to `down` only once nothing is left. Meaning, not sign, in merged code. Still not cross-checked against the answer key at `🔧 Utilities / Known Deviations`, which has never been read — so whether the file *intends* this sample as one of its twelve deliberate mistakes is a separate, still-open question from whether it is wrong. |
| 13 | Figma's `CircularProgress` `State=Over` sample is labelled **100%**. Under this system's rule — `BudgetStatus.fromFraction`, where exactly 1.0 is the limit *reached*, not exceeded — 100% classifies as `NearLimit`. | The gallery's label-versus-widget check caught it: a 1.0 fixture rendered the warning colour under an "Over" label. The gallery fixture is 1.12. Whether Figma's sample is a mistake or a different threshold rule is **not resolved** — the answer key has not been read. |
| 14 | `StatTile` is described as 170 wide with a 13px gap, and placed on screens as 170.5 wide with a 12px gap. | The tile takes the width it is given; the screen sets the gap. Neither number is pinned in the component. |
| 15 | `radius-sm` was documented in `radii.dart` as appearing in no node read. | True of the nodes read at the time — balance card, banner, checkbox. `36:167` binds it at 10. Transcribed; the note kept and corrected rather than deleted. |

## Still open

- **The gallery cannot catch a variant shortfall.** `auth-components` proposed a
  generic `expectedVariants` field and stopped at 10 of 14 tasks. Today the guard
  is one hand-written count test per component, so a component registered with 2
  of its 18 variants passes the whole gate. Closing this needs its own change.

  **The shortfall list this entry used to carry was wrong.** It claimed nine of
  twenty-four sections were short — Checkbox 1 of 6, Divider 1 of 4, ProgressBar
  1 of 6, CategoryIcon 1 of 24, Skeleton 1 of 4, PaginationDots 1 of 3,
  TransactionRow 2 of 4, TextField 4 of 5, with IconButton and AppBar "registered
  through loops that were not counted".

  Counted from the live catalog on 2026-09-09, there are **29 sections and two
  are short**: `TransactionRow` 2 of 4 and `TextField` 4 of 5. Checkbox 6,
  Divider 4, ProgressBar 6, CategoryIcon 24, Skeleton 4, PaginationDots 3,
  IconButton 18 and AppBar 4 are all complete. The last clause was the tell — it
  admitted the method was counting `GalleryVariant(` literals in source, which
  misses every section that builds its variants in a loop, and that is exactly
  what made six complete components look 1-of-N. The table twenty lines above
  already marked ProgressBar and CategoryIcon **done**.

  This mattered beyond bookkeeping: the false count was cited in
  `budget-components` as justification for narrowing that change's own variant
  requirement.
- ~~**`BarChart`** is instanced on `04.07` (`67:712`) but appears on none of the
  three component pages.~~ **Resolved 2026-09-09: it lives on a page not yet
  queried.** See *The fourth component page* below. `BarChart` is `48:34` on
  `🧩 Components / Charts` (`5:12`). Budgets `04.07` is no longer blocked on
  finding the component — only on being scheduled.

  Worth keeping for the pattern: this entry offered two hypotheses and the
  cheaper one to test was never tested. "Appears on none of the three component
  pages" was true and the inference from it was wrong, for the third time in this
  file, and for the same reason each time — **the page listing is not the file.**

## 📱 04 Budgets — read and built, 2026-09-08

| Screen | Node | State |
| --- | --- | --- |
| 04.01 Overview | `66:91` | done |
| 04.02 Empty | `66:277` | done |
| 04.03 Create — category | `66:378` | done |
| 04.04 Create — amount | `66:488` | done |
| 04.05 Detail — on track | `67:359` | done |
| 04.06 Detail — over limit | `67:524` | done |
| 04.07 History | `67:690` | **deferred** — `BarChart` is `48:34` on `5:12`; see below |

### What the annotations said that the components did not

| # | Source | What it changed |
| --- | --- | --- |
| 16 | `04.04` | *"'Alert me at 80%' is what drives BudgetCard's NearLimit state — the 80% threshold is configurable here, so the component's warning colour is data-driven, not hardcoded."* `budget-components` had shipped `BudgetStatus.nearLimitThreshold` as a constant read by three widgets. Now a parameter defaulting to 0.8. **The design file contradicted code that was already merged.** |
| 17 | `04.03` | *"The disabled reason is stated in copy under the grid, not left to be inferred from the dimming."* An accessibility rule the spec delta had missed; the spec was corrected before implementing. Modelled as an enum carrying its sentence, because a bool cannot carry a reason. |
| 18 | `04.06` | *"There is no daily-allowance tile here — it would be negative and meaningless, so it is replaced by 'Over by'."* A tile swap, not a negative number. |
| 19 | `04.06` | *"It says WHEN the budget was passed."* Required a new domain computation — the transaction that tipped the budget over, found by walking the window in occurrence order. |
| 20 | `04.01` | *"Bottom nav stays on Home because Budgets is a Home sub-screen, not a tab."* Works because unknown locations fall back to Home; pinned by a test that also asserts Budgets is absent from the destination table. |

### Not attempted

- **`BarChart`** (`67:712`, instanced on `04.07`) — **deferred, not blocked, and
  this entry was wrong.** It said the component appears on none of the three
  component pages. True, and beside the point: it is `48:34` on the *fourth*
  page, `🧩 Components / Charts` (`5:12`), queried on 2026-09-09. Budgets —
  history is still not built, but nothing is missing except the work. It belongs
  with the Insights charts, which come from the same page.
- **`Numpad`** (`36:92`) and **`NumpadKey`** (`36:91`) exist in Figma and are
  not built. `04.04` pairs the hero amount with the numpad; the screen uses a
  hidden `EditableText` behind the figure instead — the same composition the OTP
  screen already uses. Shipping without either would have repeated the
  add-transaction bug: a form demanding a value it gives no way to enter.
- **`Snackbar`** (`42:305`) is unbuilt. Create-flow failures land on the amount
  field, which is where the problem is and does not disappear on a timer.

### Values used with no recorded inspection, added here

| Value | Where | Status |
| --- | --- | --- |
| `BudgetStepIndicator.height 3`, `gap 4` | `budget_step_indicator.dart` | read from `66:399`–`66:401`'s geometry in the node listing, not from an inspected style |
| Category-cell disabled opacity 0.35 | `create_budget_category_screen.dart` | quoted from `04.03`'s annotation text, not measured on the node |

### Rollover depth is a decision, not a transcription

Annotation `04.04` says *"Rollover changes next period's limit, not this
one's"* and stops there. It does not say whether two consecutive underspent
periods both reach the third. Implemented one window deep, with the carry
reported separately from the limit. Reasoning in
`openspec/changes/budgets-feature/design.md`.

## The fourth component page, found 2026-09-09

`get_metadata` with no `nodeId` still returns three pages. The component library
is on **four**: `5:9` Atoms, `5:10` Molecules, `5:11` Organisms, and
`5:12` **`🧩 Components / Charts`**, which nothing in this repository had ever
queried. (`5:13` is a separator page named `────────────────`.)

**Charts — page `5:12`**

| Component | Node | Variants |
| --- | --- | --- |
| ChartLegendItem | `47:47` | 9 (`Slot=1`–`8`, `Other`) |
| DonutChart | `47:48` | 1, 353×482 |
| BarChart | `48:34` | 1, 353×223 |
| LineChart | `48:76` | 1, 353×226 |
| Sparkline | `48:94` | 1, 104×34 |

So the library is **50 component sets, not 45**, and five of the components the
Insights screens need were sitting on a page the map described as absent. It was
found by querying `5:12` on a hunch after `5:11`, which is the same method note
this file has carried since August: *query nodes, do not enumerate pages.*

## 📱 02 Home & Dashboard — read and partly built, 2026-09-09

Screens at `5:15`. Every sibling annotation was read — the first time, because
`home-overview`'s own proposal and design both recorded that no Figma tool was
callable, and four of these screens were built against the frames alone.

| Screen | Node | Annotation | State |
| --- | --- | --- | --- |
| 02.01 Home — default | `52:2` | `52:362` | done |
| 02.02 Home — empty | `52:372` | `52:537` | done |
| 02.03 Home — loading | `52:547` | `52:630` | done |
| 02.04 Home — over-budget alert | `57:414` | `57:612` | done |
| 02.05 Notifications — list | `57:622` | `57:830` | done |
| 02.06 Notifications — empty | `57:840` | `57:935` | done |

All six built. `lib/features/notifications` is a new feature directory holding
`HomeNotification` and `NotificationsScreen`; the derivation lives in
`lib/app/notification_providers.dart` because `features/notifications` may not
import `features/budgets` or `features/transactions`.

`04.01`–`04.07`'s `TransactionRow` question was also settled for Home: all four
instances on `52:2` (`52:177`, `52:214`, `52:246`, `52:276`) are `Type=Expense`
or `Type=Income`. No `Transfer`, no `Pending`, so Home did not need the two
unbuilt variants.

### What the annotations said that the merged code did not

| # | Source | What it changed |
| --- | --- | --- |
| 21 | `52:362` | *"Recent list is capped at 5 rows client-side."* `homeRecentLimit` was **4**, and its comment justified it as "Figma `52:2` draws four". The frame does draw four. The annotation beside it states the rule. A drawing shows one instance of a rule; it is not the rule. |
| 22 | `52:362` | *"safe-to-spend = balance minus committed budgets minus scheduled bills to period end."* The card was being handed the total balance under the safe-to-spend label, commented "there is no budget feature yet" — true when written, false since `budgets-feature`. |
| 23 | `52:630` | *"AppBar and BottomNav render immediately; only the content area is skeletonised."* `_HomeLoading` rendered **no app bar**, so the bar appeared when data landed and pushed the page down — the exact jump the skeletons exist to prevent. |
| 24 | `52:630` | The authored skeleton composition is `Card x3, Circle x4, Line x6, Row x4`, confirmed against the geometry of `52:564`–`52:594`. The implementation had `Card x1, Line x1, Row x3`. |
| 25 | `52:362` | `SectionHeader/HasAction` + `BudgetCard x2` on the default screen. Home had **no budgets section at all**, though `home-overview`'s own spec already required `BudgetCard` there. |
| 26 | `52:537` | *"An empty state with no action is a dead end."* The first-run CTA and its first checklist row both called `onLinkAccount`, which the route never passes because Accounts is unbuilt. The app's first screen had two dead prominent controls. |
| 27 | `52:537` | *"checklist items tick off independently."* Nothing ticked. Only the budget step can tick while the screen is up: any transaction replaces it, and the account step has no feature to complete. |

### Deviations recorded here, with reasons

| # | What | Resolution |
| --- | --- | --- |
| 28 | Safe-to-spend omits the **scheduled bills** term of its authored formula. | There is no bill entity, table or concept in this codebase. Completing the formula would mean inventing a domain from one clause of one annotation — how the invented spacing scale happened. The figure is short by a term it names, and says so at the point of use. |
| 29 | Safe-to-spend subtracts each budget's **unspent remainder**, not its whole limit. | Interpretation, not transcription, so the reasoning is recorded: the annotation's two terms are parallel and both name *future* outflows. Money already spent has left the balance, so subtracting the full limit deducts it twice — a fully spent 5m budget would cost 10m of headroom, and the figure would get worse the more diligently the user recorded spending. Clamped at zero, so overspending cannot hand headroom back. |
| 30 | Home's first-run **primary CTA is "Log your first expense"**, where `52:389` authors the account action. | Accounts (page 05) is unbuilt. Fidelity here would reproduce the dead end annotation `52:537` exists to prevent. Reverts when Accounts lands. |
| 31 | A first-run checklist step with no destination renders **no chevron**, where `52:428`–`52:481` author `Trailing=Chevron` on all three. | An accessory must not promise what the row cannot deliver. The notifications spec states the same rule outright — *"a row carrying a chevron with nowhere to go is not representable"* — and allowing it on this screen would have been inconsistent with it. |
| 32 | A **completed** checklist step uses `ListRow`'s `Badge` accessory. | `52:372` authors no completed state, because nothing is complete on a first-run frame. Composing an authored variant beats inventing a visual for an unauthored state. |
| 33 | Loading skeletons keep the `Line` variant's **full-bleed width** where `52:578` and `52:581` are resized to 140 and 180. | `Skeleton` authors no width property — and neither does the Figma component; the *frame* resizes the instance. Hard-coding two unrecorded pixel widths would put raw design values in a screen. Nothing jumps vertically, which is what the annotation asks for. |
| 34 | Home shows **two** budget cards. | Frame-derived, and labelled as such in code. `52:362` lists `BudgetCard x2` in its component inventory and its Data line says nothing about a cap — unlike the recent list, where the cap is stated outright. Two is what `52:2` instances, not a rule the file states. |

### Values that were derived, then verified

Both entries below were recorded as unverified while Figma access was down, and
read once it came back the same day. **Both turned out correct.** They are kept
here rather than deleted, because a guess that happens to be right is still a
guess, and the record of *how* a value arrived is what tells a later reader how
much to trust it.

| Value | Where | Outcome |
| --- | --- | --- |
| Quick-action glyphs `repeat` (Transfer), `target` (Budgets), `award` (Goals) | `home_route_screen.dart` | **Verified, all four matched.** `52:67` = `icon/plus` (`10:29`), `52:81` = `icon/repeat` (`10:63`), `52:94` = `icon/target` (`10:20`), `52:106` = `icon/award` (`11:83`). `Style=Tonal, Size=Md` (`20:54`, 44×44) and the `label/sm` + `text-secondary` caption confirmed at the same time. |
| First-run copy: the empty-state title, and the three checklist titles and subtitles | `home_screen.dart` | **Verified, exact.** All three rows match `52:428`, `52:459` and `52:481` word for word, including the leading glyphs `icon/credit-card` (`10:25`), `icon/plus` (`10:29`) and `icon/target` (`10:20`); the empty state's title and its `icon/shopping-bag` (`11:54`) match `52:389`. This copy was written while the change believed Figma was unreachable, and it was accurate anyway. |

Two strings on `52:372` do still diverge, both deliberately — see deviation 30
and the entry below.

| # | What | Resolution |
| --- | --- | --- |
| 35 | The first-run message drops `52:389`'s opening clause. Figma authors *"Add an account and log one transaction. Moneta needs about a week of data before budgets get useful."* | The second sentence is kept verbatim. The first instructs the user to add an account, which is the one thing they cannot do while Accounts is unbuilt, and it sat directly above a CTA that had been repointed away from that step for the same reason. Reverts with deviation 30 when Accounts lands. |
| 36 | Home's app bar carries a **bell**, where `52:3` authors one action with an `icon/search` glyph. | Annotation `57:830` says the notification centre is *"reached from the Home app bar"*, and search would leave it unreachable — 5.1 would be dead code. The search glyph is almost certainly `AppBar/LargeTitle`'s default left unoverridden: that component's own sample is titled "Transactions" with a search action, and `52:3` overrides only the title. Home also has nothing to search — `SearchField` (`35:38`) is unbuilt and search belongs to Transactions. **Candidate for the twelve deliberate mistakes.** |
| 37 | The notification centre is **derived on every read**, not stored. | `home-overview`'s D3 keeps persistence out of this change. The consequence is stated rather than hidden: there is no read/unread state, and an entry disappears when the fact behind it stops being true — a budget brought back under its limit stops being reported. That is a defensible reading of a derived feed and it is **not** what a stored feed does. Durable notifications need their own change. |
| 38 | Three of the five notification kinds on `57:622` are produced; two are **left out rather than seeded**. | `57:718` is a failed account sync and `57:740` is a goal's funding progress. Accounts and Goals do not exist, so neither fact can be computed. Fabricating them would put fake content in a feed the user is meant to trust, which is worse than a shorter feed. |
| 39 | The notifications empty state keeps `EmptyState`'s default **`icon/shopping-bag`**, which reads oddly over "You're all caught up". | Both `57:861` and the first-run `52:389` carry the component default with no swap applied, so the file authors a shopping bag in a notification centre. Reproduced rather than corrected, in the same spirit as `BottomNav`'s 23px tab icons — a bell would look better and would also be inventing a glyph the file does not author. **Candidate for the twelve deliberate mistakes.** |
| 40 | `/notifications` is declared **inside the `ShellRoute`**, not in the `HOME` marker block the task named. | The marker block sits outside the shell, so a route declared there renders with no bottom navigation — precisely what annotation `57:830` calls *"a real defect, not a nitpick"*. The marker exists to keep parallel agents out of each other's files, not to override the design; Budgets resolved the same conflict the same way. A mutation moving the route into the marker fails two router tests, so this is pinned. |

### The `57:414` variant check, performed

Deviation-free: `57:517` (`Category=Shopping`) and `57:551` (`Category=Food`)
are both `Type=Expense`. Neither is `Transfer` nor `Pending`, so the over-budget
screen never needed the two `TransactionRow` variants this project has not built,
and task 4.4's stop condition did not fire. This check is why 4.4 sat implemented
but unticked for the length of the Figma outage.

### What the outage actually was

Recorded because the first diagnosis was wrong and acted on. Every Figma tool
returned *"Looks like you don't have edit access to this file"* on every node,
including `5:24` and `52:116` which had answered minutes earlier. That pattern —
reads working, then uniformly failing — was read as a rate limit on the plan.

It was the **seat**. `whoami` is the tool for this and it says so in its own
description: *"You MUST use this tool if you are experiencing file access/
permission issues or are being rate limited."* It was not called until six failed
retries later. It reported `seat: "View"`, `tier: "starter"` — and a View seat
cannot use the design-context tools at all, which is exactly what the error said
in plain words. Access returned on a `seat: "Full"`, `tier: "pro"` account.

Two lessons, neither about Figma: the error message was accurate and was read as
boilerplate, and the diagnostic tool was in the tool list the whole time.

### Known gaps on Home, recorded by the third review pass

| What | Why it is left |
| --- | --- |
| **Safe-to-spend's horizon always names the month end**, while the figure now subtracts remainders from budgets that may be weekly or yearly. `_monthEndLabel` in `home_screen.dart`. | The figure and its horizon can therefore describe different periods. Making the horizon follow the budgets means deciding what to show for a mixed set — a design decision, not a fix. The label is now tested for what it does claim (month end, local, leap years, December rollover); the mismatch is the open part. |
| **`home_route_screen.dart`'s `data:` arm has no coverage.** Router tests reach Home only through the *error* arm, because `budgetRepositoryProvider` throws with no database in the test binding. | So the route wiring — `onOpenBudget`, `onSeeAllBudgets`, the quick-action handlers and the clock read — is correct by reading and unproven by test. `lib/app` is outside `tool/coverage_critical.txt`, so no gate catches it. Closing it needs one widget test through `HomeRouteScreen` with the repository, budget list and clock overridden. |

### A `dart format` trap worth knowing

Twice in this change a mutation test appeared to pass when the mutation had
never been applied: `dart format` had wrapped or collapsed the target expression,
so the search string did not match and the edit silently did nothing. A mutation
that fails to apply is indistinguishable from a test that fails to catch. Assert
that the edit landed before believing the result.

### An oddity, observed and not acted on

Frame **`145:3776`** carries the same name as `52:2` — "02.01 Home & Dashboard /
Home — default" — with the same children, at 1215px tall instead of 852 (content
962 instead of 599). Two frames with one name, one of them a taller variant.
Candidate for the file's twelve deliberate mistakes; the answer key at
`🔧 Utilities / Known Deviations` has still never been read.

## 🧩 Components / Charts and friends — built by `insight-components`, 2026-09-10

All five components this change owns are built. `LineChart` was the last, once
Figma access returned — see **`48:76` unblocked and built** below.

| Component | Node | Variants | State |
| --- | --- | --- | --- |
| ChartLegendItem | `47:47` | 9 (`Slot=1`–`8`, `Other`) | **done** |
| DonutChart | `47:48` | 1 authored; 4 gallery fixtures | **done** |
| Radio | `25:238` | 4 (selected × disabled) | **done** |
| BottomSheet | `59:211` | 1 authored; 3 gallery fixtures | **done** |
| LineChart | `48:76` | 1, 353×226 | **done** |
| BarChart | `48:34` | 1, 353×223 | not built — instanced on Budgets `04.07`, on no page 07 screen. Belongs to whichever change builds Budgets history. |
| Sparkline | `48:94` | 1, 104×34 | not built — on the Charts page, instanced nowhere on page 07. |

A horizontal bar chart was **not** added, and that is a rule rather than an
omission. Annotation `77:587`: *"ProgressBar is reused as the bar mark rather
than adding a HorizontalBarChart component; one series means one hue, so every
bar is the same colour and rank is carried by length and order."*

**No token was added.** Both colours that looked like candidates were confirmed
against existing ones by fetching the exported SVGs: the donut's segment fill
`#AA7705` is `chart/7`, and the `Other` swatch `#7C8595` is `textTertiary`.

### Provenance: what was measured, what was derived, what was transcribed

The distinction matters because two of these are weaker than a bound variable,
and a future reader should not have to guess which.

| Value | Where | Provenance |
| --- | --- | --- |
| `DonutChart.ringThickness = 39.5` | `donut_chart.dart` | **measured** off `47:50`'s exported path, which runs `y=0`→`y=39.5182` at twelve o'clock in the 208 box. The segments export as filled annular paths, so there is no stroke width to read. The trailing `0.0182` is Figma's arc-to-path conversion; 39.5 is also the only nearby value `Paint.strokeWidth`, a 32-bit float, returns unchanged. |
| `DonutChart.segmentGapDegrees = 1` | `donut_chart.dart` | **measured** at two boundaries: 0.898° at twelve o'clock (`47:57` ends 0.554° early, `47:50` starts 0.344° late) and 1.099° between `47:50` and `47:51`. No style carries it. |
| The donut's **track** ring | `donut_chart.dart` | **added.** `47:49` has eight ellipses and no track, because its sample fills the circle. The spec's "empty ring with no segments" needs something to be the ring. |
| `MonetaRadio`'s four colour roles | `moneta_radio.dart` | **derived from `25:229`**, the Checkbox set beside it on the same Atoms page — `25:238` itself could not be read. Two sub-decisions the sibling does not settle are stated in the code: disabled beats selected for the fill, and the dot survives disabling. |
| `MonetaRadioRow`'s layout | `moneta_radio_row.dart` | **derived.** `07.05` could not be read; the row follows `ListRow`'s arrangement for the same shape. |
| `MonetaBottomSheet`'s colour roles and corner radius | `bottom_sheet.dart` | **derived.** The geometry (20px handle area, 40×4 handle, 60px header, 44×44 close, 20px inset) is transcribed from `proposal.md`, recorded while access was live. No header divider was invented: nothing recorded says there is one. |

Everything marked derived was checked by task 7.5's `figma-fidelity` pass once
`48:76` became readable. What it found is below.

### Deviations recorded by `insight-components`

| # | What | Resolution |
| --- | --- | --- |
| 41 | `47:47` is a public component set with nine variants, so it must appear in the gallery — which makes it a component a caller can compose beside a chart. | `DonutChart` accepts **no** legend parameter of any kind, so a public `ChartLegendItem` does not make the donut's legend optional. Annotation `77:284`: *"the DonutChart legend is part of the component and not optional: two of the eight chart slots fall below 3:1 against the dark surface, so the visible labels ARE the required contrast relief."* A `showLegend` flag would turn an accessibility guarantee into a caller's convenience; a sibling `ChartLegend` widget would let a screen show rows that disagree with the arcs, which is harder to notice than no legend. Guarded by a test that reads the constructor's parameter list out of the source, because a widget test cannot prove a parameter's absence. |
| 42 | `47:62` assigns its eight categories slots **7, 4, 2, 8, 6, 3, 5, Other** — Food & drink is `Slot=7`, and `chart/1` is never used. The file does not colour by rank. **Corrected 2026-09-10: this order is not arbitrary.** It is exactly `SpendCategory.chartSlot`, and `chart/1` is absent because it belongs to `salary`, which is income. | `DonutChart` honours each caller's slot and ranks only the *order*, so a category keeps one colour across every screen that charts it. Overriding by rank would have been a deviation from the design as well as a worse behaviour. The ring's exported fills (`#AA7705`, `#027ED8`, `#769200`) agree with the legend's slots, so the two halves of `47:48` are consistent; it is only the *choice* of slots that is arbitrary. |
| 43 | `ChartLegendItem` pins its percentage and amount (`shrink-0` on `47:5` and `47:6`) and flexes only its label. | Reproduced as authored, and it has a real upper bound: once the label reaches zero width the row is over-subscribed and `RenderFlex` reports an overflow — at 2^61 minor units, by 47px. **This is not fixable, only choosable.** No 353px row can show an unbounded amount, and making the amount flexible is worse: `RenderFlex` gives each flexible child `freeSpace / totalFlex` and does not hand a loose child's leftover back to its sibling, so the row would sit un-flush and the label would shrink in the normal case. The design already answers which part is lost — the label. Tested at both ends: the arithmetic at 2^61 without rendering, the layout at ~10^15 minor units, which is past any real ledger. |
| 44 | `59:211` authors a 34px bottom inset. | Taken from `MediaQuery.paddingOf(context).bottom` instead. The authored 34 describes one handset, the same reason `MonetaAppBar` refuses to paint a fake status bar. Asserted at 34, 21 and 0, because a single fixture at 34 would coincide exactly with a hardcoded value. |

### `48:76` unblocked and built, 2026-09-10

Figma access returned — `whoami` reports **NIK Technology, seat Full, tier
pro** — and `LineChart` was built from the node rather than from the counts.
What the node gave that the counts did not: gridlines at y=35/70/105 of the 140
plot, `heading/h3` title and `caption/md` subtitle, y labels *outside* the plot
at 0 / half / max only, a 2px stroke, a 9px end marker with a 2px surface ring,
and a legend swatch that is a 14×3 **line** rather than a dot.

Its own description is the requirement, and it repeats the donut's: *"TWO
series, so a legend is mandatory — identity is never colour-alone. One y-axis
only; a second scale would be a dual-axis chart, which this system never
ships."*

Both series' slots are **fixed**, not parameters: `48:89` binds `chart/1` and
`48:92` binds `chart/3`. A chart whose two series could be given the same slot
is a chart whose mandatory legend cannot tell them apart.

The former text of this section, recording why the chart was held, is below for
the record.

### Previously held on `48:76`

`LineChart` is specified, planned and **not implemented**, because the Figma MCP
connection lost access to this file mid-change. `whoami` reports
`jeff@relayvault.ai`, seat **View**, tier **starter** — not the NIK Technology
Full/pro account. Same root cause as the 2026-09-09 outage: two accounts behind
one connection. Restoring it is the file owner's action.

What is recorded about `48:76` is counts, not geometry: 353×226, a title and
subtitle, a 353×140 plot with three gridlines, two series each ending in a 9×9
marker, y labels outside the plot, and a two-item legend whose swatch is a 14×3
line rather than a dot. Gridline positions, axis-label layout and the plot's own
colour roles are not recorded.

That is the line this change drew, and it is worth stating because the same
change built `Radio` and `BottomSheet` from partial information:

- a **derived** value is one this design system already answers somewhere else,
  and a fidelity pass can confirm — `Radio`'s fill colour, from the Checkbox
  beside it;
- an **invented** value is one nothing in the repository constrains — a
  gridline's y position.

This change's own proposal names the cost of the second: *"the alternative is
approximating a chart, which is how this repository's invented spacing scale
happened."* So the charts wait for the file.

### Deviations 45 and 46 — the two accessibility rules, as rules

| # | What | Resolution |
| --- | --- | --- |
| 45 | A legend is the kind of thing a cramped screen turns off. | **Neither chart accepts one.** `DonutChart` and `MonetaLineChart` expose no legend parameter of any kind, and both are guarded by a source-level check that reads the constructor's parameter list and compares it exactly, with a counterfeit guarding the extractor. Annotation `77:284` for the donut: two of the eight chart slots fall below 3:1 against the dark surface, so the visible labels *are* the required contrast relief. `48:76`'s own description for the line chart: identity is never colour-alone. |
| 46 | A dual axis is the obvious way to make two series of different magnitude both look interesting. | **Not representable.** `MonetaLineChart` has no second axis, no per-series scale, no axis minimum and no maximum parameter; the maximum is computed from both series together and the baseline is always zero. Annotation `77:430`: *"a dual-axis chart would let the two lines cross wherever the scales were chosen to make them cross."* The parameter-list check pins the API to exactly `title`, `subtitle`, `income`, `expenses`, `key`, and `fractionsOf` — the single place a value becomes a position — is asserted to measure from zero rather than from the data's minimum. |

`MonetaLineChart` also carries one recorded lesson of its own. Two mutations
survived the first pass: a negative value plotted below the baseline, and the
marker's surface ring drawn at radius zero. Both were the tests' fault. The
clamp lived inside the painter, where arithmetic is only visible through what it
draws, so it moved to `fractionsOf` and is asserted directly; and the ring was
covered only by a `drawCircle` **count**, which a zero-radius ring satisfies, so
the radii are asserted in the ordered sequence and the ring is asserted larger
than the mark.

### What the fidelity pass corrected, 2026-09-10

Run against `47:48`, `48:76` and `47:47` once the file was readable. Verdicts:
`ChartLegendItem` **faithful** (all nine variants, every value matching),
`DonutChart` **faithful with notes**, `MonetaLineChart` **divergent** — and the
divergences were real.

| # | What was wrong | Corrected to |
| --- | --- | --- |
| 1 | The end marker was a 9px coloured disc with an 11px backing disc, giving a 1px ring. I had read "9px end markers with a 2px surface ring" as disc-plus-ring. | `48:84`'s exported SVG is `<circle r=3.5 fill=#009E62 stroke=#06070A stroke-width=2/>` in a 9×9 box: a **7px** disc with the ring straddling its edge, **9px** in total. |
| 2 | The ring was `surface` (`#0A0C11`). | `#06070A` is **`canvas`**. |

Two provenance notes it improved, neither a visual defect:

- The donut's ring thickness is **exactly 39.52** (inner radius 0.62 × 104 =
  64.48), not "≈64.5". The shipped 39.5 is 0.02px out, which is why nothing
  looked wrong.
- `47:48`'s **component description is readable** and states *"Segments carry a
  ~2px surface gap"*. The doc said "no style carries it", which was true of the
  styles and false of the description — the measured 1° (≈1.0–1.6px across the
  band) is consistent with it, but the statement was available all along.
- `get_variable_defs` on `47:48` returns `chart-7` and `text-tertiary` as bound
  variables, so those two colours are now **transcribed**, not measured off an
  export.

Still open, recorded rather than fixed under time pressure: the y-axis labels
overhang the component's left edge in Figma (`x=-12/-19/-20`) and are in-flow
here, so the plot is ~20px narrower than the authored 353; the label-to-plot gap
is 8 where Figma has 4; the labels are 8px off centre against the plot's
top/bottom; and Figma's markers are inset 4.5px from the plot's right edge while
ours sit on it. Also `MonetaLineChart._axisLabel` hardcodes a millions divisor
while the unit is caller-supplied `subtitle` text — the one place the widget
lets the axis scale and the stated unit disagree, and wrong for a two-decimal
currency.

### 📱 07 Insights & Reports — four of six built, 2026-09-10

| Screen | Node | Annotation | State |
| --- | --- | --- | --- |
| 07.01 Insights — overview | `77:2` | `77:284` | done |
| 07.02 Cash flow — trend | `77:294` | `77:430` | done |
| 07.03 Category breakdown — bars | `77:440` | `77:587` | done |
| 07.04 Month comparison | `81:399` | `81:498` | **deferred** |
| 07.05 Insights — period picker | `81:508` | `81:644` | done |
| 07.06 Export report | `81:654` | `81:810` | **deferred** |

The two deferrals are named rather than left as silence: 07.04 is a two-column
comparison with per-row deltas, 07.06 needs file export, a destination field and
a share sheet. Neither is on the path to "see where the money went", and both
were skipped under an explicit instruction to skip blockers and come back.

**One finding worth more than the screens.** `SpendCategory.chartSlot` reads
Food 7, Transport 4, Shopping 2, Bills 8, Entertainment 6, Health 3, Gifts 5 —
which is **exactly** the sequence `47:62`'s legend rows use. Deviation 42
recorded that order as "arbitrary"; it is not. Each category carries its own
bound slot, and `chart/1` never appears in the donut's sample because it belongs
to `salary`, which is income. So a category keeps one colour across every list,
chart and detail screen without any screen choosing — which is exactly what
`33:311`'s description says: *"Colour and glyph are baked in together — pick a
category, never a colour."* Deviation 42 is corrected accordingly.

**A rule the annotation and the frame disagreed about.** `77:587` says
*"ProgressBar is reused as the bar mark"* and, in the same sentence, *"one
series means one hue"*. `MonetaProgressBar` derives its colour from the
fraction, so the full bar would be the near-limit warning colour — the two
halves of one sentence cannot both hold. `80:407` breaks the tie: every fill on
the frame is `chart/1`. Resolved with a `MonetaProgressBar.series` constructor
taking a `ChartSlot`; recorded as added scope in the change's `tasks.md` group 7
rather than slipped in.

### 📱 08 Profile & Settings — one of eleven built, 2026-09-10

| Screen | Node | State | What blocks it |
| --- | --- | --- | --- |
| 08.01 Profile — default | `100:2` | **done** | — |
| 08.02 Edit profile | `100:276` | deferred | needs `Avatar`; `Select` and `TextField` exist |
| 08.03 Settings — list | `100:428` | **done** | — |
| 08.04 Settings — security | `100:729` | deferred | no auth or biometrics behind it |
| 08.05 Change PIN | `101:488` | deferred | `Numpad` (`36:92`) is not built |
| 08.06 Settings — notifications | `101:618` | **done** (6 of 7 rows) | the seventh needs a monthly report the app does not produce |
| 08.07 Currency & language | `101:863` | deferred | needs multi-currency, which the wallet does not have |
| 08.08 Manage categories | `101:978` | deferred | `Chip` (`17:65`) is not built; categories are a fixed enum |
| 08.09 Edit category | `102:794` | deferred | same, plus custom colours |
| 08.10 Premium — paywall | `102:1044` | deferred | no purchases |
| 08.11 Help & FAQ | `102:1189` | deferred | `SearchField` is not built |

**The Profile tab lands on `08.01`**, as the design has it, since `Avatar`
landed in `profile-components`. `08.03` is pushed from it — from the row and
from the bar's sliders action.

`08.01`'s stat tiles are **local frames, not `StatTile`**, and that is the
annotation's instruction rather than a shortcut. `100:275`: *"StatTile is built
around a delta with a direction arrow, and 'days tracked' has no delta. Reuse
that fights the component's meaning is worse than a local frame."* The screen is
asserted unable to reach `StatTile` at all — and the local class is named
`_StatCard`, because a private class one underscore away from the component's
name invites exactly the reuse the annotation warns against.

`ListRow` gained a `destructive` flag for `08.01`'s sign-out row. `100:269`:
*"Sign out is the only destructive row and is the only label not on
text/primary."* `35:113` authors no destructive variant — the screen overrides
the label's colour on the instance — so it is a flag that changes **only** the
title, asserted by a test that captures background, border, icon, subtitle and
size and requires them identical either way.

**Rows whose destination is unbuilt are shown and disabled, not hidden.**
`100:722` hides Face ID's row *on a device without biometrics* — an absent
capability. A screen not yet built is a different fact, so those rows stay
visible, carry no chevron and do not navigate. Hiding them would make the list
look complete and shorter than the design; letting them navigate would land on a
blank screen.

**The trailing variant is derived, not passed.** `100:728`: *"The Trailing
variant is the whole information design of a settings list. Chevron promises
another screen, Toggle promises an immediate change, Value shows state. Getting
that mapping wrong is the most common settings-screen mistake."* So
`SettingsRow` has three constructors — `push`, `toggle`, `value` — and computes
the accessory from which one was used. The mistake is not expressible, and the
test asserts the invariant over every row rather than row by row, because a
per-row assertion would pass a list where a *new* row was added wrongly.

### Deviation 47 — the donut's centre box is derived, not transcribed

| # | What | Resolution |
| --- | --- | --- |
| 47 | `47:58` places the centre block at **140 wide** inside a ring whose hole is `2 × 64.5 = 129` across — and the block is 62 tall, so at its top and bottom edges the hole is only `2 × √(64.5² − 31²) ≈ 113`. The authored box overhangs the arcs by construction. | **Not transcribed.** `DonutChart.centreWidth` is computed from the inner radius and the block's height, less an 8px margin — about 105 — and the total is `BoxFit.scaleDown` rather than ellipsised, so a long figure shrinks instead of being cut. Figma gets away with 140 because its sample total, "26,000,000 ₫", is short enough not to reach the edges; a real VND total reached them and the figure touched the ring. Reported by the user, not by a test. |

Guarded by a geometric assertion — the furthest **corner** of the centre block
must sit strictly inside the inner radius with clearance — and three mutations
fail against it. Two earlier versions of that assertion did **not** fail:

- `lessThanOrEqualTo(innerRadius)` passed for a box exactly *tangent* to the
  circle, which is still touching. Tangency is not clearance.
- measuring the *total's own box* instead of the block passed too, because the
  total is scaled to fit and its box hugs the scaled text — it is always
  comfortably inside. The block keeps its full width and height whatever the
  figure says, so the block is the thing that can reach the arcs.

Both are the same mistake in different clothes: asserting on the wrong object,
or with the wrong strictness, gives a test that reads like a guarantee and holds
nothing.

### Deviation 48 — the centre's authored height has no slack at all

| # | What | Resolution |
| --- | --- | --- |
| 48 | `47:58`'s height of **62** is exactly the sum of the three authored line boxes it contains: `16 + 2 + 26 + 2 + 16`. The layout is therefore correct only while every line box is exactly its nominal height, and anything that inflates one — the platform's text size, a font whose metrics round up — pushes the period line out of the block. A device reported **2.5px of bottom overflow** with "This month" clipped. |  The block is kept at the authored 62 and its content is scaled into it: one `BoxFit.scaleDown` around the whole three-line column, *uniform* so the lines keep their authored proportions, *scaleDown* so at nominal metrics the scale is 1 and nothing moves. It sits outside the one that already scales the total, and the two absorb different things — that one keeps a long **figure** off the arcs by shrinking only the figure, this one keeps three inflated **line boxes** inside 62. |

Guarded across the platform's text sizes rather than at one of them: the old
layout was clean at the default and broke at the notch above it, so a guard
written at a single scale would have been written at the one value that could
not fail. Three mutations fail — the outer box removed, `scaleDown` widened to
`contain` (which would blow a short total up to fill 62), and the inner width
bound replaced.

The scan stops at 1.786× and excludes the two largest accessibility sizes.
What breaks above it is not the centre but the **legend row**: `47:2` pins the
percentage and the amount and flexes only the label, so past some width a 353px
row is over-subscribed — the same limit the very-large-amount test records. Where
exactly is a fact about glyph widths, and under the placeholder font every glyph
is `fontSize` wide, so the real cutoff is higher than the test's. Asserting one
would be asserting the test font.

**The same defect, found once and then looked for.** With the centre fixed, the
whole suite was re-run at 1.118× — the scale that matches the reported 2.5px —
and `08.01`'s stat tile overflowed by a pixel for the same reason: `100:61`'s
authored 66 leaves four pixels of slack around two line boxes. That one is fixed
the opposite way, because a tile on a scrolling page can grow and a hole in a
ring cannot: its authored height became a **minimum**. At 1.118× all 1639 tests
are now clean.

### `Avatar` built, and a token that was missing — 2026-09-10

| Component | Node | Variants | State |
| --- | --- | --- | --- |
| Avatar | `21:121` | 12 (3 types × 4 sizes) | **done** |

**`brandSubtle` (`#1A1236`) was missing from the token set.** Every Avatar
variant fills `var(--brand-subtle)`, and `MonetaColors` had `incomeSubtle`,
`expenseSubtle`, `warningSubtle` and `infoSubtle` — four of five semantic
families with a subtle counterpart, and the brand without one. Added as a token
rather than written as a literal in the first component to need it, with a
provenance row in `figma-tokens.md` and a new test asserting the family is
complete: a test naming the four could never notice the fifth was absent, which
is how it stayed absent.

**Two per-size tables, both transcribed, neither a formula.**

| Size | Initials style | Glyph |
| --- | --- | --- |
| 24 | `label/sm` | 14 |
| 32 | `label/sm` | 18 |
| 40 | `label/md` | 22 |
| 56 | `title/md` | 28 |

The initials style is not a scale: 24 and 32 share one style while 40 and 56
differ from both, so anything derived from the diameter has to special-case at
least two of four. The glyph sizes are worse, because they *nearly* fit — 14, 18
and 22 are all `diameter / 2 + 2`, which gives **30** at 56 where the file says
28. There is a test that states both properties out loud, so the temptation is
recorded rather than left for someone to act on.

**The glyph is `textSecondary`, not the brand colour.** `21:120`'s exported
glyph carries `stroke="#9AA3B4"`. I assumed `brandOnSurface`, because that is
what the initials use, and read the SVG instead of shipping the assumption.
There is an explicit `isNot(brandOnSurface)` assertion for it.

Initials are **derived from a name**, never passed as a string — a caller
handing over `"MT"` could equally hand over three letters or a punctuation
mark. First and last word, upper-cased, Vietnamese diacritics counting as
letters; a name with no letters falls back to the glyph, because an empty circle
is not a state. `21:106`'s description sets the order: *"Initials fall back when
no photo exists."*

### `08.06` is six rows, not the authored seven — and two are renamed

`101:853` authors seven rows (5 Toggle, 2 Value). This builds **six** (4 Toggle,
2 Value), and the gaps are features rather than shortcuts:

| Frame row | Built as | Why |
| --- | --- | --- |
| 80% of a budget used | same, **off** by default | nothing derives an 80% warning yet, so the switch silences nothing |
| Budget exceeded | same | `NotificationKind.budgetOverLimit` |
| Bill due in 3 days | **Budget period ending** | no bills feature; `budgetPeriodEnding` is the kind that exists |
| Goal milestone reached | **Money received** | no goals feature; `incomeReceived` is the kind that exists |
| Weekly summary (Value) | same | — |
| Monthly report ready | **not built** | the app produces no monthly report |
| Do not disturb (Value) | same | — |

The four group headings are kept exactly as authored — *"Bills & goals"*
included — so the screen's shape still matches the design and the gap is
visible rather than papered over.

**The switches are wired to the feed, not just stored.** `101:850`: *"so a user
can silence one category without silencing everything."* A switch that persists
a boolean and changes nothing would contradict `100:728`, which says a toggle
promises an immediate change, so `notificationsProvider` filters by them and
`allows()` switches exhaustively over `NotificationKind` — a new kind is a
compile error rather than a notification that ignores its switch.

**One default is a deliberate departure, and one was a bug I caught.** The 80%
warning ships **off**, against the frame's on, because it silences nothing yet —
and it is what keeps the defaults mixed, which `101:856` asks for. My first
version instead put *income* off by default, mapping it onto the frame's
off-state row; two existing `notifications_route_test.dart` tests failed and
caught that it silently removed a feature `home-overview` had already shipped.

### Two defects in `ListRow`, found in its own description

`35:70`: *"56px minimum so the whole row is the tap target — never make just the
trailing control tappable."* Both halves were wrong:

- rows **without a subtitle** came out at ~46px — under the authored 56 and
  under the 44px platform target — and every settings screen in this app is
  made of these;
- a **toggle row's row area was not the control's tap target.** It carried a
  separate `onTap`, so one row had two different actions and only the 52×32
  switch toggled.

Fixed, and the existing test that asserted the second behaviour was **replaced**
rather than worked around: it encoded exactly what the component description
forbids. A toggle row now has one action, and `onTap` is ignored on it.

