import 'package:moneta/core/result.dart';

/// What the auth screens can ask for.
///
/// **This app has no backend.** `📱 01 Onboarding & Auth` is designed around
/// email/password, a one-time code and social sign-in, all of which assume a
/// server; Moneta is local-first and the SQLite file on the device is the only
/// copy of anything.
///
/// So this interface exists to keep that fact in one place rather than spread
/// through eight screens. Its only implementation is
/// `LocalAuthService`, which authenticates nobody: it validates the shape of
/// what was typed and records, locally, that setup was completed. No credential
/// is transmitted, stored or checked against anything.
///
/// If a backend ever appears, it implements this and the screens do not change.
abstract interface class AuthService {
  /// Creates an account.
  ///
  /// Returns a validation failure for input the screen should not have
  /// submitted, so the screen never has to guess why it failed.
  Future<Result<void>> signUp({
    required String email,
    required String password,
  });

  /// Signs in.
  Future<Result<void>> logIn({required String email, required String password});

  /// Starts a password reset for [email].
  Future<Result<void>> requestPasswordReset({required String email});

  /// Confirms a one-time code.
  Future<Result<void>> confirmCode({required String code});

  /// How many digits a one-time code has.
  int get codeLength;
}
