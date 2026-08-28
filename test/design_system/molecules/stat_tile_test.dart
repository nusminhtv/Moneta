import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/stat_tile.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();
  const vnd = Currency.vnd;

  Future<void> pumpTile(
    WidgetTester tester, {
    StatDelta delta = StatDelta.up,
    Money value = const Money(12480000, vnd),
    String label = 'Spent this month',
    String deltaLabel = '+12.4% vs last month',
    double width = 170,
  }) => pumpMonetaWidget(
    tester,
    SizedBox(
      width: width,
      child: StatTile(
        label: label,
        value: value,
        delta: delta,
        deltaLabel: deltaLabel,
      ),
    ),
    surfaceSize: const Size(393, 300),
  );

  group('the delta is never colour alone', () {
    testWidgets('up and down each carry an arrow as well as a colour', (
      tester,
    ) async {
      await pumpTile(tester, delta: StatDelta.up);
      var icon = tester.widget<MonetaIcon>(find.byType(MonetaIcon));
      expect(icon.icon, MonetaIconName.arrowUpRight);
      expect(icon.color, colors.income);

      await pumpTile(tester, delta: StatDelta.down);
      icon = tester.widget<MonetaIcon>(find.byType(MonetaIcon));
      expect(icon.icon, MonetaIconName.arrowDownLeft);
      expect(icon.color, colors.expense);
    });

    testWidgets('flat is a third state, not a missing one', (tester) async {
      // No arrow AND tertiary text. Rendering it in the income colour with no
      // arrow would make flat and up differ by colour alone.
      await pumpTile(tester, delta: StatDelta.flat);
      expect(find.byType(MonetaIcon), findsNothing);
      expect(
        tester.widget<Text>(find.text('+12.4% vs last month')).style!.color,
        colors.textTertiary,
      );
    });

    testWidgets('the three directions are three different colours', (
      tester,
    ) async {
      final seen = <Color>{};
      for (final d in StatDelta.values) {
        await pumpTile(tester, delta: d);
        seen.add(
          tester.widget<Text>(find.text('+12.4% vs last month')).style!.color!,
        );
      }
      expect(seen, hasLength(3));
    });

    test('every direction with an arrow has a distinct one', () {
      final arrows = StatDelta.values
          .map((d) => d.arrow)
          .whereType<MonetaIconName>()
          .toSet();
      expect(arrows, hasLength(2));
      expect(StatDelta.flat.arrow, isNull);
    });
  });

  group('the tile takes a domain type', () {
    testWidgets('it formats the Money itself', (tester) async {
      await pumpTile(tester, value: const Money(12480000, vnd));
      expect(find.text(const Money(12480000, vnd).format()), findsOneWidget);
    });

    testWidgets('a different currency changes the rendered figure', (
      tester,
    ) async {
      await pumpTile(tester, value: const Money(12480000, Currency.usd));
      expect(
        find.text(const Money(12480000, Currency.usd).format()),
        findsOneWidget,
      );
    });
  });

  group('layout', () {
    testWidgets('two tiles fit the 353 content column with a 12 gap', (
      tester,
    ) async {
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: 353,
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Spent',
                  value: Money(12480000, vnd),
                  delta: StatDelta.up,
                  deltaLabel: '+12.4%',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'Left',
                  value: Money(3520000, vnd),
                  delta: StatDelta.down,
                  deltaLabel: '-4.1%',
                ),
              ),
            ],
          ),
        ),
        surfaceSize: const Size(393, 300),
      );
      expect(tester.takeException(), isNull);
      final tiles = find.byType(StatTile);
      expect(
        tester.getSize(tiles.first).width,
        tester.getSize(tiles.last).width,
      );
    });

    testWidgets('a very long value and label do not overflow', (tester) async {
      await pumpTile(
        tester,
        value: const Money(999999999999999, vnd),
        label: 'An extremely long label that will not fit on one line at all',
        deltaLabel: 'An extremely long delta description that cannot fit',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the amount stays inside the tile', (tester) async {
      // Font-independent: it asserts containment, not a measured string width.
      await pumpTile(tester, value: const Money(999999999999999, vnd));
      final tile = tester.getRect(find.byType(StatTile));
      final amount = tester.getRect(
        find.text(const Money(999999999999999, vnd).format()),
      );
      expect(amount.left, greaterThanOrEqualTo(tile.left));
      expect(amount.right, lessThanOrEqualTo(tile.right));
    });
  });
}
