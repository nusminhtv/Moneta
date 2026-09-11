import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/molecules/chart_legend_item.dart';
import 'package:moneta/design_system/molecules/chart_series.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// A spend-by-category donut with a total in the middle and its legend below.
///
/// From Figma node `47:48` — ring `47:49`, centre `47:58`, legend `47:62`.
///
/// **The legend is not optional and there is no parameter for it.** Annotation
/// `77:284`: *"the DonutChart legend is part of the component and not optional:
/// two of the eight chart slots fall below 3:1 against the dark surface, so the
/// visible labels ARE the required contrast relief."* A `showLegend` flag would
/// turn that guarantee into a caller's convenience, and the first cramped
/// screen would turn it off. A separate `ChartLegend` widget composed beside
/// the chart would be worse still: the rows could then disagree with the arcs,
/// which is harder to notice than no legend at all.
class DonutChart extends StatelessWidget {
  /// Creates a donut for [categories].
  const DonutChart({
    required this.categories,
    required this.centreLabel,
    required this.periodLabel,
    this.otherLabel = 'Other',
    super.key,
  });

  /// What to chart, in any order. The donut ranks, folds and totals them
  /// itself — see [segments]. Each datum's [ChartSeries.slot] is honoured, so
  /// a category keeps one colour across every screen that charts it.
  final List<ChartSeries> categories;

  /// The line above the total, from `47:59`: "Total spent".
  final String centreLabel;

  /// The line below the total, from `47:61`: "August 2026".
  final String periodLabel;

  /// The label the fold carries, from `47:98`: "Other".
  final String otherLabel;

  /// Ring box, from `47:49`: 208 × 208.
  static const double ringDiameter = 208;

  /// Ring thickness, **observed from the exported assets, not transcribed.**
  ///
  /// The segments export as filled annular paths, not as strokes, so there is
  /// no stroke width to read. At twelve o'clock `47:50`'s path runs from
  /// `y=0` to `y=39.5182` inside the 208 box; the outer radius is 104, so the
  /// inner is ≈64.5. The trailing `0.0182` is Figma's arc-to-path conversion,
  /// not an authored value, so the reading is **39.5**.
  ///
  /// Provenance is a measurement off an SVG — better than a guess, weaker than
  /// a variable — and is recorded as such in
  /// `docs/design-system/figma-map.md`.
  ///
  /// Rounding also makes the value assertable: `Paint.strokeWidth` is a 32-bit
  /// float, and `39.5182` comes back as `39.5181999206543`, which the `paints`
  /// matcher rejects as unequal. 39.5 round-trips exactly.
  static const double ringThickness = 39.5;

  /// Gap between segments, **observed from the exported assets**: 1°.
  ///
  /// Two boundaries were measured. At twelve o'clock `47:57` ends 0.554° before
  /// the mark and `47:50` starts 0.344° after it, a gap of 0.898°; between
  /// `47:50` and `47:51` the gap is 1.099°. Figma's arc-to-path conversion
  /// rounds, so 1° is the reading, not a transcription. Suppressed below two
  /// visible segments — a lone segment must occupy the whole ring, and a notch
  /// in an otherwise complete circle reads as missing data.
  static const double segmentGapDegrees = 1;

  /// Most coloured segments the ring will show. Categories past this fold into
  /// one neutral [ChartSlot.other] segment.
  static const int maxColoredSegments = MonetaChartPalette.slotCount;

  /// Inner radius of the ring: the outer radius less the thickness.
  static const double innerRadius = ringDiameter / 2 - ringThickness;

  /// Height of the centre block, from `47:58`: 62.
  static const double centreHeight = 62;

  /// Breathing room between the centre block and the arcs.
  static const double centreMargin = MonetaSpacing.spaceSm;

  /// Widest the centre block can be and still clear the arcs.
  ///
  /// **Derived, and a deliberate departure from `47:58`'s authored 140.** The
  /// hole is `2 × 64.5 = 129` across at its widest, so a 140-wide box already
  /// overhangs it — and the block is 62 tall, so at its top and bottom edges
  /// the hole is only `2 × √(64.5² − 31²) ≈ 113` across. Figma gets away with
  /// 140 because its sample total, "26,000,000 ₫", is short enough not to
  /// reach the edges. A real VND total is longer and did reach them: the
  /// figure touched the ring.
  ///
  /// So the width is computed from the circle rather than transcribed, which
  /// keeps it correct if the thickness or the block's height ever change.
  static final double centreWidth =
      2 *
          math.sqrt(
            innerRadius * innerRadius - (centreHeight / 2) * (centreHeight / 2),
          ) -
      centreMargin;

