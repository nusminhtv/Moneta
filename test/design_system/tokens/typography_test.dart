import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/tokens/typography.dart';

/// Transcription tests for the type scale — see the note in colors_test.dart.
///
/// Line height and letter spacing are asserted in the *Figma* units (pixels and
/// percent) and converted here, so a mistake in the production conversion shows
/// up as a failure rather than being mirrored by the test.
void main() {
  final type = MonetaTypography.figma();

  void expectStyle(
    TextStyle style, {
    required String family,
    required FontWeight weight,
    required double size,
    required double lineHeightPx,
    double trackingPercent = 0,
  }) {
    expect(style.fontFamily, family);
    expect(style.fontWeight, weight);
    expect(style.fontSize, size);
    expect(
      style.height! * style.fontSize!,
      closeTo(lineHeightPx, 1e-9),
      reason: 'line height should resolve to ${lineHeightPx}px',
    );
    expect(
      style.letterSpacing,
      closeTo(size * trackingPercent / 100, 1e-9),
      reason: 'tracking should be $trackingPercent% of $size',
    );
  }

  group('display and heading styles use Plus Jakarta Sans', () {
    test('amount-xl is 40/44 bold at -1% tracking', () {
      expectStyle(
        type.amountXl,
        family: 'Plus Jakarta Sans',
        weight: FontWeight.w700,
        size: 40,
        lineHeightPx: 44,
        trackingPercent: -1,
      );
      // The resolved pixel value Figma's CSS emitted.
      expect(type.amountXl.letterSpacing, closeTo(-0.4, 1e-9));
    });

    test('amount-md is 20/26 semibold with no tracking', () {
      expectStyle(
        type.amountMd,
        family: 'Plus Jakarta Sans',
        weight: FontWeight.w600,
        size: 20,
        lineHeightPx: 26,
      );
    });

    test('heading-h1 is 28/34 bold at -1% tracking', () {
      expectStyle(
        type.headingH1,
        family: 'Plus Jakarta Sans',
        weight: FontWeight.w700,
        size: 28,
        lineHeightPx: 34,
        trackingPercent: -1,
      );
      expect(type.headingH1.letterSpacing, closeTo(-0.28, 1e-9));
    });
  });

  group('text styles use Inter', () {
    test('title-md is 16/22 semibold', () {
      expectStyle(
        type.titleMd,
        family: 'Inter',
        weight: FontWeight.w600,
        size: 16,
        lineHeightPx: 22,
      );
    });

    test('body-lg is 16/24 regular', () {
      expectStyle(
        type.bodyLg,
        family: 'Inter',
        weight: FontWeight.w400,
        size: 16,
        lineHeightPx: 24,
      );
    });

    test('body-md is 14/20 regular', () {
      expectStyle(
        type.bodyMd,
        family: 'Inter',
        weight: FontWeight.w400,
        size: 14,
        lineHeightPx: 20,
      );
    });

    test('label-md is 14/18 medium', () {
      expectStyle(
        type.labelMd,
        family: 'Inter',
        weight: FontWeight.w500,
        size: 14,
        lineHeightPx: 18,
      );
    });

    test('label-sm is 12/16 medium', () {
      expectStyle(
        type.labelSm,
        family: 'Inter',
        weight: FontWeight.w500,
        size: 12,
        lineHeightPx: 16,
      );
    });

    test('caption-md is 12/16 regular', () {
      expectStyle(
        type.captionMd,
        family: 'Inter',
        weight: FontWeight.w400,
        size: 12,
        lineHeightPx: 16,
      );
    });
  });

  group('the scale as a whole', () {
    test('has the styles Figma defines that we have transcribed', () {
      // Figma has 13; nine are implemented. This comment used to claim the
      // missing four were recorded in docs/design-system/figma-tokens.md. They
      // were not — and neither were two of the nine. That file now carries
      // body/lg and border-strong, and says plainly that four styles are
      // unimplemented and unlisted because no surface has needed them.
      //
      // The count itself: this was edited from 8 to 9 to make the suite pass
      // when body/lg was added, while the requirement still said "exactly the
      // eight". That is a gate moved to fit the code. The requirement no longer
      // states a count; see the tokens spec delta in onboarding-flow.
      expect(type.all, hasLength(9));
    });

    test('uses only the two declared families', () {
      expect(
        type.all.map((s) => s.fontFamily).toSet(),
        {'Inter', 'Plus Jakarta Sans'},
      );
    });

    test('only bundled weights are referenced', () {
      // pubspec.yaml bundles Inter 400/500/600 and Plus Jakarta Sans 600/700.
      // Referencing an unbundled weight would silently synthesise a face.
      final bundled = {
        'Inter': {FontWeight.w400, FontWeight.w500, FontWeight.w600},
        'Plus Jakarta Sans': {FontWeight.w600, FontWeight.w700},
      };
      for (final style in type.all) {
        expect(
          bundled[style.fontFamily!],
          contains(style.fontWeight),
          reason: '${style.fontFamily} ${style.fontWeight} is not bundled',
        );
      }
    });

    test('every style centres its leading, as Figma does', () {
      for (final style in type.all) {
        expect(style.leadingDistribution, TextLeadingDistribution.even);
      }
    });

    test('sizes descend through the scale without duplication of role', () {
      expect(type.amountXl.fontSize! > type.headingH1.fontSize!, isTrue);
      expect(type.headingH1.fontSize! > type.amountMd.fontSize!, isTrue);
      expect(type.amountMd.fontSize! > type.titleMd.fontSize!, isTrue);
      expect(type.titleMd.fontSize! > type.labelSm.fontSize!, isTrue);
      expect(type.bodyLg.fontSize! > type.bodyMd.fontSize!, isTrue);
    });
  });

  group('lerp', () {
    test('reaches the target at t=1', () {
      const target = MonetaTypography(
        amountXl: TextStyle(fontSize: 10),
        amountMd: TextStyle(fontSize: 10),
        headingH1: TextStyle(fontSize: 10),
        titleMd: TextStyle(fontSize: 10),
        bodyLg: TextStyle(fontSize: 10),
        bodyMd: TextStyle(fontSize: 10),
        labelMd: TextStyle(fontSize: 10),
        labelSm: TextStyle(fontSize: 10),
        captionMd: TextStyle(fontSize: 10),
      );
      final result = type.lerp(target, 1);
      for (final style in result.all) {
        expect(style.fontSize, 10);
      }
    });

    test('at t=0 keeps the source sizes', () {
      final result = type.lerp(MonetaTypography.figma(), 0);
      expect(result.amountXl.fontSize, 40);
    });
  });
}
