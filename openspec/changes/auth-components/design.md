## Context

See `proposal.md — Why`. Eight components, read from Figma, in a repo where a
parallel agent is building a second flow from the same component library.

**This document was rewritten after a `spec-auditor` review returned NOT READY.**
Its first draft asserted three things about existing code that are false, left
six decisions open as "risks", and got its own ordering argument backwards. Each
is corrected below with the correction named, because a design doc that quietly
improves reads as though it was right the first time.

What the gates actually do, verified rather than assumed:

- `tool/check_design_tokens.dart` matches `Color(0x`, `Colors.*`, `TextStyle(`,
  `EdgeInsets.*` with a literal, and `BorderRadius.circular(<digit>)`. It does
  **not** see `height: 52`, `BorderSide(width: 2)` or `SizedBox.square(36)`. The
  first draft generalised it to "any value Figma authors must become a token" —
  false, and relying on it would have let every dimension in this change be
  hardcoded.
- `test/design_system/tokens/token_provenance_test.dart` fails a token with no
  row in `figma-tokens.md`. It checks that a **row exists**, never that the value
  matches — so it is not a substitute for pinning values in tests.
- `test/app/gallery_test.dart` fails a component that is absent, and fails two
  variants that render identically. It does **not** catch a shortfall: variant
  counts are one hand-written test per component. D0 fixes that.
- `lib/design_system` is **not** in `tool/coverage_critical.txt`. Only the 70%
  project total applies here.

## Goals / Non-Goals

**Goals.** Eight components at full variant coverage; eight new tokens with
provenance; a gallery check that catches variant shortfall; `IconButton` and
`AppBar` landed first so the parallel agent unblocks.

**Non-Goals.** See `proposal.md — Non-goals`. Additionally: no golden tests. The
repo has none (`grep matchesGoldenFile test/` is empty) and adding a golden
harness is its own change. Consequence, stated rather than left implicit: every
assertion here is structural, and **no test in this change may assert the width
of a rendered string**, because `flutter test` uses a metrics-only font where
every glyph is `fontSize` wide.

## D0 — Variant shortfall must be catchable, and is not

The gallery's count checks are `test('Button covers the full 5 x 3 x 3 matrix')`
and four siblings — one per component, written by hand, covering only what
predates this change. Registering `IconButton` with 2 of 18 variants passes the
entire gate.

Three options:

1. **Write eight more hand-written count tests.** Matches the existing style, and
   reproduces the defect for the ninth component. Rejected: this repo has already
   watched a hand-maintained list (six gallery component names, ten exemptions,
   three scanned directories) be walked past four separate times.
2. **Derive counts from each component's enums.** Works where an enum mirrors the
   variant axes, which is most of them — but not `Logo` (a boolean) and not
   anything whose Figma variants are not an enum product. Partial coverage that
   looks total.
3. **Each section declares the count its Figma node authors, and one generic
   test asserts `variants.length` matches.** **Chosen.** The number is a
   transcription from Figma, the same class of value as a token, and it lives
   next to `figmaNodeId` where a reviewer comparing against the canvas will see
   it. One check covers every section that exists or is ever added.

`GallerySection` gains a **required** `expectedVariants`. Required, not optional
with a default, because an optional one is unenforced for exactly the sections
someone forgot.

This edits `lib/app/gallery/gallery_catalog.dart`, which the parallel agent also
touches — so it is task 1.1, landing while their section list is still empty, and
the hand-off note tells them to rebase before adding sections.

## D1 — The status bar is not a widget

Figma draws `StatusBar` (`39:2`) inside all four `AppBar` variants and lists it as
a component on four auth screens. Three options:

1. **Implement it as a widget** painting a clock, signal bars and a battery.
   Highest fidelity to the canvas; on a real device it paints a fake `9:41` over
   the OS's real status bar. Rejected.
2. **Implement it as a 59px spacer**, or have `AppBar` read
   `MonetaLayout.safeAreaTop`. Correct on a 393×852 device and wrong on every
   other one. Rejected — and this is the option the first draft half-took: it
   demanded "no test asserts a hardcoded 59" while `spacing.dart:170` already
   ships `safeAreaTop = 59` and `tokens_test.dart:87` asserts it. Read literally
   that required deleting a passing test, which is what commit `b8e8091` did in
   `onboarding-flow` and what rule 5 forbids.
