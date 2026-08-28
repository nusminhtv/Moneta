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
                  GalleryVariantFrame(child: variant.build(context)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The box a single gallery variant is rendered in.
///
/// A *max* width, not a fixed one, and left-aligned. This was
/// `SizedBox(width: contentWidth)`, which forces a **tight** constraint on every
/// variant — so an `IconButton` that is 36x36 in Figma rendered 353 wide, and so
/// did every small `Button`. Nothing caught it: each component's own tests pump
/// it inside a `Center`, where constraints are loose and stretching cannot
/// happen, and the first version of the gallery test asserted a wrapper it had
/// built itself rather than this one.
///
/// The gallery is the surface a reviewer compares against the canvas, so
/// stretching a component misrepresents the one thing it exists to show.
/// Full-width components are unaffected: they take the max.
class GalleryVariantFrame extends StatelessWidget {
  /// Creates the frame.
  const GalleryVariantFrame({required this.child, super.key});

  /// The variant being shown.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: MonetaLayout.contentWidth),
        child: child,
      ),
    );
  }
}
