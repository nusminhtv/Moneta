# Figma → Flutter map

Source of truth: Figma file `kEYXQUyhXLZITkNxAHRVlf`
("Moneta — Personal Finance App").

**Check this table before implementing anything from Figma.** If a node already
has a widget, extend it; do not create a second implementation.

## What the Figma file contains

| Page | Node | Contents |
| --- | --- | --- |
| `🎨 Foundations / Iconography` | `5:7` | 50 icons (24×24, stroke weight 1.75, incl. `brand-google`, `brand-apple`) + sizing/colour/swapping rules |
| `🧩 Components / Organisms` | `5:11` | 14 component sets, listed below |

**The file contains no screen frames.** Screens are composed from this library,
so every screen layout is a recorded decision (`design.md` or an ADR), not a
transcription.

## Component sets in Figma

| Component | Node | Variants | Widget | Status |
| --- | --- | --- | --- | --- |
| StatusBar | `39:2` | — | | not started |
| AppBar | `39:112` | LargeTitle, TitleBack, TitleActions, Transparent | | not started |
| BottomNav | `39:243` | Home, Transactions, Insights, Profile | | not started |
| BalanceCard | `40:161` | Default, Masked | | not started |
| AccountCard | `40:209` | Bank, Cash, E-wallet, Credit | | not started |
| BudgetCard | `40:256` | OnTrack, NearLimit, Over | | not started |
| ProgressBar | `21:139` | Under/Near/Over × Sm/Md | `design_system/molecules/progress_bar.dart` | done |
| CategoryIcon | `33:311` | 8 categories × Sm/Md/Lg | `design_system/molecules/category_icon.dart` | done |
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

## Recorded deviations and resolved ambiguities

| # | What | Resolution |
| --- | --- | --- |
| 1 | `display/amount-xl` and `heading/h1` report `letterSpacing: -1` in Figma's style summary, but their CSS emits `-0.4px` and `-0.28px` | The summary value is a **percentage**. Implemented as absolute −0.4 and −0.28. Details in `figma-tokens.md`. |
| 2 | The proposal said 51 icons | The page holds **50**. Corrected in the proposal, spec and tasks rather than shipping a catalogue that quietly disagreed with the spec. |
| 3 | `brand-google` carries four colours; every other icon is monochrome | `MonetaIconName.preservesColour` marks it, and `MonetaIcon` skips tinting for it. Tinting would flatten Google's mark into one colour. |
| 4 | Chart *base* colours are not emitted as Figma variables | Read from each exported glyph's `stroke` and visually confirmed against a screenshot of `33:311`, since a light-mode export would have given plausible-but-wrong values. |
| 5 | Figma has no `radius-sm`, `elevation/1`, `elevation/2` or `text-secondary` on any node read | Left unimplemented rather than invented. |
