import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/data/database/app_database.dart';
import 'package:moneta/data/preferences/preference_key.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  // Assigning the global factory rather than overriding the provider, so the
  // PRODUCTION provider bodies actually run. Overriding them would leave the
  // shipped code unexecuted — which is how appDatabaseProvider reached this
  // point with zero coverage while every widget test passed.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('shared providers', () {
    test('hand back the production implementations', () {
      final container = makeContainer();
      expect(container.read(clockProvider), isA<SystemClock>());
      expect(container.read(idGeneratorProvider), isA<SystemIdGenerator>());
      expect(container.read(walletCurrencyProvider), Currency.vnd);
    });

    test('the clock returns UTC', () {
      expect(makeContainer().read(clockProvider).nowUtc().isUtc, isTrue);
    });

    test('ids from the shared generator are unique', () {
      final generator = makeContainer().read(idGeneratorProvider);
      expect({for (var i = 0; i < 500; i++) generator.next()}, hasLength(500));
    });
  });

  group('appDatabaseProvider', () {
    test('names the file the app ships with', () {
      expect(makeContainer().read(appDatabaseProvider).path, 'moneta.db');
    });

    test('is one instance per container', () {
      final container = makeContainer();
      expect(
        container.read(appDatabaseProvider),
        same(container.read(appDatabaseProvider)),
      );
    });

    test('opens, and disposing the container closes it', () async {
      final container = ProviderContainer();
      final database = container.read(appDatabaseProvider);

      expect((await database.open()).isOk, isTrue);
      expect(database.openCount, 1);

      container.dispose();
      await pumpEventQueue();

      // The connection was closed, so opening again is a second open rather
      // than the memoised first one. That is the observable consequence of
      // ref.onDispose having run — the behaviour the provider exists for.
      expect((await database.open()).isOk, isTrue);
      expect(database.openCount, 2);
      await database.close();
    });
  });

  group('preferencesStoreProvider', () {
    test('builds a store over the open database', () async {
      final container = makeContainer();
      final store = await container.read(preferencesStoreProvider.future);

      expect(
        (await store.writeBool(
          PreferenceKey.onboardingComplete,
          value: true,
        )).isOk,
        isTrue,
      );
      expect(
        (await store.readBool(PreferenceKey.onboardingComplete)).valueOrNull,
        isTrue,
      );
    });

    test('throws when the database cannot be opened', () async {
      // The error branch: a FutureProvider's error state is what the UI already
      // knows how to render, and a store that cannot be built is not something
      // a caller can work around.
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith(
            (ref) => AppDatabase(
              // A directory is not a database file.
              path: '.',
              factory: databaseFactoryFfi,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(preferencesStoreProvider.future),
        throwsStateError,
      );
    });
  });
}
