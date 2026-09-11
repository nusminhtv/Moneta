import 'package:equatable/equatable.dart';
import 'package:moneta/core/email.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';

/// Who the app belongs to, as far as the app knows.
///
/// Three fields, which is what `08.02` edits and what `08.01` and `08.03`
/// show. Annotation `100:415`: *"Three editable fields and nothing else."*
///
/// There is no account and no identity feature behind this — it is a label the
/// user chose for their own ledger.
class Profile extends Equatable {
  /// Creates a profile.
  const Profile({
    required this.name,
    this.email = '',
    this.currency = Currency.vnd,
  });

  /// The display name. `08.01` shows it and the avatar derives its initials.
  final String name;

  /// The email, which may be empty: a local-first app with no account does not
  /// need one.
  final String email;

  /// The currency new entries default to, shown on `08.03`.
  final Currency currency;

  /// This profile with one field changed.
  Profile copyWith({String? name, String? email, Currency? currency}) =>
      Profile(
        name: name ?? this.name,
        email: email ?? this.email,
        currency: currency ?? this.currency,
      );

  /// Why this profile cannot be saved, or null when it can.
  ///
  /// A name is required and an email is not. Both `08.01` and the avatar have
  /// nothing to show without a name; an address is optional because nothing
  /// sends mail to it.
  AppFailure? get validationFailure {
    if (name.trim().isEmpty) {
      return const AppFailure(
        FailureKind.validation,
        'Enter a name — it is what the Profile tab shows',
      );
    }
    if (email.trim().isNotEmpty && !isPlausibleEmail(email)) {
      return const AppFailure(FailureKind.validation, emailErrorMessage);
    }
    return null;
  }

  @override
  List<Object?> get props => [name, email, currency];
}
