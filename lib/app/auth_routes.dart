/// The `/auth` and `/setup` routes, and the flow that connects them.
///
/// Lives in `lib/app` because it is composition: the screens in
/// `features/auth/presentation` take callbacks and know nothing about routing,
/// so each is testable without a router.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/features/auth/data/local_auth_service.dart';
import 'package:moneta/features/auth/domain/auth_service.dart';
import 'package:moneta/features/auth/presentation/forgot_password_screen.dart';
import 'package:moneta/features/auth/presentation/log_in_screen.dart';
import 'package:moneta/features/auth/presentation/reset_success_screen.dart';
import 'package:moneta/features/auth/presentation/setup_screens.dart';
import 'package:moneta/features/auth/presentation/sign_up_screen.dart';
import 'package:moneta/features/auth/presentation/verify_code_screen.dart';

/// The app's auth service.
///
/// Overridable so a test can supply a service that fails, which is the only way
/// to exercise the screens' error paths.
final authServiceProvider = Provider<AuthService>(
  (ref) => const LocalAuthService(),
);

/// Paths for the auth flow.
abstract final class AuthRoutes {
  /// Create an account.
  static const String signUp = '/auth/sign-up';

  /// Sign in.
  static const String logIn = '/auth/log-in';

  /// Ask for a reset code.
  static const String forgotPassword = '/auth/forgot-password';

  /// Enter the code. Takes the address as a query parameter so a reload does
  /// not lose which address the code went to.
  static const String verify = '/auth/verify';

  /// Reset finished.
  static const String resetDone = '/auth/reset-done';

  /// Currency and country.
  static const String setupCurrency = '/setup/currency';

  /// Biometric opt-in.
  static const String setupBiometric = '/setup/biometric';

  /// First account.
  static const String setupAccount = '/setup/account';
}

/// The account types offered on `01.12`.
const List<AccountKind> accountKinds = [
  (
    icon: MonetaIconName.creditCard,
    label: 'Bank account',
    subtitle: 'Vietcombank, Techcombank, and others',
  ),
  (
    icon: MonetaIconName.smartphone,
    label: 'E-wallet',
    subtitle: 'MoMo, ZaloPay, ShopeePay',
  ),
  (
    icon: MonetaIconName.dollarSign,
    label: 'Cash',
    subtitle: 'Track what is in your pocket',
  ),
];

/// Runs [action] and routes on success, or shows its message on failure.
Future<void> _submit({
  required BuildContext context,
  required Future<Result<void>> Function() action,
  required void Function(String? error) setError,
  required VoidCallback onSuccess,
}) async {
  setError(null);
  final result = await action();
  if (!context.mounted) return;
  result.when(
    ok: (_) => onSuccess(),
    err: (failure) => setError(failure.message),
  );
}

/// Hosts [LogInScreen].
class LogInRoute extends ConsumerStatefulWidget {
  /// Creates the route.
  const LogInRoute({super.key});

  @override
  ConsumerState<LogInRoute> createState() => _LogInRouteState();
}

class _LogInRouteState extends ConsumerState<LogInRoute> {
  String? _error;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return LogInScreen(
      submitting: _busy,
      errorText: _error,
      onForgotPassword: () => context.push(AuthRoutes.forgotPassword),
      onCreateAccount: () => context.go(AuthRoutes.signUp),
      onSubmit: (email, password) async {
        setState(() => _busy = true);
        await _submit(
          context: context,
          action: () => ref
              .read(authServiceProvider)
              .logIn(email: email, password: password),
          setError: (e) => setState(() => _error = e),
          onSuccess: () => context.go(AuthRoutes.setupCurrency),
        );
        if (mounted) setState(() => _busy = false);
      },
    );
  }
}

/// Hosts [SignUpScreen].
class SignUpRoute extends ConsumerStatefulWidget {
  /// Creates the route.
  const SignUpRoute({super.key});

  @override
  ConsumerState<SignUpRoute> createState() => _SignUpRouteState();
}

class _SignUpRouteState extends ConsumerState<SignUpRoute> {
  String? _error;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return SignUpScreen(
      submitting: _busy,
      errorText: _error,
      onLogIn: () => context.go(AuthRoutes.logIn),
      onSubmit: (email, password) async {
        setState(() => _busy = true);
        await _submit(
          context: context,
          action: () => ref
              .read(authServiceProvider)
              .signUp(email: email, password: password),
          setError: (e) => setState(() => _error = e),
          onSuccess: () => context.go(AuthRoutes.setupCurrency),
        );
        if (mounted) setState(() => _busy = false);
      },
    );
  }
}

