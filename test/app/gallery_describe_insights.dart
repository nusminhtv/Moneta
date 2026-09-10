import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_radio.dart';
import 'package:moneta/design_system/molecules/chart_legend_item.dart';
import 'package:moneta/design_system/molecules/moneta_radio_row.dart';
import 'package:moneta/design_system/organisms/bottom_sheet.dart';
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
  // Figma names the variants Selected / Disabled, while the Dart property is
  // `enabled`. The description speaks Figma's vocabulary so the label is
  // comparable to it.
  MonetaRadio(:final selected, :final enabled) =>
    'Radio(selected=$selected,disabled=${!enabled})',
  MonetaRadioRow(:final selected, :final enabled, :final supporting) =>
    'RadioRow(selected=$selected,disabled=${!enabled},'
        'supporting=${supporting != null})',
  // Names the selected value AND which row it lands on, so a group whose
  // labels moved but whose selection did not is caught.
  MonetaRadioGroup<String>(:final options, :final selected) =>
    'RadioGroup(selected=$selected,'
        '${options.map((o) => '${o.title}:${o.value == selected}').join("|")})',
  // Names the option count, not "short" or "tall": the variants differ by how
  // much content they hold, and a count is the part of that a describer can
  // check outside a pump. The label claims the same number.
  MonetaBottomSheet(:final title, :final child) =>
    'BottomSheet($title,'
        '${child is MonetaRadioGroup<String> ? '${child.options.length} options' : 'opaque content'})',
  _ => null,
};
