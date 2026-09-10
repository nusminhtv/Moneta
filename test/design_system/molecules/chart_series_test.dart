import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/molecules/chart_series.dart';
import 'package:moneta/design_system/tokens/colors.dart';

const Currency _vnd = Currency.vnd;
const Currency _usd = Currency.usd;

ChartSeries _series(String label, int minor, ChartSlot slot) =>
    ChartSeries(label: label, amount: Money(minor, _vnd), slot: slot);

void main() {
  group('ChartSlot', () {
    test('eight slots carry a palette colour and Other carries none', () {
      final colored = ChartSlot.values.where((s) => s.paletteSlot != null);
      expect(colored, hasLength(MonetaChartPalette.slotCount));
      expect(
        colored.map((s) => s.paletteSlot),
        [1, 2, 3, 4, 5, 6, 7, 8],
        reason: 'declaration order must match the palette index',
      );
      expect(ChartSlot.other.paletteSlot, isNull);
    });

    test('Other draws in textTertiary, never in a chart colour', () {
      const colors = MonetaColors.dark();
      final otherColor = ChartSlot.other.colorIn(colors);

      expect(otherColor, colors.textTertiary);
      for (final slot in ChartSlot.values) {
        if (slot == ChartSlot.other) continue;
        expect(
          slot.colorIn(colors),
          isNot(otherColor),
          reason: '${slot.figmaName} must be distinguishable from Other',
        );
      }
    });

    test('every coloured slot resolves to its own palette entry', () {
      const colors = MonetaColors.dark();
      for (final slot in ChartSlot.values) {
        final palette = slot.paletteSlot;
        if (palette == null) continue;
        expect(slot.colorIn(colors), colors.chart.base(palette));
      }
      // Distinct as a set: a duplicated entry would make two series
      // indistinguishable and every per-slot assertion above still pass.
      expect(
        ChartSlot.values.map((s) => s.colorIn(colors)).toSet(),
        hasLength(ChartSlot.values.length),
      );
    });

    test('ranks past the eighth fold into Other', () {
      expect(ChartSlot.forRank(0), ChartSlot.slot1);
      expect(ChartSlot.forRank(7), ChartSlot.slot8);
      expect(ChartSlot.forRank(8), ChartSlot.other);
      expect(ChartSlot.forRank(99), ChartSlot.other);
    });

    test('figmaName speaks Figma, so gallery labels are comparable', () {
      expect(ChartSlot.slot3.figmaName, 'Slot=3');
      expect(ChartSlot.other.figmaName, 'Slot=Other');
    });
  });

  group('ChartSeries', () {
    test('equality is by value, not identity', () {
      expect(
        _series('Food', 1000, ChartSlot.slot1),
        _series('Food', 1000, ChartSlot.slot1),
      );
      expect(
        _series('Food', 1000, ChartSlot.slot1),
        isNot(_series('Food', 1001, ChartSlot.slot1)),
      );
      expect(
        _series('Food', 1000, ChartSlot.slot1),
        isNot(_series('Rent', 1000, ChartSlot.slot1)),
      );
      expect(
        _series('Food', 1000, ChartSlot.slot1),
        isNot(_series('Food', 1000, ChartSlot.slot2)),
        reason: 'the slot is part of the datum, so it is part of equality',
      );
    });

    test('withSlot re-slots without touching label or amount', () {
      final ranked = _series('Food', 1000, ChartSlot.slot1);
      final folded = ranked.withSlot(ChartSlot.other);

      expect(folded.slot, ChartSlot.other);
      expect(folded.label, ranked.label);
      expect(folded.amount, ranked.amount);
      expect(ranked.slot, ChartSlot.slot1, reason: 'the original is immutable');
    });

    test('toString names the slot as Figma does', () {
      expect(
        _series('Food', 1000, ChartSlot.other).toString(),
        contains('Slot=Other'),
      );
    });
  });

  group('chartCurrencyOf', () {
    test('reports a mismatch naming both currencies', () {
      expect(
        () => chartCurrencyOf(const [
          Money(1000, _vnd),
          Money(1000, _usd),
        ], what: 'categories'),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'categories')
              .having((e) => e.message.toString(), 'message', contains('VND'))
              .having((e) => e.message.toString(), 'message', contains('USD')),
        ),
      );
    });

    test('a mismatch in any position is reported, not only the second', () {
      expect(
        () => chartCurrencyOf(const [
          Money(1, _vnd),
          Money(2, _vnd),
          Money(3, _vnd),
          Money(4, _usd),
        ], what: 'series'),
        throwsArgumentError,
      );
    });

    test('one currency throughout is returned', () {
      expect(
        chartCurrencyOf(const [Money(1, _vnd), Money(2, _vnd)], what: 'x'),
        _vnd,
      );
      expect(
        chartCurrencyOf(const [Money(1, _usd)], what: 'x'),
        _usd,
        reason: 'the currency comes from the data, not from a default',
      );
    });

    test('empty is not a mismatch', () {
      expect(chartCurrencyOf(const <Money>[], what: 'x'), isNull);
    });

    test('zero amounts do not exempt the currency check', () {
      expect(
        () => chartCurrencyOf(const [
          Money(0, _vnd),
          Money(0, _usd),
        ], what: 'x'),
        throwsArgumentError,
        reason:
            'two zero balances in different currencies are still two '
            'currencies; a chart that sums them is wrong the moment either '
            'moves',
      );
    });
  });

  group('chartSumOf', () {
    test('sums a single currency exactly', () {
      expect(
        chartSumOf(const [
          Money(1250000, _vnd),
          Money(340000, _vnd),
        ], what: 'x'),
        const Money(1590000, _vnd),
      );
    });

    test('empty falls back to zero in the fallback currency', () {
      expect(
        chartSumOf(const <Money>[], what: 'x', fallback: _usd),
        const Money.zero(_usd),
      );
    });

    test('zero and negative amounts are summed as given, not clamped', () {
      // The donut decides that a negative contributes no arc. Deciding it here
      // instead would make the "segment sum equals the supplied sum" guarantee
      // unfalsifiable, because the sum would silently change.
      expect(
        chartSumOf(const [
          Money(1000, _vnd),
          Money(0, _vnd),
          Money(-400, _vnd),
        ], what: 'x'),
        const Money(600, _vnd),
      );
    });

    test('near-maximum amounts stay exact', () {
      // 2^53 + 1: the smallest integer a double cannot hold. Deliberately
      // computed rather than written as a literal, both because the lints
      // forbid the literal and because the shift shows what the boundary is.
      const beyondDouble = (1 << 53) + 1;
      expect(
        beyondDouble.toDouble().toInt(),
        isNot(beyondDouble),
        reason: 'this is the precision the integer path is protecting',
      );
      expect(
        chartSumOf(const [
          Money(beyondDouble, _vnd),
          Money(2, _vnd),
        ], what: 'x'),
        const Money(beyondDouble + 2, _vnd),
      );
    });

    test('a mismatch is reported before any addition happens', () {
      expect(
        () => chartSumOf(const [
          Money(1000, _vnd),
          Money(1000, _usd),
        ], what: 'categories'),
        throwsA(
          isA<ArgumentError>().having((e) => e.name, 'name', 'categories'),
        ),
      );
    });
  });
}
