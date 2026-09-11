## Why

Page 08 has eight unbuilt screens. Two of them are blocked **only** on a
missing component set — `08.05` on `Numpad`/`NumpadKey` and `08.11` on
`SearchField` — and `docs/design-system/figma-map.md` records exactly that. Two
more are blocked on a component *and* on a feature: `08.08` needs `Chip` and
custom categories, `08.09` needs `Chip` and category overrides. `08.10` is
blocked on purchases, not on a component, and it instances `Badge` at
`102:1077` — the "SAVE 31%" pill — which is the only `Badge` instance **on page
08**; no survey of the other eight screen pages was done, so nothing stronger
than that is claimed. `Badge` is built here rather than left as the one missing
set when the paywall is next reached. The alternative — defer `Badge` to the
paywall change, since it unblocks nothing on page 08 — is a fair reading; it is
built now because it is the last unbuilt *atom* the page touches and because
`ListRow` already draws a badge of its own, which makes the authored one worth
having beside it for comparison (see design D1).

Building these five sets clears every *component* blocker on page 08 in one
change, and each is something the rest of the app reuses: a filter chip, a
status pill, a search input, a keypad.

The user-visible outcome of *this* change is the gallery: five component sets,
every authored variant, browsable and tested. No screen changes. The screens
follow in a change that is not yet opened; `profile-feature`'s §6 is where they
are currently parked, and see Non-goals for what this change owes it.

## What Changes

- **`Badge`** (`17:32`) — 5 tones × 2 sizes = 10 variants. Tones map onto tokens
  that exist: `income`, `warning`, `expense`, `info` paired with their
  `*Subtle` fills, and `surfaceRaised` + `textSecondary` for `Neutral` — which
  is **not** a subtle/base pair and is specified separately. Label is
  `labelSm`. The dot is a Figma boolean property defaulting to true, so both a
  dotted and a dotless badge are authored.
- **`Chip`** (`17:65`) — 3 types (Filter, Choice, Input) × selected = 6
  variants. Selected is `brandSubtle` fill, `brand` border, `brandOnSurface`
  label; unselected is `surfaceRaised`, `borderDefault`, `textSecondary`.
  Label is `labelMd`. `Type=Input` always carries a trailing close control. The
  pill is 34 tall and sits in a 44px box — see design D3 and D6.
- **`SearchField`** (`35:38`) — 2 states. The state is **derived from the text**,
  not passed in. Text is `bodyLg`; the field is 50 tall.
- **`NumpadKey`** (`36:91`) — `Type=Digit` (label, `headingH2`) and
  `Type=Action` (a 22px glyph). Its description claims *"2 types x 2 states"*
  and `figma-map.md` records four variants; **the set contains two**. Built as
  authored, and the map's count is corrected.
- **`Numpad`** (`36:92`) — 3 × 4, rows filling the width they are given. One
  variant.
- The `Numpad` is authored **for amount entry** and carries a decimal key.
  `08.05` reuses it for a six-digit PIN, so what occupies the third-last cell is
  a parameter. That is a deviation and is recorded as one.
