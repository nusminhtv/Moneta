import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/data/database/app_database.dart';
import 'package:moneta/data/preferences/preference_key.dart';
import 'package:moneta/data/preferences/preferences_store.dart';
import 'package:moneta/features/onboarding/presentation/onboarding_providers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late PreferencesStore store;

  Future<ProviderContainer> container({bool storeFails = false}) async {
    database = AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    store = PreferencesStore((await database.open()).valueOrNull!);
    if (storeFails) await database.close();

    final c = ProviderContainer(
      overrides: [preferencesStoreProvider.overrideWith((ref) => store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('shouldShowOnboarding', () {
    test('true on first run — nothing has been recorded', () async {
      final c = await container();
      expect(await c.read(shouldShowOnboardingProvider.future), isTrue);
      await database.close();
    });

    test('false once completion is recorded', () async {
      final c = await container();
      await store.writeBool(PreferenceKey.onboardingComplete, value: true);
      expect(await c.read(shouldShowOnboardingProvider.future), isFalse);
      await database.close();
    });

    test('true when the flag was explicitly written false', () async {
      final c = await container();
      await store.writeBool(PreferenceKey.onboardingComplete, value: false);
      expect(await c.read(shouldShowOnboardingProvider.future), isTrue);
      await database.close();
    });

    test('true when the stored value is corrupt', () async {
      // Showing it twice is a minor annoyance; hiding the app behind a broken
      // read is not, and the user cannot recover from the second.
      final c = await container();
      final db = (await database.open()).valueOrNull!;
      await db.insert(PreferencesStore.table, {
        'key': PreferenceKey.onboardingComplete.storedName,
        'value': 'perhaps',
      });
      expect(await c.read(shouldShowOnboardingProvider.future), isTrue);
      await database.close();
    });

    test('true when the read fails outright', () async {
      final c = await container(storeFails: true);
      expect(await c.read(shouldShowOnboardingProvider.future), isTrue);
    });

    test('true when the store cannot be built at all', () async {
      final c = ProviderContainer(
        overrides: [
          preferencesStoreProvider.overrideWith(
            (ref) => throw StateError('no database'),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(await c.read(shouldShowOnboardingProvider.future), isTrue);
    });
  });

  group('completeOnboarding', () {
    test('records completion and flips the decision', () async {
      final c = await container();
      expect(await c.read(shouldShowOnboardingProvider.future), isTrue);

      await c.read(completeOnboardingProvider)();

      expect(
        (await store.readBool(PreferenceKey.onboardingComplete)).valueOrNull,
        isTrue,
      );
      expect(await c.read(shouldShowOnboardingProvider.future), isFalse);
      await database.close();
    });

    test('is idempotent', () async {
      final c = await container();
      await c.read(completeOnboardingProvider)();
      await c.read(completeOnboardingProvider)();

      final db = (await database.open()).valueOrNull!;
      expect(await db.query(PreferencesStore.table), hasLength(1));
      await database.close();
    });

    test('a store that cannot be built does not trap the caller', () async {
      // Distinct from the case below: there the store exists and its database is
      // closed, so writeBool returns Err. Here the store cannot be built at all
      // and preferencesStoreProvider throws. That escaped an async navigation
      // callback and left the user on the last slide with nothing happening.
      final c = ProviderContainer(
        overrides: [
          preferencesStoreProvider.overrideWith(
            (ref) => throw StateError('cannot open'),
          ),
        ],
      );
      addTearDown(c.dispose);

      await expectLater(c.read(completeOnboardingProvider)(), completes);
      // And the fallback still applies: unrecorded means show it again.
      expect(await c.read(shouldShowOnboardingProvider.future), isTrue);
    });

    test('a failed write does not crash the caller', () async {
      final c = await container(storeFails: true);
      await expectLater(c.read(completeOnboardingProvider)(), completes);
    });
  });
}
