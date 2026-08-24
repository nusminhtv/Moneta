## Context

Figma is the source of truth and it is unusually well specified: tokens are named
(`bg-surface`, `income-base`, `radius-xl`, `display/amount-xl`), and component
descriptions state the rules the component owns — the budget bar's colour is
"derived from spend, never chosen". The job here is to move those rules into Dart
without diluting them, and to make the gates enforce that no screen can bypass them.

Two constraints shape everything below:

- `tool/check_design_tokens.dart` exempts only `lib/design_system/tokens|theme`.
  Every other file must resolve design values through the theme.
- `tool/check_architecture.dart` allows `design_system → core, design_system`.
  So anything the design system needs from the domain must live in `lib/core`.

## Goals / Non-goals

**Goals**: a token layer that mirrors Figma exactly; a theme reachable from any
build context and injectable in tests; three organisms and two molecules with
complete variant coverage; a gallery route; tests that would fail if a token
value drifted.

**Non-goals**: screens, persistence, light theme, the other eleven Figma
component sets, localisation, animation beyond motion tokens.

## Decisions

### D1 — Tokens are a `ThemeExtension`, not global constants

**Options.** (a) `ThemeExtension<MonetaTheme>` on `ThemeData`; (b) static `const`
classes (`MonetaColors.income`); (c) a bespoke `InheritedWidget`.

(b) is the least code and reads well, but it makes the token set unswappable: a
golden test cannot pump a widget with an alternate token set, and a light theme
later means touching every call site. (c) reinvents what `ThemeExtension` already
does and loses `lerp` for free.

**Chosen: (a).** `MonetaTheme extends ThemeExtension<MonetaTheme>` carries
`MonetaColors`, `MonetaTypography`, `MonetaSpacing`, `MonetaRadii`,
`MonetaElevation`, `MonetaMotion` as immutable value objects. A
`BuildContext.moneta` extension getter is the single accessor. The raw values live
in `tokens/` as `const` — inside the checker's exempt path — and are assembled
into the extension in `theme/`.

This satisfies the spec requirement "tokens are reachable from any build context
and overridable in tests without rebuilding the app": a test wraps a widget in
`MaterialApp(theme: MonetaTheme.dark().toThemeData())` or passes a modified
extension.

### D2 — `SpendCategory` lives in `lib/core`, not in the design system

Figma binds colour *and* glyph to a category: "pick a category, never a colour".
That binding has to be reachable from both the design system (to render) and
future feature domains (to classify a transaction). Since `design_system` may
import `core` but not the reverse, and features may import both, `lib/core` is
the only legal home.

`SpendCategory` is an enum carrying a chart-palette slot index and an icon name.
It carries the *slot*, not a `Color` — a `Color` in `lib/core` would import
Flutter into the pure layer and would put a design value outside the token path.
The design system resolves slot → colour.

### D3 — Icons are committed SVG assets

See [ADR 0002](../../../docs/adr/0002-icon-delivery.md). Stroke weight in the
design is 1.75, which no published icon package matches, so the exported assets
are the only faithful source. `MonetaIcons` maps name → asset path; `MonetaIcon`
takes size and colour from tokens.

### D4 — The gradient is one token, and it is documented as hand-maintained

Figma cannot bind variables to gradient stops, so the file's own note says this
is the system's only hard-coded paint and must be updated by hand if
violet-600 / violet-500 / mint-600 change. We mirror that exactly: a single
`MonetaColors.brandGradient` built from the three named palette constants rather
than from three fresh hex literals, so a palette change does propagate. The
angle (137.66°) is kept as a named constant with the Figma value in a comment.

### D5 — Derived state is computed inside the component, from `Money`

`BudgetCard(spent: Money, limit: Money, category: SpendCategory)` — no `state`
parameter. The threshold rule (`<80%` income, `80%..100%` warning, `>100%`
expense) lives in one place, `BudgetStatus.fromSpend`, in the design system next
to the widget that renders it. This is what makes the spec's "a caller SHALL NOT
be able to select an appearance that contradicts the data" true by construction
rather than by convention.

`Money.ratioOf` already clamps to `0..1` and returns `0` for a zero total, which
covers the "bar never overflows" and "zero limit" scenarios; `BudgetStatus`
handles zero-limit-with-spend as over-limit separately, because a clamped ratio
of `0` would otherwise read as on-track.

### D6 — Masked balance hides digits by substituting text, not by overlaying

Figma uses dedicated masked text nodes ("•• ••• ••• ₫") rather than a blur. We do
the same: the masked variant renders a mask string. This makes the spec scenario
"no digit from any of the four amounts is present in the rendered output"
directly testable — a widget test can assert no digit appears in the render tree,
which an opacity or blur overlay would fail.

### D7 — Fonts are bundled, not fetched

