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

**No screen frames are reachable from the three visible pages** — but the file
contains 74 screens according to its own Cover. Screen layouts recorded as
"decisions" in this project were decided without access to designs that exist.

## Component sets in Figma

| Component | Node | Variants | Widget | Status |
| --- | --- | --- | --- | --- |
| StatusBar | `39:2` | — | | not started |
| Button | `13:2` (Atoms) | 5 styles × 3 sizes × 3 states = 45 | `design_system/atoms/moneta_button.dart` | done |
| PaginationDots | `70:223` | Active=1/2/3 | `design_system/molecules/pagination_dots.dart` | done |
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
| PaginationDots | `70:223` | 1, 2, 3 | | not started |
| OtpField | `70:263` | Empty, Partial, Complete | | not started |

## Foundations

| Figma | Node | Implementation | Status |
| --- | --- | --- | --- |
| Icon set (50) | `5:7` | `assets/icons/*.svg`, `lib/design_system/atoms/moneta_icon_name.dart`, `moneta_icon.dart` | done |
| Colour tokens | various | `lib/design_system/tokens/colors.dart` | done |
| Type scale (8 styles) | various | `lib/design_system/tokens/typography.dart` | done |
| Radii / elevation / spacing | various | `tokens/radii.dart`, `elevation.dart`, `spacing.dart` | done |
| Motion | *absent from Figma* | `tokens/motion.dart` — Material-derived, marked not-Figma-derived | done |

## Components with no Figma source

Two components exist that Figma does not describe. They are listed separately so
nobody mistakes them for transcriptions:

- **`TransactionRow`** — the file has no transaction row and no screen frames.
  Its layout is a decision, scored against three alternatives in
  [ADR 0003](../adr/0003-transaction-row-layout.md). When Figma gains a real row,
  this is the thing to reconcile against it.
- **`AmountSlot`** — purely internal layout machinery, introduced after the same
  overflow defect appeared in two components. It has no visual identity of its own.

## Recorded deviations and resolved ambiguities

| # | What | Resolution |
| --- | --- | --- |
| 1 | `display/amount-xl` and `heading/h1` report `letterSpacing: -1` in Figma's style summary, but their CSS emits `-0.4px` and `-0.28px` | The summary value is a **percentage**. Implemented as absolute −0.4 and −0.28. Details in `figma-tokens.md`. |
| 2 | The proposal said 51 icons | The page holds **50**. Corrected in the proposal, spec and tasks rather than shipping a catalogue that quietly disagreed with the spec. |
| 3 | `brand-google` carries four colours; every other icon is monochrome | `MonetaIconName.preservesColour` marks it, and `MonetaIcon` skips tinting for it. Tinting would flatten Google's mark into one colour. |
| 4 | Chart *base* colours are not emitted as Figma variables | Read from each exported glyph's `stroke` and visually confirmed against a screenshot of `33:311`, since a light-mode export would have given plausible-but-wrong values. |
| 5 | Figma has no `radius-sm`, `elevation/1`, `elevation/2` or `text-secondary` on any node read | Left unimplemented rather than invented. |
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
