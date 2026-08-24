# 0002. Icon delivery

- **Status:** Accepted
- **Date:** 2026-08-24
- **Change:** design-system-foundation

## Context

The Figma file's `🎨 Foundations / Iconography` page (node `5:7`) defines 51
icons. Every icon carries the same documented constraint:

> 24px stroke icon, 1.75 weight. Use via INSTANCE_SWAP — never create a variant
> per icon.

Two facts from that constraint drive this decision:

1. **Stroke weight is 1.75, not 2.** Feather, Lucide and Material Symbols all
   ship at 2.0 (Material Symbols is variable but is a different drawing).
   Substituting any of them changes the visual weight of every icon in the app.
2. **Icons are swapped, not variant-coded.** So the code needs a *catalogue*
   addressable by name, not 51 separate widgets.

Icons appear inside components that `tool/check_design_tokens.dart` polices, so
their colour must come from tokens, and their size must come from the size scale.

## Options considered

### Option A — Committed SVG assets rendered with `flutter_svg`

Download the 51 exported SVGs from Figma into `assets/icons/`, declare them in
`pubspec.yaml`, expose a `MonetaIcons` catalogue mapping names to asset paths.

- Fidelity: exact. The bytes are the designer's bytes, 1.75 stroke included.
- Cost: one dependency (`flutter_svg`); 51 files in the repo; SVG parsing at
  runtime, which is measurable but small for 24px line icons and cacheable.
- Refresh path: re-export from Figma and overwrite. Diffable in git.
- Makes harder later: nothing significant. Tinting works via `colorFilter`.

### Option B — An off-the-shelf icon package (`lucide_icons`, `feather_icons`)

Use a published package and map Figma names to its constants.

- Fidelity: wrong stroke weight on all 51 icons, and the design's set includes
  `brand-google` and `brand-apple`, which such packages do not carry.
- Cost: near zero to adopt.
- Wrong if: the 0.25 stroke-weight difference is invisible in practice. It is not
  — at 24px, stroke weight is roughly 8% of the glyph's visual mass, and the
  design's whole surface is thin-line iconography on near-black.

### Option C — Generate a custom icon font from the SVGs

Convert the exported SVGs into a `.ttf` and use `IconData`.

- Fidelity: exact, same source bytes.
- Cost: a build step outside Flutter's toolchain, plus a generated binary that
  git cannot diff and our gates cannot inspect. Changing one icon regenerates the
  whole font. Multi-colour icons are impossible, and the two brand icons are the
  kind that usually want colour.
- Benefit: fastest runtime, single asset.

### Option D — Hand-authored Dart `CustomPainter` per icon

- Rejected without scoring. 51 hand-transcribed vector paths is the single most
  likely place for an AI-authored change to introduce silent visual error, and no
  gate we have would catch it.

## Decision criteria

| Criterion | Weight | Why |
| --- | --- | --- |
| Visual fidelity to the designer's file | high | Stroke weight is an explicit design constraint |
| Refresh cost when Figma changes | high | The icon set will grow |
| Reviewability of the committed artifact | high | This repo trusts what gates and diffs can see |
| Runtime cost | low | 24px line icons, a handful on screen at once |
| Dependency count | low | One well-maintained package is acceptable |

## Decision

**Option A — committed SVG assets rendered with `flutter_svg`.**

Fidelity is a stated design constraint, which eliminates B. Between A and C, A
wins on reviewability: an SVG is a text file that a diff shows and a human can
read, whereas a generated font is an opaque binary that our verification gate
cannot say anything about. Runtime cost is the only axis where C wins and it is
the lowest-weighted one.

The catalogue is a `MonetaIcons` map from name to asset path plus a
`MonetaIcon` widget that takes `size` and `color` from tokens, so
`check_design_tokens.dart` still applies at every call site.

## Consequences

- `flutter_svg` added to `dependencies`.
- `assets/icons/*.svg` committed and declared in `pubspec.yaml`.
- A test asserts the catalogue is complete and every path resolves to a bundled
  asset — a missing asset must fail in CI, not at runtime on a user's device.
- Re-exporting from Figma is a routine, diffable operation.

## Strongest counter-argument

`flutter_svg` parses SVG at runtime on every first paint. In a long scrolling
transaction list with a category icon per row, that cost is paid per distinct
icon and could show up as jank on low-end Android. If profiling shows it, the
answer is to cache the rendered pictures or move to Option C — but the icons in
`CategoryIcon` are drawn from a fixed 8-item set, so the cache is tiny and this
is unlikely to bite.

## Revisit when

- The icon set passes roughly 150 icons, or
- profiling shows SVG rasterisation in a scroll-performance trace, or
- a design requires multi-colour icons in a list (which would also rule out C).
