import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/organisms/balance_card.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const vnd = Currency.vnd;

  Future<void> pumpCard(
    WidgetTester tester, {
    bool masked = false,
    Money? balance,
    VoidCallback? onToggleMask,
  }) {
    return pumpMonetaWidget(
      tester,
      SizedBox(
        width: 353,
        child: BalanceCard(
          totalBalance: balance ?? const Money(48320000, vnd),
          safeToSpend: const Money(6180000, vnd),
          income: const Money(32000000, vnd),
          expenses: const Money(25840000, vnd),
          safeToSpendUntil: '31 Aug',
          masked: masked,
          onToggleMask: onToggleMask,
        ),
      ),
      surfaceSize: const Size(420, 700),
    );
  }

  /// Every character rendered anywhere in the card.
  String renderedText(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .join(' ');

  group('default state', () {
    testWidgets('shows all four figures', (tester) async {
      await pumpCard(tester);
      final text = renderedText(tester);
      expect(text, contains('48.320.000'));
      expect(text, contains('6.180.000'));
      expect(text, contains('32.000.000'));
      expect(text, contains('25.840.000'));
    });

    testWidgets('signs income positive and expenses negative', (tester) async {
      await pumpCard(tester);
      final text = renderedText(tester);
      expect(text, contains('+32.000.000'));
      expect(text, contains('-25.840.000'));
    });

    testWidgets('renders expenses negative even when given as positive', (
      tester,
    ) async {
      // The caller passes a magnitude; the card owns the sign. Otherwise two
      // screens disagree about whether expenses are negative.
      await pumpCard(tester);
      expect(renderedText(tester), isNot(contains('+25.840.000')));
    });

    testWidgets('shows the period end in the safe-to-spend line', (
      tester,
    ) async {
      await pumpCard(tester);
      expect(renderedText(tester), contains('until 31 Aug'));
    });

    testWidgets('labels are the Figma copy', (tester) async {
      await pumpCard(tester);
      expect(find.text('Total balance'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
    });

    testWidgets('uses the amount-xl style on the balance', (tester) async {
      await pumpCard(tester);
      final balance = tester.widget<Text>(find.text('48.320.000 ₫'));
      expect(balance.style!.fontSize, 40);
      expect(balance.style!.color, const MonetaColors.dark().textOnBrand);
    });

    testWidgets('a zero balance renders as a formatted zero', (tester) async {
      await pumpCard(tester, balance: const Money.zero(vnd));
      // Not an empty card, not a placeholder.
      expect(renderedText(tester), contains('0'));
      expect(renderedText(tester), contains('₫'));
    });
  });

  group('masked state', () {
    testWidgets('no digit from any amount survives', (tester) async {
      await pumpCard(tester, masked: true);
      final text = renderedText(tester);
      // The single strongest assertion in this file: an overlay, blur or
      // opacity trick would leave the digits in the tree and fail here.
      expect(
        RegExp(r'\d').hasMatch(text),
        isFalse,
        reason: 'masked card still renders digits: $text',
      );
    });

    testWidgets('labels, currency and layout are unchanged', (tester) async {
      await pumpCard(tester, masked: true);
      final text = renderedText(tester);
      expect(find.text('Total balance'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(text, contains('₫'));
      expect(text, contains('•'));
    });

    testWidgets('the mask width does not depend on the amount', (tester) async {
      // A mask that shrinks with the balance leaks its magnitude, which defeats
      // the purpose of the feature.
      await pumpCard(tester, masked: true, balance: const Money(1, vnd));
      final small = renderedText(tester);
      await pumpCard(
        tester,
        masked: true,
        balance: const Money(999999999, vnd),
      );
      expect(renderedText(tester), small);
    });

    testWidgets('drops the period end, which is not a figure to hide', (
      tester,
    ) async {
      await pumpCard(tester, masked: true);
      expect(renderedText(tester), contains('Safe to spend'));
      expect(renderedText(tester), isNot(contains('Aug')));
    });
  });

  group('mask control', () {
    testWidgets('shows eye when visible and eye-off when masked', (
      tester,
    ) async {
      await pumpCard(tester);
      expect(
        tester
            .widgetList<MonetaIcon>(find.byType(MonetaIcon))
            .map((i) => i.icon),
        contains(MonetaIconName.eye),
      );

      await pumpCard(tester, masked: true);
      expect(
        tester
            .widgetList<MonetaIcon>(find.byType(MonetaIcon))
            .map((i) => i.icon),
        contains(MonetaIconName.eyeOff),
      );
    });

    testWidgets('reports the toggle to its caller', (tester) async {
      var taps = 0;
      await pumpCard(tester, onToggleMask: () => taps++);
      await tester.tap(find.byKey(BalanceCard.maskToggleKey));
      expect(taps, 1);
    });

    testWidgets('does not change its own state when tapped', (tester) async {
      // Masking is the caller's state. A card that toggled itself would
      // disagree with whatever the caller persisted.
      await pumpCard(tester, onToggleMask: () {});
      await tester.tap(find.byKey(BalanceCard.maskToggleKey));
      await tester.pump();
      expect(RegExp(r'\d').hasMatch(renderedText(tester)), isTrue);
    });

    testWidgets('is inert without a callback rather than crashing', (
      tester,
    ) async {
      await pumpCard(tester);
      await tester.tap(find.byKey(BalanceCard.maskToggleKey));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('surface', () {
    testWidgets('paints the one brand gradient and the card shadow', (
      tester,
    ) async {
      await pumpCard(tester);
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(BalanceCard),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.gradient, MonetaColors.brandGradient);
      expect(decoration.boxShadow, isNotEmpty);
      expect(decoration.borderRadius, BorderRadius.circular(24));
    });
  });

  group('currency', () {
    testWidgets('formats and masks in the amount currency, not a default', (
      tester,
    ) async {
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: 353,
          child: BalanceCard(
            totalBalance: Money(123456, Currency.usd),
            safeToSpend: Money(10000, Currency.usd),
            income: Money(200000, Currency.usd),
            expenses: Money(76544, Currency.usd),
            safeToSpendUntil: '31 Aug',
          ),
        ),
        surfaceSize: const Size(420, 700),
      );
      expect(renderedText(tester), contains(r'$1,234.56'));
    });
  });
}
