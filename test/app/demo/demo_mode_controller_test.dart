import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/app/demo/demo_dataset.dart';
import 'package:moneta/app/demo/demo_mode_controller.dart';
import 'package:moneta/app/demo/demo_seeder.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/data/preferences/preference_key.dart';
import 'package:moneta/features/transactions/domain/transaction_query.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

/// Plain `test`, never `testWidgets`: real database I/O.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final anchor = DateTime.utc(2026, 9, 17, 14, 30);
  late Directory temporaryDirectory;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync('moneta_demo_ctl');
    addTearDown(() => temporaryDirectory.deleteSync(recursive: true));
  });

  String pathIn(String name) => p.join(temporaryDirectory.path, name);

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        realDatabasePathProvider.overrideWithValue(pathIn('moneta.db')),
        demoDatabasePathProvider.overrideWithValue(pathIn('moneta_demo.db')),
        clockProvider.overrideWithValue(FixedClock(anchor)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  DemoModeController controllerIn(ProviderContainer c) =>
      c.read(demoModeControllerProvider);

  Future<int> transactionCount(ProviderContainer c) async {
    final repository = await c.read(transactionRepositoryProvider.future);
    final listed = await repository.list(TransactionQuery.all);
    return listed.valueOrNull!.length;
  }

  Future<int> budgetCount(ProviderContainer c) async {
    final repository = await c.read(budgetRepositoryProvider.future);
    return (await repository.list()).valueOrNull!.length;
  }

  group('turning it on', () {
    test('persists the flag, repoints the ledger and seeds it', () async {
      final container = makeContainer();

      final result = await controllerIn(container).setDemoMode(active: true);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, greaterThan(900));

      expect(container.read(demoModeProvider), isTrue);
      expect(
        container.read(activeDatabaseProvider).path,
        pathIn('moneta_demo.db'),
      );
      expect(await transactionCount(container), greaterThan(900));
      expect(await budgetCount(container), 3);

      final store = await container.read(preferencesStoreProvider.future);
      expect(
        (await store.readBool(PreferenceKey.demoMode)).valueOrNull,
        isTrue,
      );
    });

    test('the real ledger is still empty afterwards', () async {
      final container = makeContainer();
      await controllerIn(container).setDemoMode(active: true);
      await controllerIn(container).setDemoMode(active: false);
      expect(await transactionCount(container), 0);
    });

    test('turning it on twice seeds once', () async {
      final container = makeContainer();
      final first = await controllerIn(container).setDemoMode(active: true);
      // Transactions only. `seedOnce` returns transactions PLUS budgets, and
      // comparing the two is how the first draft of this test failed at
      // 1174 vs 1177 — a reminder that "records" and "transactions" are not
      // the same number.
      final afterFirst = await transactionCount(container);

      await controllerIn(container).setDemoMode(active: false);
      final second = await controllerIn(container).setDemoMode(active: true);

      expect(first.valueOrNull, greaterThan(900));
      expect(
        second.valueOrNull,
        0,
        reason: 'the marker makes the second activation a no-op',
      );
      expect(await transactionCount(container), afterFirst);
      expect(await budgetCount(container), 3);
    });

    test('a transaction added in demo mode survives a re-activation', () async {
      // The reason seeding is once-only rather than every launch: manual work
      // must not be wiped by turning the toggle off and on.
      final container = makeContainer();
      await controllerIn(container).setDemoMode(active: true);
      final seeded = await transactionCount(container);

      final repository = await container.read(
        transactionRepositoryProvider.future,
      );
      final dataset = generateDemoDataset(
        clock: FixedClock(anchor),
        ids: demoIdGenerator(seed: 1),
        monthsOfHistory: 1,
      );
      expect((await repository.add(dataset.transactions.first)).isOk, isTrue);

      await controllerIn(container).setDemoMode(active: false);
      await controllerIn(container).setDemoMode(active: true);

      expect(await transactionCount(container), seeded + 1);
    });
  });

  group('hydrating at startup', () {
    test('absence reads as off', () async {
      final container = makeContainer();
      final hydrated = await controllerIn(container).hydrate();
      expect(hydrated.isOk, isTrue);
      expect(hydrated.valueOrNull, isFalse);
      expect(container.read(demoModeProvider), isFalse);
    });

    test('a stored true is applied without seeding', () async {
      final first = makeContainer();
      await controllerIn(first).setDemoMode(active: true);

      // A second container over the same files is the next launch.
      final next = makeContainer();
      final hydrated = await controllerIn(next).hydrate();

      expect(hydrated.valueOrNull, isTrue);
      expect(next.read(demoModeProvider), isTrue);
      expect(
        next.read(activeDatabaseProvider).path,
        pathIn('moneta_demo.db'),
      );
      // Already seeded, and hydrate does not seed anyway.
      expect(await transactionCount(next), greaterThan(900));
    });

    test('a stored false is applied, and is not absence', () async {
      final container = makeContainer();
      final store = await container.read(preferencesStoreProvider.future);
      await store.writeBool(PreferenceKey.demoMode, value: false);

      expect((await controllerIn(container).hydrate()).valueOrNull, isFalse);
      expect(
        (await store.readBool(PreferenceKey.demoMode)).valueOrNull,
        isFalse,
        reason: 'a stored false must remain distinguishable from absence',
      );
    });

    test(
      'a corrupt stored value surfaces rather than reading as off',
      () async {
        final container = makeContainer();
        final opened = await container.read(controlDatabaseProvider).open();
        await opened.valueOrNull!.insert('settings', {
          'key': PreferenceKey.demoMode.storedName,
          'value': 'perhaps',
        });

        final hydrated = await controllerIn(container).hydrate();
        expect(
          hydrated.isOk,
          isFalse,
          reason:
              'silently reading as off is how a broken toggle looks like a UI '
              'bug instead of a storage failure',
        );
      },
    );
  });

  group('seedIfNeeded refuses to touch the real ledger', () {
    test('it fails when demo mode is off', () async {
      final container = makeContainer();
      final result = await controllerIn(container).seedIfNeeded();

      expect(result.isOk, isFalse);
      expect(
        await transactionCount(container),
        0,
        reason: 'this is the one call that could seed a real wallet',
      );
    });

    test(
      'and the refusal is a validation failure, not a storage one',
      () async {
        final container = makeContainer();
        final message = (await controllerIn(container).seedIfNeeded()).when(
          ok: (_) => null,
          err: (failure) => failure.kind,
        );
        expect(message, FailureKind.validation);
      },
    );
  });
}
