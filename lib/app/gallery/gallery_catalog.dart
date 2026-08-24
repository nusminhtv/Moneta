import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/category_icon.dart';
import 'package:moneta/design_system/molecules/progress_bar.dart';
import 'package:moneta/design_system/organisms/balance_card.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/design_system/organisms/budget_card.dart';

/// One labelled variant in the gallery.
@immutable
class GalleryVariant {
  /// Creates a variant entry.
  const GalleryVariant(this.label, this.build);

  /// The variant's name **as authored in Figma** (e.g. `State=Masked`), so a
  /// reviewer can put the gallery and the Figma canvas side by side.
  final String label;

  /// Builds the variant.
  final WidgetBuilder build;
}

/// One component in the gallery, with every variant it has.
@immutable
class GallerySection {
  /// Creates a section.
  const GallerySection({
    required this.component,
    required this.figmaNodeId,
    required this.variants,
  });

  /// Component name, matching Figma.
  final String component;

  /// The Figma node this component comes from.
  final String figmaNodeId;

  /// Every variant, in Figma order.
  final List<GalleryVariant> variants;
}

const Currency _vnd = Currency.vnd;

/// Fixtures. Deliberately fixed values — the gallery is compared against Figma
/// by eye, so it must render the same thing every time.
const _balance = Money(48320000, _vnd);
const _safeToSpend = Money(6180000, _vnd);
const _income = Money(32000000, _vnd);
const _expenses = Money(25840000, _vnd);
const _budgetLimit = Money(4000000, _vnd);

/// Every design-system component, in every variant.
///
/// This list is the gallery's contract: a test asserts each section's variant
/// count against the enum that defines it, so adding a variant to a component
/// without adding it here fails verification.
final List<GallerySection> galleryCatalog = [
  GallerySection(
    component: 'BalanceCard',
    figmaNodeId: '40:161',
    variants: [
      GalleryVariant(
        'State=Default',
        (_) => const BalanceCard(
          totalBalance: _balance,
          safeToSpend: _safeToSpend,
          income: _income,
          expenses: _expenses,
          safeToSpendUntil: '31 Aug',
        ),
      ),
      GalleryVariant(
        'State=Masked',
        (_) => const BalanceCard(
          totalBalance: _balance,
          safeToSpend: _safeToSpend,
          income: _income,
          expenses: _expenses,
          safeToSpendUntil: '31 Aug',
          masked: true,
        ),
      ),
    ],
  ),
  GallerySection(
    component: 'BudgetCard',
    figmaNodeId: '40:256',
    variants: [
      GalleryVariant(
        'State=OnTrack',
        (_) => const BudgetCard(
          category: SpendCategory.food,
          spent: Money(2450000, _vnd),
          limit: _budgetLimit,
          note: '61% used · 9 days left',
        ),
      ),
      GalleryVariant(
        'State=NearLimit',
        (_) => const BudgetCard(
          category: SpendCategory.transport,
          spent: Money(3520000, _vnd),
          limit: _budgetLimit,
          note: '88% used · 9 days left',
        ),
      ),
      GalleryVariant(
        'State=Over',
        (_) => const BudgetCard(
          category: SpendCategory.shopping,
          spent: Money(4740000, _vnd),
          limit: _budgetLimit,
          note: '740.000 ₫ over budget',
        ),
      ),
    ],
  ),
  GallerySection(
    component: 'BottomNav',
    figmaNodeId: '39:243',
    variants: [
      for (final destination in MonetaDestination.values)
        GalleryVariant(
          'Active=${destination.name[0].toUpperCase()}'
          '${destination.name.substring(1)}',
          (_) => MonetaBottomNav(active: destination),
        ),
    ],
  ),
  GallerySection(
    component: 'ProgressBar',
    figmaNodeId: '21:139',
    variants: [
      for (final size in MonetaProgressBarSize.values)
        for (final entry in const {
          'Under': 0.62,
          'Near': 0.88,
          'Over': 1.4,
        }.entries)
          GalleryVariant(
            'State=${entry.key}, Size=${size.name[0].toUpperCase()}'
            '${size.name.substring(1)}',
            (_) => MonetaProgressBar(fraction: entry.value, size: size),
          ),
    ],
  ),
  GallerySection(
    component: 'CategoryIcon',
    figmaNodeId: '33:311',
    variants: [
      for (final category in SpendCategory.values)
        for (final size in CategoryIconSize.values)
          GalleryVariant(
            'Category=${category.name}, '
            'Size=${size.name[0].toUpperCase()}${size.name.substring(1)}',
            (_) => CategoryIcon(category: category, size: size),
          ),
    ],
  ),
  GallerySection(
    component: 'Icons',
    figmaNodeId: '5:7',
    variants: [
      for (final icon in MonetaIconName.values)
        GalleryVariant('icon/${icon.figmaName}', (_) => MonetaIcon(icon)),
    ],
  ),
];
