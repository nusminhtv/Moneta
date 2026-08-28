import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/auth/presentation/auth_scaffold.dart';

/// `01.09 Reset password — success`, from Figma node `75:270`.
class ResetSuccessScreen extends StatelessWidget {
  /// Creates the success screen.
  const ResetSuccessScreen({required this.onContinue, super.key});

  /// Called from the only action on the screen.
  final VoidCallback onContinue;

  /// Identifies the action in tests.
  static const Key continueKey = ValueKey('resetSuccess.continue');

  /// Diameter of the confirmation disc.
  static const double discSize = 96;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return AuthScaffold(
      children: [
        const SizedBox(height: MonetaSpacing.space5xl),
        Center(
          child: SizedBox.square(
            dimension: discSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colors.incomeSubtle,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colors.income),
              ),
              child: Center(
                child: MonetaIcon(
                  MonetaIconName.check,
                  size: MonetaSpacing.space2xl,
                  color: theme.colors.income,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: MonetaSpacing.spaceXl),
        Text(
          'Password updated',
          textAlign: TextAlign.center,
          style: theme.text.headingH1.copyWith(color: theme.colors.textPrimary),
        ),
        const SizedBox(height: MonetaSpacing.spaceSm),
        Text(
          'You can log in with your new password.',
          textAlign: TextAlign.center,
          style: theme.text.bodyMd.copyWith(color: theme.colors.textSecondary),
        ),
        const SizedBox(height: MonetaSpacing.space4xl),
        MonetaButton(
          key: ResetSuccessScreen.continueKey,
          label: 'Back to log in',
          size: MonetaButtonSize.lg,
          expand: true,
          onPressed: onContinue,
        ),
      ],
    );
  }
}
