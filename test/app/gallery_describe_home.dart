import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/section_header.dart';

/// Describes gallery variants for 📱 02 Home & Dashboard.
///
/// **Owner: the home agent.** Returns `null` for anything it does not own, so
/// `gallery_test.dart` can chain the describers together.
///
/// Name the properties that make a variant distinct — the check this feeds
/// fails when two variants of a component render the same widget, and it can
/// only see what the description mentions.
String? describeHome(Widget widget) => switch (widget) {
  // --- HOME: add cases below ---
  ListRow(
    :final title,
    :final subtitle,
    :final leadingIcon,
    :final accessory,
    :final value,
    :final badgeLabel,
    :final toggled,
  ) =>
    'ListRow(${accessory.name},$title,$subtitle,'
        '${leadingIcon?.figmaName},$value,$badgeLabel,$toggled)',
  SectionHeader(:final title, :final actionLabel) =>
    'SectionHeader(default,$title,$actionLabel)',
  _ => null,
};
