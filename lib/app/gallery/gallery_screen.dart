import 'package:flutter/material.dart';
import 'package:moneta/app/gallery/gallery_catalog.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// Renders every design-system component in every variant.
///
/// Its job is to make fidelity checkable by eye against the Figma canvas, so
/// each variant carries the Figma variant name and each section carries the
/// Figma node id.
class GalleryScreen extends StatelessWidget {
  /// Creates the gallery.
  const GalleryScreen({super.key});

  /// Route path.
  static const String routePath = '/gallery';

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return Scaffold(
      backgroundColor: theme.colors.canvas,
      body: SafeArea(
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.x4l,
            vertical: theme.spacing.x5l,
          ),
          itemCount: galleryCatalog.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: EdgeInsets.only(bottom: theme.spacing.x5l),
                child: Text(
                  'Design system',
                  style: theme.text.headingH1.copyWith(
                    color: theme.colors.textPrimary,
                  ),
                ),
              );
            }
            return _Section(section: galleryCatalog[index - 1]);
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.section});

  final GallerySection section;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.x5l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.component,
            style: theme.text.titleMd.copyWith(color: theme.colors.textPrimary),
          ),
          Text(
            'Figma ${section.figmaNodeId} · ${section.variants.length} '
            'variant${section.variants.length == 1 ? '' : 's'}',
            style: theme.text.captionMd.copyWith(
              color: theme.colors.textTertiary,
            ),
          ),
          SizedBox(height: theme.spacing.xl),
          for (final variant in section.variants)
            Padding(
              padding: EdgeInsets.only(bottom: theme.spacing.x3l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.label,
                    style: theme.text.captionMd.copyWith(
                      color: theme.colors.textTertiary,
                    ),
                  ),
                  SizedBox(height: theme.spacing.md),
                  SizedBox(
                    width: MonetaLayout.contentWidth,
                    child: variant.build(context),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
