import 'package:flutter/material.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/elevation.dart';
import 'package:moneta/design_system/tokens/motion.dart';
import 'package:moneta/design_system/tokens/radii.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/design_system/tokens/typography.dart';

/// The whole token set, carried on [ThemeData] so any widget can reach it and a
/// test can replace it.
@immutable
class MonetaTheme extends ThemeExtension<MonetaTheme> {
  /// Creates a theme from explicit token groups.
  const MonetaTheme({
    required this.colors,
    required this.text,
    required this.spacing,
    required this.radii,
    required this.elevation,
    required this.motion,
  });

  /// The dark token set — the only one the Figma file defines.
  MonetaTheme.dark()
    : colors = const MonetaColors.dark(),
      text = MonetaTypography.figma(),
      spacing = const MonetaSpacing.figma(),
      radii = const MonetaRadii.figma(),
      elevation = const MonetaElevation.figma(),
      motion = const MonetaMotion.defaults();

  /// Colour roles.
  final MonetaColors colors;

  /// The type scale.
  final MonetaTypography text;

  /// The spacing scale.
  final MonetaSpacing spacing;

  /// Corner radii.
  final MonetaRadii radii;

  /// Shadow effects.
  final MonetaElevation elevation;

  /// Durations and curves.
  final MonetaMotion motion;

  /// Reads the token set from [context].
  ///
  /// Throws rather than falling back to a default: a widget rendering with
  /// Material defaults instead of Moneta tokens looks *almost* right, which is
  /// harder to notice than a crash and is exactly the drift this layer exists
  /// to prevent.
  static MonetaTheme of(BuildContext context) {
    final theme = Theme.of(context).extension<MonetaTheme>();
    if (theme == null) {
      throw FlutterError(
        'No MonetaTheme found in the widget tree.\n'
        'Wrap the subtree in a MaterialApp/Theme whose ThemeData carries the '
        'extension, e.g. MaterialApp(theme: MonetaTheme.dark().toThemeData()). '
        'In tests, use pumpMonetaWidget from test/support.',
      );
    }
    return theme;
  }

  /// Builds the [ThemeData] that carries this token set and maps it onto
  /// Material's own slots, so unstyled Material widgets do not fall back to
  /// purple-on-white.
  ThemeData toThemeData() {
    final colorScheme = ColorScheme.dark(
      primary: colors.brand,
      onPrimary: colors.textOnBrand,
      secondary: colors.brandOnSurface,
      onSecondary: colors.textOnBrand,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      surfaceContainerHighest: colors.surfaceRaised,
      error: colors.expense,
      onError: colors.textOnBrand,
      outline: colors.textTertiary,
      outlineVariant: colors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      fontFamily: MonetaFontFamily.text,
      splashFactory: InkSparkle.splashFactory,
      textTheme:
          TextTheme(
            displayLarge: text.amountXl,
            displayMedium: text.amountMd,
            headlineLarge: text.headingH1,
            titleMedium: text.titleMd,
            bodyMedium: text.bodyMd,
            labelLarge: text.labelMd,
            labelMedium: text.labelSm,
            labelSmall: text.captionMd,
          ).apply(
            bodyColor: colors.textPrimary,
            displayColor: colors.textPrimary,
          ),
      extensions: [this],
    );
  }

  @override
  MonetaTheme copyWith({
    MonetaColors? colors,
    MonetaTypography? text,
    MonetaSpacing? spacing,
    MonetaRadii? radii,
    MonetaElevation? elevation,
    MonetaMotion? motion,
  }) {
    return MonetaTheme(
      colors: colors ?? this.colors,
      text: text ?? this.text,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      elevation: elevation ?? this.elevation,
      motion: motion ?? this.motion,
    );
  }

  @override
  MonetaTheme lerp(MonetaTheme? other, double t) {
    if (other == null) return this;
    // Spacing, radii, elevation and motion are structural rather than visual:
    // animating them mid-transition would make layout jitter, so they snap.
    return MonetaTheme(
      colors: colors.lerp(other.colors, t),
      text: text.lerp(other.text, t),
      spacing: t < 0.5 ? spacing : other.spacing,
      radii: t < 0.5 ? radii : other.radii,
      elevation: t < 0.5 ? elevation : other.elevation,
      motion: t < 0.5 ? motion : other.motion,
    );
  }
}

/// Sugar for [MonetaTheme.of].
extension MonetaThemeContext on BuildContext {
  /// The Moneta token set for this subtree.
  MonetaTheme get moneta => MonetaTheme.of(this);
}