  /// Gap between the centre's three lines, from `47:58`: 2.
  static const double centreLineGap = MonetaSpacing.space2xs;

  /// Space above the ring, from `47:49`'s y within `47:48`: 8.
  static const double ringInset = 8;

  /// Space between the ring and the legend: `47:62` at y=234, ring ending at
  /// 216.
  static const double legendGap = 18;

  /// Key on the ring's painted surface, so tests can find the canvas.
  static const Key ringKey = Key('DonutChart.ring');

  /// Key on the legend column, so tests can count its rows.
  static const Key legendKey = Key('DonutChart.legend');

  /// Key on the centre's total, which a one-category legend row repeats.
  static const Key centreValueKey = Key('DonutChart.centreValue');

  /// Key on the box that scales the **total** to the centre's width.
  static const Key centreValueFitKey = Key('DonutChart.centreValueFit');

  /// Key on the box that scales the **whole centre block** to its bounds.
  ///
  /// Distinct from [centreValueFitKey] because the two absorb different
  /// things: that one keeps a long figure off the arcs by shrinking only the
  /// figure, this one keeps three inflated line boxes inside 62 by shrinking
  /// all of them together. See the comment at its use.
  static const Key centreFitKey = Key('DonutChart.centreFit');

  /// Key on the whole centre block.
  ///
  /// This, not the total's own box, is what can reach the arcs: the total is
  /// scaled to fit and its box hugs the scaled text, while the block keeps its
  /// full [centreWidth] × [centreHeight] whatever the figure says.
  static const Key centreBlockKey = Key('DonutChart.centreBlock');

  /// The arithmetic total of every supplied category, shown in the centre.
  ///
  /// Reports a currency mismatch rather than summing across currencies.
  Money get total =>
      chartSumOf(categories.map((c) => c.amount), what: 'categories');

  /// What the ring actually draws: ranked largest-first, capped at
  /// [maxColoredSegments], with the remainder folded into one neutral segment.
  ///
  /// The fold is the donut's own arithmetic, not the caller's. If each screen
  /// pre-folded its own data, each could get it wrong independently and the
  /// guarantee that the segments sum to the supplied total would move out of
  /// the type and into a convention.
  List<ChartSeries> get segments {
    chartCurrencyOf(
      categories.map((c) => c.amount),
      what: 'categories',
    );
    final ranked = [...categories]
      ..sort((a, b) => b.amount.minorUnits.compareTo(a.amount.minorUnits));
    if (ranked.length <= maxColoredSegments) return ranked;

    final head = ranked.take(maxColoredSegments).toList();
    final tail = ranked.skip(maxColoredSegments);
    return [
      ...head,
      ChartSeries(
        label: otherLabel,
        amount: chartSumOf(
          tail.map((c) => c.amount),
          what: 'categories',
          fallback: total.currency,
        ),
        slot: ChartSlot.other,
      ),
    ];
  }

  /// The share of the ring each of [segments] takes, in the same order.
  ///
  /// Negative amounts contribute nothing rather than sweeping backwards, so
  /// the denominator is the positive total. When nothing is positive every
  /// share is zero — no division by zero, and no ring drawn in one colour to
  /// stand in for data that is not there.
  List<double> get fractions {
    final positive = segments
        .map((s) => math.max(0, s.amount.minorUnits))
        .toList();
    final divisor = positive.fold<int>(0, (sum, value) => sum + value);
    if (divisor == 0) return [for (final _ in positive) 0.0];
    return [for (final value in positive) value / divisor];
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final drawn = segments;
    final shares = fractions;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: ringInset),
        SizedBox(
          width: ringDiameter,
          height: ringDiameter,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  key: ringKey,
                  painter: _DonutRingPainter(
                    segments: drawn,
                    fractions: shares,
                    colors: theme.colors,
                  ),
                ),
              ),
              SizedBox(
                key: centreBlockKey,
                width: centreWidth,
                height: centreHeight,
                // The block is a hard boundary and the lines are scaled to fit
                // it, because `47:58`'s authored 62 is **exactly** the sum of
                // the three authored line boxes: 16 + 2 + 26 + 2 + 16. The
                // layout therefore has zero slack, and anything that inflates
                // a line box by a fraction of a pixel pushes the period line
                // out of the block — reported from a device as a 2.5px bottom
                // overflow with "This month" clipped. Text scaling is the
                // inflator that reproduces it: at iOS's first size above the
                // default the two caption lines gain ~3.8px between them.
                //
                // Uniform, so the three lines keep their authored proportions;
                // scaleDown, so at nominal metrics the scale is 1 and nothing
                // moves. The inner [SizedBox] is what keeps the lines' width
                // bounded inside an unconstrained [FittedBox], so they still
                // ellipsise and the total still scales at [centreWidth].
                child: FittedBox(
                  key: centreFitKey,
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: centreWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          centreLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.text.captionMd.copyWith(
                            color: theme.colors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: centreLineGap),
                        // Scaled down rather than truncated. The rest of this
                        // component holds that a clipped amount is a lost
                        // amount, and that applies most of all to the total:
                        // an ellipsis here would turn 24.507.822 ₫ into
                        // "24.507…". A long total gets smaller; it never gets
                        // cut off and never reaches the arcs.
                        FittedBox(
                          key: centreValueFitKey,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            total.format(),
                            key: centreValueKey,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: theme.text.amountMd.copyWith(
                              color: theme.colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: centreLineGap),
                        Text(
                          periodLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.text.captionMd.copyWith(
                            color: theme.colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: legendGap),
        Column(
          key: legendKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < drawn.length; i++)
              ChartLegendItem.forSeries(drawn[i], fraction: shares[i]),
          ],
        ),
        const SizedBox(height: ringInset),
      ],
    );
  }
}

