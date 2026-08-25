import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/molecules/onboarding_illustration.dart';
import 'package:moneta/design_system/molecules/pagination_dots.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/onboarding/domain/onboarding_slide.dart';

/// The three-slide first-run introduction.
///
/// Transcribed from Figma `71:37`, `71:103`, `71:162`. The frame — Skip, the
/// pagination and the forward action — is fixed; only the illustration and copy
/// change between slides, which is why the pager holds just those two.
class OnboardingScreen extends StatefulWidget {
  /// Creates the introduction.
  const OnboardingScreen({required this.onFinished, super.key});

  /// Called when the user finishes or skips. Both end the introduction — Figma
  /// offers no "remind me later".
  final VoidCallback onFinished;

  /// Key on the Skip action.
  static const Key skipKey = Key('OnboardingScreen.skip');

  /// Key on the forward action.
  static const Key forwardKey = Key('OnboardingScreen.forward');

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  OnboardingSlide get _slide => OnboardingSlide.values[_index];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _forward() {
    if (_slide.isLast) {
      widget.onFinished();
      return;
    }
    // The page animation is fire-and-forget: nothing downstream waits on it,
    // and awaiting would mean holding a BuildContext across an async gap.
    unawaited(
      _controller.nextPage(
        duration: context.moneta.motion.normal,
        curve: context.moneta.motion.emphasised,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final colors = theme.colors;

    // Scaffold, not a bare ColoredBox: without a Material ancestor Flutter
    // paints its "missing Material" debug decoration — yellow underlines under
    // every Text — which is how this was caught on the simulator.
    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: MonetaSpacing.spaceLg,
            right: MonetaSpacing.spaceLg,
            top: MonetaSpacing.spaceXs,
            bottom: MonetaSpacing.spaceBase,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Reserved even on the last slide, so nothing below shifts when
              // Skip disappears.
              SizedBox(
                height: MonetaButtonSize.md.height,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _slide.isLast
                      ? const SizedBox.shrink()
                      : MonetaButton(
                          key: OnboardingScreen.skipKey,
                          label: 'Skip',
                          style: MonetaButtonStyle.ghost,
                          onPressed: widget.onFinished,
                        ),
                ),
              ),
              const SizedBox(height: MonetaSpacing.spaceMd),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: OnboardingSlide.values.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final slide = OnboardingSlide.values[i];
                    return Column(
                      children: [
                        OnboardingIllustration(
                          glyph: slide.glyph,
                          chartSlot: slide.chartSlot,
                        ),
                        const SizedBox(height: MonetaSpacing.spaceMd),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: MonetaSpacing.spaceXs,
                          ),
                          child: Column(
                            children: [
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: theme.text.headingH1.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: MonetaSpacing.spaceSm),
                              Text(
                                slide.body,
                                textAlign: TextAlign.center,
                                style: theme.text.bodyLg.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: MonetaSpacing.spaceMd),
              Center(
                child: MonetaPaginationDots(
                  count: OnboardingSlide.values.length,
                  activeIndex: _index,
                  semanticLabel: 'Introduction progress',
                ),
              ),
              const SizedBox(height: MonetaSpacing.spaceMd),
              MonetaButton(
                key: OnboardingScreen.forwardKey,
                label: _slide.isLast ? 'Get started' : 'Next',
                size: MonetaButtonSize.lg,
                expand: true,
                onPressed: _forward,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