/// Hosts [ForgotPasswordScreen].
class ForgotPasswordRoute extends ConsumerStatefulWidget {
  /// Creates the route.
  const ForgotPasswordRoute({super.key});

  @override
  ConsumerState<ForgotPasswordRoute> createState() =>
      _ForgotPasswordRouteState();
}

class _ForgotPasswordRouteState extends ConsumerState<ForgotPasswordRoute> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordScreen(
      submitting: _busy,
      onBack: () => context.pop(),
      onSubmit: (email) async {
        setState(() => _busy = true);
        await _submit(
          context: context,
          action: () =>
              ref.read(authServiceProvider).requestPasswordReset(email: email),
          setError: (_) {},
          onSuccess: () => context.push(
            Uri(
              path: AuthRoutes.verify,
              queryParameters: {'email': email},
            ).toString(),
          ),
        );
        if (mounted) setState(() => _busy = false);
      },
    );
  }
}

/// Hosts [VerifyCodeScreen].
class VerifyCodeRoute extends ConsumerStatefulWidget {
  /// Creates the route.
  const VerifyCodeRoute({required this.email, super.key});

  /// Where the code was sent.
  final String email;

  @override
  ConsumerState<VerifyCodeRoute> createState() => _VerifyCodeRouteState();
}

class _VerifyCodeRouteState extends ConsumerState<VerifyCodeRoute> {
  String? _error;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final service = ref.read(authServiceProvider);
    return VerifyCodeScreen(
      email: widget.email,
      codeLength: service.codeLength,
      submitting: _busy,
      errorText: _error,
      onBack: () => context.pop(),
      onResend: () {},
      onSubmit: (code) async {
        setState(() => _busy = true);
        await _submit(
          context: context,
          action: () => service.confirmCode(code: code),
          setError: (e) => setState(() => _error = e),
          onSuccess: () => context.go(AuthRoutes.resetDone),
        );
        if (mounted) setState(() => _busy = false);
      },
    );
  }
}

/// Hosts [SetupCurrencyScreen].
class SetupCurrencyRoute extends StatefulWidget {
  /// Creates the route.
  const SetupCurrencyRoute({super.key});

  @override
  State<SetupCurrencyRoute> createState() => _SetupCurrencyRouteState();
}

class _SetupCurrencyRouteState extends State<SetupCurrencyRoute> {
  Currency? _currency;
  String? _country;

  @override
  Widget build(BuildContext context) {
    return SetupCurrencyScreen(
      currency: _currency,
      country: _country,
      onBack: () => context.pop(),
      // The wallet is single-currency and VND today, so there is one option and
      // picking is a confirmation. When a second currency exists this opens a
      // sheet; the screen already delegates, so only this changes.
      onPickCurrency: () => setState(() => _currency = Currency.vnd),
      onPickCountry: () => setState(() => _country = 'Vietnam'),
      onContinue: () => context.go(AuthRoutes.setupBiometric),
    );
  }
}

/// Hosts [SetupLinkAccountScreen].
class SetupLinkAccountRoute extends StatelessWidget {
  /// Creates the route.
  const SetupLinkAccountRoute({required this.onFinished, super.key});

  /// Called when setup is done, either by picking or by skipping.
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return SetupLinkAccountScreen(
      kinds: accountKinds,
      onBack: () => context.pop(),
      // Picking a type does not create an account — there is no account
      // feature yet. It finishes setup, and the type is not recorded, which is
      // better than recording a choice nothing will honour.
      onPick: (_) => onFinished(),
      onSkip: onFinished,
    );
  }
}

/// Hosts [SetupBiometricScreen].
class SetupBiometricRoute extends StatelessWidget {
  /// Creates the route.
  const SetupBiometricRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return SetupBiometricScreen(
      // Enabling does nothing yet: there is no app lock to guard. The screen
      // exists and the choice is not recorded, which is honest — recording a
      // preference the app ignores would be worse than not offering it.
      onEnable: () => context.go(AuthRoutes.setupAccount),
      onSkip: () => context.go(AuthRoutes.setupAccount),
    );
  }
}

/// Hosts [ResetSuccessScreen].
class ResetSuccessRoute extends StatelessWidget {
  /// Creates the route.
  const ResetSuccessRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return ResetSuccessScreen(onContinue: () => context.go(AuthRoutes.logIn));
  }
}
