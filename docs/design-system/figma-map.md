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
| 12 | `StatTile`'s `Direction=Up` maps to income green, and its own sample reads "Spent this month / +12.4% vs last month" in green — spending more, coloured as good news. | Mapping kept as authored: direction is the caller's choice, and income up in green is correct. Changing it would make every correct use wrong to fix one wrong sample. **Candidate for the file's twelve deliberate mistakes**; not verified against the answer key at `🔧 Utilities / Known Deviations`. |
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

### An oddity, observed and not acted on

Frame **`145:3776`** carries the same name as `52:2` — "02.01 Home & Dashboard /
Home — default" — with the same children, at 1215px tall instead of 852 (content
962 instead of 599). Two frames with one name, one of them a taller variant.
Candidate for the file's twelve deliberate mistakes; the answer key at
`🔧 Utilities / Known Deviations` has still never been read.
