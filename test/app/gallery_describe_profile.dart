import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_avatar.dart';

/// Describes gallery variants for 📱 08 Profile & Settings.
///
/// Returns `null` for anything it does not own, so `gallery_test.dart` can
/// chain the describers together.
String? describeProfile(Widget widget) => switch (widget) {
  // --- PROFILE: add cases below ---
  // Names the **resolved** type, not the requested one: an image variant with
  // no image falls back, and a label claiming `Type=Image` over a rendered
  // glyph is a label that lies.
  MonetaAvatar(:final resolvedType, :final size, :final name) =>
    'Avatar(${resolvedType.name},${size.diameter.toInt()},$name)',
  _ => null,
};
