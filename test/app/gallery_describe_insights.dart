import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/molecules/chart_legend_item.dart';

/// Describes gallery variants for 📱 07 Insights & Reports.
///
/// Returns `null` for anything it does not own, so `gallery_test.dart` can
/// chain the describers together.
///
/// Name the properties that make a variant distinct — the check this feeds
/// fails when two variants of a component render the same widget, and it can
/// only see what the description mentions.
String? describeInsights(Widget widget) => switch (widget) {
  // --- INSIGHTS: add cases below ---
  // The slot's Figma name, not the enum's: the gallery label is `Slot=Other`,
  // and a claim nothing can be compared against is a claim nothing checks.
  ChartLegendItem(:final slot, :final label, :final fraction) =>
    'ChartLegendItem(${slot.figmaName},$label,$fraction)',
  _ => null,
};
