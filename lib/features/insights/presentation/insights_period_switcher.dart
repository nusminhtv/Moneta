import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/molecules/moneta_segmented_control.dart';
import 'package:moneta/features/insights/domain/insights_period.dart';

/// The four-way switcher from `77:32`.
///
/// One implementation for all the Insights screens. Annotation `77:291` says
/// the period changes the data and not the layout, and three copies of a
/// switcher would be three chances for one of them to drift.
class InsightsPeriodSwitcher extends StatelessWidget {
  /// Creates a switcher.
  const InsightsPeriodSwitcher({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// The active period.
  final InsightsPeriod selected;

  /// Called with the period chosen.
  final ValueChanged<InsightsPeriod> onChanged;

  @override
  Widget build(BuildContext context) => MonetaSegmentedControl(
    labels: [for (final period in InsightsPeriod.values) period.label],
    selectedIndex: InsightsPeriod.values.indexOf(selected),
    onChanged: (index) => onChanged(InsightsPeriod.values[index]),
  );
}
