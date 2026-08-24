/// Whether money came in or went out.
///
/// Lives in `lib/core`, not in the transactions feature, for the same reason
/// `SpendCategory` does: the design system must render it and feature domains
/// must classify by it, and `tool/check_architecture.dart` forbids
/// `design_system` from importing `features`. Core is the only legal shared home.
///
/// The sign of a transaction lives here, not in its amount. A signed amount
/// would let the two disagree — direction `income` with a negative value — and
/// every read would then have to decide which field wins.
enum TransactionDirection {
  /// Money in.
  income,

  /// Money out.
  expense;

  /// Resolves a stored name, or `null` if it is not one of ours.
  ///
  /// Returns null rather than a default so a row written by a newer version
  /// fails loudly instead of being silently mis-classified.
  static TransactionDirection? tryParse(String name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
