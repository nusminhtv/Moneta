import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/molecules/skeleton.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// Home while its data is still loading, from Figma node `52:547`.
///
/// Annotation `52:630`: *"Skeletons mirror the real layout's rhythm so nothing
/// jumps when data lands — a spinner is not a loading state in this system."*
///
/// **The app bar is part of this screen.** The annotation is explicit —
/// *"AppBar and BottomNav render immediately; only the content area is
/// skeletonised"* — and the previous implementation rendered no app bar at all,
/// so the bar materialised when the data arrived and shoved the whole page down.
/// That is the exact jump the skeletons exist to prevent, introduced by the
/// thing meant to prevent it. The bottom navigation needs no help here: the
/// shell owns it, so it never leaves.
///
/// The composition is the authored one at `52:564`–`52:594`: three `Card`, four
/// `Circle`, six `Line` and four `Row`, standing in for the balance card, the
/// four quick actions, the two section headings, the two budget cards and the
/// four transaction rows.
///
/// **Placeholder widths are not per-instance.** Figma resizes its instances —
/// the two heading skeletons are 140 and 180 wide — but `Skeleton` authors no
/// width property, and neither does the Figma component; the frame resizes the
/// instance. Rather than hard-code two unrecorded pixel widths, the `Line`
/// variant keeps its own full-bleed width. Nothing jumps vertically, which is
/// what the annotation asks for. Recorded as a deviation in
/// `docs/design-system/figma-map.md`.
class HomeLoadingScreen extends StatelessWidget {
  /// Creates the loading screen.
  const HomeLoadingScreen({required this.greeting, super.key});

  /// The app bar title, identical to the loaded screen's.
  ///
  /// Passed in rather than read from the snapshot precisely because there is no
  /// snapshot yet — and because a greeting that changes when the data lands
  /// would be its own flicker.
  final String greeting;

  /// How many quick-action placeholders the row shows.
  ///
  /// Four, matching the authored actions at `52:566`–`52:575`. A count that
  /// disagreed with the loaded screen's would reflow the row on arrival.
  static const int quickActionCount = 4;

  /// How many transaction-row placeholders the list shows.
  static const int transactionRowCount = 4;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonetaAppBar(title: greeting),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                MonetaSpacing.spaceLg,
                MonetaSpacing.spaceXs,
                MonetaSpacing.spaceLg,
                MonetaSpacing.spaceBase,
              ),
              children: const [
                // The balance card — `52:564`.
                Skeleton(shape: SkeletonShape.card),
                SizedBox(height: MonetaSpacing.spaceBase),
                // The quick actions — `52:565`.
                _QuickActionsSkeleton(),
                SizedBox(height: MonetaSpacing.spaceBase),
                // "Budgets" — `52:578`.
                Skeleton(shape: SkeletonShape.line),
                SizedBox(height: MonetaSpacing.spaceSm),
                // The two budget cards — `52:579`, `52:580`.
                Skeleton(shape: SkeletonShape.card),
                SizedBox(height: MonetaSpacing.spaceSm),
                Skeleton(shape: SkeletonShape.card),
                SizedBox(height: MonetaSpacing.spaceBase),
                // "Recent transactions" — `52:581`.
                Skeleton(shape: SkeletonShape.line),
                SizedBox(height: MonetaSpacing.spaceSm),
                // The four transaction rows — `52:582` onward.
                _TransactionRowsSkeleton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Four columns of disc-over-label, mirroring the loaded quick-actions row.
class _QuickActionsSkeleton extends StatelessWidget {
  const _QuickActionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < HomeLoadingScreen.quickActionCount; i++)
          const Expanded(
            child: Column(
              children: [
                Skeleton(shape: SkeletonShape.circle),
                SizedBox(height: MonetaSpacing.spaceXs),
                Skeleton(shape: SkeletonShape.line),
              ],
            ),
          ),
      ],
    );
  }
}

/// The recent-transaction placeholders, spaced as the real rows are.
class _TransactionRowsSkeleton extends StatelessWidget {
  const _TransactionRowsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < HomeLoadingScreen.transactionRowCount; i++)
          const Skeleton(shape: SkeletonShape.row),
      ],
    );
  }
}
