import 'package:flutter/widgets.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/design_system/atoms/moneta_avatar.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/moneta_select.dart';
import 'package:moneta/design_system/molecules/moneta_text_field.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/settings/domain/profile.dart';

/// 08.02 — the three things a user can change about themselves.
///
/// From Figma node `100:276`. Annotation `100:415`: *"Three editable fields and
/// nothing else. The check in the app bar and the footer button do the same
/// thing on purpose — thumb reach at the bottom, convention at the top."*
///
/// Both controls call one callback, so they cannot drift apart.
class EditProfileScreen extends StatefulWidget {
  /// Creates the screen.
  const EditProfileScreen({
    required this.profile,
    required this.onSave,
    this.failure,
    this.onBack,
    this.onPickCurrency,
    super.key,
  });

  /// What the fields start as. A first run passes an empty [Profile].
  final Profile profile;

  /// Called with the edited profile when either control is activated.
  final ValueChanged<Profile> onSave;

  /// Why the last save did not work, or null.
  ///
  /// The email field takes what is **about the email** — a validation failure
  /// raised while the name is filled — and a banner above the footer takes
  /// **everything else**, including a validation failure about the name and
  /// any storage failure. Split that way round, as a rule and its complement,
  /// so no failure can fall between two lists of cases; an earlier version was
  /// written as two lists and one kind fell through.
  ///
  /// Either way **the typed values stay on screen**, because discarding
  /// someone's typing on a failed save loses their work.
  final AppFailure? failure;

  /// Leaves the screen.
  final VoidCallback? onBack;

  /// Presents the currency options. The screen does not choose how.
  final VoidCallback? onPickCurrency;

  /// Content inset, from `100:332`'s x within `100:310`.
  static const double horizontalInset = MonetaSpacing.spaceLg;

  /// Avatar size, from `100:312`: `Size=56`.
  static const MonetaAvatarSize avatarSize = MonetaAvatarSize.lg;

  /// Gap between the avatar and the button under it, from `100:318`'s y.
  static const double avatarGap = MonetaSpacing.spaceBase;

  /// Gap between fields, from `100:357`'s y less `100:332`'s bottom.
  static const double fieldGap = MonetaSpacing.spaceBase;

  /// The sticky footer's height, from `100:397`: 92.
  static const double footerHeight = 92;

  /// Key on the app bar's save action.
  static const Key appBarSaveKey = Key('EditProfileScreen.appBarSave');

  /// Key on the footer's save button.
  static const Key footerSaveKey = Key('EditProfileScreen.footerSave');

