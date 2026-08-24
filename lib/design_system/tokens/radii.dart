import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';

/// Corner radii from Figma.
///
/// `radius-sm` is deliberately absent: it does not appear in any node read, and
/// inventing it would put a value in the design system that the design file has
/// never seen.
@immutable
final class MonetaRadii {
  /// Creates a radius set from explicit values.
  const MonetaRadii({
    required this.md,
    required this.lg,
    required this.xl,
    required this.pill,
  });

  /// The radii read from Figma.
  const MonetaRadii.figma() : md = 14, lg = 18, xl = 24, pill = 999;

  /// 14 — banners and inline notices.
  final double md;

  /// 18 — standard cards.
  final double lg;

  /// 24 — the hero balance card.
  final double xl;

  /// Fully rounded — pills, avatars, progress tracks.
  final double pill;

  /// [md] as a [BorderRadius].
  BorderRadius get borderMd => BorderRadius.circular(md);

  /// [lg] as a [BorderRadius].
  BorderRadius get borderLg => BorderRadius.circular(lg);

  /// [xl] as a [BorderRadius].
  BorderRadius get borderXl => BorderRadius.circular(xl);

  /// [pill] as a [BorderRadius].
  BorderRadius get borderPill => BorderRadius.circular(pill);
}
