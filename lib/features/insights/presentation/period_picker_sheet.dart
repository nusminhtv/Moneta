import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/molecules/moneta_radio_row.dart';
import 'package:moneta/design_system/organisms/bottom_sheet.dart';
import 'package:moneta/features/insights/domain/insights_period.dart';

/// 07.05 — the period picker, as a bottom sheet of radio options.
///
/// From Figma node `81:508`. The sheet is a plain widget by design, so the
/// **screen** presents it and draws the scrim — exactly as `81:525` draws the
/// scrim as a sibling of the sheet rather than part of it.
class PeriodPickerSheet extends StatelessWidget {
  /// Creates the sheet's content.
  const PeriodPickerSheet({
    required this.selected,
    required this.onSelected,
    this.onClose,
    super.key,
  });

  /// The active period, which reads as the selected option.
  final InsightsPeriod selected;

  /// Called with the period chosen.
  final ValueChanged<InsightsPeriod> onSelected;

  /// Closes without choosing.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return MonetaBottomSheet(
      title: 'Period',
      closeSemanticLabel: 'Close the period picker',
      onClose: onClose,
      child: MonetaRadioGroup<InsightsPeriod>(
        options: [
          for (final period in InsightsPeriod.values)
            MonetaRadioOption(
              value: period,
              title: period.longLabel,
              supporting: period.months == 1
                  ? 'The month so far'
                  : '${period.months} months to now',
            ),
        ],
        selected: selected,
        onChanged: onSelected,
      ),
    );
  }
}
