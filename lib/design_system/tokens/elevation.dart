import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';

/// Shadow effects from Figma.
///
/// Only the two effects the file actually defines are here. `elevation/1` and
/// `elevation/2` are referenced by name in Figma's effect list but were not
/// observed on any node read, so they are not implemented.
@immutable
final class MonetaElevation {
  /// Creates an elevation set from explicit shadow lists.
  const MonetaElevation({required this.level3, required this.brandGlow});

  /// The effects read from Figma.
  const MonetaElevation.figma()
    : level3 = const [
        BoxShadow(
          // Figma elevation/3: #0000008C — 0x8C = 140/255 = 55% black.
          color: Color(0x8C000000),
          offset: Offset(0, 12),
          blurRadius: 32,
        ),
      ],
      brandGlow = const [
        BoxShadow(
          // Figma glow/brand: #7A5AF859 — 0x59 = 89/255 = 35% brand violet.
          color: Color(0x597A5AF8),
          blurRadius: 24,
        ),
      ];

  /// The card shadow — used by the hero balance card.
  final List<BoxShadow> level3;

  /// The brand glow — used by the floating action button.
  final List<BoxShadow> brandGlow;
}
