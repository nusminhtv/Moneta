Each task is one checkpoint: verify → self-review the diff → tick → commit.
Each names the mutations to run **at that checkpoint**, not in a pass at the end.

## 1. Unblock the parallel agent

- [ ] 1.1 **Make variant shortfall catchable** (D0). Add a required
  `expectedVariants` to `GallerySection`, populate it for the five existing
  sections from `figma-map.md`, and add one generic test asserting
  `variants.length == expectedVariants` for **every** section.
  Verify: `test/app/gallery_test.dart` passes.
  Mutations: drop one variant from the `Button` section → the new check fails;
  set `expectedVariants` to `variants.length` computed from the list itself →
  the check can no longer fail, so it must be written against the declared
  number, not a derived one.
  *Do this first: it edits the shared `gallery_catalog.dart` while the parallel
  agent's section list is still empty.*

- [x] 1.2 **Eight tokens with provenance** (D2). Add `heading/h3`;
  `border-default`, `border-focus`, `text-disabled`; `border-width/hairline`,
  `/emphasis`, `/focus`; `gradient/mark`. Add a `figma-tokens.md` row for each
  naming its node (`39:58`, `27:5`, `27:18`, `27:38`, `27:5`, `27:32`, `27:18`,
  `70:206`). Extend `MonetaColors`' constructor, its `lerp`, and the
  `colors_test.dart` construction.
  Verify: `token_provenance_test.dart`, `colors_test.dart`, `typography_test.dart`.
  Mutations run: deleting the `border-focus` doc row → provenance fails, correct.
  Dropping `borderFocus` from `lerp` → **survived**, so the lerp test was the
  defect, exactly as this task anticipated: it asserted canvas, income and one
  chart slot, three remembered fields standing in for twenty-three. `MonetaColors`
  now exposes `all`, the lerp check asserts every entry reaches the target, and a
  second test parses the source so `all` cannot silently omit a field. Both
  mutations now fail, plus a third (removing a field from `all`).

  Border widths went into `MonetaLayout` beside `iconStrokeWidth` rather than a
  new token file — design.md said "border-width tokens" without saying where, and
  a new file would have sat outside the provenance check until someone remembered
  to add it, which is the hand-enumerated hole this project keeps falling into.

- [x] 1.3 **`IconButton`** from `20:114` — 3 styles × 3 sizes × 2 states.
  Dimensions on the size enum (D3). Register all 18.
  Verify: `test/design_system/atoms/icon_button_test.dart` asserts the **rendered**
  background, border and glyph colour per combination, **and** pins each table
  entry to a named token exhaustively over style × size × state; disabled is
  inert; the semantics node carries the caller's label and not the glyph name;
  sizes are 36/44/52.
  Mutations run, all five caught: ghost glyph → textPrimary; disabled glyph →
  textTertiary; sm box 36 → 44; semantic label → the glyph name; disabled still
  calling its callback.

  The glyph colours were read from the node's bound variables with
  `get_variable_defs`, not inferred from `MonetaButton`'s mapping. That matters:
  the inference would have been **wrong**. This component's disabled glyph is
  `text-disabled` where the button's is `text-tertiary`, and ghost resolves to
  `text-secondary` where the button's ghost is `text-primary`. Two invented values
  avoided by one tool call.

- [x] 1.4 **`AppBar`** from `39:112` — LargeTitle, TitleBack, TitleActions,
  Transparent. Reads `MediaQuery.padding.top`, never `MonetaLayout.safeAreaTop`
  (D1). Register all four.
  Verify: `app_bar_test.dart` asserts 96/56 bar heights; that content begins at
  the inset under **20 and 47**; that Transparent paints no background while the
  others paint canvas; that a back control ≥44×44 exists only on TitleBack and
  Transparent; that a long title ellipsises while the actions keep their
  rectangle; that an empty title keeps the height; and 0/1/2 actions.
  Mutations run, all six caught: reading `MonetaLayout.safeAreaTop` instead of the
  inset; LargeTitle 96 → 56; Transparent painting a background; TitleActions using
  h1 instead of h3; dropping the ellipsis; Transparent losing its back control.

  The action control turned out to be a ghost/md `IconButton` — `get_variable_defs`
  on `39:18` returns exactly `text-secondary` and `radius-pill`. That confirms the
  dependency the audit found and this task order was changed for.

  `MonetaAppBarAction` is a **record typedef**, not a class: a class under
  `lib/design_system` must be in the gallery or exempted, and a value type that
  renders nothing is neither. The record needs no exemption to explain away.

