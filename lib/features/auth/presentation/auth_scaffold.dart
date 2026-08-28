import 'package:flutter/material.dart' show Material;
import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// The frame every screen on `📱 01 Onboarding & Auth` shares.
///
/// From the eight screen frames: canvas background, the screen gutter
/// (`space/lg`), `space/md` above the content and `space/base` below, and the
/// device's bottom inset honoured so a primary action never sits under the home
/// indicator.
///
/// The status bar is not drawn. Figma puts a `StatusBar` at the top of every
/// frame because Figma has no operating system; here the OS draws it and the
/// space comes from the device inset.
class AuthScaffold extends StatelessWidget {
  /// Creates an auth screen frame.
  const AuthScaffold({
    required this.children,
    this.title,
    this.onBack,
    super.key,
  });

  /// The screen's content, laid out in a column.
  final List<Widget> children;

  /// When given, a compact app bar with a back control is shown.
  ///
  /// Screens that are entered rather than navigated to — sign up, log in, the
  /// success screen — have no bar in the design, so this stays null for them.
  final String? title;

  /// Called when the back control is used.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    // `Material`, not a bare `ColoredBox`. These screens sit outside the app
    // shell, so nothing above them provides one — and `MonetaTextField` wraps
    // Material's `TextField`, which asserts on a missing Material ancestor.
    //
    // On device that was a red error box over the whole form. No test caught
    // it, because `pumpMonetaWidget` wraps every widget in `MaterialApp` +
    // `Scaffold`: the harness supplied what the app did not. The same defect,
    // from the same cause, shipped once before on the onboarding screens.
    return Material(
      color: theme.colors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            MonetaAppBar(
              title: title!,
              variant: MonetaAppBarVariant.titleBack,
              onBack: onBack,
            ),
          Expanded(
            child: SafeArea(
              top: title == null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  MonetaSpacing.spaceLg,
                  MonetaSpacing.spaceMd,
                  MonetaSpacing.spaceLg,
                  MonetaSpacing.spaceBase,
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    // The design's screens fill the height and push their
                    // footer down, but a small device with the keyboard up must
                    // still scroll rather than overflow.
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.sizeOf(context).height * 0.6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The heading pair every auth screen opens with.
class AuthHeading extends StatelessWidget {
  /// Creates a heading.
  const AuthHeading({required this.title, required this.subtitle, super.key});

  /// The large line.
  final String title;

  /// The supporting line under it.
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.text.headingH1.copyWith(color: theme.colors.textPrimary),
        ),
        const SizedBox(height: MonetaSpacing.spaceSm),
        Text(
          subtitle,
          style: theme.text.bodyMd.copyWith(color: theme.colors.textSecondary),
        ),
      ],
    );
  }
}

/// The "New to Moneta? Create an account" pair at the foot of a screen.
class AuthFooterLink extends StatelessWidget {
  /// Creates a footer link.
  const AuthFooterLink({
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
    super.key,
  });

  /// The plain part.
  final String prompt;

  /// The tappable part.
  final String actionLabel;

  /// Called when the action is used.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    // Wraps rather than overflows. The prompt and the action together are
    // wider than a narrow screen once either string is translated, and a footer
    // that clips its own call to action is worse than one that takes two lines.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: MonetaSpacing.spaceXs,
      children: [
        Text(
          prompt,
          style: theme.text.bodyMd.copyWith(color: theme.colors.textSecondary),
        ),
        GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: MonetaSpacing.spaceMd,
            ),
            child: Text(
              actionLabel,
              style: theme.text.labelMd.copyWith(
                color: theme.colors.brandOnSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
