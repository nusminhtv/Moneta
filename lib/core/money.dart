import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// An exact monetary amount stored as an integer number of minor units.
///
/// Personal-finance arithmetic must never use `double`: 0.1 + 0.2 != 0.3 in
/// IEEE-754 and rounding drift shows up in balances. All amounts in Moneta are
/// minor units (VND has 0 decimals, USD has 2).
final class Money extends Equatable implements Comparable<Money> {
  const Money(this.minorUnits, this.currency);

  /// Zero in [currency].
  const Money.zero(this.currency) : minorUnits = 0;

  /// Parses a major-unit decimal string (e.g. `"12.34"`) into [Money].
  ///
  /// Throws [FormatException] when [input] is not a valid decimal or has more
  /// fraction digits than [currency] allows.
  factory Money.parse(String input, Currency currency) {
    var trimmed = input.trim();
    final negative = trimmed.startsWith('-');
    if (negative) trimmed = trimmed.substring(1);

    // Split on the currency's own decimal separator, which is null for a
    // currency with no decimals — so for VND a `.` can only be a group mark,
    // and `1.5` fails the grouping check below rather than becoming 15.
    final decimalSeparator = currency.decimalSeparator;
    final String whole;
    final String fraction;
    if (decimalSeparator == null) {
      whole = trimmed;
      fraction = '';
    } else {
      final parts = trimmed.split(decimalSeparator);
      if (parts.length > 2) {
        throw FormatException('Not a decimal amount', input);
      }
      whole = parts.first;
      fraction = parts.length == 2 ? parts[1] : '';
    }

    if (!_isWellGrouped(whole, currency.acceptedGroupSeparators) ||
        (fraction.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fraction))) {
      throw FormatException('Not a decimal amount', input);
    }
    if (fraction.length > currency.decimals) {
      throw FormatException(
        '${currency.code} allows at most ${currency.decimals} decimals',
        input,
      );
    }
    final padded = fraction.padRight(currency.decimals, '0');
    var digits = whole;
    for (final separator in currency.acceptedGroupSeparators) {
      digits = digits.replaceAll(separator, '');
    }

    final wholeUnits = int.tryParse(digits);
    final fractionUnits = padded.isEmpty ? 0 : int.parse(padded);
    // `int.tryParse` returns null past int64, but the **multiply** below wraps
    // silently — `1,000,000,000,000,000,000.00` USD came back as a positive
    // 7,766,279,631,452,241,920, which is worse than an exception because the
    // sheet's `minorUnits <= 0` guard waves it through and stores it. Checked
    // before multiplying rather than after, since after is too late.
    const maxMinorUnits = 9223372036854775807;
    if (wholeUnits == null ||
        wholeUnits > (maxMinorUnits - fractionUnits) ~/ currency.scale) {
      throw FormatException('Amount is larger than this app can hold', input);
    }

    final minor = wholeUnits * currency.scale + fractionUnits;
    return Money(negative ? -minor : minor, currency);
  }

  /// Whether [whole] is digits, optionally grouped in threes by [separators].
  ///
  /// Grouping is optional; where it appears it must actually separate groups
  /// of three. That is what refuses `1.50.000` and `1,23,456` — a separator
  /// somewhere else is a typo, and a money field that turns a typo into a
  /// plausible wrong number is the worst outcome available.
  static bool _isWellGrouped(String whole, Set<String> separators) {
    if (RegExp(r'^\d+$').hasMatch(whole)) return whole.isNotEmpty;
    for (final separator in separators) {
      final escaped = RegExp.escape(separator);
      if (RegExp('^\\d{1,3}(?:$escaped\\d{3})+\$').hasMatch(whole)) {
        return true;
      }
    }
    return false;
  }

  /// Amount in the currency's smallest unit (cents, đồng, ...).
  final int minorUnits;

  /// Currency this amount is denominated in.
  final Currency currency;

  /// True when the amount is below zero.
  bool get isNegative => minorUnits < 0;

  /// True when the amount is exactly zero.
  bool get isZero => minorUnits == 0;

  /// Absolute value.
  Money get abs => Money(minorUnits.abs(), currency);

  /// Adds [other]; both operands must share a currency.
  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency);
  }

  /// Subtracts [other]; both operands must share a currency.
  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency);
  }

  /// Negates the amount.
  Money operator -() => Money(-minorUnits, currency);

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  /// True when this amount is strictly greater than [other].
  bool operator >(Money other) => compareTo(other) > 0;

  /// True when this amount is strictly less than [other].
  bool operator <(Money other) => compareTo(other) < 0;

  /// Ratio of this amount to [total], clamped to `0.0..1.0`.
  ///
  /// Returns `0` when [total] is zero, so progress bars never divide by zero.
  double ratioOf(Money total) {
    _assertSameCurrency(total);
    if (total.minorUnits == 0) return 0;
    final raw = minorUnits / total.minorUnits;
    return raw.clamp(0.0, 1.0);
  }

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Currency mismatch: ${currency.code} vs ${other.currency.code}',
      );
    }
  }

  /// Formats for display, e.g. `₫1,250,000` or `$12.34`.
  String format({String? locale, bool showSign = false}) {
    final formatter = NumberFormat.currency(
      locale: locale ?? currency.defaultLocale,
      symbol: currency.symbol,
      decimalDigits: currency.decimals,
    );
    final text = formatter.format(minorUnits / currency.scale);
    if (showSign && minorUnits > 0) return '+$text';
    return text;
  }

  /// The grouped digits alone, with no currency symbol — `1,250,000`.
  ///
  /// The hero amount entry on `36:76` draws the digits and the currency glyph
  /// as two separate pieces of type, at different sizes and colours. Slicing the
  /// symbol off [format]'s output would break on any locale that puts it last,
  /// or uses a non-breaking space, so the number is formatted without one.
  String digits({String? locale}) => NumberFormat.decimalPatternDigits(
    locale: locale ?? currency.defaultLocale,
    decimalDigits: currency.decimals,
  ).format(minorUnits / currency.scale);

  @override
  List<Object?> get props => [minorUnits, currency];

  @override
  String toString() => '${currency.code} ${minorUnits / currency.scale}';
}

