# Design — budget-components

## The ring must not be able to lie

`CircularProgress` in Figma has no TEXT property. Its "62%", "88%" and "100%"
are typed directly onto each instance, which annotation `04.01` records as
ledger entry I10. Copying that shape into Dart would mean a `label` parameter
next to a `fraction` parameter, and the first screen that formats one of them
differently ships a ring whose arc and number disagree.

So the component takes a fraction and derives everything: the arc sweep, the
colour, and the label. There is no label parameter to get wrong. The cost is
that a caller cannot write "83%" beside an arc drawn at 0.62 — which is exactly
the thing worth losing.

State is derived through `BudgetStatus.fromFraction`, the same function
`MonetaProgressBar` uses, rather than a second threshold table. Two thresholds
drift; one does not.

**Over budget.** The arc stops at a full turn — an arc cannot show 140% — but
the label reads "140%". Clamping the number as well would hide the only fact
the ring cannot draw.

## Segment count is not a variant

Figma's own note on `36:161` says composing 2–4 items beats a variant per
segment-count × active-index because "that combination explodes fast". The Dart
control follows: it takes a list of labels and a selected index.

Equal widths are inferred, not read. The design's instances are 112.33px wide in
a 353px track — not a number anyone types. It is what an equal division looks
like once Figma writes it down, so the control uses `Expanded`, and a test
asserts the widths stay equal when one label is much longer than the others.

**Touch target.** The segment is drawn 36 tall; the track is 44. The hit area is
the track, not the segment, so the control meets the 44px minimum without
changing the drawing.

## The error state Figma admits is broken

`36:76`'s own description says the error variant "differs by colour only". That
is a defect stated in the source, not an interpretation. Rather than reproduce
it, the error state is modelled so a message is required — the Dart type makes
"error with no message" unrepresentable, which is a stronger guarantee than a
test that someone can delete.

## StatTile keeps a mapping that looks wrong

`Direction=Up` renders income green, and the component's own sample reads
"Spent this month / +12.4% vs last month" in green: spending more, coloured as
good news.

The mapping stays as authored. Direction is the caller's choice, and a tile is
not only ever about spending — income up in green is correct. Changing the
mapping would make every correct use wrong to fix one wrong sample. The sample
goes in the deviations table as a candidate for the file's twelve deliberate
mistakes; it is a screen's job to pass `Down` for spending that rose.

## Why an ADR is not needed here

Every decision above is a transcription judgement with one defensible answer,
recorded at the point of use. `/moneta:tradeoff` is for choices where a
reasonable engineer would pick differently — none of these qualify.