- **`docs/design-system/figma-map.md`** — five inventory rows move to built, the
  `NumpadKey` count is corrected from 4 to 2, and the note at `figma-map.md`'s
  `04.04` entry — which explains the shipped amount screen's hidden
  `EditableText` by recording that `Numpad` and `NumpadKey` *"exist in Figma and
  are not built"* — is corrected, because after this change they are. Three
  source comments say the same thing more bluntly and are corrected with it:
  `lib/features/budgets/presentation/create_budget_amount_screen.dart:22`
  (*"which this design system does not have"*),
  `test/features/budgets/presentation/create_budget_test.dart:181`, and
  `lib/features/home/presentation/home_screen.dart:104` (*"`SearchField`
  (`35:38`) is unbuilt"*). **Rewiring `04.04` to the new `Numpad` is not in
  scope**; only the stale reasons are.

### Decisions this change makes about code that already ships

Three existing pieces of the design system overlap the new ones. Each is settled
here rather than discovered mid-task:

- **`ListRow._RowBadge` stays.** `lib/design_system/molecules/list_row.dart`
  already draws a badge for `ListRowAccessory.badge`: `infoSubtle` fill, an
  `info` **border**, `captionMd`. The authored `Badge` has no border and uses
  `labelSm`. They are different components that look similar; unifying them
  changes a shipped widget with its own node (`35:113`) and its own tests, so it
  is not folded into a change about building five new sets. Recorded, not
  silently left.
- **`SearchField` does not compose `MonetaTextField`.** The shipped field is a
  `borderMd` rectangle with label, helper and error slots and a 52px height;
  `35:38` is a pill with none of those and a 50px height. Composing would mean
  adding a shape parameter to a shipped component for one caller. See design D4.
- **`Chip` owns a 44px hit area**, the way `MonetaCheckbox` and `MonetaRadio`
  already do (`hitSize = MonetaLayout.minTouchTarget`), rather than publishing a
  number and hoping the caller reads it.

No new dependency. No schema migration. **No token additions:** every colour
this change needs exists, which was checked name by name against
`lib/design_system/tokens/colors.dart` rather than assumed.

## Non-goals

- **No screens.** `08.05`, `08.08`, `08.10` and `08.11` are a following
  change's work — one that is **not yet opened**; an earlier draft of this
  proposal named `profile-settings-screens` as though it existed. What exists is
  `openspec/changes/profile-feature`, whose §6 carries those screens as unticked
  tasks with "needs `Numpad`, unbuilt" and "needs `SearchField`, unbuilt" as
  their blockers. Those blocker lines become false when this change lands, so
  **task 5.1 rewrites them** to name what actually remains (a PIN store,
  category overrides, purchases). Building a component and its only caller
  together is how a component ends up shaped by exactly one screen.
- **No PIN storage, no category editing, no purchases.** Features, not
  components.
- **No search behaviour.** `SearchField` reports text and a clear; *what* gets
  filtered belongs to the screen that owns a list.
- **No rewiring of `04.04`** to the new `Numpad`, and no change to
  `ListRow`'s badge. Both are named above so they are visible as deferred rather
  than missed.
- **No `Tabs`/`TabItem` or `TransactionRow`'s two missing types** — unbuilt, and
  not needed by page 08. (`Skeleton` is **already built** and shipped; an
  earlier draft of this proposal said otherwise, from a stale inventory row.)
- **No keypad haptics or press animation.** Nothing is authored, and
  `NumpadKey` has no pressed variant to animate towards.

## Capabilities

### New Capabilities

None. Five more components in a capability that already exists.

### Modified Capabilities

- `design-system/components`: adds requirements for `Badge`, `Chip`,
  `SearchField`, `NumpadKey` and `Numpad`. No existing component requirement
  changes.

## Impact

- **`lib/design_system/atoms/`** — `moneta_badge.dart`, `moneta_chip.dart`.
- **`lib/design_system/molecules/`** — `moneta_search_field.dart`,
  `numpad.dart` (`NumpadKey` ships beside `Numpad`, public, because an authored
  set must be in the gallery).
- **`lib/app/gallery/gallery_catalog_profile.dart`** — five sets registered.
  A component that exists and is not registered **fails the gate**:
  `test/app/gallery_test.dart`'s "every design-system widget is in the catalog"
  walks `lib/design_system` from the filesystem. So each component's task
  includes its registration; they cannot be split.
- **`test/app/gallery_describe_profile.dart`** — five describer cases.
  `gallery_test.dart`'s `_describe` throws `UnsupportedError` for a widget type
  it does not know, so this is required work, not a nicety.
- **`test/app/gallery_test.dart`** — the per-component **literal** variant
  counts live here, beside the ones already hand-written for Button,
  `PaginationDots`, `OnboardingIllustration` and `TransactionRow`. Five of the
  build tasks edit this file.
- **`docs/ai-workflow/evidence-log.md`** — ten mutation records, one group per
  build task.
- **`docs/design-system/figma-map.md`** — inventory rows, the `NumpadKey` count
  correction, the `04.04` note and the three stale source comments, and rows for
  the readings this change makes (the stroke convention behind chip 34 and
  search 50, `SearchField`'s off-scale 13px padding, the `chevron-left` action
  glyph, the decimal cell, and `Chip`'s 44px box).
- **`openspec/changes/profile-feature/tasks.md`** — §6's blocker lines for 6.3,
  6.5, 6.6 and 6.8, rewritten once this change makes them false.
- **One module.** Nothing in `core`, `data` or `features`. Only `lib/app`'s
  gallery catalog, which may import anything.
