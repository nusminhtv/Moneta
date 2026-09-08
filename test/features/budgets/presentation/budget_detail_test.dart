import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/budget_detail_route_screen.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/core/transaction_direction.dart';
import 'package:moneta/design_system/atoms/moneta_circular_progress.dart';
import 'package:moneta/design_system/molecules/stat_tile.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/organisms/banner.dart';
import 'package:moneta/features/budgets/domain/budget.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/domain/budget_progress.dart';
import 'package:moneta/features/budgets/domain/spend_entry.dart';
import 'package:moneta/features/budgets/presentation/budget_detail_screen.dart';

import '../../../support/pump.dart';

void main() {
  const vnd = Currency.vnd;
  const usd = Currency.usd;

  SpendEntry entry(
    String id,
    int minor, {
    int day = 10,
    TransactionDirection direction = TransactionDirection.expense,
    SpendCategory category = SpendCategory.food,
    Currency currency = vnd,
  }) => SpendEntry(
    id: id,
    category: category,
    direction: direction,
    amount: Money(minor, currency),
    occurredAt: DateTime.utc(2026, 9, day, 3),
  );

  BudgetProgress progressWith(
    List<SpendEntry> entries, {
    int limit = 1000000,
    DateTime? now,
  }) => BudgetProgress.compute(
    budget: Budget.create(
      id: 'b1',
      category: SpendCategory.food,
      limit: Money(limit, vnd),
      period: BudgetPeriod.monthly,
      startsOn: DateTime.utc(2026, 9),
      createdAt: DateTime.utc(2026, 8, 30),
    ).valueOrNull!,
    entries: entries,
    now: now ?? DateTime.utc(2026, 9, 21),
  );

  Future<void> pumpDetail(
    WidgetTester tester,
    BudgetProgress progress,
    List<SpendEntry> all,
  ) => pumpMonetaWidget(
    tester,
    SizedBox(
      width: 393,
      height: 852,
      child: BudgetDetailScreen(
        progress: progress,
        contributing: BudgetDetailRouteScreen.contributingTo(progress, all),
      ),
    ),
    surfaceSize: const Size(393, 852),
  );

  group('when the budget was passed', () {
    test('is the transaction that tipped it, not the last one', () {
      final p = progressWith([
        entry('a', 400000, day: 3),
        entry('b', 400000, day: 7),
        entry('c', 400000, day: 11),
      ]);
      expect(p.passedLimitOn, DateTime.utc(2026, 9, 11, 3));
    });

    test('does not depend on the order they arrive in', () {
      final ordered = progressWith([
        entry('a', 400000, day: 3),
        entry('b', 400000, day: 7),
        entry('c', 400000, day: 11),
      ]);
      final shuffled = progressWith([
        entry('c', 400000, day: 11),
        entry('a', 400000, day: 3),
        entry('b', 400000, day: 7),
      ]);
      expect(shuffled.passedLimitOn, ordered.passedLimitOn);
    });

    test('a single transaction that alone exceeds the limit', () {
      final p = progressWith([entry('a', 2000000, day: 4)]);
      expect(p.passedLimitOn, DateTime.utc(2026, 9, 4, 3));
    });

    test('under the limit reports nothing and is not negative', () {
      final p = progressWith([entry('a', 400000)]);
      expect(p.passedLimitOn, isNull);
      expect(p.overBy, const Money(0, vnd));
    });

    test('exactly at the limit is not over', () {
      // Consistent with BudgetStatus treating 1.0 as reached, not exceeded.
      final p = progressWith([entry('a', 1000000)]);
      expect(p.passedLimitOn, isNull);
      expect(p.overBy, const Money(0, vnd));
    });
  });

  group('the over-limit banner', () {
    testWidgets('names the date, because "you are over" is not actionable', (
      tester,
    ) async {
      final p = progressWith([
        entry('a', 400000, day: 3),
        entry('b', 900000, day: 11),
      ]);
      await pumpDetail(tester, p, const []);

      expect(find.byType(MonetaBanner), findsOneWidget);
      final banner = tester.widget<MonetaBanner>(find.byType(MonetaBanner));
      expect(banner.tone, BannerTone.danger);
      expect(banner.message, contains('11 Sep'));
      expect(banner.message, contains(const Money(300000, vnd).format()));
    });

    testWidgets('is absent when the budget is on track', (tester) async {
      await pumpDetail(tester, progressWith([entry('a', 400000)]), const []);
      expect(find.byType(MonetaBanner), findsNothing);
    });
  });

  group('the daily-allowance tile is swapped, not made negative', () {
    testWidgets('on track it shows the allowance', (tester) async {
      final p = progressWith([entry('a', 400000)]);
      await pumpDetail(tester, p, const []);

      final tiles = tester.widgetList<StatTile>(find.byType(StatTile)).toList();
      expect(tiles.map((t) => t.label), contains('Daily allowance'));
      expect(tiles.map((t) => t.label), isNot(contains('Over by')));
    });

    testWidgets('over the limit it is replaced by Over by', (tester) async {
      // 04.06: "there is no daily-allowance tile here — it would be negative
      // and meaningless." A tile reading a negative allowance fails this.
      final p = progressWith([entry('a', 1400000)]);
      await pumpDetail(tester, p, const []);

      final tiles = tester.widgetList<StatTile>(find.byType(StatTile)).toList();
      expect(tiles.map((t) => t.label), contains('Over by'));
      expect(tiles.map((t) => t.label), isNot(contains('Daily allowance')));
      expect(
        tiles.firstWhere((t) => t.label == 'Over by').value,
        const Money(400000, vnd),
      );
      for (final tile in tiles) {
        expect(
          tile.value.minorUnits,
          greaterThanOrEqualTo(0),
          reason: '${tile.label} is showing a negative amount',
        );
      }
    });
  });

  group('the ring', () {
    testWidgets('carries the budget own threshold and the true fraction', (
      tester,
    ) async {
      final p = progressWith([entry('a', 1400000)]);
      await pumpDetail(tester, p, const []);
      final ring = tester.widget<MonetaCircularProgress>(
        find.byType(MonetaCircularProgress),
      );
      expect(ring.size, MonetaCircularProgressSize.lg);
      expect(ring.fraction, closeTo(1.4, 1e-9));
      expect(ring.nearLimitThreshold, p.budget.alertThreshold);
    });
  });

  group('the listed transactions are exactly the counted ones', () {
    testWidgets('income, another category and a foreign currency are absent', (
      tester,
    ) async {
      final all = [
        entry('counted', 300000),
        entry('income', 100000, direction: TransactionDirection.income),
        entry('other', 100000, category: SpendCategory.bills),
        entry('foreign', 100, currency: usd),
        entry('before', 100000, day: 1),
      ];
      final p = progressWith(all);
      await pumpDetail(tester, p, all);

      final rows = tester
          .widgetList<TransactionRow>(find.byType(TransactionRow))
          .toList();
      expect(rows, hasLength(2));
      expect(
        rows.map((r) => r.amount.minorUnits).toSet(),
        {300000, 100000},
        reason: 'the two in-window food expenses in VND',
      );
    });

    test('the filter is the domain, not a second copy on the screen', () {
      final p = progressWith([entry('a', 300000)]);
      expect(p.counts(entry('a', 300000)), isTrue);
      expect(
        p.counts(entry('b', 100, currency: usd)),
        isFalse,
      );
      expect(
        p.counts(entry('c', 100, direction: TransactionDirection.income)),
        isFalse,
      );
      expect(
        p.counts(entry('d', 100, category: SpendCategory.bills)),
        isFalse,
      );
      expect(p.counts(entry('e', 100, day: 1)), isTrue);
    });
  });

  group('skipped foreign currency is disclosed', () {
    testWidgets('the screen says how many were not counted', (tester) async {
      final all = [entry('a', 300000), entry('b', 100, currency: usd)];
      final p = progressWith(all);
      await pumpDetail(tester, p, all);
      expect(
        find.textContaining('1 transaction in another currency'),
        findsOneWidget,
      );
    });

    test('nothing skipped means no note at all', () {
      expect(
        BudgetDetailScreen.skippedNote(progressWith([entry('a', 300000)])),
        isNull,
      );
    });

    test('the note is plural when it should be', () {
      final p = progressWith([
        entry('a', 100, currency: usd),
        entry('b', 100, currency: usd),
      ]);
      expect(BudgetDetailScreen.skippedNote(p), contains('2 transactions'));
    });
  });

  group('layout', () {
    testWidgets('nothing overflows at the design size', (tester) async {
      final all = [for (var i = 1; i <= 8; i++) entry('e$i', 300000, day: i)];
      await pumpDetail(tester, progressWith(all), all);
      expect(tester.takeException(), isNull);
    });
  });
}
