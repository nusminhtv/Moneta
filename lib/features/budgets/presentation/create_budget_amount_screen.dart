import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/spend_category.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/molecules/amount_input.dart';
import 'package:moneta/design_system/molecules/category_icon.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/moneta_segmented_control.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/budgets/domain/budget_period.dart';
import 'package:moneta/features/budgets/presentation/budget_step_indicator.dart';

/// Step 2 of the budget wizard — Figma `66:488`.
///
/// Annotation `04.04`: *"The helper line under the amount gives the user their
/// own 3-month average, which is the only number that makes a limit
/// meaningful."*
///
/// **The amount is typed into a hidden field behind [AmountInput].** Figma
/// pairs the hero amount with `Numpad` (`36:92`), which this design system did
/// not have when this screen shipped. Shipping without either would have
/// repeated a bug this project already had once: a form demanding a value it
/// gives no way to enter. `Numpad` **exists now** (`settings-components`), so
/// this screen could be rewired to it; that is deferred work rather than a
/// missing component, and is recorded in `docs/design-system/figma-map.md`.
/// The same hidden-`EditableText` composition is already used and tested by the
/// OTP screen, so it is a pattern here rather than an invention.
class CreateBudgetAmountScreen extends StatefulWidget {
  /// Creates step 2.
  const CreateBudgetAmountScreen({
    required this.category,
    required this.amount,
    required this.period,
    required this.startsOn,
    required this.rollsOver,
    required this.alertThreshold,
    this.threeMonthAverage,
    this.errorText,
    this.onPeriodChanged,
    this.onEditStart,
    this.onToggleRollover,
    this.onEditThreshold,
    this.onBack,
    this.onSubmit,
    this.onAmountChanged,
    super.key,
  });

  /// The category chosen in step 1.
  final SpendCategory category;

  /// The limit being entered.
  final Money amount;

  /// How often it resets.
  final BudgetPeriod period;

  /// The anchor date — `66:535`'s "Starts".
  final DateTime startsOn;

  /// `66:562`'s "Rolls over unused".
  final bool rollsOver;

  /// `66:584`'s "Alert me at", as a ratio.
  final double alertThreshold;

  /// The user's own average spend in this category over three months.
  ///
  /// Null when there is not enough history. Showing a made-up average would be
  /// worse than showing none: the annotation calls this "the only number that
  /// makes a limit meaningful", and a wrong one makes a wrong limit.
  final Money? threeMonthAverage;

  /// When non-null the amount is in its error state and this is the message.
  final String? errorText;

  /// Called with the newly selected period.
  final ValueChanged<BudgetPeriod>? onPeriodChanged;

  /// Called when the start date row is activated.
  final VoidCallback? onEditStart;

  /// Called when the rollover row is activated.
  final VoidCallback? onToggleRollover;

  /// Called when the alert row is activated.
  final VoidCallback? onEditThreshold;

  /// Called from the app bar and the secondary action.
  final VoidCallback? onBack;

  /// Called to create the budget. Null disables the primary action.
  final VoidCallback? onSubmit;

  /// Called as the amount is typed.
  final ValueChanged<Money>? onAmountChanged;

  /// Key on the hidden input, so a test can type into it without hunting.
  static const Key amountInputKey = Key('CreateBudgetAmountScreen.input');

  /// The helper line under the amount.
  static String helperFor(Money? average) => average == null
      ? 'Set a limit you could actually keep to.'
      : 'You averaged ${average.format()} a month here over the last '
            '3 months.';

  /// The "Starts" row's value.
  static String startLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  @override
  State<CreateBudgetAmountScreen> createState() =>
      _CreateBudgetAmountScreenState();
}

