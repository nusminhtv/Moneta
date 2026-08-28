import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';

void main() {
  group('Money.parse', () {
    test('parses whole VND amounts', () {
      expect(Money.parse('1250000', Currency.vnd).minorUnits, 1250000);
    });

    test('strips thousands separators', () {
      expect(Money.parse('1,250,000', Currency.vnd).minorUnits, 1250000);
    });

    test('parses USD with two decimals into cents', () {
      expect(Money.parse('12.34', Currency.usd).minorUnits, 1234);
    });

    test('pads a single decimal digit', () {
      expect(Money.parse('12.3', Currency.usd).minorUnits, 1230);
    });

    test('parses negatives', () {
      expect(Money.parse('-5.00', Currency.usd).minorUnits, -500);
    });

    test('rejects more decimals than the currency allows', () {
      expect(
        () => Money.parse('12.345', Currency.usd),
        throwsFormatException,
      );
      expect(
        () => Money.parse('1.5', Currency.vnd),
        throwsFormatException,
      );
    });

    test('rejects non-numeric input', () {
      expect(() => Money.parse('abc', Currency.vnd), throwsFormatException);
      expect(() => Money.parse('', Currency.vnd), throwsFormatException);
    });
  });

  group('arithmetic', () {
    test('is exact where doubles would drift', () {
      final a = Money.parse('0.10', Currency.usd);
      final b = Money.parse('0.20', Currency.usd);
      expect((a + b).minorUnits, 30);
      expect((a + b) == Money.parse('0.30', Currency.usd), isTrue);
    });

    test('subtracts and negates', () {
      const a = Money(1000, Currency.usd);
      const b = Money(250, Currency.usd);
      expect((a - b).minorUnits, 750);
      expect((-a).minorUnits, -1000);
      expect((-a).abs, a);
    });

    test('throws on currency mismatch', () {
      expect(
        () => const Money(100, Currency.usd) + const Money(100, Currency.vnd),
        throwsArgumentError,
      );
    });

    test('compares within a currency', () {
      expect(
        const Money(200, Currency.vnd) > const Money(100, Currency.vnd),
        isTrue,
      );
      expect(
        const Money(50, Currency.vnd) < const Money(100, Currency.vnd),
        isTrue,
      );
    });
  });

  group('ratioOf', () {
    test('returns the spent fraction', () {
      const spent = Money(2500, Currency.usd);
      const budget = Money(10000, Currency.usd);
      expect(spent.ratioOf(budget), 0.25);
    });

    test('clamps overspend to 1.0 so progress bars stay bounded', () {
      expect(
        const Money(
          15000,
          Currency.usd,
        ).ratioOf(const Money(10000, Currency.usd)),
        1.0,
      );
    });

    test('returns 0 instead of dividing by zero', () {
      expect(
        const Money(500, Currency.usd).ratioOf(const Money.zero(Currency.usd)),
        0.0,
      );
    });
  });

  group('format', () {
    test('formats VND with vi_VN grouping and no decimals', () {
      // vi_VN groups with '.' and puts a non-breaking space before ₫.
      expect(
        const Money(1250000, Currency.vnd).format(),
        '1.250.000\u00A0₫',
      );
    });

    test('formats USD with two decimals', () {
      expect(const Money(1234, Currency.usd).format(), r'$12.34');
    });

    test('adds an explicit plus sign for income when asked', () {
      expect(
        const Money(1234, Currency.usd).format(showSign: true),
        r'+$12.34',
      );
    });

    test('never adds a plus sign to negatives', () {
      expect(
        const Money(-1234, Currency.usd).format(showSign: true),
        isNot(startsWith('+')),
      );
    });
  });

  group('toString', () {
    test('is debuggable', () {
      expect(const Money(1234, Currency.usd).toString(), 'USD 12.34');
      expect(const Money(1250000, Currency.vnd).toString(), 'VND 1250000.0');
    });

    test('equal amounts hash equally', () {
      expect(
        const Money(100, Currency.usd).hashCode,
        const Money(100, Currency.usd).hashCode,
      );
      expect(const Money.zero(Currency.vnd).isZero, isTrue);
      expect(const Money(-1, Currency.vnd).isNegative, isTrue);
    });
  });

  group('Currency', () {
    test('resolves by code, case-insensitively', () {
      expect(Currency.fromCode('usd'), Currency.usd);
      expect(Currency.fromCode('VND'), Currency.vnd);
    });

    test('falls back to VND for unknown codes', () {
      expect(Currency.fromCode('XXX'), Currency.vnd);
    });
  });

  group('digits, for the hero amount entry', () {
    test('groups without a currency symbol', () {
      // VND's default locale is vi_VN, which groups with dots. Figma draws
      // "620,000" because the design file is written in English; the app is
      // not, and the number follows the money's locale rather than the mockup.
      const m = Money(1250000, Currency.vnd);
      expect(m.digits(), '1.250.000');
      expect(m.digits(), isNot(contains(Currency.vnd.symbol)));
    });

    test('respects the currency decimals', () {
      // VND has none, USD has two. A shared "strip the symbol off format()"
      // would get one of these wrong.
      expect(const Money(1234, Currency.usd).digits(), '12.34');
      expect(const Money(1234, Currency.vnd).digits(), '1.234');
    });

    test('zero and negative render', () {
      expect(const Money(0, Currency.vnd).digits(), '0');
      expect(const Money(-45000, Currency.vnd).digits(), contains('45.000'));
    });

    test('a very large amount groups all the way up', () {
      expect(
        const Money(999999999999999, Currency.vnd).digits(),
        '999.999.999.999.999',
      );
    });

    test('an explicit locale changes the grouping', () {
      // The point of not slicing the symbol off format(): grouping and symbol
      // placement are locale-dependent and move independently.
      final grouped = const Money(
        1250000,
        Currency.vnd,
      ).digits(locale: 'en_US');
      expect(grouped, '1,250,000');
    });
  });
}