  /// Key on the message shown for any failure the email field does not take.
  static const Key failureBannerKey = Key('EditProfileScreen.failureBanner');

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.profile.name,
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.profile.email,
  );

  /// Follows a **changed** profile into the fields.
  ///
  /// `late final` controllers are built once, so without this the `profile`
  /// parameter is a lie after the first build: a parent passing a different
  /// profile would see the old text. The currency already followed the parent
  /// — it is read from `widget.profile` — so the name and email not following
  /// was an inconsistency inside one widget.
  ///
  /// Guarded on the profile *changing*, not on every rebuild, so a parent
  /// rebuilding for any other reason cannot wipe what someone is typing.
  @override
  void didUpdateWidget(EditProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile.name != oldWidget.profile.name) {
      _name.text = widget.profile.name;
    }
    if (widget.profile.email != oldWidget.profile.email) {
      _email.text = widget.profile.email;
    }
  }

  /// The currency is **not** state here.
  ///
  /// Picking one is the parent's job — the screen does not know how the
  /// options are presented — so the chosen value arrives back as a new
  /// profile from the parent. Holding a copy would let the two disagree, and the
  /// analyzer noticed first: a field that is never reassigned is a field that
  /// cannot follow the parent.
  Currency get _currency => widget.profile.currency;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  /// The one save both controls call.
  void _save() => widget.onSave(
    Profile(
      name: _name.text,
      email: _email.text,
      currency: _currency,
    ),
  );

  /// The message for the email field, when the failure is about the email.
  ///
  /// A validation failure raised while the name is empty is about the **name**,
  /// so it does not belong here — it goes to [_bannerMessage] instead.
  String? get _emailError {
    final failure = widget.failure;
    if (failure == null || failure.kind != FailureKind.validation) return null;
    return _name.text.trim().isEmpty ? null : failure.message;
  }

  /// The message shown above the footer: **everything [_emailError] does not
  /// take**.
  ///
  /// Written as "what is left" rather than as a second list of cases, because
  /// the first version listed `storage` only and a validation failure about
  /// the name fell between the two and was rendered **nowhere**. That is the
  /// first-run path — an empty profile, a tap on Save — so the screen's
  /// primary action appeared broken, which is exactly what `08.10`'s call to
  /// action was made honest to avoid. Found by `change-verifier`.
  String? get _bannerMessage {
    final failure = widget.failure;
    if (failure == null) return null;
    return _emailError == null ? failure.message : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        children: [
          MonetaAppBar(
            title: 'Edit profile',
            variant: MonetaAppBarVariant.titleBack,
            onBack: widget.onBack,
            actions: [
              (
                icon: MonetaIconName.check,
                semanticLabel: 'Save',
                onPressed: _save,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: EditProfileScreen.horizontalInset,
                vertical: MonetaSpacing.spaceSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        MonetaAvatar(
                          type: MonetaAvatarType.initials,
                          size: EditProfileScreen.avatarSize,
                          name: _name.text,
                        ),
                        const SizedBox(height: EditProfileScreen.avatarGap),
                        // `100:318` is a ghost button with a camera glyph.
                        // There is no photo picker — `image_picker` is not a
                        // dependency — so it is disabled rather than a control
                        // that does nothing.
                        const MonetaButton(
                          label: 'Change photo',
                          style: MonetaButtonStyle.ghost,
                          size: MonetaButtonSize.sm,
                          state: MonetaButtonState.disabled,
                          leadingIcon: MonetaIconName.camera,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: EditProfileScreen.fieldGap),
                  MonetaTextField(
                    label: 'Name',
                    placeholder: 'Your name',
                    controller: _name,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: EditProfileScreen.fieldGap),
                  MonetaTextField(
                    label: 'Email',
                    placeholder: 'you@example.com',
                    controller: _email,
                    errorText: _emailError,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: EditProfileScreen.fieldGap),
                  Text(
                    'Main currency',
                    style: theme.text.labelMd.copyWith(
                      color: theme.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: MonetaSpacing.spaceXs),
                  MonetaSelect<Currency>(
                    value: _currency,
                    labelOf: (currency) =>
                        '${currency.code} (${currency.symbol})',
                    placeholder: 'Choose a currency',
                    // Disabled when there is nothing to open. `08.10`'s call to
                    // action was made honest because an inert control is worse
                    // than an absent one; the same standard applies one screen
                    // over, and `change-verifier` pointed out it had not been.
                    enabled: widget.onPickCurrency != null,
                    onTap: widget.onPickCurrency,
                  ),
                  if (_bannerMessage != null) ...[
                    const SizedBox(height: EditProfileScreen.fieldGap),
                    Text(
                      _bannerMessage!,
                      key: EditProfileScreen.failureBannerKey,
                      style: theme.text.bodyMd.copyWith(
                        color: theme.colors.expense,
                      ),
                    ),
                  ],
                  const SizedBox(height: MonetaSpacing.space2xl),
                ],
              ),
            ),
          ),
          // `100:397`, sticky: the same action as the app bar's check.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EditProfileScreen.horizontalInset,
              MonetaSpacing.spaceMd,
              EditProfileScreen.horizontalInset,
              MonetaSpacing.spaceXl,
            ),
            child: MonetaButton(
              key: EditProfileScreen.footerSaveKey,
              label: 'Save changes',
              size: MonetaButtonSize.lg,
              expand: true,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
