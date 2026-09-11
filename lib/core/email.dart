/// Whether a string is plausibly an email address.
///
/// Lives in `core` because two features need the same answer: the auth screens
/// collect an address at sign-up, and `08.02` collects one for the profile.
/// `tool/check_architecture.dart` forbids `features/settings` importing
/// `features/auth`, so the alternative to moving it was writing a second rule —
/// and two rules that are supposed to agree are two rules that can stop
/// agreeing without anyone noticing.
///
/// Deliberately **permissive**. A strict pattern rejects addresses that are
/// valid — `user+tag@sub.domain.co.uk`, quoted locals, new TLDs — and the only
/// authority on whether an address works is the address itself. This rejects
/// what is obviously not an address and lets the rest through.
bool isPlausibleEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty || trimmed.contains(' ')) return false;
  final at = trimmed.indexOf('@');
  if (at <= 0 || at != trimmed.lastIndexOf('@')) return false;
  final domain = trimmed.substring(at + 1);
  if (domain.isEmpty || !domain.contains('.')) return false;
  if (domain.startsWith('.') || domain.endsWith('.')) return false;
  return true;
}

/// What to tell someone whose address was rejected.
///
/// One message rather than a reason per rule: the rule is permissive on
/// purpose, so the only thing it can honestly say is that this is not an
/// address.
const String emailErrorMessage = 'Enter a valid email address';
