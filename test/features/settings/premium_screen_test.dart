import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_badge.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/features/settings/domain/premium_plan.dart';
import 'package:moneta/features/settings/presentation/premium_screen.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpPremium(
    WidgetTester tester, {
    ValueChanged<PremiumPlan>? onPurchaseAttempt,
    VoidCallback? onClose,
  }) => pumpMonetaWidget(
    tester,
    PremiumScreen(onClose: onClose, onPurchaseAttempt: onPurchaseAttempt),
    surfaceSize: const Size(393, 1200),
  );

  /// Whether the card for [period] reads selected, from its semantics.
  bool isSelected(WidgetTester tester, PremiumPeriod period) => tester
      .getSemantics(find.byKey(PremiumScreen.planKey(period)))
      .getSemanticsData()
      .toString()
      .contains('isSelected');

  group('the plans', () {
    testWidgets('yearly is preselected', (tester) async {
      await pumpPremium(tester);

      expect(isSelected(tester, PremiumPeriod.yearly), isTrue);
      expect(isSelected(tester, PremiumPeriod.monthly), isFalse);
      expect(isSelected(tester, PremiumPeriod.lifetime), isFalse);
    });

    testWidgets('exactly one is selected after tapping any of them', (
      tester,
    ) async {
      await pumpPremium(tester);

      for (final period in PremiumPeriod.values) {
        await tester.tap(find.byKey(PremiumScreen.planKey(period)));
        await tester.pump();

        final selected = PremiumPeriod.values
            .where((p) => isSelected(tester, p))
            .toList();
        expect(
          selected,
          [period],
          reason: 'after tapping ${period.name}, only it should be selected',
        );
      }
    });

    testWidgets('the badge claims the computed saving, on the yearly card', (
      tester,
    ) async {
      await pumpPremium(tester);

      final saving = yearlySavingPercent(
        monthly: premiumPlans
            .firstWhere((p) => p.period == PremiumPeriod.monthly)
            .price,
        yearly: premiumPlans
            .firstWhere((p) => p.period == PremiumPeriod.yearly)
            .price,
      );
      // 31, and it is on the card the annotation says carries it.
      expect(saving, 31);
      expect(find.text('SAVE 31%'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(PremiumScreen.planKey(PremiumPeriod.yearly)),
          matching: find.byType(MonetaBadge),
        ),
        findsOneWidget,
      );
      expect(find.byType(MonetaBadge), findsOneWidget);
    });
  });

  group('the comparison table', () {
    testWidgets('the negatives are not errors', (tester) async {
      await pumpPremium(tester);

      MonetaIcon glyphAt(Key key) => tester.widget<MonetaIcon>(find.byKey(key));

      for (final feature in PremiumFeature.values) {
        final free = glyphAt(PremiumScreen.freeGlyphKey(feature));
        final premium = glyphAt(PremiumScreen.premiumGlyphKey(feature));

        // Premium has everything.
        expect(premium.icon, MonetaIconName.check);
        expect(premium.color, colors.income);

        if (feature.inFree) {
          expect(free.icon, MonetaIconName.check);
          expect(free.color, colors.income);
        } else {
          expect(free.icon, MonetaIconName.x);
          // `102:1188`: "the free tier is not an error."
          expect(free.color, colors.textDisabled);
          expect(
            free.color,
            isNot(colors.expense),
            reason: 'an absent feature is a fact, not a fault',
          );
        }
      }

      // And the two colours differ, so the loop above is comparing something.
      expect(colors.income, isNot(colors.textDisabled));
    });

    testWidgets('every feature appears once', (tester) async {
      await pumpPremium(tester);
      for (final feature in PremiumFeature.values) {
        expect(find.text(feature.label), findsOneWidget);
      }
    });
  });

  group('the call to action tells the truth', () {
    testWidgets('it says purchases are unavailable', (tester) async {
      await pumpPremium(tester, onPurchaseAttempt: (_) {});
      expect(
        find.text('Purchases are not available in this build.'),
        findsOneWidget,
      );
    });

    testWidgets('it reports the chosen plan rather than doing nothing', (
      tester,
    ) async {
      final attempts = <PremiumPlan>[];
      await pumpPremium(tester, onPurchaseAttempt: attempts.add);

      await tester.tap(find.byKey(PremiumScreen.ctaKey));
      expect(attempts.single.period, PremiumPeriod.yearly);

      await tester.tap(
        find.byKey(PremiumScreen.planKey(PremiumPeriod.monthly)),
      );
      await tester.pump();
      await tester.tap(find.byKey(PremiumScreen.ctaKey));
      expect(attempts.last.period, PremiumPeriod.monthly);
    });

    testWidgets('and its label follows the selection', (tester) async {
      await pumpPremium(tester, onPurchaseAttempt: (_) {});
      expect(find.text('Continue with yearly'), findsOneWidget);

      await tester.tap(
        find.byKey(PremiumScreen.planKey(PremiumPeriod.lifetime)),
      );
      await tester.pump();
      expect(find.text('Continue with lifetime'), findsOneWidget);
    });
  });

  testWidgets('the screen can be closed', (tester) async {
    var closed = 0;
    await pumpPremium(tester, onClose: () => closed++);

    await tester.tap(find.bySemanticsLabel('Close'));
    expect(closed, 1);
  });
}
