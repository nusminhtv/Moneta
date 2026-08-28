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
| `📊 02 Budgets` | `5:17` | 7 screens |
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
| CircularProgress | `25:272` | 9 (3 states × 3 sizes) |
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
| StatTile | `35:137` | 3 directions |
| EmptyState | `35:166` | 2 (HasAction true/false) |
| AmountInput | `36:76` | 2 |
| NumpadKey | `36:91` | 4 |
| Numpad | `36:92` | 1 |
| SegmentedItem | `36:167` | 2 |
| SegmentedControl | `36:168` | 1 |
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
