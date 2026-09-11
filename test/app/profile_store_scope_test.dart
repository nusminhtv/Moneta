import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/profile_providers.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/features/settings/domain/profile.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

/// Plain `test`, never `testWidgets`: real database I/O, which never completes
/// inside a `FakeAsync` zone (CLAUDE.md).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory temporaryDirectory;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync('moneta_profile');
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

  test('the profile is readable while demo mode is on', () async {
    final container = makeContainer();
    final store = await container.read(profileStoreProvider.future);

    await store.save(
      const Profile(
        name: 'Trần Văn Minh',
        email: 'minh@example.com',
        currency: Currency.usd,
      ),
    );

    // **With demo mode on**, not after toggling it off again. Once it is off,
    // `activeDatabaseProvider` returns the control database *object itself*
    // (see `app_providers.dart`), so a ledger-scoped store would read the same
    // rows and pass — the assertion has to be made while the two differ.
    container.read(demoModeProvider.notifier).active = true;
    expect(container.read(demoModeProvider), isTrue);
    expect(
      container.read(activeDatabaseProvider),
      isNot(same(container.read(controlDatabaseProvider))),
      reason: 'the two databases must actually differ, or this proves nothing',
    );

    final whileDemo = await (await container.read(
      profileStoreProvider.future,
    )).read();
    expect(whileDemo.valueOrNull?.name, 'Trần Văn Minh');
    expect(whileDemo.valueOrNull?.currency, Currency.usd);

    // And it is still there afterwards.
    container.read(demoModeProvider.notifier).active = false;
    final afterDemo = await (await container.read(
      profileStoreProvider.future,
    )).read();
    expect(afterDemo.valueOrNull?.name, 'Trần Văn Minh');
  });

  test('a profile saved during demo mode is the real one', () async {
    final container = makeContainer();
    container.read(demoModeProvider.notifier).active = true;

    final store = await container.read(profileStoreProvider.future);
    await store.save(const Profile(name: 'Bích'));

    container.read(demoModeProvider.notifier).active = false;
    final read = await (await container.read(
      profileStoreProvider.future,
    )).read();
    expect(
      read.valueOrNull?.name,
      'Bích',
      reason: "a name entered in demo mode is still the user's own name",
    );
  });

  group('saving through the provider, which nothing exercised before', () {
    // `change-verifier` found `saveProfile` at **0 of 9 lines covered**: every
    // route test overrode `profileProvider` with a literal, so the save path —
    // and the failure routing that hangs off it — was dead to the suite. That
    // is the hole the silent empty-name defect lived in.
    //
    // Plain `test`, never `testWidgets`: real database I/O never completes
    // inside a `FakeAsync` zone.

    test('a valid save reaches the provider that screens read', () async {
      final container = makeContainer();
      expect(await container.read(profileProvider.future), isNull);

      final failure = await saveProfile(
        await container.read(profileStoreProvider.future),
        const Profile(name: 'Minh', email: 'minh@example.com'),
      );
      container.invalidate(profileProvider);

      expect(failure, isNull);
      final read = await container.read(profileProvider.future);
      expect(read?.name, 'Minh');
      expect(read?.email, 'minh@example.com');
    });

    test('an invalid save returns the failure and stores nothing', () async {
      final container = makeContainer();

      final failure = await saveProfile(
        await container.read(profileStoreProvider.future),
        const Profile(name: ''),
      );

      expect(failure?.kind, FailureKind.validation);
      expect(
        await container.read(profileProvider.future),
        isNull,
        reason: 'a refused profile must not reach the provider',
      );
    });

    test("an invalid email is refused with the rule's message", () async {
      final container = makeContainer();

      final failure = await saveProfile(
        await container.read(profileStoreProvider.future),
        const Profile(name: 'Minh', email: 'not-an-address'),
      );

      expect(failure?.kind, FailureKind.validation);
      expect(failure?.message, 'Enter a valid email address');
    });

    test('a second save replaces the first', () async {
      final container = makeContainer();

      final store = await container.read(profileStoreProvider.future);
      await saveProfile(store, const Profile(name: 'Minh'));
      await saveProfile(
        store,
        const Profile(name: 'Bích', currency: Currency.usd),
      );
      container.invalidate(profileProvider);

      final read = await container.read(profileProvider.future);
      expect(read?.name, 'Bích');
      expect(read?.currency, Currency.usd);
    });
  });
}
