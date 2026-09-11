import 'package:flutter/services.dart';
import 'package:moneta/core/money.dart';

/// Groups an amount's digits as it is typed.
///
/// Types `1500000` and reads `1.500.000` for VND, `1,500,000` for USD — the
/// currency's own grouping, because `Money.digits` uses the locale's and the
/// field should agree with what the amount will look like once it is saved.
///
/// Lives here rather than in `design_system`: the gallery test scans that
/// directory for public classes and a formatter is not a component, so it would
/// need an exemption to explain away. If a second screen needs it, that is when
/// it moves.
class AmountInputFormatter extends TextInputFormatter {
  /// Creates a formatter for [currency].
  const AmountInputFormatter(this.currency);

  /// Whose grouping and decimal separators to use.
  final Currency currency;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final decimalSeparator = currency.decimalSeparator;
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    // Where the caret is, counted in **digits** rather than characters.
    // Inserting a separator shifts every character after it, so a character
    // index jumps by one each time a group closes — the classic defect of this
    // control.
    final digitsBeforeCaret = _countDigits(
      text.substring(0, newValue.selection.baseOffset.clamp(0, text.length)),
    );

    final split = decimalSeparator == null
        ? [text]
        : text.split(decimalSeparator);
    // More than one decimal separator is not an amount; leave it alone and let
    // the parser refuse it rather than silently discarding what was typed.
    if (split.length > 2) return newValue;

    final whole = _digitsOnly(split.first);
    final grouped = _group(whole);

    // The decimal tail is passed through untouched, including a trailing
    // separator: without that, typing `12.` would be regrouped to `12` and the
    // decimal point would vanish under the user's finger.
    final tail = split.length == 2
        ? '$decimalSeparator${_digitsOnly(split[1])}'
        : '';
    final formatted = '$grouped$tail';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _offsetAfterDigits(formatted, digitsBeforeCaret),
      ),
    );
  }

  /// [digits] with a separator every three places from the right.
  String _group(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(currency.groupSeparator);
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static String _digitsOnly(String text) =>
      text.replaceAll(RegExp(r'[^\d]'), '');

  static int _countDigits(String text) =>
      text.replaceAll(RegExp(r'[^\d]'), '').length;

  /// The offset in [text] just after its [count]th digit.
  static int _offsetAfterDigits(String text, int count) {
    if (count <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < text.length; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) {
        seen++;
        if (seen == count) return i + 1;
      }
    }
    return text.length;
  }
}
