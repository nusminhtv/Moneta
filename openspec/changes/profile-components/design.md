## Context

- `21:121` is 3 types × 4 sizes. All twelve are required: `CLAUDE.md` says a
  Figma component set is implemented with all its variants, not just the one the
  current screen needs.
- The type style and glyph size **vary per size and do not scale**. Initials:
  `label/sm` at 24 and 32, `label/md` at 40, `title/md` at 56. Glyph: 14, 18,
  22, 28. A formula fitted to the small end is wrong at 56.
- `MonetaColors` has no `brandSubtle`, which every variant fills.
- `MonetaIcon` already takes a `MonetaIconName` and a size, so the icon type
  composes rather than draws.

## Goals / Non-Goals

Goals: twelve variants that a reviewer can compare against the canvas; a token
rather than a literal; initials derived rather than passed.

Non-goals: image loading of any kind (see `proposal.md`); the other four unbuilt
page-08 components.

## Decisions

### D1 — `brandSubtle` is a token, not a literal

`#1A1236` is a bound Figma variable (`--brand-subtle`) that this token set
simply lacks. Adding it is the smaller change: the alternative is a
`// design-token-ignore` in the first component that needs it, and then a second
when `Chip` or the paywall needs the same tint.

It also closes a real gap rather than serving one component — income, expense,
warning and info all already have their subtle counterpart.

### D2 — The type style per size is a table, not arithmetic

Four transcribed pairs on the size enum. Considered and rejected: deriving the
style from the diameter. 24 and 32 share `label/sm` while 40 and 56 differ from
both, so any formula has to special-case at least two of the four — at which
point it is a table with extra steps, and a table cannot be wrong between its
entries.

Same for the glyph sizes, and there the formula is actively misleading: 14, 18
and 22 are all `size / 2 + 2`, which fits three of four points and gives 30 at
56 where the file says 28.

### D3 — Initials are derived from a name

The component takes a display name and computes the initials. A caller passing
`"MT"` directly could pass anything — three letters, a lowercase pair, a
punctuation mark — and the circle would render it.

Falling back to the icon when a name yields no letters is what makes "no photo,
no name" a defined state rather than an empty circle. `21:121`'s own
description sets the order: *"Initials fall back when no photo exists."*

### D4 — The image type takes an `ImageProvider`

Not a URL, not a file path, not a widget. An `ImageProvider` is the type Flutter
already uses for "an image from somewhere", so the component stays out of
loading, caching and error handling — which is what `21:121` asks for by calling
the image variants placeholders.

A `Widget` child was rejected: it would let a caller put anything in the circle,
and the circle would then not be an avatar.

## Risks / Trade-offs

- **Twelve variants, one of which (image) cannot be meaningfully asserted in a
  widget test** — the gallery renders it with a `MemoryImage` of a 1×1 pixel, so
  the variant is at least exercised; visual correctness of a real photo is not
  something this repository's harness can check, and that is recorded rather
  than faked with a golden.
- **Initials in the placeholder font** — every glyph is `fontSize` wide in
  tests, so "does MT fit in 24px" cannot be asserted by width. Asserted as
  containment instead: the text's box stays inside the circle.

## Migration Plan

Additive. `brandSubtle` is a new field on `MonetaColors`, which is constructed
in exactly two places (`figma()` and the test double), both updated.
