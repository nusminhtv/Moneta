import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/onboarding_illustration.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpAt(
    WidgetTester tester,
    double width, {
    int chartSlot = 1,
    MonetaIconName glyph = MonetaIconName.target,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MonetaTheme.dark().toThemeData(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: OnboardingIllustration(glyph: glyph, chartSlot: chartSlot),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect rectOf(WidgetTester tester, Key key) =>
      tester.getRect(find.byKey(key).first);

  Color? fillOf(WidgetTester tester, Key key) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(DecoratedBox),
        matchRoot: true,
      ),
    );
    return (box.decoration as BoxDecoration).color;
  }

  group('geometry', () {
    // Figma places all three on the band's centre line. Scaling `left` without
    // scaling `top` left them concentric at exactly 353 and nowhere else.
    for (final width in <double>[
      OnboardingIllustration.designWidth,
      340,
      320,
      280,
      240,
    ]) {
      testWidgets('ring, halo and glyph stay concentric at ${width}px', (
        tester,
      ) async {
        await pumpAt(tester, width);

        final ring = rectOf(tester, OnboardingIllustration.ringKey);
        final halo = rectOf(tester, OnboardingIllustration.haloKey);
        final glyph = rectOf(tester, OnboardingIllustration.glyphKey);

        expect(halo.center.dx, moreOrLessEquals(ring.center.dx, epsilon: 0.5));
        expect(halo.center.dy, moreOrLessEquals(ring.center.dy, epsilon: 0.5));
        expect(glyph.center.dx, moreOrLessEquals(ring.center.dx, epsilon: 0.5));
        expect(glyph.center.dy, moreOrLessEquals(ring.center.dy, epsilon: 0.5));
      });
    }

    testWidgets('the halo sits inside the ring at every width', (tester) async {
      for (final width in <double>[353, 300, 260]) {
        await pumpAt(tester, width);
        final ring = rectOf(tester, OnboardingIllustration.ringKey);
        final halo = rectOf(tester, OnboardingIllustration.haloKey);
        expect(
          ring.contains(halo.topLeft) &&
              ring.contains(halo.bottomRight - const Offset(0.01, 0.01)),
          isTrue,
          reason: 'halo escaped the ring at $width',
        );
      }
    });

    testWidgets('both axes scale by the same factor', (tester) async {
      await pumpAt(tester, OnboardingIllustration.designWidth);
      final full = rectOf(tester, OnboardingIllustration.ringKey);
      await pumpAt(tester, OnboardingIllustration.designWidth / 2);
      final half = rectOf(tester, OnboardingIllustration.ringKey);

      expect(half.width, moreOrLessEquals(full.width / 2, epsilon: 0.5));
      expect(half.height, moreOrLessEquals(full.height / 2, epsilon: 0.5));
    });

    testWidgets('the band height scales with the width', (tester) async {
      // 268 and 353 are Figma's own numbers, written out rather than read back
      // off the widget, so a change to either constant fails here.
      await pumpAt(tester, 353);
      expect(
        tester.getSize(find.byType(OnboardingIllustration)).height,
        moreOrLessEquals(268, epsilon: 0.5),
      );

      await pumpAt(tester, 353 / 2);
      expect(
        tester.getSize(find.byType(OnboardingIllustration)).height,
        moreOrLessEquals(268 / 2, epsilon: 0.5),
      );
    });

    testWidgets('never scales up past the size Figma authors', (tester) async {
      // A tablet gets the authored illustration, centred — not a huge one.
      await pumpAt(tester, OnboardingIllustration.designWidth * 2);
      final ring = rectOf(tester, OnboardingIllustration.ringKey);
      expect(ring.width, moreOrLessEquals(262, epsilon: 0.5));
    });
  });

  group('theming', () {
    testWidgets("the halo is the slot's subtle chart fill", (tester) async {
      for (var slot = 1; slot <= 4; slot++) {
        await pumpAt(tester, 353, chartSlot: slot);
        expect(
          fillOf(tester, OnboardingIllustration.haloKey),
          colors.chart.subtle(slot),
          reason: 'halo ignored chartSlot $slot',
        );
      }
    });

    testWidgets("the accent dots are the slot's base chart colour", (
      tester,
    ) async {
      for (var slot = 1; slot <= 4; slot++) {
        await pumpAt(tester, 353, chartSlot: slot);
        expect(
          fillOf(tester, OnboardingIllustration.dotKey(0)),
          colors.chart.base(slot),
          reason: 'dot ignored chartSlot $slot',
        );
      }
    });

    testWidgets('two different slots really do differ', (tester) async {
      await pumpAt(tester, 353, chartSlot: 1);
      final one = fillOf(tester, OnboardingIllustration.haloKey);
      await pumpAt(tester, 353, chartSlot: 4);
      expect(fillOf(tester, OnboardingIllustration.haloKey), isNot(one));
    });

    testWidgets('the ring is the subtle border token, not a chart colour', (
      tester,
    ) async {
      await pumpAt(tester, 353);
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(OnboardingIllustration.ringKey),
          matching: find.byType(DecoratedBox),
          matchRoot: true,
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.border!.top.color, colors.borderSubtle);
      expect(
        decoration.color,
        isNull,
        reason: 'the ring is a hairline, not a fill',
      );
    });

    testWidgets('every accent dot is drawn, at its Figma size', (tester) async {
      // The expected sizes are literals on purpose. Comparing the rendered
      // width against `accentDots[i].size` would compare the implementation to
      // itself: shrinking a dot from 12 to 1 changed both sides and the
      // assertion held. These are the four sizes read from the Figma frame.
      const expected = <double>[12, 8, 9, 14];
      expect(
        OnboardingIllustration.accentDots.map((d) => d.size),
        expected,
        reason: 'the transcribed dot sizes changed',
      );

      await pumpAt(tester, OnboardingIllustration.designWidth);
      for (final (index, size) in expected.indexed) {
        final rect = rectOf(tester, OnboardingIllustration.dotKey(index));
        expect(
          rect.width,
          moreOrLessEquals(size, epsilon: 0.5),
          reason: 'dot $index is not ${size}px wide',
        );
        expect(rect.height, moreOrLessEquals(size, epsilon: 0.5));
      }
    });

    testWidgets('the dots are drawn at half opacity, as Figma applies', (
      tester,
    ) async {
      await pumpAt(tester, 353);
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(OnboardingIllustration.dotKey(0)),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, OnboardingIllustration.accentDotOpacity);
    });

    testWidgets('the glyph is the one it was given', (tester) async {
      // Asserting the identity of the rendered icon, not merely that the key
      // exists. The findsOneWidget version of this test passed while the
      // component ignored its `glyph` parameter and drew the same icon on all
      // three slides — 617 green tests, one hardcoded constant.
      for (final glyph in [
        MonetaIconName.award,
        MonetaIconName.creditCard,
        MonetaIconName.target,
      ]) {
        await pumpAt(tester, 353, glyph: glyph);
        final icon = tester.widget<MonetaIcon>(
          find.byKey(OnboardingIllustration.glyphKey),
        );
        expect(icon.icon, glyph, reason: 'the illustration ignored its glyph');
      }
    });

    testWidgets('the glyph is drawn at the Figma size in the base colour', (
      tester,
    ) async {
      await pumpAt(tester, OnboardingIllustration.designWidth, chartSlot: 3);
      final icon = tester.widget<MonetaIcon>(
        find.byKey(OnboardingIllustration.glyphKey),
      );
      expect(icon.size, moreOrLessEquals(72, epsilon: 0.5));
      expect(icon.color, colors.chart.base(3));
    });
  });
}
