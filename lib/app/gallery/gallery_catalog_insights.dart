import 'package:moneta/app/gallery/gallery_catalog.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/molecules/chart_legend_item.dart';
import 'package:moneta/design_system/molecules/chart_series.dart';

/// Gallery sections for 📱 07 Insights & Reports and 🧩 Components / Charts.
///
/// Kept in its own file for the same reason the auth, home and budget spreads
/// are: two agents editing one list collide on every line.
final List<GallerySection> insightSections = [
  // --- INSIGHTS: add sections below ---
  GallerySection(
    component: 'ChartLegendItem',
    figmaNodeId: '47:47',
    // All nine, built from the enum rather than written out, so a tenth slot
    // cannot be added to the palette without appearing here. The label is
    // Figma's own variant name (`Slot=3`, `Slot=Other`).
    variants: [
      for (final slot in ChartSlot.values)
        GalleryVariant(
          slot.figmaName,
          (_) => ChartLegendItem(
            label: _legendLabels[slot]!,
            fraction: _legendFractions[slot]!,
            amount: _legendAmounts[slot]!,
            slot: slot,
          ),
        ),
    ],
  ),
];

/// Fixed fixtures — the gallery is compared against Figma by eye, so it must
/// render the same thing every time. `Slot=1` carries `47:2`'s own sample
/// ("Food & drink", 26%, 6,760,000 ₫); the rest are a plausible descending
/// breakdown so the nine rows read as one chart's legend rather than nine
/// copies of one row.
const Map<ChartSlot, String> _legendLabels = {
  ChartSlot.slot1: 'Food & drink',
  ChartSlot.slot2: 'Transport',
  ChartSlot.slot3: 'Rent',
  ChartSlot.slot4: 'Shopping',
  ChartSlot.slot5: 'Bills',
  ChartSlot.slot6: 'Health',
  ChartSlot.slot7: 'Entertainment',
  ChartSlot.slot8: 'Education',
  ChartSlot.other: 'Other',
};

const Map<ChartSlot, double> _legendFractions = {
  ChartSlot.slot1: 0.26,
  ChartSlot.slot2: 0.18,
  ChartSlot.slot3: 0.15,
  ChartSlot.slot4: 0.12,
  ChartSlot.slot5: 0.1,
  ChartSlot.slot6: 0.07,
  ChartSlot.slot7: 0.05,
  ChartSlot.slot8: 0.04,
  ChartSlot.other: 0.03,
};

const Map<ChartSlot, Money> _legendAmounts = {
  ChartSlot.slot1: Money(6760000, Currency.vnd),
  ChartSlot.slot2: Money(4680000, Currency.vnd),
  ChartSlot.slot3: Money(3900000, Currency.vnd),
  ChartSlot.slot4: Money(3120000, Currency.vnd),
  ChartSlot.slot5: Money(2600000, Currency.vnd),
  ChartSlot.slot6: Money(1820000, Currency.vnd),
  ChartSlot.slot7: Money(1300000, Currency.vnd),
  ChartSlot.slot8: Money(1040000, Currency.vnd),
  ChartSlot.other: Money(780000, Currency.vnd),
};
