import 'package:moneta/core/result.dart';
import 'package:moneta/features/auth/domain/auth_service.dart';
import 'package:moneta/features/auth/domain/credentials.dart';

/// The only [AuthService] there is, and it authenticates nobody.
///
/// Moneta has no backend. This validates the shape of what was typed and
/// succeeds. It does **not** transmit anything, does **not** store a password,
/// and does **not** check a credential against any record — there is no record.
///
/// Named `Local` rather than `Fake` or `Stub` on purpose: those names imply a
/// real one exists elsewhere and this stands in for it during tests. Nothing
/// stands behind this. A reader who assumed otherwise would think the app has
/// accounts.
final class LocalAuthService implements AuthService {
  /// Creates the local service.
  const LocalAuthService();

  @override
  int get codeLength => 6;

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
  }) async {
    final failure =
        Credentials.emailError(email) ?? Credentials.passwordError(password);
    if (failure != null) return Err(AppFailure.validation(failure));
    return const Ok(null);
  }

  @override
  Future<Result<void>> logIn({
    required String email,
    required String password,
  }) async {
    // Deliberately the same shape check as sign-up, and no credential
    // comparison: there is nothing to compare against. A screen must not be
    // able to read this as "the password was correct".
    final failure =
        Credentials.emailError(email) ?? Credentials.passwordError(password);
    if (failure != null) return Err(AppFailure.validation(failure));
    return const Ok(null);
  }

  @override
  Future<Result<void>> requestPasswordReset({required String email}) async {
    final failure = Credentials.emailError(email);
    if (failure != null) return Err(AppFailure.validation(failure));
    return const Ok(null);
  }

  @override
  Future<Result<void>> confirmCode({required String code}) async {
    if (!Credentials.isCompleteCode(code, codeLength)) {
      return Err(AppFailure.validation('Enter all $codeLength digits'));
    }
    return const Ok(null);
  }
}
