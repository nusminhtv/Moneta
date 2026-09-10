import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/molecules/chart_series.dart';

/// The chart slot a category draws in.
///
/// `SpendCategory` already carries `chartSlot`, and it is not incidental:
/// Food 7, Transport 4, Shopping 2, Bills 8, Entertainment 6, Health 3,
/// Gifts 5 is **exactly** the sequence `47:62`'s legend rows use. What looked
/// like an arbitrary slot order in the donut's Figma sample is each category's
/// own bound slot, which is why `chart/1` never appears there — it belongs to
/// `salary`, and salary is income.
///
/// So a category keeps one colour on every screen that charts it, without any
/// screen choosing.
ChartSlot slotFor(SpendCategory category) =>
    ChartSlot.values.firstWhere((s) => s.paletteSlot == category.chartSlot);
