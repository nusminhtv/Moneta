import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/profile_providers.dart';
import 'package:moneta/core/money.dart';
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
}