/// Paints the ring: a track, then one arc per segment, clockwise from twelve.
class _DonutRingPainter extends CustomPainter {
  const _DonutRingPainter({
    required this.segments,
    required this.fractions,
    required this.colors,
  });

  final List<ChartSeries> segments;
  final List<double> fractions;
  final MonetaColors colors;

  /// Twelve o'clock. Flutter's zero is three o'clock and sweeps clockwise.
  static const double _startAngle = -math.pi / 2;

  /// A fresh `Paint` per draw.
  ///
  /// This change's `design.md` (D4) claims a shared mutated `Paint` is what
  /// made `MonetaCircularProgress`'s colour requirement untestable, because
  /// "a recording canvas keeps the reference". **That is not true in this
  /// Flutter version, and it was checked here rather than repeated.** Two
  /// probes: a two-arc painter mutating one `Paint` reports both colours
  /// correctly to `paints..arc(color:)`, and reverting the ring's own painter
  /// to a shared instance leaves all 14 of its tests passing.
  ///
  /// The ring's colour requirement was unguarded because **no test asserted
  /// what reached the canvas at all**, not because of aliasing. The ordered
  /// `paints` sequence is what makes it fail now.
  ///
  /// The fresh `Paint` stays, on the narrower ground that it is correct: a
  /// painter instance outlives one `paint()` call, so an instance field would
  /// alias across repaints. It is no longer load-bearing for the tests.
  Paint _stroke(Color color, double thickness) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = thickness
    ..strokeCap = StrokeCap.butt;

  @override
  void paint(Canvas canvas, Size size) {
    const thickness = DonutChart.ringThickness;
    final radius = math.min(size.width, size.height) / 2 - thickness / 2;
    if (radius <= 0) return;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: radius,
    );

    // The track first, and it is an addition to `47:49`: the authored sample's
    // eight segments fill the circle, so no track is visible there and none is
    // drawn. The spec's empty case asks for "an empty ring with no segments",
    // which needs something to be the ring.
    canvas.drawArc(
      rect,
      _startAngle,
      2 * math.pi,
      false,
      _stroke(colors.track, thickness),
    );

    final visible = fractions.where((f) => f > 0).length;
    // A lone segment occupies the whole ring: a 1° notch in an otherwise
    // complete circle reads as missing data rather than as a separator.
    final gap = visible < 2 ? 0.0 : segmentGapRadians;
    final available = 2 * math.pi - visible * gap;

    var angle = _startAngle + gap / 2;
    for (var i = 0; i < segments.length; i++) {
      final fraction = fractions[i];
      if (fraction <= 0) continue;
      final sweep = fraction * available;
      canvas.drawArc(
        rect,
        angle,
        sweep,
        false,
        _stroke(segments[i].slot.colorIn(colors), thickness),
      );
      angle += sweep + gap;
    }
  }

  /// [DonutChart.segmentGapDegrees] in radians.
  static double get segmentGapRadians =>
      DonutChart.segmentGapDegrees * math.pi / 180;

  @override
  bool shouldRepaint(_DonutRingPainter oldDelegate) =>
      oldDelegate.segments != segments ||
      oldDelegate.fractions != fractions ||
      oldDelegate.colors != colors;
}
