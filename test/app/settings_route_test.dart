import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/profile_providers.dart';
import 'package:moneta/app/router.dart';
import 'package:moneta/app/settings_route_screens.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/data/preferences/preferences_store.dart';
import 'package:moneta/design_system/atoms/moneta_avatar.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/settings/data/profile_store.dart';
import 'package:moneta/features/settings/domain/profile.dart';
import 'package:moneta/features/settings/presentation/edit_profile_screen.dart';
import 'package:moneta/features/settings/presentation/help_screen.dart';
import 'package:moneta/features/settings/presentation/manage_categories_screen.dart';
import 'package:moneta/features/settings/presentation/premium_screen.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';
import 'package:sqflite/sqflite.dart' show DatabaseExecutor;

import '../support/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository repository;

  setUp(() => repository = FakeTransactionRepository());

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    Profile? profile,
    ProfileStore? store,
  }) async {
    await tester.binding.setSurfaceSize(const Size(393, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWith((ref) => repository),
          // The stored profile, faked. The store's real behaviour — including
          // that it is control-scoped — is tested against a real database in
          // `profile_store_scope_test.dart`; **real I/O inside `testWidgets`
          // never completes** under `FakeAsync` (CLAUDE.md), so this harness
          // fakes the provider and tests the wiring.
          // With a store, the **real** `profileProvider` runs over it — so
          // invalidating it after a save is observable, and deleting that line
          // fails a test. With a literal, the provider is faked and the store
          // is never reached.
          if (store == null)
            profileProvider.overrideWith((ref) async => profile)
          else
            profileStoreProvider.overrideWith((ref) async => store),
        ],
        child: MaterialApp.router(
          theme: MonetaTheme.dark().toThemeData(),
          routerConfig: buildRouter(initialLocation: location),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('08.11 is reachable from both screens that link to it', () {
    testWidgets('from 08.01, the Profile tab', (tester) async {
      await pumpAt(tester, SettingsRoutes.profile);

      await tester.tap(find.text('Help & FAQ'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);
    });

    testWidgets('from 08.03, the settings list', (tester) async {
      await pumpAt(tester, SettingsRoutes.list);

      await tester.tap(find.text('Help & FAQ'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);
    });

    testWidgets('and the back control returns', (tester) async {
      await pumpAt(tester, SettingsRoutes.list);
      await tester.tap(find.text('Help & FAQ'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsNothing);
    });
  });

  group('a row that goes somewhere does not say it is unbuilt', () {
    for (final location in [SettingsRoutes.profile, SettingsRoutes.list]) {
      testWidgets('on $location', (tester) async {
        await pumpAt(tester, location);

        // Every row with a tap target must not also carry "Not built yet".
        // The two are contradictory, and the screen shipped with three rows
        // saying it while `settings-components` was clearing their blockers.
        for (final row in tester.widgetList<ListRow>(find.byType(ListRow))) {
          if (row.onTap != null) {
            expect(
              row.subtitle,
              isNot('Not built yet'),
              reason: '"${row.title}" is tappable and claims to be unbuilt',
            );
          }
        }

        // And the Help row specifically has gained its destination.
        final help = tester
            .widgetList<ListRow>(find.byType(ListRow))
            .where((r) => r.title == 'Help & FAQ');
        expect(help, hasLength(1));
        expect(help.single.onTap, isNotNull);
        expect(help.single.accessory, ListRowAccessory.chevron);
      });
    }
  });

  group('the stored profile is what 08.01 and 08.03 show', () {
    testWidgets('name, email and the avatar initials', (tester) async {
      await pumpAt(
        tester,
        SettingsRoutes.profile,
        profile: const Profile(
          name: 'Trần Văn Minh',
          email: 'minh@example.com',
        ),
      );

      expect(find.text('Trần Văn Minh'), findsOneWidget);
      expect(find.text('minh@example.com'), findsOneWidget);
      // Initials from the stored name, not from a placeholder.
      expect(
        tester.widget<MonetaAvatar>(find.byType(MonetaAvatar)).name,
        'Trần Văn Minh',
      );
      expect(find.text('TM'), findsOneWidget);
    });

    testWidgets('and with nothing stored it asks rather than inventing', (
      tester,
    ) async {
      await pumpAt(tester, SettingsRoutes.profile);

      expect(find.text('Add your name'), findsOneWidget);
      // The placeholders this screen shipped with are gone.
      expect(find.text('Moneta user'), findsNothing);
      expect(find.text('Not signed in'), findsNothing);
    });

    testWidgets('08.03 shows the stored currency, not a hard-coded VND', (
      tester,
    ) async {
      await pumpAt(
        tester,
        SettingsRoutes.list,
        profile: const Profile(name: 'Minh', currency: Currency.usd),
      );

      expect(find.text('USD'), findsOneWidget);
      expect(find.text('VND'), findsNothing);
    });
  });

  group('saving on 08.02 changes what 08.01 shows', () {
    testWidgets('the whole handler runs: save, refresh, leave', (tester) async {
      // The one link in the chain nothing exercised. `change-verifier` found
      // `EditProfileRouteScreen.onSave` at **0 lines covered**, because every
      // test overrode `profileProvider` with a literal and never drove the
      // handler that writes.
      //
      // A *fake* store rather than a real one: real database I/O never
      // completes inside `testWidgets` (CLAUDE.md), and this test is about the
      // handler, not about SQLite — `profile_store_scope_test.dart` drives the
      // real store against a real file.
      final store = _RecordingProfileStore(
        initial: const Profile(name: 'Minh'),
      );
      // Reached the way a user reaches it, so there is somewhere to return to
      // — `pop` on an initial route does nothing, which is how the first
      // version of this test failed.
      await pumpAt(
        tester,
        SettingsRoutes.profile,
        profile: const Profile(name: 'Minh'),
        store: store,
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, 'Bích Ngọc');
      await tester.tap(find.byKey(EditProfileScreen.footerSaveKey));
      await tester.pumpAndSettle();

      expect(store.saved.single.name, 'Bích Ngọc');
      // And the screen left, which only happens on success.
      expect(find.byType(EditProfileScreen), findsNothing);
      // And `08.01` shows the new name — which is the whole scenario, and
      // which only holds because the handler refreshed what reads the profile.
      expect(find.text('Bích Ngọc'), findsOneWidget);
      expect(find.text('Minh'), findsNothing);
    });

    testWidgets('a refused save stays put and shows why', (tester) async {
      final store = _RecordingProfileStore(
        initial: const Profile(name: 'Minh'),
        failure: const AppFailure(FailureKind.storage, 'Disk is full'),
      );
      await pumpAt(
        tester,
        SettingsRoutes.profile,
        profile: const Profile(name: 'Minh'),
        store: store,
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(EditProfileScreen.footerSaveKey));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.text('Disk is full'), findsOneWidget);
    });
  });

  group('08.08 counts the real ledger', () {
    testWidgets('the counts on screen are the transactions inserted', (
      tester,
    ) async {
      // Three in one category this month, and one **outside the month** that
      // must not be counted.
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 2, 12);
      final lastMonth = DateTime(now.year, now.month - 1, 15, 12);

      Transaction make(String id, DateTime at, int minor) => Transaction.create(
        id: id,
        amount: Money(minor, Currency.vnd),
        category: SpendCategory.food,
        direction: TransactionDirection.expense,
        occurredAt: at,
        createdAt: at,
      ).valueOrNull!;

      for (var i = 0; i < 3; i++) {
        await repository.add(make('food-$i', thisMonth, 10000));
      }
      await repository.add(make('old', lastMonth, 999999));

      await pumpAt(tester, SettingsRoutes.categories);

      expect(find.byType(ManageCategoriesScreen), findsOneWidget);
      expect(
        find.text('3 transactions'),
        findsOneWidget,
        reason: 'the fourth is last month and must not be counted',
      );
      expect(
        find.text(const Money(30000, Currency.vnd).format()),
        findsWidgets,
      );
    });

    testWidgets('reachable from 08.03', (tester) async {
      await pumpAt(tester, SettingsRoutes.list);

      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      expect(find.byType(ManageCategoriesScreen), findsOneWidget);
    });
  });

  group('08.10 is reachable and leaveable', () {
    testWidgets("from 08.01's Premium row", (tester) async {
      await pumpAt(tester, SettingsRoutes.profile);

      await tester.tap(find.text('Premium'));
      await tester.pumpAndSettle();
      expect(find.byType(PremiumScreen), findsOneWidget);
    });

    testWidgets('and the close action leaves it', (tester) async {
      await pumpAt(tester, SettingsRoutes.profile);
      await tester.tap(find.text('Premium'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(PremiumScreen), findsNothing);
    });
  });

  group('08.02 is reachable from both screens', () {
    testWidgets("from 08.01's Edit button", (tester) async {
      await pumpAt(
        tester,
        SettingsRoutes.profile,
        profile: const Profile(name: 'Minh'),
      );

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
      // And it opens on the stored values.
      expect(find.text('Minh'), findsWidgets);
    });

    testWidgets("from 08.03's Edit profile row", (tester) async {
      await pumpAt(tester, SettingsRoutes.list);

      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });
  });
}

/// A [ProfileStore] that records what it was asked to save.
///
/// Returns an already-completed future, which is what lets the route handler
/// run to completion inside `testWidgets` — a real store's I/O would not.
class _RecordingProfileStore extends ProfileStore {
  _RecordingProfileStore({Profile? initial, this.failure})
    : _current = initial,
      super(const PreferencesStore(_NeverUsedDatabase()));

  Profile? _current;

  /// What `save` reports, or null for success.
  final AppFailure? failure;

  /// Every profile `save` was called with, in order.
  final List<Profile> saved = [];

  @override
  Future<Result<Profile?>> read() async => Ok(_current);

  @override
  Future<Result<void>> save(Profile profile) async {
    saved.add(profile);
    // A **refused** save must not change what a later read returns, or the
    // "stays put" test would pass for a store that wrote anyway.
    if (failure != null) return Err(failure!);
    _current = profile;
    return const Ok(null);
  }
}

/// Stands in for the database the fake store never touches.
///
/// `ProfileStore` needs a `PreferencesStore` and a `PreferencesStore` needs an
/// executor; this one throws if anything reaches it, so a fake that
/// accidentally hit storage would fail loudly rather than quietly.
class _NeverUsedDatabase implements DatabaseExecutor {
  const _NeverUsedDatabase();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'the recording store answers without a database',
  );
}
