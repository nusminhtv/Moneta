import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/tokens/colors.dart';

/// One of the nine legend slots authored on Figma node `47:47`.
///
/// A slot is chosen, never a colour. `47:47`'s own description — *"only the
/// swatch carries the series colour"* — and the fact that the eight-slot
/// palette was validated as a set mean a caller picking a colour could place
/// two adjacent series outside the validated contrast band.
///
/// [other] carries no palette slot at all. It is the fold, not a ninth hue:
/// making its palette slot `null` is what stops it ever being one.
enum ChartSlot {
  /// `chart/1` — mint.
  slot1(1),

  /// `chart/2` — violet.
  slot2(2),

  /// `chart/3` — coral.
  slot3(3),

  /// `chart/4` — sky.
  slot4(4),

  /// `chart/5` — lime.
  slot5(5),

  /// `chart/6` — pink.
  slot6(6),

  /// `chart/7` — amber. Confirmed as `#AA7705` from the exported donut asset,
  /// which is why the donut needed no new token.
  slot7(7),

  /// `chart/8` — teal.
  slot8(8),

  /// The neutral fold, `Slot=Other` on `47:47`. Draws in `textTertiary`
  /// (`#7C8595`, transcribed from `47:42`), not in a chart colour.
  other(null);

  const ChartSlot(this.paletteSlot);

  /// 1-based palette slot, or null for [other].
  final int? paletteSlot;

  /// How many slots carry a palette colour: the eight, excluding [other].
  static const int coloredCount = MonetaChartPalette.slotCount;

  /// The colour this slot draws in.
  Color colorIn(MonetaColors colors) => switch (paletteSlot) {
    final int slot => colors.chart.base(slot),
    null => colors.textTertiary,
  };

  /// The slot for a 0-based [rank] in a largest-first ordering.
  ///
  /// Ranks past the eighth get [other], which is the cap the donut applies
  /// expressed as a total function rather than as a branch at the call site.
  static ChartSlot forRank(int rank) {
    assert(rank >= 0, 'rank must be 0-based and non-negative, got $rank');
    if (rank >= coloredCount) return other;
    return values[rank];
  }

  /// The label Figma gives this variant, e.g. `Slot=3` or `Slot=Other`.
  String get figmaName => 'Slot=${paletteSlot ?? 'Other'}';
}

/// A named quantity with a chart slot: one datum both charts are built from.
///
/// Three parallel lists (`labels`, `amounts`, `slots`) were the alternative and
/// were rejected outright — lists of possibly different lengths are a defect
/// waiting to be written, and the specs require a mismatch to be *reported*.
///
/// Lives in `design_system` rather than `core` because [ChartSlot] is a
/// design-system concept and `lib/core` may import nothing but `core`.
@immutable
final class ChartSeries extends Equatable {
  /// Creates a datum.
  const ChartSeries({
    required this.label,
    required this.amount,
    required this.slot,
  });

  /// What the quantity is — a category name, a series name.
  final String label;

  /// The quantity. A domain type: the component formats it.
  final Money amount;

  /// Which legend slot it draws in.
  final ChartSlot slot;

  /// This datum with a different [slot], for a chart assigning slots by rank.
  ChartSeries withSlot(ChartSlot newSlot) =>
      ChartSeries(label: label, amount: amount, slot: newSlot);

  @override
  List<Object?> get props => [label, amount, slot];

  @override
  String toString() => 'ChartSeries($label, $amount, ${slot.figmaName})';
}

/// The one currency [amounts] share, or null when [amounts] is empty.
///
/// Throws [ArgumentError] naming both currencies when they disagree. Every
/// chart in this library routes its amounts through here, so "reports a
/// currency mismatch rather than summing them" is one implementation rather
/// than one per chart — and a chart that forgets to call it has no currency to
/// draw with, which is a compile-time hole rather than a silent wrong total.
Currency? chartCurrencyOf(Iterable<Money> amounts, {required String what}) {
  Currency? currency;
  for (final amount in amounts) {
    if (currency == null) {
      currency = amount.currency;
      continue;
    }
    if (amount.currency != currency) {
      throw ArgumentError.value(
        amount,
        what,
        'currency mismatch: ${currency.code} vs ${amount.currency.code}. '
        'A chart cannot sum or scale two currencies; convert before charting.',
      );
    }
  }
  return currency;
}

/// The sum of [amounts], or zero in [fallback] when [amounts] is empty.
///
/// Checks the currency first, so a mismatch is reported by [chartCurrencyOf]
/// with both codes named rather than by `Money.+` mid-fold.
Money chartSumOf(
  Iterable<Money> amounts, {
  required String what,
  Currency fallback = Currency.vnd,
}) {
  final currency = chartCurrencyOf(amounts, what: what) ?? fallback;
  var total = Money.zero(currency);
  for (final amount in amounts) {
    total += amount;
  }
  return total;
}
