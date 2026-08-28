import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// Skeleton placeholder shape.
///
/// From Figma node `38:139`: Line, Circle, Card and Row.
enum SkeletonShape {
  /// A single text line.
  line,

  /// A circular avatar or icon placeholder.
  circle,

  /// A card-sized block.
  card,

  /// A row with a leading circle and two lines.
  row,
}

/// Loading placeholder used before content resolves.
///
/// From Figma node `38:139`.
class Skeleton extends StatelessWidget {
  /// Creates a skeleton placeholder.
  const Skeleton({required this.shape, super.key});

  /// Shape variant to render.
  final SkeletonShape shape;

  @override
  Widget build(BuildContext context) {
    return switch (shape) {
      SkeletonShape.line => const _SkeletonLine(),
      SkeletonShape.circle => const _SkeletonCircle(),
      SkeletonShape.card => const _SkeletonCard(),
      SkeletonShape.row => const _SkeletonRow(),
    };
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.track,
        borderRadius: borderRadius,
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine();

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return _SkeletonBlock(
      width: double.infinity,
      height: MonetaSpacing.spaceMd,
      borderRadius: theme.radii.borderPill,
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle();

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: _SkeletonBlock(
        width: MonetaSpacing.space4xl,
        height: MonetaSpacing.space4xl,
        borderRadius: theme.radii.borderPill,
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return _SkeletonBlock(
      width: double.infinity,
      height: MonetaSpacing.space5xl + MonetaSpacing.space5xl,
      borderRadius: theme.radii.borderLg,
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MonetaSpacing.spaceBase,
        vertical: MonetaSpacing.spaceMd,
      ),
      child: Row(
        children: [
          const Skeleton(shape: SkeletonShape.circle),
          const SizedBox(width: MonetaSpacing.spaceMd),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SkeletonBlock(
                  width: double.infinity,
                  height: MonetaSpacing.spaceMd,
                  borderRadius: theme.radii.borderPill,
                ),
                const SizedBox(height: MonetaSpacing.spaceSm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.62,
                    child: _SkeletonBlock(
                      width: double.infinity,
                      height: MonetaSpacing.spaceSm,
                      borderRadius: theme.radii.borderPill,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
