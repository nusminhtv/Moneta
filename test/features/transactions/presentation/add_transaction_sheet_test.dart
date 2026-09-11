import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/clock.dart';
import 'package:moneta/core/id_generator.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/transactions/presentation/add_transaction_sheet.dart';
import 'package:moneta/features/transactions/presentation/transaction_providers.dart';

import '../../../support/fake_transaction_repository.dart';

void main() {
  late FakeTransactionRepository repository;

  Future<void> pumpSheet(
    WidgetTester tester, {
    required Clock clock,
    Currency currency = Currency.vnd,
  }) async {
    repository = FakeTransactionRepository();
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWith((ref) => repository),
          clockProvider.overrideWithValue(clock),
          idGeneratorProvider.overrideWithValue(FixedIdGenerator()),
          walletCurrencyProvider.overrideWithValue(currency),
        ],
        child: MaterialApp(
          theme: MonetaTheme.dark().toThemeData(),
          home: const Scaffold(body: AddTransactionSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the amount field groups as you type', () {
    testWidgets('typing 1500000 shows 1.500.000', (tester) async {
      await pumpSheet(tester, clock: FixedClock(DateTime.utc(2026, 8, 20, 10)));

      await tester.enterText(
        find.byKey(AddTransactionSheet.amountFieldKey),
        '1500000',
      );
      await tester.pump();

      expect(find.text('1.500.000'), findsOneWidget);
      expect(find.text('1500000'), findsNothing);
    });

    testWidgets('and what is shown is what is saved', (tester) async {
      // The whole point of the change, used rather than merely held: before
      // it, `Money.parse('1.500.000', vnd)` threw, so a grouped field could
      // not have been submitted at all.
      await pumpSheet(tester, clock: FixedClock(DateTime.utc(2026, 8, 20, 10)));

      await tester.enterText(
        find.byKey(AddTransactionSheet.amountFieldKey),
        '1500000',
      );
      await tester.tap(find.byKey(AddTransactionSheet.submitKey));
      await tester.pumpAndSettle();

      expect(find.byKey(AddTransactionSheet.errorKey), findsNothing);
      expect(
        repository.items.single.amount,
        const Money(1500000, Currency.vnd),
      );
    });

    testWidgets('the currency is shown, on the side its locale puts it', (
      tester,
    ) async {
      // **Both currencies.** Asserting only VND — both sides of it — killed a
      // hard-coded *prefix* and let a hard-coded *suffix* through, because the
      // USD branch of the ternary was never executed by any test.
      // `change-verifier` found it by replacing the pair with an unconditional
      // suffix and watching the whole suite pass.
      final expected = {
        Currency.vnd: (prefix: null, suffix: ' ₫'),
        Currency.usd: (prefix: r'$ ', suffix: null),
      };

      for (final entry in expected.entries) {
        await pumpSheet(
          tester,
          clock: FixedClock(DateTime.utc(2026, 8, 20, 10)),
          currency: entry.key,
        );

        final field = tester.widget<TextField>(
          find.byKey(AddTransactionSheet.amountFieldKey),
        );
        expect(
          field.decoration!.prefixText,
          entry.value.prefix,
          reason: '${entry.key.code} prefix',
        );
        expect(
          field.decoration!.suffixText,
          entry.value.suffix,
          reason: '${entry.key.code} suffix',
        );
      }
    });

    testWidgets('and a currency with no decimals offers no decimal key', (
      tester,
    ) async {
      // Unrequested and untested until `change-verifier` pointed it out.
      for (final currency in Currency.values) {
        await pumpSheet(
          tester,
          clock: FixedClock(DateTime.utc(2026, 8, 20, 10)),
          currency: currency,
        );
        expect(
          tester
              .widget<TextField>(find.byKey(AddTransactionSheet.amountFieldKey))
              .keyboardType,
          TextInputType.numberWithOptions(decimal: currency.decimals > 0),
          reason: currency.code,
        );
      }
      // And the two currencies differ here, so the loop compares something.
      expect(Currency.vnd.decimals, 0);
      expect(Currency.usd.decimals, 2);
    });

    testWidgets('USD groups with commas and keeps its decimals', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        clock: FixedClock(DateTime.utc(2026, 8, 20, 10)),
        currency: Currency.usd,
      );

      await tester.enterText(
        find.byKey(AddTransactionSheet.amountFieldKey),
        '1234.56',
      );
      await tester.tap(find.byKey(AddTransactionSheet.submitKey));
      await tester.pumpAndSettle();

      expect(find.byKey(AddTransactionSheet.errorKey), findsNothing);
      expect(
        repository.items.single.amount,
        const Money(123456, Currency.usd),
      );
    });
  });

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
