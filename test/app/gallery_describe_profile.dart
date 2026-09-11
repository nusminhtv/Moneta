import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_avatar.dart';
import 'package:moneta/design_system/atoms/moneta_badge.dart';
import 'package:moneta/design_system/atoms/moneta_chip.dart';
import 'package:moneta/design_system/molecules/moneta_search_field.dart';

/// Describes gallery variants for 📱 08 Profile & Settings.
///
/// Returns `null` for anything it does not own, so `gallery_test.dart` can
/// chain the describers together.
String? describeProfile(Widget widget) => switch (widget) {
  // --- PROFILE: add cases below ---
  // Names the state **and** the text it is derived from. The catalog labels
  // these `State=Empty` and `State=Filled`, and the label check requires the
  // description to carry any property a label names — so the description says
  // the word, and computes it the same way the widget does rather than
  // repeating a parameter, because there is no parameter to repeat.
  MonetaSearchField(:final placeholder, :final controller) =>
    'SearchField('
        '${(controller?.text ?? '').isEmpty ? 'Empty' : 'Filled'},'
        '$placeholder,${controller?.text ?? ''})',
  MonetaChip(:final type, :final selected, :final leadingIcon, :final label) =>
    'Chip(${type.name},$selected,${leadingIcon?.name},$label)',
  MonetaBadge(:final tone, :final size, :final dot, :final label) =>
    'Badge(${tone.name},${size.name},$dot,$label)',
  // Names the **resolved** type, not the requested one: an image variant with
  // no image falls back, and a label claiming `Type=Image` over a rendered
  // glyph is a label that lies.
  MonetaAvatar(:final resolvedType, :final size, :final name) =>
    'Avatar(${resolvedType.name},${size.diameter.toInt()},$name)',
  _ => null,
};
