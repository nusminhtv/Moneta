import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/atoms/moneta_logo.dart';
import 'package:moneta/design_system/molecules/moneta_text_field.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/auth/domain/credentials.dart';
import 'package:moneta/features/auth/presentation/auth_scaffold.dart';

/// `01.06 Log in`, from Figma node `73:223`.
class LogInScreen extends StatefulWidget {
  /// Creates the log-in screen.
  const LogInScreen({
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onCreateAccount,
    this.onBiometric,
    this.submitting = false,
    this.errorText,
    super.key,
  });

  /// Called with a validated email and password.
  final void Function(String email, String password) onSubmit;

  /// Called from "Forgot password?".
  final VoidCallback onForgotPassword;

  /// Called from the footer link.
  final VoidCallback onCreateAccount;

  /// Called from the Face ID affordance. Omitted when biometrics are off.
  final VoidCallback? onBiometric;

  /// Whether a submission is in flight.
  final bool submitting;

  /// A failure to show above the form.
  final String? errorText;

  /// Identifies the primary action in tests.
  static const Key submitKey = ValueKey('logIn.submit');

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _showErrors = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _showErrors = true);
    final emailError = Credentials.emailError(_email.text);
    final passwordError = Credentials.passwordError(_password.text);
    if (emailError != null || passwordError != null) return;
    widget.onSubmit(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return AuthScaffold(
      children: [
        const MonetaLogo(showWordmark: false),
        const SizedBox(height: MonetaSpacing.spaceMd),
        const AuthHeading(
          title: 'Welcome back',
          subtitle: 'Log in to pick up where you left off.',
        ),
        const SizedBox(height: MonetaSpacing.spaceMd),
        MonetaTextField(
          controller: _email,
          label: 'Email',
          placeholder: 'you@example.com',
          leadingIcon: MonetaIconName.mail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: _showErrors ? Credentials.emailError(_email.text) : null,
        ),
        const SizedBox(height: MonetaSpacing.spaceMd),
        MonetaTextField(
          controller: _password,
          label: 'Password',
          leadingIcon: MonetaIconName.lock,
          trailingIcon: _obscure ? MonetaIconName.eye : MonetaIconName.eyeOff,
          onTrailingIconPressed: () => setState(() => _obscure = !_obscure),
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          errorText: _showErrors
              ? Credentials.passwordError(_password.text)
              : null,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: MonetaButton(
            label: 'Forgot password?',
            style: MonetaButtonStyle.ghost,
            onPressed: widget.onForgotPassword,
          ),
        ),
        if (widget.errorText != null) ...[
          Text(
            widget.errorText!,
            style: theme.text.captionMd.copyWith(color: theme.colors.expense),
          ),
          const SizedBox(height: MonetaSpacing.spaceSm),
        ],
        MonetaButton(
          key: LogInScreen.submitKey,
          label: 'Log in',
          size: MonetaButtonSize.lg,
          expand: true,
          state: widget.submitting
              ? MonetaButtonState.loading
              : MonetaButtonState.normal,
          onPressed: _submit,
        ),
        if (widget.onBiometric != null) ...[
          const SizedBox(height: MonetaSpacing.spaceXl),
          Center(
            child: Column(
              children: [
                MonetaIconButton(
                  icon: MonetaIconName.scanFace,
                  semanticLabel: 'Log in with Face ID',
                  style: MonetaIconButtonStyle.tonal,
                  size: MonetaIconButtonSize.lg,
                  onPressed: widget.onBiometric,
                ),
                const SizedBox(height: MonetaSpacing.spaceSm),
                Text(
                  'Use Face ID',
                  style: theme.text.labelMd.copyWith(
                    color: theme.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: MonetaSpacing.spaceXl),
        AuthFooterLink(
          prompt: 'New to Moneta?',
          actionLabel: 'Create an account',
          onPressed: widget.onCreateAccount,
        ),
      ],
    );
  }
}
