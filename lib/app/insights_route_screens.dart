/// Route wrappers for the Insights screens.
///
/// The screens are presentational — figures in, callbacks out — so this is
/// where they meet the providers and the router. Same split as
/// `home_route_screen.dart`, and the only one `check_architecture.dart` allows:
/// a feature may not import `lib/app`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/insights_providers.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/features/insights/domain/insights_period.dart';
import 'package:moneta/features/insights/presentation/cash_flow_screen.dart';
import 'package:moneta/features/insights/presentation/category_breakdown_screen.dart';
import 'package:moneta/features/insights/presentation/insights_overview_screen.dart';
import 'package:moneta/features/insights/presentation/period_picker_sheet.dart';

/// Where the Insights sub-screens live.
class InsightsRoutes {
  const InsightsRoutes._();

  /// 07.02 Cash flow.
  static const String cashFlow = '/insights/cash-flow';

  /// 07.03 Category breakdown.
  static const String categories = '/insights/categories';
}

/// 07.01, wired.
class InsightsOverviewRouteScreen extends ConsumerWidget {
  /// Creates the route screen.
  const InsightsOverviewRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(insightsSummaryProvider)
        .when(
          loading: () => const _InsightsLoading(),
          error: (error, _) => const _InsightsError(),
          data: (summary) => InsightsOverviewScreen(
            summary: summary,
            onPeriodChanged: (period) =>
                ref.read(insightsPeriodProvider.notifier).period = period,
            onOpenPeriodPicker: () => showInsightsPeriodPicker(context, ref),
          ),
        );
  }
}

/// 07.02, wired.
class CashFlowRouteScreen extends ConsumerWidget {
  /// Creates the route screen.
  const CashFlowRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(insightsSummaryProvider)
        .when(
          loading: () => const _InsightsLoading(),
          error: (error, _) => const _InsightsError(),
          data: (summary) => CashFlowScreen(
            summary: summary,
            onPeriodChanged: (period) =>
                ref.read(insightsPeriodProvider.notifier).period = period,
            onBack: () => context.pop(),
          ),
        );
  }
}

/// 07.03, wired.
class CategoryBreakdownRouteScreen extends ConsumerWidget {
  /// Creates the route screen.
  const CategoryBreakdownRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(insightsSummaryProvider)
        .when(
          loading: () => const _InsightsLoading(),
          error: (error, _) => const _InsightsError(),
          data: (summary) => CategoryBreakdownScreen(
            summary: summary,
            onPeriodChanged: (period) =>
                ref.read(insightsPeriodProvider.notifier).period = period,
            onBack: () => context.pop(),
          ),
        );
  }
}

/// Presents 07.05.
///
/// The sheet is a plain widget by design, so presenting it — and the scrim —
/// belongs here, exactly as `81:525` draws the scrim as the sheet's sibling.
Future<void> showInsightsPeriodPicker(
  BuildContext context,
  WidgetRef ref,
) async {
  final chosen = await showModalBottomSheet<InsightsPeriod>(
    context: context,
    backgroundColor: const Color(
      0x00000000,
    ), // design-token-ignore: the sheet paints its own surface
    isScrollControlled: true,
    builder: (sheetContext) => PeriodPickerSheet(
      selected: ref.read(insightsPeriodProvider),
      onSelected: (period) => Navigator.of(sheetContext).pop(period),
      onClose: () => Navigator.of(sheetContext).pop(),
    ),
  );
  // Dismissing changes nothing: only a chosen period is applied.
  if (chosen != null) {
    ref.read(insightsPeriodProvider.notifier).period = chosen;
  }
}

class _InsightsLoading extends StatelessWidget {
  const _InsightsLoading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// The error arm, which is **not** the empty state.
///
/// `transactions` already has a requirement about this: an empty wallet and an
/// unreadable one are different facts, and one screen for both hides a storage
/// failure behind "nothing here yet".
class _InsightsError extends StatelessWidget {
  const _InsightsError();

  @override
  Widget build(BuildContext context) => const Center(
    child: EmptyState(
      icon: MonetaIconName.alertTriangle,
      title: 'Could not read your ledger',
      message: 'Something went wrong reading the data. Try again in a moment.',
    ),
  );
}
