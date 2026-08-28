import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_checkbox.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/atoms/moneta_logo.dart';
import 'package:moneta/design_system/molecules/moneta_text_field.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/auth/domain/credentials.dart';
import 'package:moneta/features/auth/presentation/auth_scaffold.dart';

/// `01.05 Sign up`, from Figma node `73:68`.
class SignUpScreen extends StatefulWidget {
  /// Creates the sign-up screen.
  const SignUpScreen({
    required this.onSubmit,
    required this.onLogIn,
    this.submitting = false,
    this.errorText,
    super.key,
  });

  /// Called with a validated email and password.
  final void Function(String email, String password) onSubmit;

  /// Called from the footer link.
  final VoidCallback onLogIn;

  /// Whether a submission is in flight.
  final bool submitting;

  /// A failure to show above the action.
  final String? errorText;

  /// Identifies the primary action in tests.
  static const Key submitKey = ValueKey('signUp.submit');

  /// Identifies the terms checkbox in tests.
  static const Key termsKey = ValueKey('signUp.terms');

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _accepted = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _showErrors = true);
    if (!_accepted) return;
    if (Credentials.emailError(_email.text) != null) return;
    if (Credentials.passwordError(_password.text) != null) return;
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
          title: 'Create your account',
          subtitle: 'Track every account in one place.',
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
          helper: 'At least ${Credentials.minPasswordLength} characters',
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
        const SizedBox(height: MonetaSpacing.spaceMd),
        Row(
          children: [
            MonetaCheckbox(
              key: SignUpScreen.termsKey,
              state: _accepted
                  ? MonetaCheckboxState.checked
                  : MonetaCheckboxState.unchecked,
              semanticLabel: 'Accept the terms and privacy policy',
              onChanged: (next) => setState(
                () => _accepted = next == MonetaCheckboxState.checked,
              ),
            ),
            Expanded(
              child: Text(
                'I agree to the Terms and the Privacy Policy.',
                style: theme.text.bodyMd.copyWith(
                  color: theme.colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        if (_showErrors && !_accepted) ...[
          const SizedBox(height: MonetaSpacing.spaceXs),
          Text(
            'Accept the terms to continue',
            style: theme.text.captionMd.copyWith(color: theme.colors.expense),
          ),
        ],
        if (widget.errorText != null) ...[
          const SizedBox(height: MonetaSpacing.spaceSm),
          Text(
            widget.errorText!,
            style: theme.text.captionMd.copyWith(color: theme.colors.expense),
          ),
        ],
        const SizedBox(height: MonetaSpacing.spaceBase),
        MonetaButton(
          key: SignUpScreen.submitKey,
          label: 'Create account',
          size: MonetaButtonSize.lg,
          expand: true,
          state: widget.submitting
              ? MonetaButtonState.loading
              : MonetaButtonState.normal,
          onPressed: _submit,
        ),
        const SizedBox(height: MonetaSpacing.spaceXl),
        AuthFooterLink(
          prompt: 'Already have an account?',
          actionLabel: 'Log in',
          onPressed: widget.onLogIn,
        ),
      ],
    );
  }
}