/// Currencies Moneta supports out of the box.
enum Currency {
  /// Vietnamese đồng — no minor unit.
  vnd('VND', '₫', 0, 'vi_VN'),

  /// United States dollar.
  usd('USD', r'$', 2, 'en_US');

  const Currency(this.code, this.symbol, this.decimals, this.defaultLocale);

  /// ISO-4217 code.
  final String code;

  /// Display symbol.
  final String symbol;

  /// Number of fraction digits.
  final int decimals;

  /// Locale used when no explicit locale is supplied to [Money.format].
  final String defaultLocale;

  /// The character this currency's locale puts between groups of three.
  ///
  /// **Derived, not transcribed.** `intl` already knows — a table on this enum
  /// would be a second source of truth, and it would be wrong the first time a
  /// currency was added without someone remembering to update it.
  String get groupSeparator =>
      NumberFormat.decimalPattern(defaultLocale).symbols.GROUP_SEP;

  /// The character this currency's locale puts before the fraction, or null
  /// when the currency has none.
  ///
  /// A currency with zero decimals cannot have a decimal separator, which is
  /// what stops `.` being read as one for VND.
  String? get decimalSeparator => decimals == 0
      ? null
      : NumberFormat.decimalPattern(defaultLocale).symbols.DECIMAL_SEP;

  /// Whether [symbol] is written before the number rather than after it.
  ///
  /// Asked of [Money.format]'s own output rather than assumed, so the answer
  /// cannot drift from where the symbol actually lands.
  bool get symbolLeads => NumberFormat.currency(
    locale: defaultLocale,
    symbol: symbol,
    decimalDigits: decimals,
  ).format(0).trimLeft().startsWith(symbol);

  /// Every character this currency accepts between groups when parsing.
  ///
  /// The locale's own separator, plus a comma: `Money.parse('1,250,000', vnd)`
  /// has always worked and is a shipped contract, and someone typing on a US
  /// keyboard is a real thing.
  ///
  /// Removing the decimal separator changes nothing for **either currency here**
  /// — VND has none and USD's is `.`, which was never in the set. It is kept
  /// for the currency this app does not have yet: in `de_DE` or `fr_FR` the
  /// decimal separator **is** a comma, and without this line `1,50 €` would
  /// parse as one hundred and fifty. Unexercised, and stated as such rather
  /// than left looking load-bearing.
  Set<String> get acceptedGroupSeparators =>
      {groupSeparator, ','}..remove(decimalSeparator);

  /// Minor units per major unit (10^[decimals]).
  int get scale => switch (decimals) {
    0 => 1,
    2 => 100,
    _ => 1,
  };

  /// Looks up a currency by ISO code, defaulting to [Currency.vnd].
  static Currency fromCode(String code) => values.firstWhere(
    (c) => c.code == code.toUpperCase(),
    orElse: () => Currency.vnd,
  );
}