class _CreateBudgetAmountScreenState extends State<CreateBudgetAmountScreen> {
  late final TextEditingController _digits = TextEditingController(
    text: widget.amount.minorUnits == 0
        ? ''
        : widget.amount.minorUnits.toString(),
  );
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _digits.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTyped(String raw) {
    // Digits only. A minus sign or a decimal point in a minor-unit field is a
    // parse failure waiting to happen, and the domain refuses both anyway.
    final cleaned = raw.replaceAll(RegExp('[^0-9]'), '');
    if (cleaned != raw) {
      _digits.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
    }
    widget.onAmountChanged?.call(
      Money(int.tryParse(cleaned) ?? 0, widget.amount.currency),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonetaAppBar(
            title: 'New budget',
            variant: MonetaAppBarVariant.titleBack,
            onBack: widget.onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                MonetaSpacing.spaceLg,
                MonetaSpacing.spaceXs,
                MonetaSpacing.spaceLg,
                MonetaSpacing.spaceBase,
              ),
              children: [
                const BudgetStepIndicator(step: 2),
                const SizedBox(height: MonetaSpacing.spaceBase),
                Text(
                  'Step 2 of 2',
                  style: theme.text.labelSm.copyWith(
                    color: theme.colors.textTertiary,
                  ),
                ),
                const SizedBox(height: MonetaSpacing.spaceMd),
                Row(
                  children: [
                    CategoryIcon(
                      category: widget.category,
                      showLabelForAccessibility: false,
                    ),
                    const SizedBox(width: MonetaSpacing.spaceSm),
                    Expanded(
                      child: Text(
                        widget.category.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text.headingH3.copyWith(
                          color: theme.colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                // The hero amount, with the field that actually receives the
                // keystrokes hidden behind it. Tapping anywhere on the figure
                // focuses the field, so the caret the design draws is where
                // typing appears to happen.
                GestureDetector(
                  onTap: _focus.requestFocus,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (widget.errorText case final message?)
                        AmountInput.error(
                          amount: widget.amount,
                          message: message,
                        )
                      else
                        AmountInput(
                          amount: widget.amount,
                          helper: CreateBudgetAmountScreen.helperFor(
                            widget.threeMonthAverage,
                          ),
                        ),
                      // Sized to nothing and painted in the canvas colour: it
                      // must be in the tree to take focus and raise the
                      // keyboard, and must not be seen. `Offstage` would take
                      // it out of the tree and it could never focus — the exact
                      // mistake the OTP screen shipped first.
                      SizedBox(
                        width: MonetaLayout.borderWidthHairline,
                        height: MonetaLayout.borderWidthHairline,
                        child: EditableText(
                          key: CreateBudgetAmountScreen.amountInputKey,
                          controller: _digits,
                          focusNode: _focus,
                          style: theme.text.captionMd.copyWith(
                            color: theme.colors.canvas,
                          ),
                          cursorColor: theme.colors.canvas,
                          backgroundCursorColor: theme.colors.canvas,
                          keyboardType: TextInputType.number,
                          onChanged: _onTyped,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Period',
                  style: theme.text.labelSm.copyWith(
                    color: theme.colors.textTertiary,
                  ),
                ),
                const SizedBox(height: MonetaSpacing.spaceSm),
                MonetaSegmentedControl(
                  labels: [for (final p in BudgetPeriod.values) p.label],
                  selectedIndex: BudgetPeriod.values.indexOf(widget.period),
                  onChanged: widget.onPeriodChanged == null
                      ? null
                      : (i) => widget.onPeriodChanged!(BudgetPeriod.values[i]),
                ),
                const SizedBox(height: MonetaSpacing.spaceBase),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colors.surfaceRaised,
                    borderRadius: theme.radii.borderLg,
                    border: Border.all(color: theme.colors.borderSubtle),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MonetaSpacing.spaceBase,
                      vertical: MonetaSpacing.space2xs,
                    ),
                    child: Column(
                      children: [
                        ListRow(
                          title: 'Starts',
                          accessory: ListRowAccessory.value,
                          value: CreateBudgetAmountScreen.startLabel(
                            widget.startsOn,
                          ),
                          onTap: widget.onEditStart,
                        ),
                        ListRow(
                          title: 'Rolls over unused',
                          accessory: ListRowAccessory.value,
                          value: widget.rollsOver ? 'Yes' : 'No',
                          onTap: widget.onToggleRollover,
                        ),
                        ListRow(
                          title: 'Alert me at',
                          accessory: ListRowAccessory.value,
                          value: '${(widget.alertThreshold * 100).round()}%',
                          onTap: widget.onEditThreshold,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MonetaSpacing.spaceLg,
              MonetaSpacing.space0,
              MonetaSpacing.spaceLg,
              MonetaSpacing.spaceBase,
            ),
            child: Row(
              children: [
                Expanded(
                  child: MonetaButton(
                    label: 'Back',
                    style: MonetaButtonStyle.secondary,
                    size: MonetaButtonSize.lg,
                    expand: true,
                    onPressed: widget.onBack,
                  ),
                ),
                const SizedBox(width: MonetaSpacing.spaceSm),
                Expanded(
                  child: MonetaButton(
                    label: 'Create budget',
                    size: MonetaButtonSize.lg,
                    expand: true,
                    onPressed: widget.onSubmit,
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
