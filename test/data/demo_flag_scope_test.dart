import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/data/preferences/preference_key.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

/// The one defect this split exists to prevent: a demo flag stored in the
/// database the flag selects.
///
/// Plain `test`, never `testWidgets`: these bodies await real database I/O, and
/// a `testWidgets` body runs inside a `FakeAsync` zone where a real future
/// never completes — the test **hangs indefinitely instead of failing**. Written
/// with `testWidgets` first, and it hung, exactly as `CLAUDE.md` says it
/// would.
///
/// Turn demo mode on, and the write goes to the real database; the read that
/// follows comes from the demo database, which has never heard of it. The
/// toggle reports itself off a moment after being switched on.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory temporaryDirectory;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync('moneta_flag');
    addTearDown(() => temporaryDirectory.deleteSync(recursive: true));
  });

  String pathIn(String name) => p.join(temporaryDirectory.path, name);

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        realDatabasePathProvider.overrideWithValue(pathIn('moneta.db')),
        demoDatabasePathProvider.overrideWithValue(pathIn('moneta_demo.db')),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('the toggle does not undo itself', () {
    test('the flag reads back true after the swap it caused', () async {
      final container = makeContainer();

      // Write the flag the way the controller will: through the store, before
      // the active ledger changes.
      final before = await container.read(preferencesStoreProvider.future);
      expect(
        (await before.writeBool(PreferenceKey.demoMode, value: true)).isOk,
        isTrue,
      );

      // Now the swap actually happens.
      container.read(demoModeProvider.notifier).active = true;
      expect(
        container.read(activeDatabaseProvider).path,
        pathIn(
          'moneta_demo.db',
        ),
      );

      // **Re-resolved, not reused.** Holding `before` across the swap would
      // read from the still-open control connection and pass even with the
      // store bound to the active database — which is precisely the defect.
      final after = await container.read(preferencesStoreProvider.future);
      expect(
        (await after.readBool(PreferenceKey.demoMode)).valueOrNull,
        isTrue,
        reason:
            'the flag was read from the database it selects, so turning demo '
            'mode on reports demo mode off',
      );
    });

    test('and it survives being turned back off', () async {
      final container = makeContainer();
      final store = await container.read(preferencesStoreProvider.future);
      await store.writeBool(PreferenceKey.demoMode, value: true);
      container.read(demoModeProvider.notifier).active = true;
      expect(
        container.read(activeDatabaseProvider).path,
        pathIn(
          'moneta_demo.db',
        ),
      );

      final off = await container.read(preferencesStoreProvider.future);
      await off.writeBool(PreferenceKey.demoMode, value: false);
      container.read(demoModeProvider.notifier).active = false;

      final back = await container.read(preferencesStoreProvider.future);
      expect(
        (await back.readBool(PreferenceKey.demoMode)).valueOrNull,
        isFalse,
        reason: 'absence would mean the write landed in the demo ledger',
      );
    });

    test('the store is the same instance across a swap', () async {
      // The consequence of being bound to a database that does not move: the
      // provider does not rebuild, so nothing in flight against it is lost.
      final container = makeContainer();
      final before = await container.read(preferencesStoreProvider.future);
      container.read(demoModeProvider.notifier).active = true;
      expect(
        container.read(activeDatabaseProvider).path,
        pathIn(
          'moneta_demo.db',
        ),
      );
      final after = await container.read(preferencesStoreProvider.future);

      expect(after, same(before));
    });
  });

  group('and no code can point the store at a database that moves', () {
    // A behavioural test cannot prove absence, and a future call site could
    // reintroduce this without touching the tests above.
    const source = 'lib/data/app_providers.dart';

    String storeBodyIn(String text) {
      final start = text.indexOf('final preferencesStoreProvider');
      expect(start, greaterThan(-1), reason: 'the provider was renamed');
      final end = text.indexOf('});', start);
      return text.substring(start, end);
    }

    test('preferencesStoreProvider reads the control database', () {
      final body = storeBodyIn(File(source).readAsStringSync());
      expect(body, contains('controlDatabaseProvider'));
      expect(
        body,
        isNot(contains('activeDatabaseProvider')),
        reason:
            'settings must not be read from the ledger the toggle swaps, or '
            'the toggle undoes itself',
      );
    });

    test('and the check itself can fail', () {
      // Guards the guard: if the extractor stopped finding the body, the test
      // above would pass forever on an empty string.
      const counterfeit = '''
        final preferencesStoreProvider = FutureProvider<PreferencesStore>((
          ref,
        ) async {
          final opened = await ref.watch(activeDatabaseProvider).open();
          return opened.when(ok: PreferencesStore.new, err: (f) => throw f);
        });
      ''';
      final body = storeBodyIn(counterfeit);
      expect(body, contains('activeDatabaseProvider'));
      expect(body, isNot(contains('controlDatabaseProvider')));
    });

    test('no other file builds a PreferencesStore at all', () {
      final offenders = <String>[];
      for (final file in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        if (file.path.endsWith('preferences_store.dart')) continue;
        if (file.path.endsWith('app_providers.dart')) continue;
        if (file.readAsStringSync().contains('PreferencesStore(')) {
          offenders.add(file.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'a second construction site is a second chance to bind it to the '
            'wrong database: ${offenders.join(', ')}',
      );
    });
  });
}
