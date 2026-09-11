## Context

See `proposal.md` — Why. Constraints that shape the approach:

- Four of the five sets are small and independent. The interesting decisions are
  about **two descriptions that disagree with their own frames**, three
  collisions with components that already ship, and one component reused for a
  job it was not drawn for.
- **The gallery makes build-then-register impossible to split.**
  `test/app/gallery_test.dart`'s "every design-system widget is in the catalog"
  walks `lib/design_system` from the filesystem, so a component that exists and
  is unregistered fails the suite. `_describe` additionally throws
  `UnsupportedError` for a widget type no describer knows, and each variant
  label is checked against the widget it builds. Each component's work is
  therefore one task: widget, catalog entry, describer, tests. (Enums are not
  matched by the scan's class regex, so the tone and type enums need no entry.)
- `tool/check_design_tokens.dart` (see `tool/design_token_rules.dart`) matches
  exactly five constructs: `Color(0x`, `Colors.`, `TextStyle(`, `EdgeInsets.*`
  containing a digit, and `BorderRadius.circular(` containing a digit. What that
  means here is spelt out under Risks — it fires on the paddings, it is blind to
  a `SizedBox`, and it cannot see an API at all.
- `MonetaSpacing` holds 0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64 and
  `MonetaRadii` 6, 10, 14, 18, 24, 999. `MonetaLayout` holds
  `minTouchTarget = 44` and `borderWidthHairline = 1`. The authored 3, 5, 6, 10,
  13, 22 and 56 are on no scale and become named `static const` doubles, the way
  `ChartLegendItem.verticalInset` and `MonetaCheckbox.boxSize` already are.
- `MonetaIcon` takes an arbitrary `size`, so 14/16/18/20/22px glyphs need no new
  plumbing.
- The 50-icon set has **no backspace or delete glyph** — checked against
  `MonetaIconName`'s 50 members. The action key's `key-glyph` instance-swaps to
  `icon/chevron-left`. A constraint, not a mistake.

### One stroke convention, and the two descriptions it makes wrong

`Chip` and `SearchField` each carry a description stating a height their own
frame contradicts. Rather than settle each by preference, one convention was
tested against both frames:

> **Figma draws these strokes inside the frame, so the frame *is* the padding
> box.** In Flutter, `DecoratedBox` wrapping `Padding` reproduces that exactly —
> the border paints inside the box and adds nothing to it. `Container` with
> `padding:` and a border does *not*: its decoration inflates the child by the
> border on every side.

Measured, not assumed — `DecoratedBox` + `Padding(vertical: 8)` + an 18px line
is **34.0**; the same content in a `Container` is **36.0**.

| | Description | Frame | Padding + line, stroke inside | Built |
| --- | --- | --- | --- | --- |
| `Chip` `17:65` | 36 | **34** (`101:1002`) | `8 + 18 + 8` = **34** | 34 |
| `SearchField` `35:38` | 48 | **50** (`102:1213`) | `13 + 24 + 13` = **50** | 50 |

One rule, both frames reproduced exactly, and both descriptions wrong by two —
in opposite directions, which is why no single fudge could have satisfied them.

The alternative convention was tried and **fails**: if the strokes were outside
and the codegen folded them into the reported padding, `SearchField` would be
`12 + 24 + 12` + 2 = 50 ✓ *and* keep 12 on the spacing scale, but `Chip` would
be `8 + 18 + 8` + 2 = 36 ≠ its 34 frame. It explains one frame and breaks the
other; the inside-stroke rule explains both.

The cost of the chosen reading is that `SearchField`'s vertical padding is
**13**, which is off the spacing scale — the scale has 12 and 16. That is
recorded as an off-scale authored value rather than rounded to 12, because
rounding it would miss the 50 the frame states. Both heights clear 44 either
way, which is what the descriptions exist to claim.

### What counts as a variant

The file distinguishes two kinds of property and this change follows it:

- A **variant property** — `Tone`, `Size`, `Type`, `Selected`, `State` — defines
  the variant set. `17:32` enumerates ten nodes (tone × size); `17:65` six
  (type × selected); `36:91` two.
- A **boolean component property** — `Badge`'s `dot`, `Chip`'s `leadingIcon` —
  is a slot toggle inside a variant, not an axis of it. No node exists for
  "Success/Sm without its dot".

So the gallery registers the **authored variant nodes** (10, 6, 2) and the
boolean properties are exercised by tests. This is stated once in the spec so
the counts and "every component in every variant" do not appear to disagree.

## Goals / Non-Goals

Design-level goals beyond the proposal's scope:

- Make each component's **accessibility claim satisfiable by the component**.
  Where the authored box is too small, the component owns the hit area; it does
  not publish a number and hope a caller reads it.
- Make a state that can be *derived* impossible to pass in.
- Leave every reading visible in the code with the arithmetic and the
  measurement that produced it.

Non-goals at design level:

- Animation and haptics. Nothing is authored; `NumpadKey` has no pressed variant.
- Goldens. This repository still has none. Structure and token assertions
  instead, and the gap stays recorded.
- A generic `ChipGroup`. Single selection across a row is the caller's
  invariant, exactly as `Radio`'s group rule was left to `RadioRow`
  (`insight-components` D8).

## Decisions

### D1 — `Badge` takes a tone enum, and the tone owns both colours

**Chosen:** `MonetaBadgeTone` with five members, each resolving its fill and
label from `MonetaColors`. The four semantic tones are `*Subtle` + the tone
colour; `Neutral` is `surfaceRaised` + `textSecondary`, encoded per-tone rather
than by a naming convention that would have to bend for it.

Alternatives:

- *Two colour parameters.* Rejected: ten authored variants exist precisely so
  `expenseSubtle` cannot be paired with `income`. A colour parameter makes the
  illegal pairing as easy as the legal one.
- *Derive both colours by name from one token family.* Rejected: works for four
  tones, breaks on `Neutral`. A convention with one exception is one nobody can
  rely on.
- *Extract `ListRow._RowBadge` and generalise it.* The real badge in the
  repository, and the alternative most worth naming. Rejected for this change:
  it fills `infoSubtle`, **draws an `info` border** and uses `captionMd`, where
  the authored `Badge` has no border and uses `labelSm`. Adopting `MonetaBadge`
  inside `ListRow` would change a shipped widget's appearance, force a tone into
  `ListRow`'s API, and put `35:113` up for re-checking. A follow-up, recorded in
  the proposal.

### D2 — `dot` defaults to on; the label is mandatory and non-empty

**Chosen:** `dot: true` by default, matching the Figma property's own default,
and a required label asserted non-empty.

Why this boolean gets a default while D8's decimal cell does not: the Figma
property **has** a default, and both of its renderings are legitimate for the
same caller — a badge without its dot is still a correct badge. `Numpad`'s cell
has no authored default because the file authors only the amount-entry pad; the
PIN cell is this change's invention, so there is no default to inherit and the
caller must say which it means. Stated because two decisions in one document
that treat defaults differently otherwise look like inconsistency.

The set's description — *"Never rely on tone alone — pair with the dot or with
text"* — is discharged by the **label**, not the dot: the dot is drawn in the
label's own colour and so carries nothing a colour-blind reader can use. A
mandatory non-empty label is the only thing that actually satisfies the rule,
which is why `''` is an assertion failure.

Rejected: a mandatory dot. It would make the authored dotless rendering
unbuildable.

### D3 — `Chip` owns a 44px hit area

**Chosen:** the painted pill is the authored 34; the box the chip occupies is
`MonetaLayout.minTouchTarget`, pill centred.

This is the pattern `MonetaCheckbox` and `MonetaRadio` already ship
(`boxSize = 22`, `hitSize = MonetaLayout.minTouchTarget`).

Alternatives:

- *Publish a `minimumRowHeight` constant and leave the row to the caller.*
  Rejected: it makes an accessibility guarantee depend on a caller reading a
  constant.
- *Grow the pill to 44.* Rejected: it stops being the authored component;
  `101:1001`'s filter row is 34 tall.

Consequence, stated because the next change inherits it: `08.08`'s filter row
becomes 44 tall where the file draws 34, and everything below shifts. A
deviation for the **screen** to record when it is built.

The input chip's close control sits inside that same 44px box, so the two
targets partition it: the close control takes a 44 × 44 area at the trailing
end and the label area takes the rest. Specified, because "the close control
remains visible" says nothing about how much of the box it owns.

### D4 — `SearchField` is standalone, not `MonetaTextField` with a shape parameter

`MonetaTextField` already has `controller`, `placeholder`, `leadingIcon`,
`trailingIcon`, `onTrailingIconPressed`, `onChanged`, `onSubmitted`,
`focusNode`, `enabled`, a **derived** state (`MonetaTextFieldState.of`) and
`fieldHeight = 52`. The overlap is real and this is the change's largest option.

**Chosen:** a separate component.

- `35:38` is a **pill** (`theme.radii.borderPill`); `27:44` is
  `theme.radii.borderMd`. Composing means adding a shape parameter to a shipped
  component to serve one caller, and the next caller adds the next parameter.
- `35:38` has no label, helper or error slot; `27:44`'s five states are built
  around exactly those. A search field with an error state is not authored.
- The heights differ: 50 against 52.

Rejected alternative: compose and pass a shape. Its one real advantage — a
single controller lifecycle — is answered by D5. The cost of the choice is two
`TextField` wiring blocks, named here rather than pretended away.

### D5 — `SearchField` disposes only what it created

**Chosen:** accept an optional controller; when none is given, create one and
dispose it; support replacement through `didUpdateWidget`.

Alternatives:

- *No controller in the API — `initialText` + `onChanged`.* Genuinely cheaper:
  all four disposal scenarios disappear. Rejected because `08.11` needs to
  **clear** the field from outside (the empty-state's "email support" path
  resets the query), and an uncontrolled field cannot be reset by its parent
  without a key trick.
- *Require a caller-supplied controller.* Rejected: every gallery entry and
  every test would then need a `StatefulWidget` around it to render one field.

`MonetaTextField` uses `late final _controller = widget.controller ?? …`, which
cannot support replacement. Worth knowing before copying its shape — the copy
should not copy the gap.

The assertions are written to be capable of failing: a missed disposal throws
nothing by itself, so "no exception after unmount" is not a test. The
assertions are that a **supplied** controller is still usable afterwards and
that an **owned** one reports itself disposed.

### D6 — Both disputed heights are built to their frames, under one convention

**Chosen:** `Chip` 34 and `SearchField` 50, built with `DecoratedBox` + `Padding`
so the stroke paints inside, per the table in Context.

Alternatives:

- *Build to the descriptions (36 and 48).* Rejected: it contradicts both frames,
  and the descriptions cannot both be right under any one rule.
- *Build the chip to 34 and the search field to 48* — i.e. take each
  component's smaller number. Rejected: 48 requires a 12px padding, which the
  codegen's 13 and the 50px frame both contradict. It would be choosing the
  on-scale number over two measurements.
- *Round `SearchField`'s off-scale 13 to `MonetaSpacing.spaceMd`.* Rejected for
  the same reason, and recorded as the cost of the chosen reading.

`SearchField`'s **clear control** is where a target is added deliberately: an
18px glyph cannot be a 44px target, so the glyph keeps its authored size inside
a `minTouchTarget` hit area — the decision `BottomSheet`'s close control took.

### D7 — `NumpadKey` ships two variants, and the count discrepancy is recorded

**Chosen:** implement `Type=Digit` and `Type=Action` at `State=Default`, and
correct `figma-map.md`'s "4" to "2, and the description claims 4".

Alternatives:

- *Invent a pressed or disabled state to reach four.* Rejected outright. The
  rule is that the **authored** set is implemented; a fabricated variant
  satisfies a count while making the map less true.
- *Assume the second state exists and was missed.* Rejected: the set was read by
  node id and returns a `state` union with one member. **Candidate for the
  twelve deliberate mistakes**, recorded as such.

Variant counts are asserted as **literals** (10, 6, 2) alongside the
enum-derived expression, because `hasLength(Enum.values.length)` cannot fail
when a member is added — which `gallery_test.dart` already learned for Button,
where the count is pinned both ways. The mutation that demonstrates this has to
add an enum member **and** register a variant for it; adding only a catalog
entry fails the enum expression too and would prove nothing.

### D8 — The `Numpad`'s third-last cell is a required parameter

**Chosen:** a two-member enum selecting the authored decimal key or an **empty
cell**, with no default (see D2 for why this default is absent where `dot`'s is
not).

Alternatives:

- *Always render the decimal key; the PIN screen ignores it.* Rejected: a key
  identical to nine live keys that does nothing is a defect, and the first bug
  report is "the dot key is broken".
- *Always render it; the PIN accepts a dot.* Rejected: the PIN is six digits.
- *Let the caller pass an arbitrary widget for the cell.* The most flexible and
  the least honest: the pad would no longer be `36:92` in any checkable sense,
  and the gallery could not enumerate what it renders.
- *A second `Numpad` component.* Rejected: `36:92` has one variant; two
  components drift.

A **deviation from `36:92`**, recorded as one, its cause a reuse the file does
not anticipate.

### D9 — `NumpadKey` is public and in the gallery

**Chosen:** public, beside `Numpad`. `MonetaSegmentedItem` /
`MonetaSegmentedControl` are the existing precedent: both public, both
catalogued.

Alternative, and it is a real one: keep `NumpadKey` private and add it to
`gallery_test.dart`'s `exempt` set, which is a gated mechanism this repo already
uses for four types (`AmountSlot`, `ChartSeries`, `MonetaRadioOption`,
`LineSeries`). Rejected because every one of those four **renders nothing** —
they are value types. `NumpadKey` is an authored component set with two variants
and its own description; exempting a rendering component would be the first
exemption of something the gallery exists to show.

## Risks / Trade-offs

- **A variant-count test that cannot fail** → literals alongside the enum
  expression (D7), with a mutation that adds an enum member *and* a variant.
- **The chip's 44px box changes `08.08`'s layout** → named in D3 as a deviation
  the screen records, not discovered there.
- **`SearchField` duplicates text-field wiring** → accepted in D4, with the
  disposal rule the shipped field lacks written down in D5.
- **`check_design_tokens.dart` fires on the paddings** → `EdgeInsets.symmetric(
  horizontal: 10, vertical: 5)` matches its `EdgeInsets`-with-a-digit rule, and
  `BorderRadius.circular(999)` matches its radius rule. Avoided the way the
  repository already does it: named `static const` doubles for the off-scale
  numbers (`ChartLegendItem.verticalInset` is the precedent) and
  `theme.radii.borderPill` for the shape. No `// design-token-ignore` is needed
  and none is used.
- **The same checker is blind to the numbers that matter most** → it cannot see
  `SizedBox(height: 56)` or `size: 22`, so **every authored geometry number is
  asserted by a widget test**; the table below names which. The gate is not
  credited with catching them.
- **The checker cannot see an API at all** → the "no raw design values from
  callers" requirement is verified by a **source-text test** over the five
  constructors, the same instrument `SearchField`'s derived-state check uses,
  guarded by a counterfeit so it can fail. Not by the gate.
- **`04.04`'s reason goes stale the moment `Numpad` exists** → the map row and
  the three source comments that say `Numpad`/`SearchField` are unbuilt are
  listed in the proposal's Impact and corrected in task 5.1. Rewiring `04.04` is
  out of scope and recorded as such.
- **`check_architecture.dart`** → everything lands in `design_system`, which may
  import `core` and `design_system`; the gallery lives in `app`, which may import
  anything. None of the five needs `Money`.

## Verification

Money, currency-mismatch and empty-database boundaries **do not apply** to these
five: none takes a `Money`, none reads storage. The boundaries that do apply are
empty and over-long labels, a width too narrow to fill, disabled state, pasted
newlines, platform text size and directionality — each a scenario in the spec.

| Requirement | Test file | What catches a regression |
| --- | --- | --- |
| Badge — 10 variants | `test/design_system/atoms/moneta_badge_test.dart` | literal 10 **and** the enum product |
| Badge — the tone table, `Neutral` included | same | table over tones; swapping two fills fails |
| Badge — dot 5/6, paddings, total height 22/26 | same | measured against the named constants |
| Badge — empty label, long label, text scale | same | assertion thrown; containment at named scale factors |
| Chip — 6 variants | `test/design_system/atoms/moneta_chip_test.dart` | literal 6 **and** the enum product |
| Chip — brand triple | same | fill, border and label asserted together |
| Chip — close vs select, and their 44px split | same | two callbacks; both hit areas measured |
| Chip — 34px pill in a 44px box | same | both measured; shrinking the box fails |
| SearchField — derived state | `test/design_system/molecules/moneta_search_field_test.dart` | source check over **constructor parameters**, counterfeit-guarded |
| SearchField — 50px, clear target, focus, long value, newline, disabled | same | heights and hit areas measured; focus asserted to change nothing |
| SearchField — controller ownership | same | supplied controller usable after unmount; owned one reports disposed |
| NumpadKey — two variants, not four | `test/design_system/molecules/numpad_test.dart` | literal 2; an added enum member **plus** variant fails |
| Numpad — fill at 353, 393 and 200 | same | equal widths; no overflow at 200, which a fixed 109px key would breach |
| Numpad — digits, delete, glyph, RTL order | same | every digit reported; `chevronLeft`; `1`'s x < `3`'s x under RTL |
| Numpad — decimal cell required | same | PIN pad renders one fewer key and reports no decimal |
| No raw design values in any API | source-text test, **not** the gate | a `Color`/`TextStyle`/`EdgeInsets` parameter fails it |
| Gallery completeness and describers | `test/app/gallery_test.dart` | filesystem walk; `_describe` throws for an unknown type |

Every component's task carries **its own** mutation, run and recorded in
`docs/ai-workflow/evidence-log.md` as part of that task — ten in total across
tasks 1–4, not batched into close-out where a decorative test is already
committed by the time the batch runs. A mutation that survives means the test is
decorative and gets rewritten, not annotated.

## Migration Plan

None. Five additive components, no persistence, no schema, no public API
changed, no dependency added. Nothing to roll back beyond the commits.

## Open Questions

None that affect these specs, this approach or these tasks.
