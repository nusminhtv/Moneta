import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// One trailing action in a [MonetaAppBar].
///
/// A record rather than a class on purpose: a class under `lib/design_system`
/// must be in the component gallery or explicitly exempted, and a value type
/// that renders nothing is neither. The record sidesteps that without needing an
/// exemption to explain away.
typedef MonetaAppBarAction = ({
  MonetaIconName icon,
  String semanticLabel,
  VoidCallback? onPressed,
});

/// Which app bar this is, from Figma node `39:112`.
enum MonetaAppBarVariant {
  /// 96px bar with the large display title. Scroll-top screens.
  largeTitle(barHeight: 96, hasBack: false, hasBackground: true),

  /// 56px compact bar with a back control and a centred title.
  titleBack(barHeight: 56, hasBack: true, hasBackground: true),

  /// 56px compact bar with a leading title and room for two actions.
  titleActions(barHeight: 56, hasBack: false, hasBackground: true),

  /// 56px compact bar with no fill, so a hero image or gradient shows through.
  transparent(barHeight: 56, hasBack: true, hasBackground: false);

  const MonetaAppBarVariant({
    required this.barHeight,
    required this.hasBack,
    required this.hasBackground,
  });

  /// Height of the bar itself, **below** the device's top inset.
  final double barHeight;

  /// Whether this variant carries a back control.
  final bool hasBack;

  /// Whether this variant paints the canvas behind itself.
  final bool hasBackground;
}

/// The top app bar.
///
/// From Figma node `39:112` — four variants, all implemented.
///
/// **The status bar is not drawn here.** Figma embeds a 59px `StatusBar`
/// (`39:2`) inside every variant because Figma has no operating system; on a
/// device the OS draws it, and painting a fake `9:41` over the real one is a
/// defect rather than fidelity. The space comes from `MediaQuery.padding.top`.
///
/// `MonetaLayout.safeAreaTop` is a correct transcription of the 59 Figma
/// authors and stays a token — but this widget must not read it. A bar that
/// reads the token looks token-driven in review and is still wrong on any device
/// whose inset is not 59.
class MonetaAppBar extends StatelessWidget {
  /// Creates an app bar.
  const MonetaAppBar({
    required this.title,
    this.variant = MonetaAppBarVariant.largeTitle,
    this.onBack,
    this.actions = const [],
    super.key,
  });

  /// The bar's title.
  final String title;

  /// Which of the four Figma variants to render.
  final MonetaAppBarVariant variant;

  /// Called when the back control is activated.
  ///
  /// Only rendered on variants whose [MonetaAppBarVariant.hasBack] is true.
  final VoidCallback? onBack;

  /// Trailing actions, drawn right to left in the order given.
  final List<MonetaAppBarAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final centred =
        variant == MonetaAppBarVariant.titleBack ||
        variant == MonetaAppBarVariant.transparent;

    final titleStyle = switch (variant) {
      MonetaAppBarVariant.largeTitle => theme.text.headingH1,
      MonetaAppBarVariant.titleActions => theme.text.headingH3,
      MonetaAppBarVariant.titleBack ||
      MonetaAppBarVariant.transparent => theme.text.titleMd,
    };

    // Figma: LargeTitle and TitleActions inset the title by the screen gutter;
    // the two that carry a back control pad both sides by the smaller value,
    // because the control supplies its own visual inset.
    final leadingPad = variant.hasBack
        ? MonetaSpacing.spaceSm
        : MonetaSpacing.spaceLg;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: variant.hasBackground ? theme.colors.canvas : null,
      ),
      child: SafeArea(
        bottom: false,
        left: false,
        right: false,
        child: SizedBox(
          height: variant.barHeight,
          child: Padding(
            padding: EdgeInsets.only(
              left: leadingPad,
              right: MonetaSpacing.spaceSm,
            ),
            child: Row(
              children: [
                if (variant.hasBack)
                  MonetaIconButton(
                    icon: MonetaIconName.chevronLeft,
                    semanticLabel: 'Back',
                    onPressed: onBack,
                  ),
                const SizedBox(width: MonetaSpacing.spaceSm),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    textAlign: centred ? TextAlign.center : TextAlign.start,
                    style: titleStyle.copyWith(color: theme.colors.textPrimary),
                  ),
                ),
                const SizedBox(width: MonetaSpacing.spaceSm),
                for (final action in actions)
                  MonetaIconButton(
                    icon: action.icon,
                    semanticLabel: action.semanticLabel,
                    onPressed: action.onPressed,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
