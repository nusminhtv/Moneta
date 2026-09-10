import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/data/database/app_database.dart';
import 'package:moneta/data/preferences/preference_key.dart';
import 'package:moneta/data/preferences/preferences_store.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  // Assigning the global factory rather than overriding the provider, so the
  // PRODUCTION provider bodies actually run. Overriding them would leave the
  // shipped code unexecuted — which is how the database provider reached this
  // point with zero coverage while every widget test passed.
  //
  // The two path providers ARE overridden, at a temporary directory. They exist
  // to be overridden: the swap has to be observed against two real files, and
  // the bodies under test are the ones that build and close connections, not
  // the two that return a filename.
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

  late Directory temporaryDirectory;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync('moneta_dbs');
    addTearDown(() => temporaryDirectory.deleteSync(recursive: true));
  });

  String pathIn(String name) => p.join(temporaryDirectory.path, name);

  ProviderContainer makeDatabaseContainer() {
    final container = ProviderContainer(
      overrides: [
        realDatabasePathProvider.overrideWithValue(pathIn('moneta.db')),
        demoDatabasePathProvider.overrideWithValue(pathIn('moneta_demo.db')),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('the database providers ship the right files', () {
    test('name the files the app ships with', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(realDatabasePathProvider), 'moneta.db');
      expect(container.read(demoDatabasePathProvider), 'moneta_demo.db');
      expect(container.read(controlDatabaseProvider).path, 'moneta.db');
    });

    test('the control database is one instance per container', () {
      final container = makeDatabaseContainer();
      expect(
        container.read(controlDatabaseProvider),
        same(container.read(controlDatabaseProvider)),
      );
    });

    test('opens, and disposing the container closes it', () async {
      final container = ProviderContainer(
        overrides: [
          realDatabasePathProvider.overrideWithValue(pathIn('moneta.db')),
        ],
      );
      final database = container.read(controlDatabaseProvider);

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

  group('the active database follows the demo flag', () {
    test('with demo off it IS the control database, not a second handle', () {
      final container = makeDatabaseContainer();
      expect(container.read(demoModeProvider), isFalse);
      expect(
        container.read(activeDatabaseProvider),
        same(container.read(controlDatabaseProvider)),
        reason:
            'two AppDatabase handles on one path would each open the file, and '
            '"the database is opened once" is a requirement',
      );
    });

    test('with demo on it is a different database, on the demo file', () {
      final container = makeDatabaseContainer();
      container.read(demoModeProvider.notifier).active = true;

      final active = container.read(activeDatabaseProvider);
      expect(active, isNot(same(container.read(controlDatabaseProvider))));
      expect(active.path, pathIn('moneta_demo.db'));
      expect(container.read(controlDatabaseProvider).path, pathIn('moneta.db'));
    });

    test('switching closes the connection it replaces', () async {
      final container = makeDatabaseContainer();
      container.read(demoModeProvider.notifier).active = true;

      final demo = container.read(activeDatabaseProvider);
      expect((await demo.open()).isOk, isTrue);
      expect(demo.openCount, 1);

      container.read(demoModeProvider.notifier).active = false;
      await pumpEventQueue();

      // Same observable consequence as container disposal: a closed connection
      // has to be opened again, so openCount moves.
      expect((await demo.open()).isOk, isTrue);
      expect(demo.openCount, 2);
      await demo.close();
    });

    test('turning demo off does NOT close the control database', () async {
      final container = makeDatabaseContainer();
      final control = container.read(controlDatabaseProvider);
      expect((await control.open()).isOk, isTrue);
      expect(control.openCount, 1);

      container.read(demoModeProvider.notifier).active = true;
      // Reading the active provider matters: Riverpod is lazy, so without a
      // read the demo branch is never built, no `onDispose` is registered, and
      // this test passes for a provider that closes the control connection on
      // every swap. A mutation adding that close survived until this line
      // existed.
      expect(
        container.read(activeDatabaseProvider).path,
        pathIn(
          'moneta_demo.db',
        ),
      );
      await pumpEventQueue();
      container.read(demoModeProvider.notifier).active = false;
      expect(
        container.read(activeDatabaseProvider),
        same(container.read(controlDatabaseProvider)),
      );
      await pumpEventQueue();

      // Still the same open connection: settings live here, and closing it on
      // every toggle would make the preference read that decides the toggle
      // race the toggle itself.
      expect((await control.open()).isOk, isTrue);
      expect(control.openCount, 1);
    });

    test(
      'a write after the switch lands in the new file, and only there',
      () async {
        final container = makeDatabaseContainer();

        // `onboardingComplete` is the only key that exists; any durable row
        // proves which file a write reached.
        Future<void> writeSetting(
          AppDatabase database, {
          required bool on,
        }) async {
          final opened = await database.open();
          final store = PreferencesStore(opened.valueOrNull!);
          await store.writeBool(PreferenceKey.onboardingComplete, value: on);
        }

        Future<int> settingRows(String file) async {
          final db = await databaseFactoryFfi.openDatabase(file);
          final rows = await db.query(PreferencesStore.table);
          await db.close();
          return rows.length;
        }

        // One row in the real file.
        await writeSetting(container.read(activeDatabaseProvider), on: true);
        expect(await settingRows(pathIn('moneta.db')), 1);

        container.read(demoModeProvider.notifier).active = true;
        await pumpEventQueue();

        // A write through the ACTIVE database now goes to the demo file.
        await writeSetting(container.read(activeDatabaseProvider), on: false);
        expect(await settingRows(pathIn('moneta_demo.db')), 1);

        // And the real file is untouched — still exactly the one row, unchanged.
        expect(
          await settingRows(pathIn('moneta.db')),
          1,
          reason: 'the real ledger must not gain a row from a demo-mode write',
        );
        final real = await databaseFactoryFfi.openDatabase(pathIn('moneta.db'));
        final rows = await real.query(PreferencesStore.table);
        await real.close();
        expect(
          rows.single['value'],
          PreferencesStore.trueText,
          reason: 'the demo-mode write must not have overwritten it either',
        );
      },
    );

    test('both databases are built by the same migration set', () async {
      final container = makeDatabaseContainer();
      container.read(demoModeProvider.notifier).active = true;
      final demo = container.read(activeDatabaseProvider);
      final control = container.read(controlDatabaseProvider);

      Future<Set<String>> tablesOf(AppDatabase database) async {
        final opened = await database.open();
        final rows = await opened.valueOrNull!.query(
          'sqlite_master',
          columns: ['name'],
          where: 'type = ?',
          whereArgs: ['table'],
        );
        return {
          for (final row in rows) row['name']! as String,
        }..removeWhere((name) => name.startsWith('sqlite_'));
      }

      expect(
        await tablesOf(demo),
        await tablesOf(control),
        reason:
            'a demo database that can drift from the real schema is a '
            'second schema nobody migrates',
      );
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
          controlDatabaseProvider.overrideWith(
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
