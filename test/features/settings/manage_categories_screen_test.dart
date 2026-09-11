import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/atoms/moneta_chip.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/settings/domain/category_usage.dart';
import 'package:moneta/features/settings/presentation/manage_categories_screen.dart';

import '../../support/pump.dart';

void main() {
  const vnd = Currency.vnd;

  List<CategoryUsage> usageFor(Map<SpendCategory, (int, int)> counts) => [
    for (final category in SpendCategory.values)
      CategoryUsage(
        category: category,
        count: counts[category]?.$1 ?? 0,
        total: Money(counts[category]?.$2 ?? 0, vnd),
      ),
  ];

  Future<void> pumpCategories(
    WidgetTester tester, {
    List<CategoryUsage>? usage,
    TransactionDirection direction = TransactionDirection.expense,
    ValueChanged<TransactionDirection>? onDirectionChanged,
  }) => pumpMonetaWidget(
    tester,
    ManageCategoriesScreen(
      usage: usage ?? usageFor({SpendCategory.food: (3, 60000)}),
      direction: direction,
      onDirectionChanged: onDirectionChanged ?? (_) {},
    ),
    surfaceSize: const Size(393, 1400),
  );

  group('the filter', () {
    testWidgets('exactly one chip is selected, never both', (tester) async {
      for (final selected in TransactionDirection.values) {
        await pumpCategories(tester, direction: selected);

        for (final option in TransactionDirection.values) {
          expect(
            tester
                .widget<MonetaChip>(
                  find.byKey(ManageCategoriesScreen.chipKey(option)),
                )
                .selected,
            option == selected,
            reason: '${option.name} with ${selected.name} chosen',
          );
        }
      }
    });

    testWidgets('tapping one reports it', (tester) async {
      final picked = <TransactionDirection>[];
      await pumpCategories(tester, onDirectionChanged: picked.add);

      await tester.tap(
        find.byKey(
          ManageCategoriesScreen.chipKey(TransactionDirection.income),
        ),
      );
      expect(picked, [TransactionDirection.income]);
    });

    testWidgets('the filter row is 44 tall, not the 34 the file draws', (
      tester,
    ) async {
      await pumpCategories(tester);

      // The literal, not `MonetaLayout.minTouchTarget`: an expectation taken
      // from the implementation's own constant cannot fail. `101:1001` draws
      // 34; `Chip` took ownership of its touch target in
      // `settings-components`, so this row is 10px taller than the file.
      expect(
        tester.getSize(find.byKey(ManageCategoriesScreen.filterRowKey)).height,
        44,
      );
      expect(MonetaLayout.minTouchTarget, 44);
    });
  });

  group('the rows are information, not controls', () {
    testWidgets('the only things that respond are the two chips', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpCategories(tester);

      // Every interactive node on the screen, by label — not "no row node is a
      // button", which is what the first two versions of this asserted and
      // which a `GestureDetector` on the row's *icon* walked straight past.
      // A tap anywhere in a row is a tap the screen cannot honour.
      //
      // The semantics tree is the instrument because a source scan for
      // `onTap` cannot see a `GestureDetector`, an `InkWell`, or a callback
      // passed through a variable.
      final interactive = <String>[];
      void walk(SemanticsNode node) {
        final data = node.getSemanticsData().toString();
        if (data.contains('isButton') || data.contains('tap')) {
          interactive.add('${node.label}|$data');
        }
        node.visitChildren((child) {
          walk(child);
          return true;
        });
      }

      walk(tester.getSemantics(find.byType(ManageCategoriesScreen)));

      expect(
        interactive.map((entry) => entry.split('|').first).toSet(),
        // All three named, so a fourth interactive thing anywhere fails —
        // including the app bar's back control, which is a control and is
        // listed rather than filtered out.
        {'Back', 'Expenses', 'Income'},
        reason:
            'the two chips and the back control are everything this screen '
            'can act on; every row is information',
      );
      expect(interactive, hasLength(3));

      handle.dispose();
    });

    testWidgets('one row per category, unused ones included', (tester) async {
      await pumpCategories(tester);

      for (final category in SpendCategory.values) {
        expect(
          find.text(category.label),
          findsOneWidget,
          reason: '${category.name} is missing',
        );
      }
    });

    testWidgets('an unused category says so rather than showing nothing', (
      tester,
    ) async {
      await pumpCategories(tester);

      expect(find.text('Not used this month'), findsWidgets);
      expect(find.text('3 transactions'), findsOneWidget);
    });

    testWidgets('one transaction is singular', (tester) async {
      await pumpCategories(
        tester,
        usage: usageFor({SpendCategory.food: (1, 20000)}),
      );
      expect(find.text('1 transaction'), findsOneWidget);
      expect(find.text('1 transactions'), findsNothing);
    });

    testWidgets('the totals are shown as money', (tester) async {
      await pumpCategories(
        tester,
        usage: usageFor({SpendCategory.food: (3, 60000)}),
      );
      expect(find.text(const Money(60000, vnd).format()), findsOneWidget);
    });
  });

  testWidgets('nothing overflows with every category listed', (tester) async {
    await pumpCategories(
      tester,
      usage: usageFor({
        for (final category in SpendCategory.values) category: (99, 999999999),
      }),
    );
    expect(tester.takeException(), isNull);
  });
}
