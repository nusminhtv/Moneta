import 'package:meta/meta.dart';

/// The spacing scale.
///
/// **Two scales live here, deliberately and temporarily.**
///
/// The Figma set — [space0] through [space5xl] — is read from the real variable
/// collection at node `107:75` and is the only one new code may use.
///
/// The older set — [xxs] through [x6l] — was reverse-engineered from literal gaps
/// in component nodes before the collection was found. Its names are bound to the
/// wrong values: `sm` is 6 where Figma's `space/sm` is 8, `lg` is 10 where
/// Figma's is 20. Four of its steps (6, 10, 14, 28) are not in the collection at
/// all. It stays only so existing widgets keep compiling; each member names its
/// replacement. Migrating them is a follow-up change.
///
/// See docs/design-system/figma-tokens.md for the full comparison.
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

  /// 2 — tightest gap. **Deprecated:** use [space2xs] (also 2).
  final double xxs;

  /// 4 — icon-to-label gap. **Deprecated:** use [spaceXs] (also 4).
  final double xs;

  /// 6. **Deprecated and wrong:** Figma's `space/sm` is 8 ([spaceSm]). 6 is not
  /// in the spacing collection at all — it is `radius-xs`.
  final double sm;

  /// 8. **Deprecated and wrong:** this is Figma's `space/sm` ([spaceSm]).
  /// Figma's `space/md` is 12 ([spaceMd]).
  final double md;

  /// 10. **Deprecated and wrong:** Figma's `space/lg` is 20 ([spaceLg]). 10 is
  /// not in the spacing collection — it is `radius-sm`.
  final double lg;

  /// 12. **Deprecated and wrong:** this is Figma's `space/md` ([spaceMd]).
  /// Figma's `space/xl` is 24 ([spaceXl]).
  final double xl;

  /// 14. **Deprecated and wrong:** not in the spacing collection — it is
  /// `radius-md`.
  final double xxl;

  /// 16 — card padding. **Deprecated:** use [spaceBase] (also 16).
  final double x3l;

  /// 20 — screen gutter. **Deprecated:** use [spaceLg] (also 20).
  final double x4l;

  /// 24. **Deprecated:** use [spaceXl] (also 24).
  final double x5l;

  /// 28. **Deprecated and wrong:** not in the spacing collection.
  final double x6l;

  // ── Figma's real collection, node 107:75 ──────────────────────────────
  // Names and values exactly as authored, with Figma's stated purpose.

  /// 0 — reset only.
  static const double space0 = 0;

  /// 2 — icon to label inside a chip.
  static const double space2xs = 2;

  /// 4 — label to value in a stat tile.
  static const double spaceXs = 4;

  /// 8 — between rows in a dense list.
  static const double spaceSm = 8;

  /// 12 — default vertical rhythm on a screen.
  static const double spaceMd = 12;

  /// 16 — card inner padding.
  static const double spaceBase = 16;

  /// 20 — screen horizontal gutter.
  static const double spaceLg = 20;

  /// 24 — between sections.
  static const double spaceXl = 24;

  /// 32 — above a section header.
  static const double space2xl = 32;

  /// 40 — hero block padding.
  static const double space3xl = 40;

  /// 48 — empty-state breathing room.
  static const double space4xl = 48;

  /// 64 — full-screen state centring.
  static const double space5xl = 64;

  /// Figma's collection in ascending order, for tests and the gallery.
  static const List<double> figmaScale = [
    space0,
    space2xs,
    spaceXs,
    spaceSm,
    spaceMd,
    spaceBase,
    spaceLg,
    spaceXl,
    space2xl,
    space3xl,
    space4xl,
    space5xl,
  ];

  /// Every step of the **deprecated** scale, ascending.
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
  ///
  /// **Not observed in Figma — derived.** The file authors the FAB (56) and the
  /// bar, but no slot width; this is 56 plus 8 clearance either side. Recorded
  /// in `docs/design-system/figma-tokens.md` as derived rather than left to look
  /// like a transcription.
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
