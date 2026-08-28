import 'package:moneta/app/gallery/gallery_catalog.dart';
import 'package:moneta/design_system/atoms/moneta_icon_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
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
              'Style=${style.name}, Size=${size.name}, State=${state.name}',
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
