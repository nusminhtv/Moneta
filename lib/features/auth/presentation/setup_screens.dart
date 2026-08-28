import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/moneta_select.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/auth/presentation/auth_scaffold.dart';

/// One account type the wallet can hold, for `01.12`.
typedef AccountKind = ({MonetaIconName icon, String label, String subtitle});

/// `01.10 Setup — currency and country`, from Figma node `75:325`.
class SetupCurrencyScreen extends StatelessWidget {
  /// Creates the currency setup screen.
  const SetupCurrencyScreen({
    required this.currency,
    required this.country,
    required this.onPickCurrency,
    required this.onPickCountry,
    required this.onContinue,
    required this.onBack,
    super.key,
  });

  /// The chosen currency, or null before a choice is made.
  final Currency? currency;

  /// The chosen country, or null before a choice is made.
  final String? country;

  /// Opens the currency picker. The screen presents it, not the control.
  final VoidCallback onPickCurrency;

  /// Opens the country picker.
  final VoidCallback onPickCountry;

  /// Called when both are chosen and the user continues.
  final VoidCallback onContinue;

  /// Called from the app bar's back control.
  final VoidCallback onBack;

  /// Identifies the primary action in tests.
  static const Key continueKey = ValueKey('setupCurrency.continue');

  /// Whether the screen has everything it needs.
  bool get isComplete => currency != null && country != null;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Set up',
      onBack: onBack,
      children: [
        const AuthHeading(
          title: 'Where do you spend?',
          subtitle: 'This sets how amounts are written throughout the app.',
        ),
        const SizedBox(height: MonetaSpacing.spaceBase),
        const SectionHeader(title: 'Currency'),
        MonetaSelect<Currency>(
          value: currency,
          labelOf: (c) => '${c.code} — ${c.symbol}',
          placeholder: 'Select a currency',
          onTap: onPickCurrency,
        ),
        const SizedBox(height: MonetaSpacing.spaceBase),
        const SectionHeader(title: 'Country'),
        MonetaSelect<String>(
          value: country,
          labelOf: (c) => c,
          placeholder: 'Select a country',
          onTap: onPickCountry,
        ),
        const SizedBox(height: MonetaSpacing.space2xl),
        MonetaButton(
          key: SetupCurrencyScreen.continueKey,
          label: 'Continue',
          size: MonetaButtonSize.lg,
          expand: true,
          state: isComplete
              ? MonetaButtonState.normal
              : MonetaButtonState.disabled,
          onPressed: isComplete ? onContinue : null,
        ),
      ],
    );
  }
}

/// `01.11 Setup — enable Face ID`, from Figma node `75:467`.
class SetupBiometricScreen extends StatelessWidget {
  /// Creates the biometric setup screen.
  const SetupBiometricScreen({
    required this.onEnable,
    required this.onSkip,
    super.key,
  });

  /// Called when the user opts in.
  final VoidCallback onEnable;

  /// Called when the user declines. Declining is a first-class choice, not a
  /// dismissal — the screen offers it as plainly as it offers enabling.
  final VoidCallback onSkip;

  /// Identifies the primary action in tests.
  static const Key enableKey = ValueKey('setupBiometric.enable');

  /// Identifies the decline action in tests.
  static const Key skipKey = ValueKey('setupBiometric.skip');

  /// Diameter of the illustration disc.
  static const double discSize = 96;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return AuthScaffold(
      children: [
        const SizedBox(height: MonetaSpacing.space4xl),
        Center(
          child: SizedBox.square(
            dimension: discSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colors.surfaceRaised,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colors.borderStrong),
              ),
              child: Center(
                child: MonetaIcon(
                  MonetaIconName.scanFace,
                  size: MonetaSpacing.space2xl,
                  color: theme.colors.brandOnSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: MonetaSpacing.spaceXl),
        const AuthHeading(
          title: 'Unlock with Face ID',
          subtitle:
              'Your data never leaves this device. Face ID only decides who '
              'can open the app.',
        ),
        const SizedBox(height: MonetaSpacing.space4xl),
        MonetaButton(
          key: SetupBiometricScreen.enableKey,
          label: 'Enable Face ID',
          size: MonetaButtonSize.lg,
          expand: true,
          onPressed: onEnable,
        ),
        const SizedBox(height: MonetaSpacing.spaceSm),
        MonetaButton(
          key: SetupBiometricScreen.skipKey,
          label: 'Not now',
          style: MonetaButtonStyle.ghost,
          size: MonetaButtonSize.lg,
          expand: true,
          onPressed: onSkip,
        ),
      ],
    );
  }
}

/// `01.12 Setup — link first account`, from Figma node `75:516`.
class SetupLinkAccountScreen extends StatelessWidget {
  /// Creates the link-account screen.
  const SetupLinkAccountScreen({
    required this.kinds,
    required this.onPick,
    required this.onSkip,
    required this.onBack,
    super.key,
  });

  /// The account types offered.
  final List<AccountKind> kinds;

  /// Called with the chosen type.
  final ValueChanged<AccountKind> onPick;

  /// Called when the user defers. Skipping must stay possible: the app works
  /// with no account linked, and a setup step that cannot be skipped is a wall.
  final VoidCallback onSkip;

  /// Called from the app bar's back control.
  final VoidCallback onBack;

  /// Identifies the decline action in tests.
  static const Key skipKey = ValueKey('setupLink.skip');

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Set up',
      onBack: onBack,
      children: [
        const AuthHeading(
          title: 'Add your first account',
          subtitle: 'You can add more later, or skip and start with cash.',
        ),
        const SizedBox(height: MonetaSpacing.spaceBase),
        for (final kind in kinds)
          ListRow(
            title: kind.label,
            subtitle: kind.subtitle,
            leadingIcon: kind.icon,
            accessory: ListRowAccessory.chevron,
            onTap: () => onPick(kind),
          ),
        const SizedBox(height: MonetaSpacing.space2xl),
        MonetaButton(
          key: SetupLinkAccountScreen.skipKey,
          label: 'Skip for now',
          style: MonetaButtonStyle.ghost,
          size: MonetaButtonSize.lg,
          expand: true,
          onPressed: onSkip,
        ),
      ],
    );
  }
}
