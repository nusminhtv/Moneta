import 'package:moneta/core/email.dart' as core;

/// Validation for what the auth screens collect.
///
/// Pure and in `domain` so the 85% coverage gate reaches it: an off-by-one in a
/// password rule is exactly the kind of thing that hides in a screen.
abstract final class Credentials {
  /// Shortest password the app accepts.
  static const int minPasswordLength = 8;

  /// Whether [email] is plausibly an address.
  ///
  /// **Delegates to `lib/core/email.dart`**, which is where the rule moved so
  /// that `08.02` could use the same one. It kept its name and its behaviour
  /// here: the check that this was a move and not a rewrite is that this
  /// file's own tests pass unmodified.
  static bool isPlausibleEmail(String email) => core.isPlausibleEmail(email);

  /// Why [email] is not acceptable, or null when it is.
  static String? emailError(String email) =>
      isPlausibleEmail(email) ? null : core.emailErrorMessage;

  /// Why [password] is not acceptable, or null when it is.
  static String? passwordError(String password) =>
      password.length >= minPasswordLength
      ? null
      : 'Use at least $minPasswordLength characters';

  /// Whether [code] is a complete numeric code of [length] digits.
  static bool isCompleteCode(String code, int length) =>
      code.length == length && RegExp(r'^\d+$').hasMatch(code);
}
