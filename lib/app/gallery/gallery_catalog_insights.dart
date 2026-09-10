import 'package:moneta/app/gallery/gallery_catalog.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/atoms/moneta_radio.dart';
import 'package:moneta/design_system/molecules/chart_legend_item.dart';
import 'package:moneta/design_system/molecules/chart_series.dart';
import 'package:moneta/design_system/molecules/moneta_radio_row.dart';
import 'package:moneta/design_system/organisms/bottom_sheet.dart';
import 'package:moneta/design_system/organisms/donut_chart.dart';
import 'package:moneta/design_system/organisms/line_chart.dart';

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
  GallerySection(
    component: 'DonutChart',
    figmaNodeId: '47:48',
    variants: [
      // `47:62`'s own eight categories, in its own scrambled slot order —
      // Food & drink is `Slot=7`, not `Slot=1`. Reproduced as authored so the
      // gallery and the Figma canvas can be compared directly.
      GalleryVariant(
        'Categories=8, Fold=None',
        (_) => const DonutChart(
          categories: _donutAuthored,
          centreLabel: 'Total spent',
          periodLabel: 'August 2026',
        ),
      ),
      // Nine, so the eight-segment cap and the neutral fold are visible to a
      // reviewer rather than only to the suite.
      GalleryVariant(
        'Categories=9, Fold=Other',
        (_) => const DonutChart(
          categories: _donutNine,
          centreLabel: 'Total spent',
          periodLabel: 'August 2026',
        ),
      ),
      GalleryVariant(
        'Categories=1, Fold=None',
        (_) => DonutChart(
          categories: _donutAuthored.take(1).toList(),
          centreLabel: 'Total spent',
          periodLabel: 'August 2026',
        ),
      ),
      GalleryVariant(
        'Categories=0, Fold=None',
        (_) => const DonutChart(
          categories: [],
          centreLabel: 'Total spent',
          periodLabel: 'August 2026',
        ),
      ),
    ],
  ),
  // `25:238` is an Atoms-page component, not a Charts one. It lands in this
  // spread because `insight-components` is the change that builds it — 07.05's
  // sheet is where it is instanced — and one owner per spread is the whole
  // point of the split.
  GallerySection(
    component: 'Radio',
    figmaNodeId: '25:238',
    variants: [
      for (final selected in [false, true])
        for (final enabled in [true, false])
          GalleryVariant(
            'Selected=$selected, Disabled=${!enabled}',
            (_) => MonetaRadio(
              selected: selected,
              enabled: enabled,
              semanticLabel: 'Weekly',
              onSelected: () {},
            ),
          ),
    ],
  ),
  // Not an authored component set: D8's composition, which is where the group
  // rule lives. Registered under the atom's node because that is the node it
  // composes; the row's own layout is derived, and 7.5's fidelity pass is what
  // will confirm or correct it.
  GallerySection(
    component: 'RadioRow',
    figmaNodeId: '25:238',
    variants: [
      GalleryVariant(
        'Selected=true, Supporting=true',
        (_) => const MonetaRadioRow(
          title: 'Monthly',
          supporting: 'On the 1st',
          selected: true,
        ),
      ),
      GalleryVariant(
        'Selected=false, Supporting=true',
        (_) => const MonetaRadioRow(
          title: 'Weekly',
          supporting: 'Every Monday',
          selected: false,
        ),
      ),
      GalleryVariant(
        'Selected=false, Supporting=false',
        (_) => const MonetaRadioRow(title: 'Yearly', selected: false),
      ),
      GalleryVariant(
        'Selected=false, Disabled=true',
        (_) => const MonetaRadioRow(
          title: 'Custom range',
          supporting: 'Not available yet',
          selected: false,
          enabled: false,
        ),
      ),
    ],
  ),
  GallerySection(
    component: 'RadioGroup',
    figmaNodeId: '25:238',
    variants: [
      // One variant per selectable value, because "exactly one is selected" is
      // the thing a reviewer is here to check, and it can only be checked by
      // seeing the selection move.
      for (final selected in _periods)
        GalleryVariant(
          'Selected=$selected',
          (_) => MonetaRadioGroup<String>(
            options: [
              for (final period in _periods)
                MonetaRadioOption(value: period, title: period),
            ],
            selected: selected,
            onChanged: (_) {},
          ),
        ),
    ],
  ),
  GallerySection(
    component: 'LineChart',
    figmaNodeId: '48:76',
    variants: [
      // `48:76` is one authored variant. The four here are the cases that look
      // different: the authored twelve months, a narrow band well above zero
      // (which is what the zero baseline is *for*), a single point, and none.
      GalleryVariant(
        'Points=12',
        (_) => MonetaLineChart(
          title: 'Cash flow',
          subtitle: 'Income vs expenses · VND millions',
          income: _line('Income', _incomeMillions),
          expenses: _line('Expenses', _expenseMillions),
        ),
      ),
      GalleryVariant(
        'Points=6, Max=35',
        (_) => MonetaLineChart(
          title: 'Cash flow',
          subtitle: 'A narrow band, well above zero',
          income: _line('Income', const [33, 34, 33, 35, 34, 34]),
          expenses: _line('Expenses', const [30, 31, 30, 32, 31, 30]),
        ),
      ),
      GalleryVariant(
        'Points=1',
        (_) => MonetaLineChart(
          title: 'Cash flow',
          subtitle: 'One month only',
          income: _line('Income', const [32]),
          expenses: _line('Expenses', const [26]),
        ),
      ),
      GalleryVariant(
        'Points=0',
        (_) => MonetaLineChart(
          title: 'Cash flow',
          subtitle: 'Nothing recorded yet',
          income: _line('Income', const []),
          expenses: _line('Expenses', const []),
        ),
      ),
    ],
  ),
  GallerySection(
    component: 'BottomSheet',
    figmaNodeId: '59:211',
    variants: [
      // `59:211` is one variant, and one fixture would show a reviewer nothing
      // about the requirement — that the height follows the content. Three
      // heights, so the thing being reviewed is visible.
      GalleryVariant(
        'Content=3 options',
        (_) => MonetaBottomSheet(
          title: 'Choose a period',
          onClose: () {},
          child: MonetaRadioGroup<String>(
            options: [
              for (final period in _periods)
                MonetaRadioOption(value: period, title: period),
            ],
            selected: _periods[1],
            onChanged: (_) {},
          ),
        ),
      ),
      GalleryVariant(
        'Content=8 options',
        (_) => MonetaBottomSheet(
          title: 'Choose a category',
          onClose: () {},
          child: MonetaRadioGroup<String>(
            options: [
              for (final category in _sheetCategories)
                MonetaRadioOption(value: category, title: category),
            ],
            selected: _sheetCategories.first,
            onChanged: (_) {},
          ),
        ),
      ),
      GalleryVariant(
        'Content=30 options',
        (_) => MonetaBottomSheet(
          title: 'Everything at once',
          onClose: () {},
          child: MonetaRadioGroup<String>(
            options: [
              for (var i = 0; i < 30; i++)
                MonetaRadioOption(value: 'Option $i', title: 'Option $i'),
            ],
            selected: 'Option 0',
            onChanged: (_) {},
          ),
        ),
      ),
    ],
  ),
];

