Each task below is one checkpoint: widget, gallery entry, describer case, tests
and its own mutations together. **They cannot be split into
build-then-register** — `test/app/gallery_test.dart` walks `lib/design_system`
from the filesystem, so a component that exists and is unregistered fails the
suite and the gate would be red between the two halves.

Ten mutations in total. Each is run, and recorded in
`docs/ai-workflow/evidence-log.md`, **in the task that owns it** — not batched
into close-out, where a decorative test would already be committed.

## 1. Badge

- [x] 1.1 `MonetaBadge` at all ten authored variants (`17:32`), registered in
  the gallery with its describer case and its literal count in
  `test/app/gallery_test.dart`. Tone enum owns both colours per the spec's table
  — `Neutral` is `surfaceRaised` + `textSecondary`, not a subtle pair.
  `labelSm` label, mandatory and asserted non-empty; dot on by default at
  5px/6px; total height 22 at `Sm` and 26 at `Md`; `theme.radii.borderPill`.
  Verified by `test/design_system/atoms/moneta_badge_test.dart` — a table over
  5 tones × 2 sizes asserting both token colours, the dot size and the total
  height reach the render tree; a long label contained in a 120px parent at
  text scales 1.0/1.3/2.0; an empty label asserting — plus the catalog test with
  a **literal** ten.
  **M1:** swap `Success` and `Danger` fills → the table must fail.
  **M2:** make `Neutral` an `infoSubtle` pair → the `Neutral` row must fail.

## 2. Chip

- [x] 2.1 `MonetaChip` at all six authored variants (`17:65`), registered with
  its describer case and literal count. Three types × selected; the brand
  triple asserted as a set; `Type=Input` always carrying its close control;
  optional 16px leading glyph; `labelMd`; empty label asserting;
  `theme.radii.borderPill` with `MonetaLayout.borderWidthHairline`. **The 34px
  pill inside a `MonetaLayout.minTouchTarget` box ships in this same task** —
  the accessibility requirement is not left unmet at a checkpoint — with the
  close control owning a 44px square at the trailing end and selection owning
  the remainder. Verified by `test/design_system/atoms/moneta_chip_test.dart`,
  measuring **both** the painted pill (34) and the occupied box (44), asserting
  the two tap areas partition it, and truncating a label in a 140px parent with
  the close control still fully visible.
  **M3:** give the selected chip the unselected border → the triple assertion
  must fail.
  **M4:** drop the hit box so the chip is 34 tall → the box measurement must
  fail.

## 3. SearchField

- [x] 3.1 `MonetaSearchField` at both authored states (`35:38`), registered with
  its describer case. State **derived** from the text; 50 tall (`13 + 24 + 13`,
  border painted inside); `bodyLg`; pill shape; the clear control inside a 44px
  hit area. Verified by
  `test/design_system/molecules/moneta_search_field_test.dart`: empty shows the
  placeholder and no clear; text shows the value and a clear; clearing empties
  and reports; typing reports; heights and hit areas measured; and a source
  check over the **constructor parameters** (guarded by a counterfeit) that none
  is named for a state.
  **M5:** accept a `state` parameter → the source check must fail.
  **M6:** shrink the clear control to its 18px glyph → the hit-area measurement
  must fail.
- [x] 3.2 Controller ownership (D5): accept one, or create and dispose one, with
  replacement through `didUpdateWidget`. Verified by tests asserting that a
  **supplied** controller is still usable after the field is unmounted, that an
  **owned** controller reports itself disposed, and that a replaced controller
  is the one read and reported — not by the absence of an exception, which a
  missed disposal does not produce.
  **M7:** dispose the supplied controller too → the first assertion must fail.
- [x] 3.3 Boundaries: disabled accepts nothing and offers no clear; focus
  changes nothing; a value longer than the field neither grows it nor hides the
  clear control; a pasted newline does not make it two lines tall. Verified by
  the same test file.
  **M8:** honour `enabled` in the decoration but not in the input handling →
  the disabled test must fail. (This task carries its own mutation so it can
  fail independently of 3.1, rather than being pure test work behind shipped
  behaviour.)

## 4. Numpad

- [ ] 4.1 `NumpadKey` at both authored variants (`36:91`), registered with its
  describer case — digit label in `headingH2`, 22px action glyph, 56 tall,
  inert without a callback. Verified by
  `test/design_system/molecules/numpad_test.dart` and a catalog assertion of the
  **literal two**, standing beside the enum-derived expression.
  **M9:** add a third `pressed` member to the key-type enum **and** register a
  catalog variant for it → the literal count must fail while the enum-derived
  count passes. Adding only a catalog entry would fail both and would
  demonstrate nothing, which is the point of the mutation.
- [ ] 4.2 `Numpad` (`36:92`) registered with its describer case — 3 × 4, rows
  filling the given width, digits in reading order, action key reporting a
  delete with the set's `chevronLeft` glyph, nothing thrown with no callbacks.
  Verified by the same file: equal-width keys at 353, 393 **and 200**, every
  digit reported, and `1` painted left of `3` under `TextDirection.rtl`
  (positions, not tree order).
  **M10:** fix the key width at the standalone 109 → the 200px case must fail.
  Note: this task lands with the third-last cell already a **required**
  parameter, because 4.3 makes it one and a default added here would have to be
  removed there.
- [ ] 4.3 The third-last cell as that required parameter (D8): the authored
  decimal key, or an **empty cell** for a PIN, no default. Verified by a test
  that the PIN pad renders one fewer key and can report no decimal, and by the
  amount pad reporting one.

## 5. Close-out

- [ ] 5.1 Documentation, in one pass. `docs/design-system/figma-map.md`: the
  five inventory rows marked done; the `NumpadKey` row corrected from 4 to 2
  with "the description claims 4"; the stroke convention recorded with the table
  from `design.md` (chip 34 against a 36 description, search 50 against a 48
  description, one rule, both frames); `SearchField`'s off-scale 13px padding;
  the `chevron-left` action glyph and the absent backspace icon; the decimal
  cell deviation; `Chip`'s 44px box and the layout shift it hands `08.08`; and
  the `04.04` note corrected where it records `Numpad` as not built. Plus the
  three stale source comments named in the proposal, and `profile-feature`
  §6's blocker lines for 6.3, 6.5, 6.6 and 6.8 rewritten to what actually
  remains.
  **Scope is those rows only.** Roughly seventeen other inventory rows are
  built-but-unmarked from earlier changes, and `figma-map.md`'s "Seven are
  implemented" line disagrees with its own table; both are out of scope here and
  named so the next change inherits a known number rather than a wrong one.
  Verified by `rg` for the **new** strings — "the description claims 4", the
  stroke-convention heading, "13", "chevron-left", "44px box" — not for the
  component names, which are already in the file today.
- [ ] 5.2 Full `tool/verify.sh --change settings-components` green with the
  evidence file committed, and `docs/ai-workflow/evidence-log.md` carrying
  **ten** mutation records (M1–M10) for this change with their outcomes.
  Verified by the gate's own summary and by `rg -c` over the log.
- [ ] 5.3 `figma-fidelity` **per component**, five runs, each against its node
  (`17:32`, `17:65`, `35:38`, `36:91`, `36:92`). A finding is either fixed in
  this task or recorded in `figma-map.md` as a deviation with its reason —
  stated now so a fidelity finding is not unbounded rework discovered late.
  Verified by the five verdicts.
- [ ] 5.4 `change-verifier` says ship. Verified by the agent's verdict, not by
  my own reading of the diff.
