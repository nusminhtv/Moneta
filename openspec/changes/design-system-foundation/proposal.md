## Why

Nothing in Moneta can be built until the design system exists. The Figma file
already contains a complete, documented token set and a component library with
explicit state rules — for example, a budget bar's colour is *derived* from spend
(`under=income`, `>=80%=warning`, `over=expense`), never chosen by hand. If
screens are built before those rules live in code, every screen re-derives them
slightly differently and the app stops looking like one product.

The user-visible outcome: a running app whose home surface shows a real balance
card, budget cards that change colour and border as spend crosses thresholds, and
a bottom navigation bar whose active tab always matches the current screen —
visually identical to Figma on an iPhone-class viewport.

## What Changes

- **New token layer** `lib/design_system/tokens/`: colours (surface, text, brand,
  semantic income/expense/warning, 8-slot chart palette), typography (Inter +
  Plus Jakarta Sans, 6 named styles), spacing, radii, elevation, motion.
- **New theme** `lib/design_system/theme/`: a `MonetaTheme` `ThemeExtension`
  carrying the tokens, plus the `ThemeData` that wires fonts and Material
  defaults. `lib/app` starts using it.
- **New icon set**: the 51 icons on the Figma Iconography page, delivered as
  committed SVG assets rendered through `flutter_svg`, exposed as a
  `MonetaIcons` catalogue. Stroke weight in the design is 1.75, which no
  off-the-shelf icon package matches, so the exported assets are the only faithful
  source. **Adds a dependency:** `flutter_svg`.
- **New molecules**: `ProgressBar` (3 states × 2 sizes), `CategoryIcon`
  (8 categories × 3 sizes).
- **New organisms**: `BalanceCard` (Default, Masked), `BudgetCard` (OnTrack,
  NearLimit, Over), `BottomNav` (Home, Transactions, Insights, Profile) with the
  centre FAB.
- **New domain enum** `SpendCategory` in `lib/core`, because `CategoryIcon` binds
  colour and glyph to a category and that binding must be shared by lists,
  charts and detail screens rather than re-chosen per screen.
- **A gallery route** in `lib/app` that renders every component in every variant,
  so fidelity is checkable by looking at a running app, not only by reading tests.

## Capabilities

### New Capabilities
- `design-system/tokens`: the token contract — what tokens exist, what they
  resolve to, and the rule that no raw design value may appear outside the token
  layer.
- `design-system/components`: the behaviour of each design-system component,
  including full variant coverage and the derived-state rules that the component
  owns rather than its caller.

### Modified Capabilities
None — this is the first behavioural change in the repository.

## Non-goals

- **No screens.** Home, Transactions, Insights and Profile screens are out of
  scope; only the gallery route exists. Figma contains no screen frames, so screen
  layout is a separate design decision.
- **No persistence and no real data.** Components take values passed in; the
  gallery uses fixtures. Storage arrives in the next change.
- **No light theme.** The Figma design is dark-only. Tokens are structured so a
  light set can be added later, but no light values are invented now.
- **Not all 14 Figma component sets.** AppBar, AccountCard, GoalCard, Dialog,
  Snackbar, Banner, BottomSheet, Logo, PaginationDots, OtpField and StatusBar are
  deliberately deferred; they are pulled in by the changes that first need them,
  so that each arrives with a real caller.
- **No localisation.** Copy is English; `Money.format` already handles vi_VN
  number formatting.
- **No animation work** beyond exposing motion duration/curve tokens.

## Impact

- **Modules touched:** `lib/design_system` (new, the bulk of the change),
  `lib/core` (one new enum), `lib/app` (theme wiring + gallery route),
  `test/design_system` (new). `lib/data` and `lib/features` are untouched.
- **Dependencies added:** `flutter_svg`.
- **Assets added:** 51 SVG files under `assets/icons/`, declared in
  `pubspec.yaml`.
- **No schema migration** — this change adds no persistence.
- **Gates affected:** `tool/check_design_tokens.dart` currently passes trivially
  because no UI exists. After this change it becomes load-bearing, and
  `lib/design_system/tokens|theme` become the only exempt paths.
- **Figma nodes consumed:** `5:7` (icons), `40:161`, `40:256`, `21:139`,
  `33:311`, `39:243`, `20:125`. Recorded in `docs/design-system/figma-map.md`.