- [ ] 1.5 **Hand off.** Append the two commit SHAs for 1.3 and 1.4 and the
  verify-run path to `docs/ai-workflow/evidence-log.md`, and update the status
  line in `docs/ai-workflow/parallel-brief-home-dashboard.md` to say
  `IconButton` and `AppBar` are on `main` and that `GallerySection` now requires
  `expectedVariants`. Then tell the user to merge, because the parallel agent's
  six screens are blocked until then.
  Verify: both artifacts contain the SHAs; `bash tool/verify.sh --change
  auth-components` green.
  *This task exists because "tell the user" is not a work product. Its output is
  two edited files, which is checkable.*

## 2. Input components

- [ ] 2.1 **`TextField`** from `27:44` — five states, all **derived** (D5), body
  52px.
  Verify: `text_field_test.dart` asserts the 52px body; that error changes border
  colour **and** border width and the helper token, and that width alone
  separates error from default; that focus changes border width and adds the
  brand glow; that filled shows the value in primary and empty shows the
  placeholder in tertiary; that disabled reads the disabled tokens and refuses
  input; that omitting the label puts the body at the widget's top edge and makes
  the widget shorter; and that an over-long label, value and helper — including
  one unbroken word — do not overflow.
  Mutations: make error and default share a border width → the greyscale test
  fails; accept a `state` parameter and render error with no `errorText` → the
  derivation test fails; use `textPrimary` at opacity for disabled → the token
  test fails.

- [ ] 2.2 **`OtpField`** from `70:263` — Empty, Partial, Complete, length a
  parameter.
  Verify: `otp_field_test.dart` asserts filled-ness is derived from the code and
  cannot be passed; that a filled position renders its character and an empty one
  renders none; that a code longer than the length is a validation failure, not a
  silent truncation; that the value round-trips.
  Mutations: report complete for a short code → the derivation test fails;
  truncate an over-long code silently → the validation test fails.

- [ ] 2.3 **`Select`** from `38:131` — Placeholder, Value; renders closed and
  delegates activation (D7).
  Verify: `select_test.dart` asserts placeholder and value use different text
  tokens; that it takes a value plus a label function, not a formatted string;
  that activation fires the callback and presents nothing; that disabled is inert.
  Mutations: render the placeholder in the primary token → the token test fails;
  fire the callback when disabled → the inert test fails.

## 3. Remaining atoms

- [ ] 3.1 **`Checkbox`** from `25:229` — 3 states × enabled/disabled.
  Indeterminate draws a bar natively; if `25:219` instances an icon the set lacks,
  **raise it before implementing** (D4) — adding an icon changes the count
  `moneta_icon_test.dart` pins at 50 and is a rule-5 gate change.
  Verify: `checkbox_test.dart` asserts the three marks are distinct shapes, not
  tints; that indeterminate reports itself; that disabled is inert; that the drawn
  box is 22×22 and the hit area ≥44×44.
  Mutations: render indeterminate with the check glyph → the distinct-mark test
  fails; shrink the hit area to the drawn box → the touch-target test fails.

- [ ] 3.2 **`Divider`** from `21:126` — 2 orientations × 2 tones.
  Verify: `divider_test.dart` asserts which dimension is the hairline per
  orientation; that the tones resolve to different border tokens; that a
  horizontal divider in an unbounded-width parent renders rather than throwing.
  Mutations: give both tones the same token → the tone test fails; use
  `double.infinity` on the cross axis → the unbounded test fails.

- [ ] 3.3 **`Logo`** from `70:205` — mark alone and mark with wordmark (D8).
  Drawn natively; no asset, no `pubspec.yaml` change.
  Verify: `logo_test.dart` asserts both forms render the mark and differ by the
  wordmark's presence; that the mark stays square when resized; that exactly one
  semantics node carries `Moneta` and no descendant adds an image or icon node;
  that the gradient reads the palette constants rather than fresh literals.
  Mutations: hardcode the gradient stops → the palette test fails; label the logo
  anything other than the product name → the semantics test fails.

## 4. Close-out

- [ ] 4.1 Record in `docs/design-system/figma-map.md`: the eight components moved
  to implemented with their nodes and variant counts; the `StatusBar` deviation
  and its reasoning (D1); the second gradient and why the requirement changed; and
  every dimension pinned on a component enum, with the node it was read from, in
  the existing table for values with no separate provenance row.
  Verify: `token_provenance_test.dart` still passes; the map's component table
  matches `expectedVariants` in the catalog for all eight.

- [ ] 4.2 Run `bash tool/verify.sh --change auth-components` and the
  `change-verifier` agent. Resolve everything it marks DO NOT SHIP, and record
  each finding rather than only the fix. Append the outcome to
  `docs/ai-workflow/evidence-log.md`, including which mutations were tried per
  task and any that survived.
