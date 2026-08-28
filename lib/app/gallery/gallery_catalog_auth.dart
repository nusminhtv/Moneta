import 'package:flutter/widgets.dart';
import 'package:moneta/app/gallery/gallery_catalog.dart';
import 'package:moneta/design_system/atoms/moneta_checkbox.dart';
import 'package:moneta/design_system/atoms/moneta_divider.dart';
import 'package:moneta/design_system/atoms/moneta_icon_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/atoms/moneta_logo.dart';
import 'package:moneta/design_system/molecules/moneta_otp_field.dart';
import 'package:moneta/design_system/molecules/moneta_select.dart';
import 'package:moneta/design_system/molecules/moneta_text_field.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';

/// Gallery sections for 📱 01 Onboarding & Auth.
///
/// **Owner: the auth agent.** The home agent must not edit this file — see
/// `docs/ai-workflow/parallel-brief-home-dashboard.md`.
///
/// `test/app/gallery_test.dart` fails if a class under `lib/design_system` is
/// absent from the catalog, so every component built for the auth flow is
/// registered here, in every variant Figma authors.
final List<GallerySection> authSections = [
  // --- AUTH: add below ---
  GallerySection(
    component: 'TextField',
    figmaNodeId: '27:44',
    // Every state is derived, so each variant is built by setting the inputs
    // that produce it rather than by naming it.
    variants: [
      GalleryVariant(
        'State=Default',
        (_) => const MonetaTextField(
          label: 'Email',
          placeholder: 'you@example.com',
          helper: 'We will never share your email.',
        ),
      ),
      GalleryVariant(
        'State=Filled',
        (_) => MonetaTextField(
          controller: TextEditingController(text: 'minh@example.com'),
          label: 'Email',
          helper: 'We will never share your email.',
        ),
      ),
      GalleryVariant(
        'State=Error',
        (_) => MonetaTextField(
          controller: TextEditingController(text: 'not-an-email'),
          label: 'Email',
          errorText: 'That address is not valid',
        ),
      ),
      GalleryVariant(
        'State=Disabled',
        (_) => MonetaTextField(
          controller: TextEditingController(text: 'minh@example.com'),
          label: 'Email',
          helper: 'We will never share your email.',
          enabled: false,
        ),
      ),
    ],
  ),
  GallerySection(
    component: 'OtpField',
    figmaNodeId: '70:263',
    variants: [
      GalleryVariant('Filled=Empty', (_) => const MonetaOtpField(code: '')),
      GalleryVariant(
        'Filled=Partial',
        (_) => const MonetaOtpField(code: '482'),
      ),
      GalleryVariant(
        'Filled=Complete',
        (_) => const MonetaOtpField(code: '482915'),
      ),
    ],
  ),
  GallerySection(
    component: 'Select',
    figmaNodeId: '38:131',
    variants: [
      GalleryVariant(
        'State=Placeholder',
        (_) => MonetaSelect<String>(
          value: null,
          labelOf: (v) => v,
          placeholder: 'Select an account',
          onTap: () {},
        ),
      ),
      GalleryVariant(
        'State=Value',
        (_) => MonetaSelect<String>(
          value: 'Vietcombank',
          labelOf: (v) => v,
          placeholder: 'Select an account',
          onTap: () {},
        ),
      ),
    ],
  ),
  GallerySection(
    component: 'Checkbox',
    figmaNodeId: '25:229',
    variants: [
      for (final state in MonetaCheckboxState.values)
        for (final enabled in [true, false])
          GalleryVariant(
            'State=${state.name}, Disabled=${!enabled}',
            (_) => MonetaCheckbox(
              state: state,
              semanticLabel: 'Remember me',
              enabled: enabled,
              onChanged: (_) {},
            ),
          ),
    ],
  ),
  GallerySection(
    component: 'Divider',
    figmaNodeId: '21:126',
    variants: [
      for (final orientation in MonetaDividerOrientation.values)
        for (final tone in MonetaDividerTone.values)
          GalleryVariant(
            'Orientation=${orientation.name}, Tone=${tone.name}',
            (_) => MonetaDivider(orientation: orientation, tone: tone),
          ),
    ],
  ),
  GallerySection(
    component: 'Logo',
    figmaNodeId: '70:205',
    variants: [
      GalleryVariant('Wordmark=true', (_) => const MonetaLogo()),
      GalleryVariant(
        'Wordmark=false',
        (_) => const MonetaLogo(showWordmark: false),
      ),
    ],
  ),
  GallerySection(
    component: 'AppBar',
    figmaNodeId: '39:112',
    variants: [
      for (final variant in MonetaAppBarVariant.values)
        GalleryVariant(
          'Variant=${variant.name}',
          (_) => MonetaAppBar(
            title: 'Transactions',
            variant: variant,
            onBack: () {},
            actions: [
              (
                icon: MonetaIconName.search,
                semanticLabel: 'Search',
                onPressed: () {},
              ),
            ],
          ),
        ),
    ],
  ),
  GallerySection(
    component: 'IconButton',
    figmaNodeId: '20:114',
    // All 18. The glyph is held constant so the grid reads as a matrix of
    // style × size × state rather than a parade of icons.
    variants: [
      for (final style in MonetaIconButtonStyle.values)
        for (final size in MonetaIconButtonSize.values)
          for (final state in MonetaIconButtonState.values)
            GalleryVariant(
              'Style=${style.name}, Size=${size.name}, '
              'State=${state == MonetaIconButtonState.normal ? "Default" : state.name}',
              (_) => MonetaIconButton(
                icon: MonetaIconName.search,
                semanticLabel: 'Search',
                style: style,
                size: size,
                state: state,
                onPressed: () {},
              ),
            ),
    ],
  ),
];
