import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_badge.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/settings/domain/premium_plan.dart';

/// 08.10 — the only commercial screen in the app.
///
/// From Figma node `102:1044`. Annotation `102:1176`: *"Price first, then a
/// comparison the user can check rather than a wall of marketing claims."*
///
/// **Nothing is purchasable.** There is no purchase plumbing in this app, and
/// the call to action says so rather than doing nothing when pressed. A paywall
/// whose button silently fails is worse than one that admits what it cannot do,
/// and one that appears to take money is worse than both.
class PremiumScreen extends StatefulWidget {
  /// Creates the screen.
  const PremiumScreen({this.onClose, this.onPurchaseAttempt, super.key});

  /// Leaves the screen. `102:1179`: the app bar's action is "swapped to x".
  final VoidCallback? onClose;

  /// Called when the call to action is pressed, with the chosen plan.
  ///
  /// It is the caller's job to say that purchases are unavailable — the screen
  /// does not know how this app reports things.
  final ValueChanged<PremiumPlan>? onPurchaseAttempt;

  /// Content inset, from `102:1067`'s x within `102:1066`.
  static const double horizontalInset = MonetaSpacing.spaceLg;

  /// Gap between the three plan cards, from `102:1076`'s x: 8.
  static const double planGap = MonetaSpacing.spaceSm;

  /// A plan card's inner padding, from `102:1073`.
  static const double planPadding = MonetaSpacing.spaceSm;

  /// The unselected cards' height, from `102:1072`: 80.
  static const double planHeight = 80;

  /// The selected card's height, from `102:1076`: 106 — it carries the badge.
  static const double selectedPlanHeight = 106;

  /// A comparison row's height, from `102:1101`: 36.
  static const double comparisonRowHeight = 36;

  /// The key for a plan's card, so a test can tap and measure one.
  static Key planKey(PremiumPeriod period) =>
      ValueKey('PremiumScreen.plan.${period.name}');

  /// The key for the glyph saying whether [feature] is in the free tier.
  static Key freeGlyphKey(PremiumFeature feature) =>
      ValueKey('PremiumScreen.free.${feature.name}');

  /// The key for the glyph saying whether [feature] is in premium.
  static Key premiumGlyphKey(PremiumFeature feature) =>
      ValueKey('PremiumScreen.premium.${feature.name}');

  /// Key on the call to action.
  static const Key ctaKey = Key('PremiumScreen.cta');

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  /// `102:1182`: *"Yearly preselected."*
  PremiumPeriod _selected = PremiumPeriod.yearly;