Inter and Plus Jakarta Sans are declared in `pubspec.yaml` as bundled font
families. `google_fonts` would fetch at runtime, which means first paint uses a
fallback and golden tests become non-deterministic. Bundled fonts also keep the
app working offline, which a local-first app should.

## Risks / trade-offs

- **Token drift.** The gate stops raw values appearing outside `tokens/`, but
  nothing stops a *wrong* value being typed inside `tokens/`. Mitigation: the
  token test asserts the concrete Figma hex values, so a typo fails a test rather
  than shipping. This is the one place where the test asserts constants against
  constants deliberately — it is a transcription check, and transcription is
  exactly what can go wrong here.
- **Letter-spacing units in Figma (resolved during task 1.1).** The style summary
  reports `letterSpacing: -1` for both `display/amount-xl` and `heading/h1`, while
  the emitted CSS says `-0.4px` (40px text) and `-0.28px` (28px text). Since
  −0.4/40 = −0.28/28 = −1%, the summary figure is a percentage. Implemented as
  absolute `-0.4` and `-0.28`. Recorded in `docs/design-system/figma-tokens.md`.
- **Spec corrected during task 1.1.** The specs originally said "six named text
  styles". Reading `39:8` and `42:329` surfaced `heading/h1` and `body/md`, making
  it eight. The spec was updated before any typography code was written, rather
  than the code quietly covering eight while the spec claimed six.
- **Motion has no Figma source.** No transition or easing value appears in any node
  read. Motion tokens are defined from Material's emphasised durations and curves
  and are marked in code as not Figma-derived — the only such values in the token
  layer.
- **Chart base colours came from exported SVG strokes, not from variables.** Figma
  does not emit `var(--chart-N)` for a glyph's stroke, and `get_variable_defs`
  needs a live desktop selection. The strokes were read from the downloaded assets
  and confirmed against a screenshot of `33:311`, because an export resolved in
  light mode would have produced plausible but wrong values.
- **Only three of fourteen component sets.** Deliberate: each remaining set
  arrives with a real caller. The risk is that a later screen needs one urgently;
  the mitigation is that `/moneta:figma-pull` makes adding one a short, repeatable
  operation.
- **Goldens are platform-sensitive.** Font rendering differs between macOS and
  Linux CI. Mitigation: goldens are generated and compared on CI's platform only
  (`flutter test --update-goldens` is never run in CI), and layout-critical
  assertions are written as explicit geometry checks rather than relying on
  goldens alone.

## Verification plan

Each spec requirement maps to a concrete gate:

| Spec requirement | Verified by |
| --- | --- |
| Tokens are the only source of design values | `dart run tool/check_design_tokens.dart` (gate) |
| Colour tokens resolve to Figma values | `test/design_system/tokens/colors_test.dart` — asserts every hex |
| Typography tokens | `test/design_system/tokens/typography_test.dart` — family/size/height/spacing per style |
| Radius / elevation / motion tokens | `test/design_system/tokens/tokens_test.dart` |
| Tokens reachable from context; overridable in tests | `test/design_system/theme/moneta_theme_test.dart` |
| Components own derived state | `test/design_system/organisms/budget_card_test.dart` — threshold table test; plus the absence of a `state` parameter in the API |
| Components accept domain types | Compile-time: constructors take `Money`; `test/.../balance_card_test.dart` asserts formatted output |
| Full variant coverage | One test per variant per component; `test/design_system/variant_coverage_test.dart` cross-checks the count against `docs/design-system/figma-map.md` |
| Balance card masked hides digits | Widget test asserting no digit in the render tree |
| Budget card thresholds and border | Table-driven widget test at 0%, 79%, 80%, 100%, 101%, 400%, and zero-limit |
| Bar never overflows | Geometry assertion on the fill's width vs the track's |
| Bottom nav exactly one active | Widget test per active value asserting colours of all four |
| Bottom nav safe area | Widget test with a `MediaQuery` bottom inset |
| Icons complete and resolvable | `test/design_system/icons_test.dart` — enumerates the catalogue, asserts each asset loads from the bundle |
| Gallery covers everything | `test/app/gallery_test.dart` — asserts one entry per component per variant |

Plus the standing gates: `dart analyze --fatal-infos`, `check_architecture.dart`,
coverage ≥85% on `lib/core` (the new enum) and ≥70% overall.

## Open questions

- **Light theme values.** Figma is dark-only. Structure supports a light set;
  values do not exist. Left open rather than invented.
- **Remaining chart palette slots.** Three of the eight `chart-N-subtle` values
  are directly observed (`2`, `4`, `7`); the other five must be read from Figma
  during task 1 rather than interpolated. If a slot cannot be read, the task
  stops and asks — an interpolated palette would silently break the CVD-validated
  spacing the Figma notes describe.
