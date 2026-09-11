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

  /// What to call this person in a greeting: the **first** word of [name].
  ///
  /// Empty when the name yields no letters, so a caller can fall back rather
  /// than greeting nobody.
  ///
  /// **The first word, not the last, and that is a decision with a cost.** A
  /// string cannot say whether it is written given-name-first (`Minh Tran`) or
  /// surname-first (`Trần Văn Minh`), and no rule is right for both:
  ///
  /// | Name | First word | Last word |
  /// | --- | --- | --- |
  /// | `Minh Tran` | **Minh** | Tran — the surname |
  /// | `Trần Văn Minh` | Trần — the surname | **Minh** |
  ///
  /// The first word was chosen because it is right for the name this app's own
  /// demo data uses. Detecting the order per name was rejected: it cannot be
  /// done reliably, and a heuristic that is usually right makes the greeting
  /// unpredictable, which is worse than being consistently one thing.
  ///
  /// Non-letters are stripped, so `Minh,` becomes `Minh` and `Đặng` survives.
  ///
  /// The first word **that has letters**, not simply the first word: `123 Minh`
  /// greets Minh rather than nobody. A leading house number or a stray dash is
  /// not what someone is called.
  ///
  /// Uses Unicode's own letter property rather than the `[A-Za-zÀ-ỹ]` range
  /// `MonetaAvatar.initialsOf` uses. `change-verifier` measured what that range
  /// does: `李小龙` and `김수현` yield **nothing**, so a Chinese or Korean name
  /// would be greeted as a stranger forever — while `×` and `÷` (U+00D7,
  /// U+00F7) and a Devanagari danda fall *inside* it and would be greeted as
  /// names. `\p{L}` gets both right.
  ///
  /// **`MonetaAvatar.initialsOf` still has that range and therefore that
  /// defect.** It is a design-system component with its own node and its own
  /// tests; changing it is not this change's to do, and it is recorded rather
  /// than left to be discovered.
  String get firstName {
    final letters = RegExp(r'[^\p{L}]', unicode: true);
    for (final word in name.split(RegExp(r'\s+'))) {
      final stripped = word.replaceAll(letters, '');
      if (stripped.isNotEmpty) return stripped;
    }
    return '';
  }

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
