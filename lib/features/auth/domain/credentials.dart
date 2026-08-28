/// Validation for what the auth screens collect.
///
/// Pure and in `domain` so the 85% coverage gate reaches it: an off-by-one in a
/// password rule is exactly the kind of thing that hides in a screen.
abstract final class Credentials {
  /// Shortest password the app accepts.
  static const int minPasswordLength = 8;

  /// Whether [email] is plausibly an address.
  ///
  /// Deliberately permissive. A strict pattern rejects addresses that are valid
  /// — `user+tag@sub.domain.co.uk`, quoted locals, new TLDs — and the only
  /// authority on whether an address works is the address itself. This rejects
  /// what is obviously not an address and lets the rest through.
  static bool isPlausibleEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty || trimmed.contains(' ')) return false;
    final at = trimmed.indexOf('@');
    if (at <= 0 || at != trimmed.lastIndexOf('@')) return false;
    final domain = trimmed.substring(at + 1);
    if (domain.isEmpty || !domain.contains('.')) return false;
    if (domain.startsWith('.') || domain.endsWith('.')) return false;
    return true;
  }

  /// Why [email] is not acceptable, or null when it is.
  static String? emailError(String email) =>
      isPlausibleEmail(email) ? null : 'Enter a valid email address';

  /// Why [password] is not acceptable, or null when it is.
  static String? passwordError(String password) =>
      password.length >= minPasswordLength
      ? null
      : 'Use at least $minPasswordLength characters';

  /// Whether [code] is a complete numeric code of [length] digits.
  static bool isCompleteCode(String code, int length) =>
      code.length == length && RegExp(r'^\d+$').hasMatch(code);
}
