import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_circular_progress.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/design_system/molecules/moneta_segmented_control.dart';

/// Describes gallery variants for 📱 04 Budgets.
///
/// Returns `null` for anything it does not own, so `gallery_test.dart` can
/// chain the describers together.
///
/// Name the properties that make a variant distinct — the check this feeds
/// fails when two variants of a component render the same widget, and it can
/// only see what the description mentions.
String? describeBudgets(Widget widget) => switch (widget) {
  // --- BUDGETS: add cases below ---
  // The state is named, not just the fraction: it is what Figma names the
  // variant after, and it is derived — so a ring whose fraction drifts out of
  // the state its label claims is caught here rather than by eye.
  MonetaCircularProgress(:final fraction, :final size) =>
    'CircularProgress(${_figmaState(BudgetStatus.fromFraction(fraction))},'
        '${size.name},$fraction)',
  MonetaSegmentedItem(:final label, :final selected) =>
    'SegmentedItem($selected,$label)',
  MonetaSegmentedControl(:final labels, :final selectedIndex) =>
    'SegmentedControl(default,${labels.join("|")},$selectedIndex)',
  _ => null,
};

/// Figma's name for a budget status.
///
/// `25:272` names its variants Under / Near / Over; the Dart enum reads
/// onTrack / nearLimit / over. Same three states, two vocabularies — the
/// gallery compares the variant label against this description, so it has to
/// speak Figma's.
String _figmaState(BudgetStatus status) => switch (status) {
  BudgetStatus.onTrack => 'under',
  BudgetStatus.nearLimit => 'near',
  BudgetStatus.over => 'over',
};
