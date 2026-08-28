import 'package:moneta/app/gallery/gallery_catalog.dart';
import 'package:moneta/design_system/atoms/moneta_circular_progress.dart';

/// Gallery sections for 📱 04 Budgets.
///
/// Kept in its own file for the same reason the auth and home spreads are: two
/// agents editing one list collide on every line.
final List<GallerySection> budgetSections = [
  // --- BUDGETS: add sections below ---
  GallerySection(
    component: 'CircularProgress',
    figmaNodeId: '25:272',
    variants: [
      for (final (state, fraction) in const [
        ('Under', 0.62),
        ('Near', 0.88),
        // Figma's Over sample is labelled 100%. Under this system's rule —
        // `BudgetStatus.fromFraction`, where exactly 1.0 is the limit *reached*
        // and not exceeded — 100% is NearLimit, so a 1.0 fixture would render
        // the warning colour under an "Over" label. The gallery's own
        // label-versus-widget check caught that. 1.12 is genuinely over.
        ('Over', 1.12),
      ])
        for (final size in MonetaCircularProgressSize.values)
          GalleryVariant(
            'State=$state, Size=${size.name[0].toUpperCase()}${size.name.substring(1)}',
            (_) => MonetaCircularProgress(fraction: fraction, size: size),
          ),
    ],
  ),
];