3. **Read `MediaQuery.padding.top`.** **Chosen.** The 59 in Figma is the artist's
   stand-in for the device inset, not a value to transcribe into layout.

`MonetaLayout.safeAreaTop` stays. It is a correct transcription of what Figma
authors and its test stays green; `AppBar` simply must not read it. The spec says
so explicitly, because "reads a token" and "reads the right thing" are not the
same and only the first is visible in review.

**Test construction, stated because the nearest precedent gets it wrong.**
`bottom_nav_test.dart` sets its test inset *to the very constant a broken widget
would hardcode*, so it cannot discriminate. The `AppBar` test uses **20 and 47** —
neither is 59 nor 34 — and asserts the content origin equals each.

## D2 — Eight new tokens, with their provenance

| Token | Value | Node |
| --- | --- | --- |
| `heading/h3` | Plus Jakarta Sans SemiBold 18/24, tracking 0 | `39:58` |
| `border-default` | white 10% | `27:5` |
| `border-focus` | `#9A83FB` | `27:18` |
| `text-disabled` | `#3D4553` | `27:38` |
| `border-width/hairline` | 1 | `27:5` |
| `border-width/emphasis` | 1.5 | `27:32` |
| `border-width/focus` | 2 | `27:18` |
| `gradient/mark` | violet-500 → mint-500 at 128.48° | `70:206` |

**`text-disabled` as its own token, not `textPrimary` at reduced opacity.** An
opacity-derived colour composites differently against `bg-surface` than against
`bg-surface-raised`, so the same disabled control would differ between two
screens; and the design authors an opaque value, so deriving it would be
inventing a number when one was given.

**Border widths as tokens** because no gate can see them otherwise (see Context).

Adding three colours to `MonetaColors` has two consequences the first draft
missed: its constructor is all-required, so `colors_test.dart`'s construction
must gain three arguments; and `lerp` must interpolate them, where a forgotten
field is silent because the lerp test only checks canvas, income and one chart
slot. Both are in task 1.2.

## D3 — Dimensions live on the component's own enum

52px field body, 96/56 bar heights, 36/44/52 icon buttons, 22×22 checkbox. Two
options:

1. **Add them to `MonetaLayout`.** It has a provenance table, so they would be
   documented. But `MonetaLayout` is screen geometry — frame size, safe areas,
   nav height — and a text field's body height is not screen geometry. This is
   also the class the invented `fabSlotWidth = 72` came from.
2. **On the component's own size enum**, the way `MonetaButtonSize` already
   carries `height`, `horizontalPadding` and `iconSize` with Figma's annotation
   quoted in its doc comment. **Chosen.** It is the established pattern, it keeps
   the value next to the thing it describes, and the per-size test that pins it
   is already written for `MonetaButton` and can be copied.

These are not tokens and no gate sees them, so each component's test pins them to
literals read from the node, and `figma-map.md` records which node each came from.

## D4 — Every state change is legible without colour

`MonetaPaginationDots` set the precedent: its active dot differs in **width as
well as** colour, and a test asserts width alone identifies position. The first
draft said states must "survive greyscale" without naming a second channel, which
means the test gets written after the implementation and asserts whatever was
built. Second channels are chosen here:

| State | Second channel |
| --- | --- |
| `TextField` error | border **width** ≠ default width |
| `TextField` focus | border **width** ≠ default width, plus the brand glow |
| `TextField` filled vs default | the value string is present vs a placeholder |
| `Checkbox` checked / indeterminate / unchecked | check glyph / horizontal bar / nothing |
| `OtpField` filled vs empty position | the character is rendered vs not |

`Checkbox` checked uses the existing `icon/check`. **Indeterminate draws a bar
natively rather than using an icon**: the set has no `minus`, and adding one would
change `MonetaIconName.values.length`, which `moneta_icon_test.dart` pins at 50 as
a deliberate Figma-count gate. Editing that is a rule-5 change needing prior
agreement, and it would also touch the `Icons` gallery section in the **shared**
catalog. If reading `25:219` shows Figma instancing an icon we lack, that is
raised before implementing, not absorbed.

## D5 — Component state is derived, never passed

`TextField` takes no `state` parameter. It derives: focused from its `FocusNode`,
filled from its text, error from a non-null `errorText`, disabled from `enabled`.
`OtpField` derives filled-ness from the code's length.

