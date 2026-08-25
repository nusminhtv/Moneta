import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/category_icon.dart';
import 'package:moneta/design_system/molecules/onboarding_illustration.dart';
import 'package:moneta/design_system/molecules/pagination_dots.dart';
import 'package:moneta/design_system/molecules/progress_bar.dart';
import 'package:moneta/design_system/molecules/transaction_row.dart';
import 'package:moneta/design_system/organisms/balance_card.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';
import 'package:moneta/design_system/organisms/budget_card.dart';
import 'package:moneta/features/transactions/domain/transaction.dart';

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
    component: 'Button',
    figmaNodeId: '13:2',
    // All 45. The gallery is where the 5 × 3 × 3 matrix is actually looked at:
    // every one of these was implemented and none was ever rendered here, so a
    // wrong foreground or label style was invisible to a reviewer as well as to
    // the suite.
    variants: [
      for (final style in MonetaButtonStyle.values)
        for (final size in MonetaButtonSize.values)
          for (final state in MonetaButtonState.values)
            GalleryVariant(
              'Style=${style.name}, Size=${size.name}, State=${state.name}',
              (_) => MonetaButton(
                label: 'Continue',
                style: style,
                size: size,
                state: state,
                onPressed: () {},
              ),
            ),
    ],
  ),
  GallerySection(
    component: 'PaginationDots',
    figmaNodeId: '70:223',
    variants: [
      for (var active = 0; active < 3; active++)
        GalleryVariant(
          'Count=3, Active=${active + 1}',
          (_) => MonetaPaginationDots(count: 3, activeIndex: active),
        ),
    ],
  ),
  GallerySection(
    component: 'OnboardingIllustration',
    figmaNodeId: '71:59',
    // One per slide, because the chart slot is the only thing that varies and
    // the slots are what a reviewer needs to compare against the frames.
    variants: [
      GalleryVariant(
        'Slot=4, Glyph=credit-card (accounts)',
        (_) => const OnboardingIllustration(
          glyph: MonetaIconName.creditCard,
          chartSlot: 4,
        ),
      ),
      GalleryVariant(
        'Slot=1, Glyph=target (budgets)',
        (_) => const OnboardingIllustration(
          glyph: MonetaIconName.target,
          chartSlot: 1,
        ),
      ),
      GalleryVariant(
        'Slot=2, Glyph=award (goals)',
        (_) => const OnboardingIllustration(
          glyph: MonetaIconName.award,
          chartSlot: 2,
        ),
      ),
    ],
  ),
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
  GallerySection(
    component: 'TransactionRow',
    figmaNodeId: '29:70',
    // Only the two directions the widget implements. Figma 29:70 also authors
    // Transfer and Pending, which this codebase has no domain concept for yet —
    // recorded in figma-map.md rather than faked with a placeholder here.
    variants: [
      GalleryVariant(
        'Direction=Expense',
        (_) => TransactionRow(
          title: 'Highlands Coffee',
          amount: const Money(45000, _vnd),
          direction: TransactionDirection.expense,
          category: SpendCategory.food,
          occurredAt: DateTime.utc(2026, 8, 24, 2, 15),
        ),
      ),
      GalleryVariant(
        'Direction=Income',
        (_) => TransactionRow(
          title: 'Salary',
          amount: _income,
          direction: TransactionDirection.income,
          category: SpendCategory.salary,
          occurredAt: DateTime.utc(2026, 8, 24, 1),
        ),
      ),
    ],
  ),
];
