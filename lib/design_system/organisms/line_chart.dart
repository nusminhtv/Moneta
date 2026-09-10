import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/molecules/chart_series.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// One line: a name and a point per period.
@immutable
class LineSeries extends Equatable {
  /// Creates a series.
  const LineSeries({required this.label, required this.points});

  /// The name shown in the legend. Identity never rests on hue alone.
  final String label;

  /// One value per period, oldest first. Domain types, not doubles.
  final List<Money> points;

  @override
  List<Object?> get props => [label, points];
}

/// Income against expenses over twelve months, on **one** shared axis.
///
/// From Figma node `48:76`. Its description is the requirement:
///
/// > *"Income vs expenses over 12 months. TWO series, so a legend is mandatory
/// > — identity is never colour-alone. One y-axis only; a second scale would be
/// > a dual-axis chart, which this system never ships. 2px strokes, 9px end
/// > markers with a 2px surface ring where marks overlap."*
///
/// **A second axis is not representable.** There is no per-series scale, no
/// axis minimum and no maximum parameter: the maximum is computed from both
/// series together and the baseline is always zero. Annotation `77:430`
/// explains why — *"a dual-axis chart would let the two lines cross wherever
/// the scales were chosen to make them cross"* — and a flag would turn that
/// into a caller's choice.
///
/// Two named series rather than a `List<LineSeries>` (design D6): a list
/// invites a third, and the moment there are three the shared-axis argument
/// stops being about two lines.
class MonetaLineChart extends StatelessWidget {
  /// Creates a chart.
  const MonetaLineChart({
    required this.title,
    required this.subtitle,
    required this.income,
    required this.expenses,
    super.key,
  });

  /// Heading, from `48:77`: "Cash flow".
  final String title;

  /// Sub-heading, from `48:78`: "Income vs expenses · VND millions".
  final String subtitle;

  /// The income line. Drawn in `chart/1`.
  final LineSeries income;

  /// The expense line. Drawn in `chart/3`.
  final LineSeries expenses;

  /// Plot height, from `48:79`: 140.
  static const double plotHeight = 140;

  /// Gap between title, subtitle, plot and legend, from `48:76`: 10.
  static const double blockGap = 10;

  /// Stroke width of a series, from the component description: 2.
  static const double strokeWidth = 2;

  /// End-marker **outer** diameter, from `48:84`: 9.
  ///
  /// Outer, including the ring — which is the correction a `figma-fidelity`
  /// pass made. The component description says "9px end markers with a 2px
  /// surface ring", and I read that as a 9px disc *plus* a ring, giving an 11px
  /// mark. `48:84`'s exported SVG settles it:
  /// `<circle cx=4.5 cy=4.5 r=3.5 fill=#009E62 stroke=#06070A stroke-width=2/>`
  /// in a 9×9 box — a **7px** coloured disc with the 2px ring straddling its
  /// edge, 9px in total.
  static const double markerSize = 9;

  /// Ring drawn around a marker so two overlapping marks stay separable, from
  /// the component description: 2. Straddles the disc's edge rather than
  /// sitting outside it.
  static const double markerRingWidth = 2;

  /// The coloured disc's diameter: the 9px mark less the 2px ring around it.
  static const double markerDiscSize = markerSize - markerRingWidth;

  /// Gridlines drawn across the plot, from `48:80`–`48:82`: three, at 35, 70
  /// and 105 of the 140 — quarter, half and three-quarters.
  static const int gridlineCount = 3;

  /// Legend swatch, from `48:89`: 14 × 3. A **line**, not a dot, because these
  /// series are lines.
  static const double legendSwatchWidth = 14;

  /// See [legendSwatchWidth].
  static const double legendSwatchHeight = 3;

  /// Gap between the two legend entries, from `48:87`: 18.
  static const double legendGap = 18;

  /// Gap between a legend swatch and its label, from `48:88`: 7.
  static const double legendSwatchGap = 7;

  /// The income line's slot. Fixed, not a parameter: `48:89` binds `chart/1`,
  /// and a chart whose two series could be given the same slot would be a
  /// chart whose legend cannot tell them apart.
  static const ChartSlot incomeSlot = ChartSlot.slot1;

  /// The expense line's slot, from `48:92`: `chart/3`.
  static const ChartSlot expenseSlot = ChartSlot.slot3;

  /// Key on the plot, so tests can read the canvas.
  static const Key plotKey = Key('MonetaLineChart.plot');

  /// The one axis maximum, in minor units, shared by both series.
  ///
  /// Always measured from zero. Returns 1 rather than 0 for an all-zero chart,
  /// so nothing divides by zero and both lines land on the baseline.
  int get axisMaxMinor {
    final all = [...income.points, ...expenses.points];
    if (all.isEmpty) return 1;
    final highest = all.map((m) => m.minorUnits).fold(0, math.max);
    return highest <= 0 ? 1 : highest;
  }

  /// The currency both series share.
  ///
  /// Reports a mismatch rather than plotting two currencies against one axis.
  Currency? get currency => chartCurrencyOf([
    ...income.points,
    ...expenses.points,
  ], what: 'series');

  /// Whether the two series can be plotted against the same x positions.
  bool get hasEqualLengths => income.points.length == expenses.points.length;

