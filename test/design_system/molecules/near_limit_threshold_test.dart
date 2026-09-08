import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/atoms/moneta_circular_progress.dart';
import 'package:moneta/design_system/molecules/budget_status.dart';
import 'package:moneta/design_system/molecules/progress_bar.dart';
import 'package:moneta/design_system/organisms/budget_card.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

/// The near-limit boundary belongs to the budget, not to the widget.
///
/// Annotation `04.04`: *"'Alert me at 80%' is what drives BudgetCard's
/// NearLimit state — the 80% threshold is configurable here, so the component's
/// warning colour is data-driven, not hardcoded."*
///
/// `budget-components` shipped it as a constant that three widgets read. These
/// tests pin the correction, and pin that the status is still derived.
void main() {
  const colors = MonetaColors.dark();
  const vnd = Currency.vnd;

  group('BudgetStatus', () {
    test('a budget can move its own boundary', () {
      expect(
        BudgetStatus.fromFraction(0.7, nearLimitThreshold: 0.6),
        BudgetStatus.nearLimit,
      );
      expect(BudgetStatus.fromFraction(0.7), BudgetStatus.onTrack);
    });

    test('over the limit ignores the threshold entirely', () {
      for (final t in [0.1, 0.5, 0.8, 1.0]) {
        expect(
          BudgetStatus.fromFraction(1.2, nearLimitThreshold: t),
          BudgetStatus.over,
          reason: 'threshold $t changed the over-limit verdict',
        );
      }
    });

    test('a threshold of 1.0 warns only once the limit is reached', () {
      expect(
        BudgetStatus.fromFraction(0.99, nearLimitThreshold: 1),
        BudgetStatus.onTrack,
      );
      // Exactly 1.0 is the limit reached, not exceeded — the existing rule.
      expect(
        BudgetStatus.fromFraction(1, nearLimitThreshold: 1),
        BudgetStatus.nearLimit,
      );
    });

    test('fromSpend carries the threshold through', () {
      expect(
        BudgetStatus.fromSpend(
          const Money(700, vnd),
          const Money(1000, vnd),
          nearLimitThreshold: 0.6,
        ),
        BudgetStatus.nearLimit,
      );
      expect(
        BudgetStatus.fromSpend(const Money(700, vnd), const Money(1000, vnd)),
        BudgetStatus.onTrack,
      );
    });

    test('the default is unchanged, so every existing call site is', () {
      expect(BudgetStatus.defaultNearLimitThreshold, 0.8);
      expect(BudgetStatus.fromFraction(0.79), BudgetStatus.onTrack);
      expect(BudgetStatus.fromFraction(0.8), BudgetStatus.nearLimit);
    });
  });

  group('the three widgets agree at a moved boundary', () {
    test('bar and ring resolve the same colour', () {
      for (final t in [0.5, 0.8, 0.95, 1.0]) {
        for (final f in [0.4, 0.49, 0.5, 0.79, 0.8, 0.94, 1.0, 1.2]) {
          expect(
            MonetaProgressBar.fillColorFor(f, colors, nearLimitThreshold: t),
            MonetaCircularProgress.arcColorFor(
              f,
              colors,
              nearLimitThreshold: t,
            ),
            reason: 'bar and ring disagree at fraction $f, threshold $t',
          );
        }
      }
    });

    testWidgets('the card warns at its own boundary', (tester) async {
      Future<void> pumpCard({required double threshold}) => pumpMonetaWidget(
        tester,
        SizedBox(
          width: 353,
          child: BudgetCard(
            category: SpendCategory.food,
            spent: const Money(600000, vnd),
            limit: const Money(1000000, vnd),
            note: '60% used',
            nearLimitThreshold: threshold,
          ),
        ),
        surfaceSize: const Size(393, 300),
      );

      await pumpCard(threshold: 0.5);
      expect(
        tester.widget<BudgetCard>(find.byType(BudgetCard)).status,
        BudgetStatus.nearLimit,
      );

      await pumpCard(threshold: BudgetStatus.defaultNearLimitThreshold);
      expect(
        tester.widget<BudgetCard>(find.byType(BudgetCard)).status,
        BudgetStatus.onTrack,
      );
    });

    testWidgets('the card passes its threshold down to its bar', (
      tester,
    ) async {
      // A card that warns while the bar inside it stays green would be worse
      // than no threshold at all.
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: 353,
          child: BudgetCard(
            category: SpendCategory.food,
            spent: Money(600000, vnd),
            limit: Money(1000000, vnd),
            note: '60% used',
            nearLimitThreshold: 0.5,
          ),
        ),
        surfaceSize: const Size(393, 300),
      );
      expect(
        tester
            .widget<MonetaProgressBar>(find.byType(MonetaProgressBar))
            .nearLimitThreshold,
        0.5,
      );
    });
  });

  group('the status is still derived, not chosen', () {
    test('no widget accepts a BudgetStatus', () {
      const bar = MonetaProgressBar(fraction: 0.5);
      const ring = MonetaCircularProgress(fraction: 0.5);
      const card = BudgetCard(
        category: SpendCategory.food,
        spent: Money(500, vnd),
        limit: Money(1000, vnd),
        note: '50%',
      );
      for (final w in <Widget>[bar, ring, card]) {
        expect(
          w.toDiagnosticsNode().getProperties().map((p) => p.name),
          isNot(contains('status')),
          reason: '${w.runtimeType} exposes a settable status',
        );
      }
    });
  });
}
