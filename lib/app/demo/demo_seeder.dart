import 'dart:math';

import 'package:moneta/app/demo/demo_dataset.dart';
import 'package:moneta/app/demo/demo_seed_marker.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/features/budgets/domain/budget_repository.dart';
import 'package:moneta/features/transactions/domain/transaction_repository.dart';

/// Writes a [DemoDataset] into whichever ledger the repositories point at.
///
/// **Through the repositories, never through SQL.** Two things follow, and both
/// are the reason:
///
/// 1. The dataset is *provably enterable by hand* — every record was accepted
///    by the same method the application's own forms call, so a screen can
///    never be reviewed against data a user could not have produced.
/// 2. The seeder cannot drift from the schema, because it does not know the
///    schema. A migration that adds a column needs no change here.
///
/// The cost is one write per record rather than one batch. That is measured
/// rather than assumed — see the evidence log — and optimising it would mean
/// threading a transaction-scoped executor through two repository
/// constructors, which is a cross-feature API change and not a tweak.
class DemoSeeder {
  /// Creates a seeder over the ledger these repositories serve.
  const DemoSeeder({required this.transactions, required this.budgets});

  /// Where transactions go.
  final TransactionRepository transactions;

  /// Where budgets go.
  final BudgetRepository budgets;

  /// Writes every record in [dataset], stopping at the first failure.
  ///
  /// Stops rather than continuing because a partially written ledger reported
  /// as a success is worse than a reported failure: the screens would show a
  /// ledger with holes in it and nothing would say why. The caller is
  /// responsible for not marking the ledger seeded when this returns [Err] —
  /// which is what makes the next activation try again.
  Future<Result<int>> seed(DemoDataset dataset) async {
    var written = 0;

    for (final transaction in dataset.transactions) {
      final result = await transactions.add(transaction);
      if (result case Err(:final failure)) return Err(failure);
      written++;
    }

    for (final budget in dataset.budgets) {
      final result = await budgets.add(budget);
      if (result case Err(:final failure)) return Err(failure);
      written++;
    }

    return Ok(written);
  }

  /// Seeds [dataset] only if [marker] says this ledger has not been seeded in
  /// full, and records the marker only if every record landed.
  ///
  /// Returns the number of records written, or zero when the ledger was already
  /// seeded — which is how the caller can tell "nothing to do" from "did the
  /// work" without asking again.
  ///
  /// The order matters and is the whole point: seed, *then* mark. Marking first
  /// would turn a failed seed into a ledger that is never retried, and a
  /// row-count check in place of the marker would do the same thing, because a
  /// seed that fails after its first record leaves rows behind.
  Future<Result<int>> seedOnce({
    required DemoSeedMarker marker,
    required DemoDataset dataset,
  }) async {
    final seeded = await marker.isSeeded();
    if (seeded case Err(:final failure)) return Err(failure);
    if (seeded.valueOrNull ?? false) return const Ok(0);

    final written = await seed(dataset);
    if (written case Err(:final failure)) return Err(failure);

    final marked = await marker.markSeeded();
    if (marked case Err(:final failure)) return Err(failure);

    return written;
  }
}

/// The identifier source a demo seed uses.
///
/// A `SystemIdGenerator` with **both** of its sources fixed. The production
/// default is `Random.secure()` plus the wall clock, which would make the
/// dataset irreproducible — so ids come from a seeded sequence and a fixed
/// timestamp prefix, and the same dataset comes out every time.
///
/// It lives here rather than beside the generator on purpose. `demo_dataset.dart`
/// is asserted to construct no id source at all — a source-level check that
/// caught this function when it was there — because the generator's whole claim
/// is that both sources of non-determinism arrive as parameters. *Choosing* a
/// deterministic one is the seeder's business, not the generator's.
///
/// A function rather than a constant because the generator is stateful: each
/// call must start its counter over, or two datasets generated in one process
/// would disagree.
IdGenerator demoIdGenerator({int seed = defaultDemoSeed}) => SystemIdGenerator(
  random: Random(seed),
  now: () => DateTime.utc(2026),
);
