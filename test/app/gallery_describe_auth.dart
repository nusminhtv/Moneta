import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_checkbox.dart';
import 'package:moneta/design_system/atoms/moneta_divider.dart';
import 'package:moneta/design_system/atoms/moneta_icon_button.dart';
import 'package:moneta/design_system/atoms/moneta_logo.dart';
import 'package:moneta/design_system/molecules/moneta_otp_field.dart';
import 'package:moneta/design_system/molecules/moneta_select.dart';
import 'package:moneta/design_system/molecules/moneta_text_field.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';

/// Describes gallery variants for 📱 01 Onboarding & Auth.
///
/// **Owner: the auth agent.** Returns `null` for anything it does not own, so
/// `gallery_test.dart` can chain the describers together.
///
/// Name the properties that make a variant distinct — the check this feeds
/// fails when two variants of a component render the same widget, and it can
/// only see what the description mentions.
/// Figma names the resting state `Default`; the Dart enums call it `normal`,
/// because `default` is a keyword. The describer speaks the label's vocabulary —
/// the same reason the pagination describer reports 1-based positions.
String _figmaState(String name) => name == 'normal' ? 'default' : name;

String? describeAuth(Widget widget) => switch (widget) {
  // --- AUTH: add cases below ---
  // Names the *derived* state, because that is what the label claims. The
  // field has no `state` parameter by design, so a describer that reported only
  // its inputs could not be compared against `State=Error`.
  MonetaTextField(
    :final label,
    :final errorText,
    :final enabled,
    :final controller,
  ) =>
    'TextField(${_figmaState(MonetaTextFieldState.of(enabled: enabled, focused: false, hasText: controller?.text.isNotEmpty ?? false, hasError: errorText != null).name)},$label)',
  MonetaOtpField(:final code, :final length) =>
    'OtpField(${MonetaOtpField.stateOf(code, length).name},$code)',
  MonetaSelect(:final value, :final placeholder) =>
    'Select(${value == null ? "placeholder" : "value"},$value,$placeholder)',
  MonetaCheckbox(:final state, :final enabled) =>
    'Checkbox(${state.name},disabled=${!enabled})',
  MonetaDivider(:final orientation, :final tone) =>
    'Divider(${orientation.name},${tone.name})',
  MonetaLogo(:final showWordmark) => 'Logo(wordmark=$showWordmark)',
  MonetaAppBar(:final variant, :final title) =>
    'AppBar(${variant.name},$title)',
  MonetaIconButton(:final style, :final size, :final state) =>
    'IconButton(${style.name},${size.name},${_figmaState(state.name)})',
  _ => null,
};
