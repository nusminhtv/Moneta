import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/transactions/presentation/add_transaction_sheet.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

import '../../../support/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository repository;

  Future<void> pumpSheet(WidgetTester tester, {required Clock clock}) async {
    repository = FakeTransactionRepository();
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWith((ref) => repository),
          clockProvider.overrideWithValue(clock),
          idGeneratorProvider.overrideWithValue(FixedIdGenerator()),
        ],
        child: MaterialApp(
          theme: MonetaTheme.dark().toThemeData(),
          home: const Scaffold(body: AddTransactionSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('recording a transaction', () {
    testWidgets('succeeds on a clock that advances between reads', (
      tester,
    ) async {
      // The bug this catches: the sheet read `nowUtc()` twice — once for the
      // validator's "now" and once for the transaction's instant — and then
      // rejected the instant for being after now. Under FixedClock the two
      // readings are identical and it passes; under a real clock they are
      // microseconds apart and every single submission failed, with a message
      // telling the user to pick a date on a form that has no date field.
      await pumpSheet(
        tester,
        clock: TickingClock(DateTime.utc(2026, 8, 20, 10)),
      );

      await tester.enterText(
        find.byKey(AddTransactionSheet.amountFieldKey),
        '45000',
      );
      await tester.tap(find.byKey(AddTransactionSheet.submitKey));
      await tester.pumpAndSettle();

      expect(
        find.byKey(AddTransactionSheet.errorKey),
        findsNothing,
        reason: 'the form rejected its own timestamp',
      );
      expect(repository.items, hasLength(1));
    });

    testWidgets('still succeeds on a frozen clock', (tester) async {
      await pumpSheet(tester, clock: FixedClock(DateTime.utc(2026, 8, 20, 10)));

      await tester.enterText(
        find.byKey(AddTransactionSheet.amountFieldKey),
        '45000',
      );
      await tester.tap(find.byKey(AddTransactionSheet.submitKey));
      await tester.pumpAndSettle();

      expect(repository.items, hasLength(1));
    });
  });

  group('the date field', () {
    testWidgets('is present, and defaults to today without being set', (
      tester,
    ) async {
      // The user's report: the form rejected a submission for its date while
      // offering nowhere to choose one. `_occurredAt` was declared, read once,
      // and never written by anything.
      await pumpSheet(
        tester,
        clock: TickingClock(DateTime.utc(2026, 8, 20, 10)),
      );

      expect(find.byKey(AddTransactionSheet.dateFieldKey), findsOneWidget);
      expect(
        find.text('Today'),
        findsOneWidget,
        reason: 'no default shown for an unset date',
      );
    });

    testWidgets('a chosen date reaches the recorded transaction', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        clock: TickingClock(DateTime.utc(2026, 8, 20, 10)),
      );

      await tester.enterText(
        find.byKey(AddTransactionSheet.amountFieldKey),
        '45000',
      );
      await tester.tap(find.byKey(AddTransactionSheet.dateFieldKey));
      await tester.pumpAndSettle();

      // The picker opens on the current date; step back a day and accept.
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('19'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AddTransactionSheet.submitKey));
      await tester.pumpAndSettle();

      expect(repository.items, hasLength(1));
      expect(
        repository.items.single.occurredAt.toLocal().day,
        19,
        reason: 'the chosen date was dropped on the way to the repository',
      );
    });

    testWidgets('a future date cannot be chosen', (tester) async {
      // The form rejects one anyway; making it unreachable is better than
      // explaining it after the fact.
      await pumpSheet(
        tester,
        clock: TickingClock(DateTime.utc(2026, 8, 20, 10)),
      );
      await tester.tap(find.byKey(AddTransactionSheet.dateFieldKey));
      await tester.pumpAndSettle();

      final dialog = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(
        dialog.lastDate.isAfter(DateTime(2026, 8, 20, 23, 59)),
        isFalse,
        reason: 'the picker allowed a date after today',
      );
    });
  });
}
