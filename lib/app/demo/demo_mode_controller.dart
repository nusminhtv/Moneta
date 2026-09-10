import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/app/budget_providers.dart';
import 'package:moneta/app/demo/demo_dataset.dart';
import 'package:moneta/app/demo/demo_seed_marker.dart';
import 'package:moneta/app/demo/demo_seeder.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/data/preferences/preference_key.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

/// Turns demo mode on and off, and seeds the demo ledger the first time.
///
/// The **effects** live here; the flag itself lives in
/// `lib/data/app_providers.dart`, because `activeDatabaseProvider` depends on
/// it and `lib/data` may not import `lib/app`. That split is also what lets a
/// feature surface read the flag without importing this file.
///
/// Order matters. The preference is written first, because it is the durable
/// answer and everything else can be redone; the flag flips next, which repoints
/// every repository at the other ledger; seeding happens last, against the
/// ledger that is now active.
///
/// A seed that fails therefore leaves demo mode **on** with an unseeded ledger,
/// and that is deliberate rather than overlooked: the marker was not written, so
/// the next activation tries again, and in the meantime the screens show an
/// empty ledger under the demo banner — which the spec calls an empty ledger
/// rather than an error. Rolling the preference back instead would hide a
/// storage failure behind a toggle that silently refused to move.
class DemoModeController {
  /// Creates a controller over [ref].
  const DemoModeController(this.ref);

  /// The container this controller acts on.
  final Ref ref;

  /// Reads the stored flag and applies it, without seeding.
  ///
  /// Called at startup. Absence reads as off, and is distinguished from a
  /// stored `false` by the store rather than collapsed into it.
  Future<Result<bool>> hydrate() async {
    final store = await ref.read(preferencesStoreProvider.future);
    final stored = await store.readBool(PreferenceKey.demoMode);
    if (stored case Err(:final failure)) return Err(failure);

    final active = stored.valueOrNull ?? false;
    ref.read(demoModeProvider.notifier).active = active;
    return Ok(active);
  }

  /// Turns demo mode on or off.
  ///
  /// Returns the number of records seeded — zero when nothing needed seeding,
  /// which includes every deactivation.
  Future<Result<int>> setDemoMode({required bool active}) async {
    final store = await ref.read(preferencesStoreProvider.future);
    final written = await store.writeBool(
      PreferenceKey.demoMode,
      value: active,
    );
    if (written case Err(:final failure)) return Err(failure);

    ref.read(demoModeProvider.notifier).active = active;

    if (!active) return const Ok(0);
    return seedIfNeeded();
  }

  /// Deletes the demo ledger and generates it again.
  ///
  /// Refuses unless demo mode is active — the same guard [seedIfNeeded] makes,
  /// and for the same reason: this is a destructive call and the real ledger
  /// must never be reachable from it.
  ///
  /// Deletes the **file**, so the reopen runs the shared migration set from
  /// nothing and the result is identical to a first run.
  Future<Result<int>> resetDemoLedger() async {
    if (!ref.read(demoModeProvider)) {
      return const Err(
        AppFailure.validation('The demo ledger is not the active one'),
      );
    }

    final deleted = await ref.read(activeDatabaseProvider).deleteFile();
    if (deleted case Err(:final failure)) return Err(failure);

    // Every repository is built over the old connection, so the graph has to
    // be rebuilt before anything reads or writes again.
    ref.invalidate(activeDatabaseProvider);
    return seedIfNeeded();
  }

  /// Seeds the demo ledger if it has not been seeded in full.
  ///
  /// Safe to call repeatedly: the marker makes the second call a no-op.
  Future<Result<int>> seedIfNeeded() async {
    if (!ref.read(demoModeProvider)) {
      // Refusing rather than seeding the real ledger. This is the one call in
      // the change that could write generated data into a real wallet, so it
      // checks instead of trusting its caller.
      return const Err(
        AppFailure.validation('The demo ledger is not the active one'),
      );
    }

    final opened = await ref.read(activeDatabaseProvider).open();
    if (opened case Err(:final failure)) return Err(failure);

    final marker = DemoSeedMarker(opened.valueOrNull!);
    final seeder = DemoSeeder(
      transactions: await ref.read(transactionRepositoryProvider.future),
      budgets: await ref.read(budgetRepositoryProvider.future),
    );

    return seeder.seedOnce(
      marker: marker,
      dataset: generateDemoDataset(
        clock: ref.read(clockProvider),
        ids: demoIdGenerator(),
        currency: ref.read(walletCurrencyProvider),
      ),
    );
  }
}

/// The controller.
final demoModeControllerProvider = Provider<DemoModeController>(
  DemoModeController.new,
);