  PremiumPlan get _plan =>
      premiumPlans.firstWhere((p) => p.period == _selected);

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final monthly = premiumPlans
        .firstWhere((p) => p.period == PremiumPeriod.monthly)
        .price;
    final yearly = premiumPlans
        .firstWhere((p) => p.period == PremiumPeriod.yearly)
        .price;
    final saving = yearlySavingPercent(monthly: monthly, yearly: yearly);

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        children: [
          MonetaAppBar(
            title: 'Premium',
            variant: MonetaAppBarVariant.titleBack,
            onBack: widget.onClose,
            actions: [
              (
                icon: MonetaIconName.x,
                semanticLabel: 'Close',
                onPressed: widget.onClose,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: PremiumScreen.horizontalInset,
                vertical: MonetaSpacing.spaceSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'MONETA PREMIUM',
                    style: theme.text.labelSm.copyWith(
                      color: theme.colors.brandOnSurface,
                    ),
                  ),
                  const SizedBox(height: MonetaSpacing.spaceXs),
                  Text(
                    'Everything, with nothing held back',
                    style: theme.text.headingH1.copyWith(
                      color: theme.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: MonetaSpacing.spaceSm),
                  Text(
                    'One payment or one subscription. Your data stays on this '
                    'device either way.',
                    style: theme.text.bodyMd.copyWith(
                      color: theme.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: MonetaSpacing.spaceBase),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final plan in premiumPlans) ...[
                        if (plan != premiumPlans.first)
                          const SizedBox(width: PremiumScreen.planGap),
                        Expanded(
                          child: _PlanCard(
                            key: PremiumScreen.planKey(plan.period),
                            plan: plan,
                            selected: plan.period == _selected,
                            savingPercent: plan.period == PremiumPeriod.yearly
                                ? saving
                                : null,
                            onTap: () =>
                                setState(() => _selected = plan.period),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: MonetaSpacing.spaceBase),
                  const SectionHeader(title: 'Free against Premium'),
                  const SizedBox(height: MonetaSpacing.spaceXs),
                  _ComparisonTable(),
                  const SizedBox(height: MonetaSpacing.space2xl),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PremiumScreen.horizontalInset,
              MonetaSpacing.spaceMd,
              PremiumScreen.horizontalInset,
              MonetaSpacing.spaceLg,
            ),
            child: Column(
              children: [
                MonetaButton(
                  key: PremiumScreen.ctaKey,
                  label: 'Continue with ${_plan.period.label.toLowerCase()}',
                  size: MonetaButtonSize.lg,
                  expand: true,
                  onPressed: widget.onPurchaseAttempt == null
                      ? null
                      : () => widget.onPurchaseAttempt!(_plan),
                ),
                const SizedBox(height: MonetaSpacing.spaceSm),
                Text(
                  'Purchases are not available in this build.',
                  textAlign: TextAlign.center,
                  style: theme.text.captionMd.copyWith(
                    color: theme.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the three plan cards.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.savingPercent,
    required this.onTap,
    super.key,
  });

  final PremiumPlan plan;
  final bool selected;
  final int? savingPercent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return Semantics(
      button: true,
      selected: selected,
      label: '${plan.period.label}, ${plan.price.format()}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? theme.colors.brandSubtle
                : theme.colors.surfaceRaised,
            borderRadius: theme.radii.borderLg,
            border: Border.all(
              color: selected ? theme.colors.brand : theme.colors.borderSubtle,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PremiumScreen.planPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (savingPercent != null) ...[
                  MonetaBadge(
                    label: 'SAVE $savingPercent%',
                    tone: MonetaBadgeTone.success,
                    dot: false,
                  ),
                  const SizedBox(height: MonetaSpacing.spaceXs),
                ],
                Text(
                  plan.period.label,
                  style: theme.text.labelSm.copyWith(
                    color: theme.colors.textTertiary,
                  ),
                ),
                const SizedBox(height: MonetaSpacing.space2xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    plan.price.format(),
                    maxLines: 1,
                    style: theme.text.titleMd.copyWith(
                      color: selected
                          ? theme.colors.brandOnSurface
                          : theme.colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: MonetaSpacing.space2xs),
                Text(
                  plan.period.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.captionMd.copyWith(
                    color: theme.colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `102:1096` — what each tier has.
class _ComparisonTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    Widget glyph({required bool present, required Key key}) => MonetaIcon(
      present ? MonetaIconName.check : MonetaIconName.x,
      key: key,
      size: MonetaSpacing.spaceLg,
      // `102:1188`: "the negatives are not expense/base — the free tier is not
      // an error." Absence is a fact about a tier, not a fault.
      color: present ? theme.colors.income : theme.colors.textDisabled,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: theme.radii.borderLg,
        border: Border.all(color: theme.colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MonetaSpacing.spaceMd),
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                SizedBox(
                  width: MonetaSpacing.space4xl,
                  child: Text(
                    'Free',
                    textAlign: TextAlign.center,
                    style: theme.text.labelSm.copyWith(
                      color: theme.colors.textTertiary,
                    ),
                  ),
                ),
                SizedBox(
                  width: MonetaSpacing.space4xl,
                  child: Text(
                    'Premium',
                    textAlign: TextAlign.center,
                    style: theme.text.labelSm.copyWith(
                      color: theme.colors.brandOnSurface,
                    ),
                  ),
                ),
              ],
            ),
            for (final feature in PremiumFeature.values)
              SizedBox(
                height: PremiumScreen.comparisonRowHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        feature.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text.bodyMd.copyWith(
                          color: theme.colors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MonetaSpacing.space4xl,
                      child: Center(
                        child: glyph(
                          present: feature.inFree,
                          key: PremiumScreen.freeGlyphKey(feature),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MonetaSpacing.space4xl,
                      child: Center(
                        child: glyph(
                          present: true,
                          key: PremiumScreen.premiumGlyphKey(feature),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
