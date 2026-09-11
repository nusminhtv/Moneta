import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/home_providers.dart';
import 'package:moneta/app/home_route_screen.dart';
import 'package:moneta/app/profile_providers.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/home/domain/home_snapshot.dart';
import 'package:moneta/features/settings/domain/profile.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

import '../support/fake_transaction_repository.dart';

void main() {
  final empty = HomeSnapshot.empty(Currency.vnd);

  Future<void> pumpHome(
    WidgetTester tester, {
    Profile? profile,
    AsyncValue<HomeSnapshot>? snapshot,
  }) async {
    final resolved = snapshot ?? AsyncValue.data(empty);
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Tear the tree down first. Pumping a structurally identical tree reuses
    // the element tree and the existing `ProviderScope`, so a second call with
    // different overrides can leave the **old** value in place — which is why
    // the three-state test below passed for a mutation that gave the error arm
    // a different greeting. An empty pump between them makes each case a fresh
    // scope.
    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWith(
            (ref) => FakeTransactionRepository(),
          ),
          profileProvider.overrideWith((ref) async => profile),
          homeSnapshotProvider.overrideWith((ref) => resolved),
        ],
        child: MaterialApp(
          theme: MonetaTheme.dark().toThemeData(),
          home: const Scaffold(body: HomeRouteScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the greeting is the stored first name', () {
    test('greetingFor builds the string', () {
      // The rule, apart from the widget: `Hi ` + the first name, or the
      // anonymous greeting when there is no name to use.
      expect(greetingFor(const Profile(name: 'Minh Tran')), 'Hi Minh');
      expect(greetingFor(const Profile(name: 'Trần Văn Minh')), 'Hi Trần');
      expect(greetingFor(null), 'Hi there');
    });

    test('a name with no letters greets a stranger, not an empty space', () {
      // `Hi ` with nothing after it is worse than `Hi there`. The fallback is
      // on the **first name being empty**, not on the profile being absent, so
      // both routes reach the same string.
      for (final nameless in ['👨‍👩‍👧', '123', '   ']) {
        expect(
          greetingFor(Profile(name: nameless)),
          'Hi there',
          reason: '"$nameless"',
        );
      }
    });

    testWidgets('Home shows it', (tester) async {
      await pumpHome(tester, profile: const Profile(name: 'Minh Tran'));

      expect(find.text('Hi Minh'), findsOneWidget);
      expect(find.text('Hi there'), findsNothing);
    });

    testWidgets('and greets a stranger on first run', (tester) async {
      await pumpHome(tester);

      expect(find.text('Hi there'), findsOneWidget);
    });
  });

  testWidgets('every Home state shows the identical greeting', (tester) async {
    // Asserted **across** the states rather than in one of them. The constant
    // this replaced existed for exactly this: annotation `52:630` requires the
    // bar to be identical while loading and once loaded, and three separate
    // reads would be free to drift apart.
    const profile = Profile(name: 'Minh Tran');
    final seen = <String>{};

    for (final snapshot in <AsyncValue<HomeSnapshot>>[
      const AsyncValue.loading(),
      AsyncValue.data(empty),
      AsyncValue.error(StateError('boom'), StackTrace.empty),
    ]) {
      await pumpHome(tester, profile: profile, snapshot: snapshot);

      final title = tester
          .widgetList<Text>(find.textContaining('Hi '))
          .map((t) => t.data!)
          .toSet();
      expect(title, hasLength(1), reason: 'one greeting per state');
      seen.addAll(title);
    }

    expect(
      seen,
      {'Hi Minh'},
      reason: 'the three states disagree about what to call the user',
    );
  });
}
