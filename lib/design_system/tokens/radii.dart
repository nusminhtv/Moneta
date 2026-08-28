import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';

/// Corner radii from Figma.
///
/// `radius-sm` was documented here as deliberately absent — "it does not appear
/// in any node read" — which was true of the nodes read at the time: the balance
/// card, the banner and the checkbox. Reading `36:167` for the segmented control
/// found it bound there, so the value is now transcribed rather than invented.
/// The note stays because the reasoning is still right: a radius with no node
/// behind it does not belong in this file.
@immutable
final class MonetaRadii {
  /// Creates a radius set from explicit values.
  const MonetaRadii({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.pill,
  });

  /// The radii read from Figma.
  const MonetaRadii.figma()
    : xs = 6,
      sm = 10,
      md = 14,
      lg = 18,
      xl = 24,
      pill = 999;

  /// 6 — the checkbox box. Verified at `107:79`.
  final double xs;

  /// 10 — the segment of a segmented control. Verified at `36:167`.
  final double sm;

  /// 14 — banners and inline notices.
  final double md;

  /// 18 — standard cards.
  final double lg;

  /// 24 — the hero balance card.
  final double xl;

  /// Fully rounded — pills, avatars, progress tracks.
  final double pill;

  /// [xs] as a [BorderRadius].
  BorderRadius get borderXs => BorderRadius.circular(xs);

  /// [sm] as a [BorderRadius].
  BorderRadius get borderSm => BorderRadius.circular(sm);

  /// [md] as a [BorderRadius].
  BorderRadius get borderMd => BorderRadius.circular(md);

  /// [lg] as a [BorderRadius].
  BorderRadius get borderLg => BorderRadius.circular(lg);

  /// [xl] as a [BorderRadius].
  BorderRadius get borderXl => BorderRadius.circular(xl);

  /// [pill] as a [BorderRadius].
  BorderRadius get borderPill => BorderRadius.circular(pill);
}
