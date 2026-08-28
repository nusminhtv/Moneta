import 'package:moneta/app/gallery/gallery_catalog.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/atoms/moneta_circular_progress.dart';
import 'package:moneta/design_system/molecules/amount_input.dart';
import 'package:moneta/design_system/molecules/moneta_segmented_control.dart';
import 'package:moneta/design_system/molecules/stat_tile.dart';

/// Gallery sections for 📱 04 Budgets.
///
/// Kept in its own file for the same reason the auth and home spreads are: two
/// agents editing one list collide on every line.
final List<GallerySection> budgetSections = [
  // --- BUDGETS: add sections below ---
  GallerySection(
    component: 'CircularProgress',
    figmaNodeId: '25:272',
    variants: [
      for (final (state, fraction) in const [
        ('Under', 0.62),
        ('Near', 0.88),
        // Figma's Over sample is labelled 100%. Under this system's rule —
        // `BudgetStatus.fromFraction`, where exactly 1.0 is the limit *reached*
        // and not exceeded — 100% is NearLimit, so a 1.0 fixture would render
        // the warning colour under an "Over" label. The gallery's own
        // label-versus-widget check caught that. 1.12 is genuinely over.
        ('Over', 1.12),
      ])
        for (final size in MonetaCircularProgressSize.values)
          GalleryVariant(
            'State=$state, '
            'Size=${size.name[0].toUpperCase()}${size.name.substring(1)}',
            (_) => MonetaCircularProgress(fraction: fraction, size: size),
          ),
    ],
  ),
  GallerySection(
    component: 'SegmentedItem',
    figmaNodeId: '36:167',
    variants: [
      GalleryVariant(
        'Selected=False',
        (_) => const MonetaSegmentedItem(label: 'Monthly', selected: false),
      ),
      GalleryVariant(
        'Selected=True',
        (_) => const MonetaSegmentedItem(label: 'Monthly', selected: true),
      ),
    ],
  ),
  GallerySection(
    component: 'SegmentedControl',
    figmaNodeId: '36:168',
    variants: [
      GalleryVariant(
        'Variant=Default',
        // Not `const`: the 2..4 assert reads `labels.length`, which a constant
        // expression cannot. The guard is worth more than the const.
        (_) => MonetaSegmentedControl(
          labels: const ['Weekly', 'Monthly', 'Yearly'],
          selectedIndex: 1,
        ),
      ),
    ],
  ),
  GallerySection(
    component: 'StatTile',
    figmaNodeId: '35:137',
    variants: [
      GalleryVariant(
        'Direction=Up',
        (_) => const StatTile(
          label: 'Spent this month',
          value: Money(12480000, Currency.vnd),
          delta: StatDelta.up,
          deltaLabel: '+12.4% vs last month',
        ),
      ),
      GalleryVariant(
        'Direction=Down',
        (_) => const StatTile(
          label: 'Spent this month',
          value: Money(9120000, Currency.vnd),
          delta: StatDelta.down,
          deltaLabel: '-8.2% vs last month',
        ),
      ),
      GalleryVariant(
        'Direction=Flat',
        (_) => const StatTile(
          label: 'Spent this month',
          value: Money(10400000, Currency.vnd),
          delta: StatDelta.flat,
          deltaLabel: 'Level with last month',
        ),
      ),
    ],
  ),
  GallerySection(
    component: 'AmountInput',
    figmaNodeId: '36:76',
    variants: [
      GalleryVariant(
        'State=Default',
        (_) => const AmountInput(
          amount: Money(620000, Currency.vnd),
          helper: 'Tap a category below to continue',
        ),
      ),
      GalleryVariant(
        'State=Error',
        (_) => const AmountInput.error(
          amount: Money(620000, Currency.vnd),
          // Figma leaves both variants sharing one merged helper string,
          // because Amount / Currency / Helper are TEXT properties. Its own
          // description says to set the real message per instance.
          message: 'That is more than this budget has left',
        ),
      ),
    ],
  ),
];
