import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/data/preferences/preference_key.dart';
import 'package:moneta/data/preferences/preferences_store.dart';
import 'package:moneta/features/settings/domain/profile.dart';

/// Reads and writes the [Profile].
///
/// In `data` rather than `domain`: it is backed by [PreferencesStore], and
/// CLAUDE.md holds that `domain/` depends on `core` only.
/// `tool/check_architecture.dart` keys on the top-level `features` segment and
/// would not have caught this one, so the layer is a decision made by hand.
///
/// **Control-scoped**, like every other preference: the store it is given is
/// the control database's, which the demo toggle never swaps. A ledger-scoped
/// name would mean turning demo mode on renamed the user.
final class ProfileStore {
  /// Creates a store over [preferences].
  const ProfileStore(this.preferences);

  /// Where the three values live.
  final PreferencesStore preferences;

  /// The stored profile, or `Ok(null)` when the user has not set one.
  ///
  /// Absence is the name's absence: an email or a currency without a name is
  /// not a profile anyone chose, and `08.01` needs a name to show anything.
  Future<Result<Profile?>> read() async {
    final name = await preferences.readString(PreferenceKey.profileName);
    if (name is Err<String?>) return Err(name.failure);
    final storedName = name.valueOrNull;
    if (storedName == null || storedName.trim().isEmpty) {
      return const Ok(null);
    }

    final email = await preferences.readString(PreferenceKey.profileEmail);
    if (email is Err<String?>) return Err(email.failure);

    final currency = await preferences.readString(
      PreferenceKey.profileCurrency,
    );
    if (currency is Err<String?>) return Err(currency.failure);

    return Ok(
      Profile(
        name: storedName,
        email: email.valueOrNull ?? '',
        currency: _currencyOf(currency.valueOrNull),
      ),
    );
  }

  /// Saves [profile], or reports why it cannot be saved.
  ///
  /// Validation runs first, so a rejected profile writes nothing at all rather
  /// than a name without its email.
  Future<Result<void>> save(Profile profile) async {
    final invalid = profile.validationFailure;
    if (invalid != null) return Err(invalid);

    final name = await preferences.writeString(
      PreferenceKey.profileName,
      value: profile.name.trim(),
    );
    if (name is Err<void>) return name;

    final email = await preferences.writeString(
      PreferenceKey.profileEmail,
      value: profile.email.trim(),
    );
    if (email is Err<void>) return email;

    return preferences.writeString(
      PreferenceKey.profileCurrency,
      value: profile.currency.name,
    );
  }

  /// The currency [stored] names, defaulting to the wallet's.
  ///
  /// An unknown name falls back rather than failing: a row written by a newer
  /// build naming a currency this one does not have should not make the whole
  /// profile unreadable.
  static Currency _currencyOf(String? stored) {
    for (final currency in Currency.values) {
      if (currency.name == stored) return currency;
    }
    return Currency.vnd;
  }
}
