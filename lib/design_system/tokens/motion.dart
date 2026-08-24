import 'package:flutter/animation.dart';
import 'package:meta/meta.dart';

/// Duration and easing tokens.
///
/// **Not Figma-derived.** The design file defines no transition or easing
/// values. These come from Material 3's emphasised motion set and are the only
/// values in the token layer that did not come from the design. Flagged so a
/// design review knows which values are ours to argue about.
@immutable
final class MonetaMotion {
  /// Creates a motion set from explicit values.
  const MonetaMotion({
    required this.fast,
    required this.normal,
    required this.slow,
    required this.standard,
    required this.emphasised,
  });

  /// The Material-derived defaults.
  const MonetaMotion.defaults()
    : fast = const Duration(milliseconds: 150),
      normal = const Duration(milliseconds: 250),
      slow = const Duration(milliseconds: 400),
      standard = Curves.easeInOutCubic,
      emphasised = Curves.easeOutCubic;

  /// State changes the user should barely notice — a colour or opacity swap.
  final Duration fast;

  /// The default transition length.
  final Duration normal;

  /// Entrances and exits of large surfaces.
  final Duration slow;

  /// Default easing for a change that starts and ends on screen.
  final Curve standard;

  /// Easing for something arriving — decelerates into place.
  final Curve emphasised;
}
