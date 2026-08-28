import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/moneta_text_field.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/auth/domain/credentials.dart';
import 'package:moneta/features/auth/presentation/auth_scaffold.dart';

/// `01.08 Forgot password`, from Figma node `73:432`.
class ForgotPasswordScreen extends StatefulWidget {
  /// Creates the forgot-password screen.
  const ForgotPasswordScreen({
    required this.onSubmit,
    required this.onBack,
    this.submitting = false,
    super.key,
  });

  /// Called with a validated email.
  final ValueChanged<String> onSubmit;

  /// Called from the app bar's back control.
  final VoidCallback onBack;

  /// Whether a submission is in flight.
  final bool submitting;

  /// Identifies the primary action in tests.
  static const Key submitKey = ValueKey('forgotPassword.submit');

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _showErrors = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _showErrors = true);
    if (Credentials.emailError(_email.text) != null) return;
    widget.onSubmit(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Forgot password',
      onBack: widget.onBack,
      children: [
        const AuthHeading(
          title: 'Reset your password',
          subtitle: 'We will send a six-digit code to your email.',
        ),
        const SizedBox(height: MonetaSpacing.spaceXl),
        MonetaTextField(
          controller: _email,
          label: 'Email',
          placeholder: 'you@example.com',
          leadingIcon: MonetaIconName.mail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          errorText: _showErrors ? Credentials.emailError(_email.text) : null,
        ),
        const SizedBox(height: MonetaSpacing.spaceXl),
        MonetaButton(
          key: ForgotPasswordScreen.submitKey,
          label: 'Send code',
          size: MonetaButtonSize.lg,
          expand: true,
          state: widget.submitting
              ? MonetaButtonState.loading
              : MonetaButtonState.normal,
          onPressed: _submit,
        ),
      ],
    );
  }
}