This follows `BudgetCard`, which deliberately has no `state` parameter "so a
caller cannot show a green card for an over-budget category". The same reasoning
forbids an error border on a field with no error.

Consequence for the gallery: each variant is constructed by setting the inputs
that produce the state, not by naming it. That is more work in the fixture and it
is the point.

## D6 — Ordering, corrected

The first draft ordered `AppBar` before `IconButton` and argued the parallel agent
needed `AppBar` most. **That argument was wrong on its own terms**: `AppBar`'s
`TitleBack` and `Transparent` variants contain a back control that the spec
requires to be ≥44×44, which is an `IconButton` — so `AppBar` depends on
`IconButton` and building it first produces either a blocked task or throwaway
code.

Order is: tokens → `IconButton` → `AppBar` → hand-off. The parallel agent needs
both, and this way neither is built twice.

`ListRow` and `SectionHeader` are **not** in this change — the home-dashboard
agent owns them, and screens 01.10 and 01.12 in the follow-up change depend on
them. That dependency runs the other way and is recorded in the brief.

## D7 — `Select` renders the closed state only

`38:131` authors two variants, both closed: `Placeholder` and `Value`. The picker
that opens is `BottomSheet` (`59:211`), which is unimplemented.

Options: build the sheet too (scope creep into an unimplemented organism), or
ship a control that renders closed and delegates activation. **Chosen: delegate.**
The spec says so, so `auth-screens` cannot discover it as a surprise.

## D8 — `Logo` needs no asset

`70:205` was read before this was written. The mark is a 48px container at
`radius-md`, filled with a gradient from violet-500 to mint-500 at 128.48°,
carrying the `glow/brand` effect, with `icon/zap` at 26px centred. The wordmark is
the string "Moneta" in `heading/h1`. Every piece exists.

So: drawn natively, `pubspec.yaml` untouched, no `assets/brand/` directory, and
no `runAsync` needed in its test. Had it been an SVG this would have been a
build-config change and the proposal's "lib/design_system only" would have been
false — which is why it was read before being planned rather than listed as a
risk.

It has **two** variants, not the one the first draft claimed: `showWordmark`
is a property on the node.

## Verification

| Requirement | Test | Gate |
| --- | --- | --- |
| Gallery catches variant shortfall | `test/app/gallery_test.dart` generic count check | test |
| Eight new tokens have provenance rows | `token_provenance_test.dart` | test |
| New colours are pinned and lerp-complete | `colors_test.dart` | test |
| IconButton 18 combinations, rendered **and** table pinned | `icon_button_test.dart` | test |
| AppBar 4 variants; offset follows insets 20 and 47 | `app_bar_test.dart` | test |
| AppBar title truncates; 0/1/2 actions; empty title | `app_bar_test.dart` | test |
| TextField 5 derived states; error and focus differ by width | `text_field_test.dart` | test |
| TextField long/empty label, value, helper | `text_field_test.dart` | test |
| OtpField derived filled-ness; over-long code refused | `otp_field_test.dart` | test |
| Select placeholder/value tokens; delegates; disabled inert | `select_test.dart` | test |
| Checkbox three marks; 44×44 hit area; disabled inert | `checkbox_test.dart` | test |
| Divider orientation, tones, unbounded parent | `divider_test.dart` | test |
| Logo both forms; square; announces `Moneta` | `logo_test.dart` | test |
| No status-bar widget exists | `gallery_test.dart` class scan | test |
| No raw colour/type/inset/radius | — | `check_design_tokens.dart` |
| No layer violation | — | `check_architecture.dart` |

**Each task names its own mutations and runs them at its checkpoint** — not in a
single pass at the end. A survivor found after eight components means reopening
eight components at once, and the six rounds on `onboarding-flow` were mostly
spent discovering that a green suite is not evidence.

## Risks

- **Adding a required field to `GallerySection` breaks the parallel agent's file
  the moment they add a section.** Mitigated by doing it first and telling them.
  If they have already added sections when 1.1 lands, the fix is theirs to rebase
  and mine to tell them immediately, not to make the field optional.
- **`25:219` may instance an icon the set lacks** (D4). Raised, not absorbed.
- **Merge surface.** Only `gallery_catalog.dart`, `gallery_test.dart`,
  `figma-map.md` and `figma-tokens.md` are shared, each with an owner marker. A
  conflict anywhere else means an ownership rule was broken and is reported, not
  guessed at.
