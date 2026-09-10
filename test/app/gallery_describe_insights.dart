import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/molecules/chart_legend_item.dart';
import 'package:moneta/design_system/organisms/donut_chart.dart';

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
  // Names the segment count AFTER folding, and the slots in ring order: the
  // variant labels claim "8 as authored", "9 folded into Other", "1" and "0",
  // and a claim nothing can be compared against is a claim nothing checks.
  DonutChart(:final categories, :final segments) =>
    'DonutChart(${categories.length}->${segments.length},'
        'fold=${categories.length > DonutChart.maxColoredSegments ? 'Other' : 'None'},'
        '${segments.map((s) => s.slot.figmaName).join("|")})',
  _ => null,
};
