import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/typography.dart';

/// Ring diameters from Figma node `25:272`.
enum MonetaCircularProgressSize {
  /// 48 — no label. Inline, beside a row.
  sm(48, null),

  /// 72 — the total card on `04.01`.
  md(72, 6),

  /// 120 — the hero ring on `04.05` and `04.06`.
  lg(120, 10);

  const MonetaCircularProgressSize(this.diameter, this.strokeWidth);

  /// Outer diameter in logical pixels.
  final double diameter;

  /// Ring thickness, or null for the size that carries no percentage label.
  ///
  /// `sm` still draws a ring; the null marks the absent label, not an absent
  /// stroke.
  ///
  /// **Derived, not observed.** Figma exports the arcs as SVG assets, so the
  /// diameters are read from the node and the stroke widths are not available
  /// as numbers. 6 at 72 and 10 at 120 hold the ratio the exported arcs show;
  /// they are recorded in figma-map.md under values used with no inspection.
  final double? strokeWidth;

  /// Whether this size shows a percentage label. `Sm` does not.
  bool get hasLabel => strokeWidth != null;

  /// Ring thickness for painting.
  double get stroke => strokeWidth ?? 4;
}

/// A ring showing spend against a limit.
///
/// From Figma node `25:272` — 3 states × 3 sizes. The state is **derived** from
/// [fraction] through [BudgetStatus.fromFraction], the same function
/// `MonetaProgressBar` uses, so a ring and a bar showing one budget cannot
/// disagree about whether it is over.
///
/// **There is no label parameter, on purpose.** Figma gives this component no
/// TEXT property; its 62% / 88% / 100% are typed onto each instance, which
/// annotation `04.01` records as ledger entry I10. A `label` beside a
/// [fraction] is a ring whose number can contradict its arc, so the label is
/// derived from the same fraction that draws the sweep.
class MonetaCircularProgress extends StatelessWidget {
  /// Creates a ring.
  const MonetaCircularProgress({
    required this.fraction,
    this.size = MonetaCircularProgressSize.md,
    this.semanticLabel,
    super.key,
  });

  /// Spend as a fraction of the limit, **unclamped**.
  ///
  /// The sweep is clamped for drawing; the colour and the label need the raw
  /// value, because an arc cannot show 140% and the number is the only place
  /// that fact survives.
  final double fraction;

  /// Which of the three authored diameters to draw.
  final MonetaCircularProgressSize size;

  /// Accessibility label. Null for a ring whose meaning is in adjacent text.
  final String? semanticLabel;

  /// The arc colour for a fraction — the same rule the bar uses.
  static Color arcColorFor(double fraction, MonetaColors colors) =>
      BudgetStatus.fromFraction(fraction).colorIn(colors);

  /// The label a fraction produces, or null at [MonetaCircularProgressSize.sm].
  ///
  /// Reports the true percentage even past the limit: the sweep stops at a full
  /// turn, so the number is carrying what the drawing cannot.
  static String? labelFor(double fraction, MonetaCircularProgressSize size) {
    if (!size.hasLabel) return null;
    if (!fraction.isFinite) return '0%';
    return '${(fraction * 100).round()}%';
  }

  /// The type style each size uses for its label, as Figma authors them.
  static TextStyle labelStyleFor(
    MonetaCircularProgressSize size,
    MonetaTypography text,
  ) => size == MonetaCircularProgressSize.lg ? text.amountMd : text.labelMd;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final label = labelFor(fraction, size);
    final swept = !fraction.isFinite ? 0.0 : fraction.clamp(0.0, 1.0);

    return Semantics(
      label: semanticLabel,
      value: '${(swept * 100).round()}%',
      child: SizedBox.square(
        dimension: size.diameter,
        child: CustomPaint(
          painter: _RingPainter(
            sweep: swept,
            arcColor: arcColorFor(fraction, theme.colors),
            trackColor: theme.colors.track,
            strokeWidth: size.stroke,
          ),
          child: label == null
              ? null
              : Center(
                  child: Text(
                    label,
                    style: labelStyleFor(
                      size,
                      theme.text,
                    ).copyWith(color: theme.colors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.sweep,
    required this.arcColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double sweep;
  final Color arcColor;
  final Color trackColor;
  final double strokeWidth;

  /// Twelve o'clock. Flutter's zero angle is three o'clock.
  static const double _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - strokeWidth) / 2,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = trackColor);
    if (sweep > 0) {
      canvas.drawArc(
        rect,
        _start,
        math.pi * 2 * sweep,
        false,
        base..color = arcColor,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.sweep != sweep ||
      old.arcColor != arcColor ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
