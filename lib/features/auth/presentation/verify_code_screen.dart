import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/molecules/moneta_otp_field.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/auth/domain/credentials.dart';
import 'package:moneta/features/auth/presentation/auth_scaffold.dart';

/// `01.07 OTP verification`, from Figma node `73:349`.
///
/// The keypad is the system keyboard: the code field is driven by a hidden
/// input rather than a bespoke numpad, so paste, autofill and the
/// one-time-code suggestion above the keyboard all work. A custom numpad would
/// look closer to a mockup and break all three.
class VerifyCodeScreen extends StatefulWidget {
  /// Creates the verification screen.
  const VerifyCodeScreen({
    required this.email,
    required this.onSubmit,
    required this.onBack,
    required this.onResend,
    this.codeLength = MonetaOtpField.defaultLength,
    this.submitting = false,
    this.errorText,
    super.key,
  });

  /// Where the code was sent, shown so a typo in the address is visible here.
  final String email;

  /// Called with a complete code.
  final ValueChanged<String> onSubmit;

  /// Called from the app bar's back control.
  final VoidCallback onBack;

  /// Called from "Resend code".
  final VoidCallback onResend;

  /// How many digits the code has.
  final int codeLength;

  /// Whether a submission is in flight.
  final bool submitting;

  /// A failure to show under the field.
  final String? errorText;

  /// Identifies the hidden input in tests.
  static const Key inputKey = ValueKey('verifyCode.input');

  /// Identifies the primary action in tests.
  static const Key submitKey = ValueKey('verifyCode.submit');

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _complete =>
      Credentials.isCompleteCode(_code.text, widget.codeLength);

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return AuthScaffold(
      title: 'Verify',
      onBack: widget.onBack,
      children: [
        AuthHeading(
          title: 'Enter the code',
          subtitle: 'We sent ${widget.codeLength} digits to ${widget.email}.',
        ),
        const SizedBox(height: MonetaSpacing.spaceXl),
        // The real input sits *underneath* the boxes, full size, so tapping
        // anywhere focuses it and the system keyboard drives it — which is what
        // makes paste, autofill and the one-time-code suggestion work.
        //
        // It was `Offstage` at first. That hides a widget from layout entirely:
        // it cannot take focus, so the keyboard never appeared, and no test
        // could find it either. The boxes are opaque, so the input is invisible
        // without being absent.
        SizedBox(
          height: MonetaOtpField.boxHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: EditableText(
                  key: VerifyCodeScreen.inputKey,
                  controller: _code,
                  focusNode: _focus,
                  style: theme.text.bodyLg.copyWith(
                    color: theme.colors.canvas,
                  ),
                  cursorColor: theme.colors.brand,
                  backgroundCursorColor: theme.colors.track,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.length > widget.codeLength) {
                      _code.text = value.substring(0, widget.codeLength);
                    }
                  },
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: MonetaOtpField(
                    code: _code.text,
                    length: widget.codeLength,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: MonetaSpacing.spaceMd),
          Text(
            widget.errorText!,
            style: theme.text.captionMd.copyWith(color: theme.colors.expense),
          ),
        ],
        const SizedBox(height: MonetaSpacing.spaceXl),
        MonetaButton(
          key: VerifyCodeScreen.submitKey,
          label: 'Verify',
          size: MonetaButtonSize.lg,
          expand: true,
          state: widget.submitting
              ? MonetaButtonState.loading
              : (_complete
                    ? MonetaButtonState.normal
                    : MonetaButtonState.disabled),
          onPressed: _complete ? () => widget.onSubmit(_code.text) : null,
        ),
        const SizedBox(height: MonetaSpacing.spaceMd),
        Center(
          child: MonetaButton(
            label: 'Resend code',
            style: MonetaButtonStyle.ghost,
            onPressed: widget.onResend,
          ),
        ),
      ],
    );
  }
}