/// The eight categories `07.05`'s sheet chooses between, plus Other.
const List<String> _sheetCategories = [
  'Food & drink',
  'Transport',
  'Shopping',
  'Bills & utilities',
  'Entertainment',
  'Health',
  'Gifts',
  'Other',
];

/// The three budget periods, which is what `07.05`'s sheet chooses between.
const List<String> _periods = ['Weekly', 'Monthly', 'Yearly'];

/// `47:62`'s eight categories with the slots it actually assigns them.
const List<ChartSeries> _donutAuthored = [
  ChartSeries(
    label: 'Food & drink',
    amount: Money(6760000, Currency.vnd),
    slot: ChartSlot.slot7,
  ),
  ChartSeries(
    label: 'Transport',
    amount: Money(4420000, Currency.vnd),
    slot: ChartSlot.slot4,
  ),
  ChartSeries(
    label: 'Shopping',
    amount: Money(3900000, Currency.vnd),
    slot: ChartSlot.slot2,
  ),
  ChartSeries(
    label: 'Bills & utilities',
    amount: Money(3380000, Currency.vnd),
    slot: ChartSlot.slot8,
  ),
  ChartSeries(
    label: 'Entertainment',
    amount: Money(2600000, Currency.vnd),
    slot: ChartSlot.slot6,
  ),
  ChartSeries(
    label: 'Health',
    amount: Money(2340000, Currency.vnd),
    slot: ChartSlot.slot3,
  ),
  ChartSeries(
    label: 'Gifts',
    amount: Money(1560000, Currency.vnd),
    slot: ChartSlot.slot5,
  ),
  ChartSeries(
    label: 'Other',
    amount: Money(1040000, Currency.vnd),
    slot: ChartSlot.other,
  ),
];

/// Nine categories: `47:62`'s eight plus one more, so the cap has something to
/// fold. `chart/1` is the one slot `47:62` never uses.
const List<ChartSeries> _donutNine = [
  ..._donutAuthored,
  ChartSeries(
    label: 'Education',
    amount: Money(520000, Currency.vnd),
    slot: ChartSlot.slot1,
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

/// Twelve months of income, in millions, as `48:76`'s sample reads.
const List<int> _incomeMillions = [
  28,
  30,
  29,
  32,
  31,
  33,
  32,
  34,
  33,
  35,
  34,
  32,
];

/// Twelve months of expenses, in millions.
const List<int> _expenseMillions = [
  22,
  24,
  21,
  26,
  23,
  27,
  25,
  28,
  24,
  29,
  26,
  26,
];

LineSeries _line(String label, List<int> millions) => LineSeries(
  label: label,
  points: [for (final m in millions) Money(m * 1000000, Currency.vnd)],
);
