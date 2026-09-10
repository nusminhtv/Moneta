## 1. The Token

- [x] 1.1 `brandSubtle` on `MonetaColors` — `#1A1236` from `21:106`'s bound
  variable — wired through the constructor, `figma()`, `props` and `lerp`.
  Verify: `test/design_system/tokens/colors_test.dart` asserts the value; the
  subtle-family test asserts the brand now has one; the lerp test asserts it
  interpolates; and it is asserted distinguishable from `canvas`, `surface` and
  `surfaceRaised`. `bash tool/verify.sh --change profile-components` passes.

## 2. Avatar

- [x] 2.1 `lib/design_system/atoms/moneta_avatar.dart` from `21:121`: three
  types × four sizes, all twelve, on `brandSubtle`, circular.
  Verify: `test/design_system/atoms/moneta_avatar_test.dart` asserts every size
  is its authored diameter and circular, and every variant sits on
  `brandSubtle`.
- [x] 2.2 The per-size type table (D2): `label/sm`, `label/sm`, `label/md`,
  `title/md`, in `brandOnSurface`.
  Verify: one assertion per size against the theme's own style, so a change to
  the type scale moves both together; plus a test that 24 and 32 share a style
  and 40 and 56 do not, which is the thing a formula would get wrong.
- [x] 2.3 The per-size glyph table: 14, 18, 22, 28, in **`textSecondary`**.
  Verify: one assertion per size; and an explicit assertion that the glyph is
  *not* `brandOnSurface`, because that is what I assumed before reading
  `21:120`'s exported stroke.
- [x] 2.4 Initials derived from a name (D3), with the icon fallback.
  Verify: one word gives one initial, several give two, lowercase is upcased,
  and an empty or letterless name falls back to the icon rather than an empty
  circle. Initials stay inside the circle at the smallest size.
- [x] 2.5 The image type (D4): an `ImageProvider`, clipped to the circle, with
  the initials-then-icon fallback when none is supplied.
  Verify: a supplied image is clipped circular; no image falls back correctly.
- [x] 2.6 Gallery registration at all twelve, with a count test.
  Verify: `test/app/gallery_test.dart` fails if fewer than twelve are
  registered, and the labels are Figma's own variant names.

## 3. Close-Out

- [x] 3.1 `docs/design-system/figma-map.md`: `Avatar` done with its node and
  variant count; `brandSubtle` recorded as a token this change added and why it
  was missing; the per-size tables recorded as transcribed, with the note that
  the glyph formula fits three of four points and is wrong at 56.
  Verify: the entry names the nodes and says which values are transcribed.
- [x] 3.2 Run the full gate.
  Verify: `bash tool/verify.sh --change profile-components` passes.
