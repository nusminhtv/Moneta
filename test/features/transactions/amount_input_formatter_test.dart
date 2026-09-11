import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/features/transactions/presentation/amount_input_formatter.dart';

void main() {
  /// Applies the formatter to [text], with the caret at [caret] (default: the
  /// end), and returns what the field would show.
  TextEditingValue format(
    String text, {
    Currency currency = Currency.vnd,
    int? caret,
    String previous = '',
  }) => AmountInputFormatter(currency).formatEditUpdate(
    TextEditingValue(text: previous),
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret ?? text.length),
    ),
  );

  group('grouping', () {
    test('digits group in the currency style', () {
      expect(format('1500000').text, '1.500.000');
      expect(format('1500000', currency: Currency.usd).text, '1,500,000');
    });

    test('short amounts are left alone', () {
      expect(format('1').text, '1');
      expect(format('999').text, '999');
      expect(format('1000').text, '1.000');
    });

    test('an empty field stays empty', () {
      // No separator, no zero, no symbol-only text — the placeholder is what
      // should be seen.
      expect(format('').text, isEmpty);
    });

    test('already-grouped text is regrouped, not doubled', () {
      expect(format('1.500.000').text, '1.500.000');
    });

    test('deleting a digit regroups what is left', () {
      // `1.500.000` with the last digit removed.
      expect(format('1.500.00', previous: '1.500.000').text, '150.000');
    });

    test('a very large amount groups all the way up', () {
      expect(format('987654321').text, '987.654.321');
    });
  });

  group('the decimal tail', () {
    test('is kept and not grouped', () {
      expect(format('1234.5', currency: Currency.usd).text, '1,234.5');
    });

    test('survives being half-typed', () {
      // Without this, `12.` is regrouped to `12` and the decimal point the
      // user just typed vanishes under their finger.
      expect(format('12.', currency: Currency.usd).text, '12.');
    });

    test('a second separator is left for the parser to refuse', () {
      expect(format('1.2.3', currency: Currency.usd).text, '1.2.3');
    });

    test('VND has no decimal tail, so a dot is grouping', () {
      expect(format('1.500', currency: Currency.vnd).text, '1.500');
    });
  });

  group('the caret', () {
    test('stays with its digit when one is inserted in the middle', () {
      // `1.500.000` with a `9` typed after the first digit: the raw text the
      // field reports is `19.500.000` with the caret at character 2.
      final result = format('19.500.000', caret: 2, previous: '1.500.000');

      expect(result.text, '19.500.000');
      // Two digits precede the caret, so it sits after the `9` — which is
      // character 2 here. Counting characters instead of digits is what makes
      // a caret jump when a group closes.
      expect(result.selection.baseOffset, 2);
      expect(result.text.substring(0, result.selection.baseOffset), '19');
    });

    test('stays put when inserting a digit closes a group', () {
      // `100` → typing `0` at the end gives `1000`, which becomes `1.000`.
      // The caret must follow the four digits, not stay at character 4.
      final result = format('1000', caret: 4, previous: '100');

      expect(result.text, '1.000');
      expect(result.selection.baseOffset, 5);
      expect(
        result.text.substring(0, result.selection.baseOffset),
        '1.000',
        reason: 'the caret must be after the last digit, not inside the group',
      );
    });

    test('counts digits, not characters, past existing separators', () {
      // The case that tells the two apart. In `1.500.000` with the caret at
      // character 5 — just after `1.500` — there are **four** digits before
      // it. Counting characters instead would land after the fifth digit, at
      // character 7, and the caret would jump two places for no reason.
      //
      // Every other caret case here has equal digit and character counts, so
      // they pass either way: counting characters survived them all until this
      // one was added.
      final result = format('1.500.000', caret: 5);

      expect(result.text, '1.500.000');
      expect(result.selection.baseOffset, 5);
      expect(result.text.substring(0, result.selection.baseOffset), '1.500');
    });

    test('goes to the start when there is nothing before it', () {
      final result = format('500', caret: 0);
      expect(result.selection.baseOffset, 0);
    });
  });

  group('what is displayed is what parses', () {
    test('every grouped value the formatter produces parses back', () {
      // The point of the whole change: the field shows what `Money.parse` can
      // read. Before it, `1.500.000` threw.
      for (final currency in Currency.values) {
        for (final raw in ['1', '999', '1000', '1500000', '987654321']) {
          final shown = format(raw, currency: currency).text;
          expect(
            Money.parse(shown, currency).minorUnits,
            int.parse(raw) * currency.scale,
            reason: '${currency.code}: "$shown"',
          );
        }
      }
    });
  });
}
