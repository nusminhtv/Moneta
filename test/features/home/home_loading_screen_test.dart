import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/molecules/skeleton.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/features/home/domain/home_snapshot.dart';
import 'package:moneta/features/home/presentation/home_loading_screen.dart';
import 'package:moneta/features/home/presentation/home_screen.dart';

import '../../support/pump.dart';

/// Home's loading state, against node `52:547` and annotation `52:630`.
///
/// The shipped version rendered no app bar and three skeleton shapes where the
/// frame authors four. Both defects were invisible to the suite because nothing
/// compared the loading state to the loaded one.
void main() {
  const vnd = Currency.vnd;
  const size = Size(393, 852);

  int countShape(WidgetTester tester, SkeletonShape shape) => tester
      .widgetList<Skeleton>(find.byType(Skeleton))
      .where((s) => s.shape == shape)
      .length;

  Future<void> pumpLoading(WidgetTester tester) => pumpMonetaWidget(
    tester,
    const SizedBox(
      width: 393,
      height: 852,
      child: HomeLoadingScreen(greeting: 'Hi there'),
    ),
    surfaceSize: size,
  );

  Future<void> pumpLoaded(WidgetTester tester) => pumpMonetaWidget(
    tester,
    SizedBox(
      width: 393,
      height: 852,
      child: HomeScreen(
        snapshot: const HomeSnapshot(
          totalBalance: Money(31877000, vnd),
          income: Money(32000000, vnd),
          expenses: Money(123000, vnd),
          recent: [],
          safeToSpend: Money(31877000, vnd),
        ),
        greeting: 'Hi there',
        now: DateTime.utc(2026, 8, 20, 3),
      ),
    ),
    surfaceSize: size,
  );

  group('the app bar does not move when data lands', () {
    testWidgets('the loading state has an app bar at all', (tester) async {
      // It did not. The bar appeared with the data and shoved the page down.
      await pumpLoading(tester);
      expect(find.byType(MonetaAppBar), findsOneWidget);
    });

    testWidgets('the bar is the same height loading and loaded', (
      tester,
    ) async {
      await pumpLoading(tester);
      final loading = tester.getSize(find.byType(MonetaAppBar));

      await pumpLoaded(tester);
      final loaded = tester.getSize(find.byType(MonetaAppBar));

      expect(loading, loaded);
    });

    testWidgets('the bar sits at the same offset loading and loaded', (
      tester,
    ) async {
      await pumpLoading(tester);
      final loading = tester.getTopLeft(find.byType(MonetaAppBar));

      await pumpLoaded(tester);
      final loaded = tester.getTopLeft(find.byType(MonetaAppBar));

      expect(loading, loaded);
    });

    testWidgets('the greeting is identical in both states', (tester) async {
      // A title that changed on arrival would be its own flicker.
      await pumpLoading(tester);
      expect(find.text('Hi there'), findsOneWidget);
      await pumpLoaded(tester);
      expect(find.text('Hi there'), findsOneWidget);
    });

    testWidgets('the content below the bar starts at the same offset', (
      tester,
    ) async {
      // The point of the whole screen: the first content row does not shift.
      await pumpLoading(tester);
      final loading = tester.getTopLeft(find.byType(ListView));

      await pumpLoaded(tester);
      final loaded = tester.getTopLeft(find.byType(ListView));

      expect(loading, loaded);
    });
  });

  group('the authored skeleton composition', () {
    // Annotation `52:630`: Card x3, Circle x4, Line x6, Row x4.
    testWidgets('three cards, for the balance and the two budgets', (
      tester,
    ) async {
      await pumpLoading(tester);
      expect(countShape(tester, SkeletonShape.card), 3);
    });

    testWidgets('four rows, one per recent transaction', (tester) async {
      await pumpLoading(tester);
      expect(countShape(tester, SkeletonShape.row), 4);
    });

    testWidgets('six lines: four quick-action labels and two headings', (
      tester,
    ) async {
      await pumpLoading(tester);
      expect(countShape(tester, SkeletonShape.line), 6);
    });

    testWidgets('four discs of its own, plus one inside each row', (
      tester,
    ) async {
      // `Skeleton/Row` composes a circle internally, so the tree carries eight:
      // the four quick-action discs and the four row avatars. Asserting four
      // here would silently pass if the quick-action row vanished.
      await pumpLoading(tester);
      expect(countShape(tester, SkeletonShape.circle), 8);
    });

    testWidgets('no spinner is used anywhere', (tester) async {
      // Annotation `52:630`: "a spinner is not a loading state in this system".
      // Asserting that skeletons exist does not test that, because a spinner
      // added beside them passes. This looks for the spinner.
      await pumpLoading(tester);
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(
        find.byWidgetPredicate((w) => w is ProgressIndicator),
        findsNothing,
      );
    });

    testWidgets('nothing overflows at the design size', (tester) async {
      await pumpLoading(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
