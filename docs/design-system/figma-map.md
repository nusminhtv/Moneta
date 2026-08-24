# Figma → Flutter map

Source of truth: Figma file `kEYXQUyhXLZITkNxAHRVlf`
("Moneta — Personal Finance App").

**Check this table before implementing anything from Figma.** If a node already
has a widget, extend it; do not create a second implementation.

## What the Figma file contains

| Page | Node | Contents |
| --- | --- | --- |
| `🎨 Foundations / Iconography` | `5:7` | 51 icons (24×24, Feather-style, incl. `brand-google`, `brand-apple`) + sizing/colour/swapping rules |
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
| GoalCard | `40:257` | — | | not started |
| Dialog | `42:284` | Informational, Confirm, Destructive | | not started |
| Snackbar | `42:305` | Success, Error, Info | | not started |
| Banner | `42:329` | Warning, Danger, Info, Success | | not started |
| BottomSheet | `59:211` | — | | not started |
| Logo | `70:205` | — | | not started |
| PaginationDots | `70:223` | 1, 2, 3 | | not started |
| OtpField | `70:263` | Empty, Partial, Complete | | not started |

## Recorded deviations

None yet. Any intentional difference from the Figma source goes here with a
reason and the change that introduced it.
