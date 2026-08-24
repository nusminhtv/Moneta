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
    final trimmed = input.trim().replaceAll(',', '');
    final match = RegExp(r'^(-)?(\d+)(?:\.(\d+))?$').firstMatch(trimmed);
    if (match == null) {
      throw FormatException('Not a decimal amount', input);
    }
    final fraction = match.group(3) ?? '';
    if (fraction.length > currency.decimals) {
      throw FormatException(
        '${currency.code} allows at most ${currency.decimals} decimals',
        input,
      );
    }
    final padded = fraction.padRight(currency.decimals, '0');
    final whole = int.parse(match.group(2)!);
    final minor =
        whole * currency.scale + (padded.isEmpty ? 0 : int.parse(padded));
    return Money(match.group(1) == '-' ? -minor : minor, currency);
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