  /// The `0..1` heights the plot draws [points] at, measured from zero.
  ///
  /// The **only** place a value becomes a position, so the clamp lives here and
  /// is testable. A negative contributes zero rather than sweeping below the
  /// baseline: the axis says it starts at zero, and a line below it would make
  /// the axis a lie. Computing this in the painter instead left a mutation
  /// removing the clamp alive, because a painter's arithmetic is only visible
  /// through what it draws.
  List<double> fractionsOf(List<Money> points) => [
    for (final point in points) math.max(0, point.minorUnits) / axisMaxMinor,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    // Both checks before anything is drawn: a chart that renders half of a
    // contradiction is worse than one that refuses.
    currency;
    if (!hasEqualLengths) {
      throw ArgumentError.value(
        expenses.points.length,
        'expenses',
        'the two series must have the same number of points; income has '
            '${income.points.length}. Plotting them against different x '
            'positions would put January under February.',
      );
    }

    final max = axisMaxMinor;
    final labelStyle = theme.text.captionMd.copyWith(
      color: theme.colors.textTertiary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.text.headingH3.copyWith(
            color: theme.colors.textPrimary,
          ),
        ),
        const SizedBox(height: blockGap),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: labelStyle,
        ),
        const SizedBox(height: blockGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Labels outside the plot, as `49:34`–`49:36` place them. Only
            // three: zero, the midpoint and the maximum — so the axis "states
            // the range", which is what makes a gap above the lines read as
            // information rather than as a rendering fault.
            SizedBox(
              height: plotHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_axisLabel(max), style: labelStyle),
                  Text(_axisLabel(max ~/ 2), style: labelStyle),
                  Text(_axisLabel(0), style: labelStyle),
                ],
              ),
            ),
            const SizedBox(width: MonetaSpacing.spaceSm),
            Expanded(
              child: SizedBox(
                height: plotHeight,
                child: CustomPaint(
                  key: plotKey,
                  painter: _LinePlotPainter(
                    income: fractionsOf(income.points),
                    expenses: fractionsOf(expenses.points),
                    colors: theme.colors,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: blockGap),
        Row(
          children: [
            _LegendEntry(label: income.label, slot: incomeSlot),
            const SizedBox(width: legendGap),
            _LegendEntry(label: expenses.label, slot: expenseSlot),
          ],
        ),
      ],
    );
  }

  /// An axis label in whole millions, as `48:78` says the axis is scaled.
  String _axisLabel(int minorUnits) {
    const million = 1000000;
    if (minorUnits >= million) return '${minorUnits ~/ million}';
    return '$minorUnits';
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.label, required this.slot});

  final String label;
  final ChartSlot slot;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: slot.colorIn(theme.colors),
            borderRadius: theme.radii.borderPill,
          ),
          child: const SizedBox(
            width: MonetaLineChart.legendSwatchWidth,
            height: MonetaLineChart.legendSwatchHeight,
          ),
        ),
        const SizedBox(width: MonetaLineChart.legendSwatchGap),
        Text(
          label,
          maxLines: 1,
          style: theme.text.labelSm.copyWith(
            color: theme.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Paints the gridlines, then the two series, then their end markers.
class _LinePlotPainter extends CustomPainter {
  const _LinePlotPainter({
    required this.income,
    required this.expenses,
    required this.colors,
  });

  /// Heights in `0..1`, already clamped by [MonetaLineChart.fractionsOf].
  final List<double> income;

  /// See [income].
  final List<double> expenses;
  final MonetaColors colors;

  /// A fresh `Paint` per draw. A painter instance outlives one `paint()` call,
  /// so an instance field would alias across repaints.
  Paint _paint(Color color, {required double width, PaintingStyle? style}) =>
      Paint()
        ..color = color
        ..style = style ?? PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    // Gridlines first, so the series sit on top of them. Order IS the
    // requirement here, and it is asserted.
    for (var i = 1; i <= MonetaLineChart.gridlineCount; i++) {
      final y = size.height * i / (MonetaLineChart.gridlineCount + 1);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        _paint(colors.borderSubtle, width: 1),
      );
    }

    _drawSeries(
      canvas,
      size,
      income,
      MonetaLineChart.incomeSlot.colorIn(colors),
    );
    _drawSeries(
      canvas,
      size,
      expenses,
      MonetaLineChart.expenseSlot.colorIn(colors),
    );
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    List<double> points,
    Color color,
  ) {
    if (points.isEmpty) return;

    Offset at(int index) {
      // A single point sits at the right edge, where its end marker belongs,
      // rather than at x=0 where it would look like the start of a line that
      // is not there.
      final x = points.length == 1
          ? size.width
          : size.width * index / (points.length - 1);
      return Offset(x, size.height - size.height * points[index]);
    }

    if (points.length > 1) {
      final path = Path()..moveTo(at(0).dx, at(0).dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(at(i).dx, at(i).dy);
      }
      canvas.drawPath(path, _paint(color, width: MonetaLineChart.strokeWidth));
    }

    // The end marker, with the surface ring the description asks for so two
    // marks that land on each other stay separable.
    final end = at(points.length - 1);
    // Ring first, then the disc on top of it: the ring is `canvas`, not
    // `surface` — `48:84`'s stroke is `#06070A`, which is the canvas token.
    // Both were wrong until the fidelity pass read the exported SVG.
    canvas
      ..drawCircle(
        end,
        MonetaLineChart.markerSize / 2,
        _paint(
          colors.canvas,
          width: MonetaLineChart.markerRingWidth,
          style: PaintingStyle.fill,
        ),
      )
      ..drawCircle(
        end,
        MonetaLineChart.markerDiscSize / 2,
        _paint(color, width: 1, style: PaintingStyle.fill),
      );
  }

  @override
  bool shouldRepaint(_LinePlotPainter oldDelegate) =>
      oldDelegate.income != income ||
      oldDelegate.expenses != expenses ||
      oldDelegate.colors != colors;
}
