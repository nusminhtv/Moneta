import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/typography.dart';

/// Which of the three authored avatar types to draw, from `21:121`.
enum MonetaAvatarType {
  /// A supplied photo, clipped to the circle.
  image,

  /// Initials derived from a display name.
  initials,

  /// The `icon/user` glyph — the fallback when there is neither.
  icon,
}

/// Avatar diameters, from `21:121`: four sizes.
///
/// Each carries its own **transcribed** type style and glyph size. Neither
/// scales, and neither is a formula:
///
/// - initials go `label/sm`, `label/sm`, `label/md`, `title/md`, so 24 and 32
///   share a style while 40 and 56 differ from both;
/// - glyphs go 14, 18, 22, 28 — the first three are `size / 2 + 2`, which fits
///   three of four points and gives **30** at 56 where the file says 28.
///
/// A table cannot be wrong between its entries. A formula fitted to the small
/// end is wrong at the large one, which is exactly the mistake available here.
enum MonetaAvatarSize {
  /// 24px, from `21:82`/`21:97`/`21:109`.
  xs(diameter: 24, glyphSize: 14),

  /// 32px, from `21:88`/`21:100`/`21:112`.
  sm(diameter: 32, glyphSize: 18),

  /// 40px, from `21:91`/`21:103`/`21:115`.
  md(diameter: 40, glyphSize: 22),

  /// 56px, from `21:94`/`21:106`/`21:118`.
  lg(diameter: 56, glyphSize: 28);

  const MonetaAvatarSize({required this.diameter, required this.glyphSize});

  /// Width and height of the circle.
  final double diameter;

  /// Edge length of the `icon/user` glyph inside it.
  final double glyphSize;

  /// The initials' type style at this size.
  TextStyle initialsStyle(MonetaTypography text) => switch (this) {
    MonetaAvatarSize.xs => text.labelSm,
    MonetaAvatarSize.sm => text.labelSm,
    MonetaAvatarSize.md => text.labelMd,
    MonetaAvatarSize.lg => text.titleMd,
  };

  /// The label Figma gives this size, e.g. `Size=40`.
  String get figmaName => 'Size=${diameter.toInt()}';
}

/// A user avatar: a photo, initials, or the user glyph.
///
/// From Figma node `21:121` — 3 types × 4 sizes, all twelve implemented.
///
/// `21:121`'s description: *"3 types x 4 sizes. Image variants are placeholders
/// — apply a real image fill on the instance."* So [image] is an
/// `ImageProvider` the caller supplies and this component does no fetching,
/// caching or decoding of its own.
///
/// **Initials are derived from [name], never passed as a string.** A caller
/// handing over `"MT"` could equally hand over three letters, a lowercase pair
/// or a punctuation mark, and the circle would render it. `21:106`'s
/// description sets the fallback order: *"Initials fall back when no photo
/// exists."*
class MonetaAvatar extends StatelessWidget {
  /// Creates an avatar.
  const MonetaAvatar({
    required this.type,
    required this.size,
    this.name,
    this.image,
    this.semanticLabel,
    super.key,
  });

  /// Which of the three types to draw.
  ///
  /// Requesting [MonetaAvatarType.image] with no [image], or
  /// [MonetaAvatarType.initials] with a [name] that yields no letters, falls
  /// back — photo, then initials, then glyph — rather than rendering an empty
  /// circle.
  final MonetaAvatarType type;

  /// Which diameter.
  final MonetaAvatarSize size;

  /// The display name initials are derived from.
  final String? name;

  /// The photo. An `ImageProvider`, not a URL and not a widget: a widget would
  /// let a caller put anything in the circle, and then it would not be an
  /// avatar.
  final ImageProvider<Object>? image;

  /// What to announce. Falls back to [name], then to a generic description.
  final String? semanticLabel;

  /// Most initials shown, from `21:106`'s `MT`.
  static const int maxInitials = 2;

  /// Key on the initials, so tests can read them without matching a string.
  static const Key initialsKey = Key('MonetaAvatar.initials');

  /// Key on the glyph.
  static const Key glyphKey = Key('MonetaAvatar.glyph');

  /// Key on the photo.
  static const Key imageKey = Key('MonetaAvatar.image');

  /// The initials [name] yields, or empty when it yields none.
  ///
  /// First letter of the first word and of the last, upper-cased. A one-word
  /// name gives one letter; a name with no letters at all gives none, which is
  /// what triggers the glyph fallback.
  static String initialsOf(String? name) {
    final words = (name ?? '')
        .split(RegExp(r'\s+'))
        .map((word) => word.replaceAll(RegExp('[^A-Za-zÀ-ỹ]'), ''))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  /// Which type will actually be drawn, after the fallbacks.
  MonetaAvatarType get resolvedType {
    if (type == MonetaAvatarType.image && image != null) {
      return MonetaAvatarType.image;
    }
    if (initialsOf(name).isNotEmpty && type != MonetaAvatarType.icon) {
      return MonetaAvatarType.initials;
    }
    return MonetaAvatarType.icon;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return Semantics(
      label: semanticLabel ?? name ?? 'Profile picture',
      image: resolvedType == MonetaAvatarType.image,
      // The initials are decoration, not content: a screen reader announcing
      // "Minh Tran, MT" reads the same name twice, and the second time as two
      // letters. The container carries the label; what is inside it does not.
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size.diameter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.brandSubtle,
            shape: BoxShape.circle,
          ),
          // Clipped, because `21:121` sets `overflow-clip`: a photo must take
          // the circle's shape rather than sit as a square behind it.
          child: ClipOval(child: Center(child: _content(theme))),
        ),
      ),
    );
  }

  Widget _content(MonetaTheme theme) => switch (resolvedType) {
    MonetaAvatarType.image => Image(
      key: imageKey,
      image: image!,
      width: size.diameter,
      height: size.diameter,
      fit: BoxFit.cover,
    ),
    MonetaAvatarType.initials => Text(
      initialsOf(name),
      key: initialsKey,
      maxLines: 1,
      style: size
          .initialsStyle(theme.text)
          .copyWith(color: theme.colors.brandOnSurface),
    ),
    // `textSecondary`, not `brandOnSurface`. `21:120`'s exported glyph is
    // `stroke="#9AA3B4"` — I assumed the brand colour, because the initials use
    // it, and the file says otherwise.
    MonetaAvatarType.icon => MonetaIcon(
      MonetaIconName.user,
      key: glyphKey,
      size: size.glyphSize,
      color: theme.colors.textSecondary,
    ),
  };
}
