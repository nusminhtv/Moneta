## Context

Everything here is transcription, not design. Figma page `5:14` has the screens
and each carries an annotation frame. The one novel decision is how to introduce
the correct spacing scale without breaking the widgets built on the invented one.

## Decisions

### D1 — Add Figma's spacing tokens; do not swap the invented ones yet

`docs/design-system/figma-tokens.md` records the defect: our `sm`/`md`/`lg`/`xl`
are 6/8/10/12 where Figma's are 8/12/20/24, and four of our steps (6, 10, 14, 28)
are not in the collection at all.

**Options.** (a) rename and remap now; (b) add the correct set alongside;
(c) build onboarding on the wrong scale and fix later.

(a) touches every existing widget and every widget test in the same change that
introduces twelve screens — the exact bundling the spec auditor has flagged twice.
(c) guarantees rework across twelve screens.

**Chosen: (b).** `MonetaSpacing` gains Figma's twelve names with Figma's values.
The old names stay, marked deprecated in the doc comment with the correct
replacement named. New code uses only the new set; the token checker cannot tell
them apart, so this relies on review, and the follow-up migration is what makes it
safe rather than permanent.

### D2 — `MonetaButton` implements all 45 variants, but not as 45 code paths

Figma: 5 styles × 3 sizes × 3 states, described as "the highest-reach component in
this system". CLAUDE.md requires the full variant set.

Style resolves to a `(background, foreground, border)` triple, size to a
`(height, horizontal padding, text style)` triple, and state modifies both. That
is three small tables and one build method, so completeness costs a table row
rather than a widget.

`Loading` swaps the label for a spinner **without changing width** — Figma states
this explicitly, and it is the one state with a layout consequence.

### D3 — The illustration is decorative SVG, the glyph is our icon

The slide illustration is a halo, a ring, four accent dots and a 72px glyph. The
glyph is an existing icon (`icon/credit-card` on slide one), so it uses
`MonetaIcon`. The halo, ring and dots are exported as SVG and rendered with
`flutter_svg` — the same route as the icon set.

Rejected: redrawing them as Flutter circles. Their fills are gradients and
opacities this project has not read, and inventing them is exactly the failure
this codebase has just spent a day correcting.

### D4 — The seen-flag needs a key/value store, and this change adds a minimal one

`home-overview` planned a `PreferencesStore` and is frozen. Rather than depend on
a frozen change or duplicate it, this adds the smallest store that satisfies one
boolean, in `lib/data/preferences/`, with the same shape the frozen change
specified so the two converge rather than collide.

Migration `v2` creates `settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)`.

### D5 — A failed read shows the introduction

Showing it twice is a minor annoyance; hiding the app behind a broken read is not.
The spec states this as a requirement rather than leaving it to the implementation.

**This reasoning applies to the write too, and the implementation missed that.**
Recording completion awaited a store that throws when the database cannot be
opened, from inside an async navigation callback — so the exception escaped,
`context.go` never ran, and the user was stuck on the last slide. The read path
guarded exactly this case; the write path did not, and the test that looked like
it covered the write closed the database while keeping the store object, so the
write returned `Err` and passed. Symmetric-looking coverage that was not
symmetric. Caught by `change-verifier` before archive, not by the gate.

### D6 — Routing decides once, at startup

The router reads the flag before building. It does not re-check on every
navigation, so finishing the introduction does not race with the redirect.

## Risks

- **Two spacing scales coexist.** Deliberate and time-boxed by the follow-up
  migration. The risk is a new widget reaching for an old name; only review
  catches that.

  It happened. `MonetaButton` used `theme.spacing.md` — the invented 8 — twice,
  and review did not catch it; `change-verifier` did. The value coincides with
  Figma's `space/sm`, so nothing looked wrong, which is precisely why "only
  review catches that" was too weak a control to write down and move on from.
  Now on `MonetaSpacing.spaceSm`. The follow-up migration should end the
  coexistence rather than rely on review again.
- **Figma's screens assume accounts.** This change stops before auth precisely so
  that conflict is decided on its own.
- **`bottomNavHeight` and the BalanceCard weight defect are untouched here.** They
  belong to the fidelity backlog, not to this change.

## Verification plan

| Requirement | Verified by |
| --- | --- |
| First run shows it; later runs do not | `test/features/onboarding/onboarding_providers_test.dart` |
| Skipping counts as completion | same |
| A failed flag read still shows it | same, with a failing store |
| Three slides, stable frame | `test/features/onboarding/onboarding_screen_test.dart` |
| Forward on last slide finishes | same |
| Skip absent on last slide | same |
| Swiping moves the indicator | same |
| Active dot differs in width, not just colour | `test/design_system/molecules/pagination_dots_test.dart` — asserts widths differ |
| Splash hands over unaided | `test/features/onboarding/splash_screen_test.dart` with a fake clock |
| Button: all 45 variants | `test/design_system/atoms/moneta_button_test.dart` — table-driven |
| Button: Loading keeps width | same |
| Spacing tokens match Figma | `test/design_system/tokens/spacing_test.dart` — asserts the twelve values |
