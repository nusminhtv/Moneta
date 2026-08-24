import 'package:meta/meta.dart';

/// The spacing scale.
///
/// **Not read from a Figma variable collection.** No named spacing variables
/// appear in any node this project has read; padding and gap values are literal
/// in the components. The steps below are the distinct observed values, in
/// ascending order, with the node each was seen in recorded in
/// docs/design-system/figma-tokens.md.
///
/// If a spacing variable collection turns up in the file, this scale should be
/// replaced by it rather than extended.
@immutable
final class MonetaSpacing {
  /// Creates a spacing scale from explicit steps.
  const MonetaSpacing({
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.x3l,
    required this.x4l,
    required this.x5l,
    required this.x6l,
  });

  /// The scale derived from observed Figma values.
  const MonetaSpacing.figma()
    : xxs = 2,
      xs = 4,
      sm = 6,
      md = 8,
      lg = 10,
      xl = 12,
      xxl = 14,
      x3l = 16,
      x4l = 20,
      x5l = 24,
      x6l = 28;

  /// 2 — tightest gap, between a title and its note.
  final double xxs;

  /// 4 — icon-to-label gap in a nav tab.
  final double xs;

  /// 6 — gap between rows inside a card.
  final double sm;

  /// 8 — nav tab row padding.
  final double md;

  /// 10 — card content gap; progress bar height.
  final double lg;

  /// 12 — card head gap; banner vertical padding.
  final double xl;

  /// 14 — banner horizontal padding.
  final double xxl;

  /// 16 — card padding.
  final double x3l;

  /// 20 — hero card padding; stats gap.
  final double x4l;

  /// 24 — app bar trailing padding.
  final double x5l;

  /// 28 — status bar leading padding.
  final double x6l;

  /// Every step, ascending. Used by tests and the gallery.
  List<double> get all => [
    xxs,
    xs,
    sm,
    md,
    lg,
    xl,
    xxl,
    x3l,
    x4l,
    x5l,
    x6l,
  ];
}

/// Fixed layout measurements from the Figma frames.
///
/// These are not a scale — they are specific sizes the design commits to, and a
/// screen that ignores them stops matching the file.
abstract final class MonetaLayout {
  /// Design frame width.
  static const double frameWidth = 393;

  /// Design frame height.
  static const double frameHeight = 852;

  /// Top safe area baked into every Figma screen frame.
  static const double safeAreaTop = 59;

  /// Bottom safe area baked into every Figma screen frame.
  static const double safeAreaBottom = 34;

  /// Width of the content column inside the frame.
  static const double contentWidth = 353;

  /// Bottom navigation bar height, excluding the safe area.
  static const double bottomNavHeight = 64;

  /// Floating action button diameter.
  static const double fabSize = 56;

  /// How far the floating action button rises above the nav bar.
  static const double fabOverlap = 19;

  /// Width of the gap in the tab row that the floating action button sits over.
  static const double fabSlotWidth = 72;

  /// Default icon canvas size.
  static const double iconSize = 24;

  /// Stroke weight the icon set is drawn at.
  static const double iconStrokeWidth = 1.75;

  /// Progress bar height.
  static const double progressBarHeight = 10;

  /// Minimum touch target for an icon-only action.
  static const double minTouchTarget = 44;
}
