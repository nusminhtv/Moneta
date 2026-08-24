import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/tokens/elevation.dart';
import 'package:moneta/design_system/tokens/motion.dart';
import 'package:moneta/design_system/tokens/radii.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

void main() {
  group('radii', () {
    const radii = MonetaRadii.figma();

    test('match the Figma set', () {
      expect(radii.md, 14);
      expect(radii.lg, 18);
      expect(radii.xl, 24);
      expect(radii.pill, 999);
    });

    test('ascend, so a larger name is never a smaller radius', () {
      expect(radii.md < radii.lg, isTrue);
      expect(radii.lg < radii.xl, isTrue);
      expect(radii.xl < radii.pill, isTrue);
    });

    test('expose BorderRadius helpers with the same values', () {
      expect(radii.borderMd, BorderRadius.circular(14));
      expect(radii.borderLg, BorderRadius.circular(18));
      expect(radii.borderXl, BorderRadius.circular(24));
      expect(radii.borderPill, BorderRadius.circular(999));
    });
  });

  group('elevation', () {
    const elevation = MonetaElevation.figma();

    test('level 3 matches the Figma card shadow', () {
      expect(elevation.level3, hasLength(1));
      final shadow = elevation.level3.single;
      expect(shadow.offset, const Offset(0, 12));
      expect(shadow.blurRadius, 32);
      // #0000008C
      expect(shadow.color.a, closeTo(0x8C / 255, 1e-6));
      expect(shadow.color.r, 0);
      expect(shadow.color.g, 0);
      expect(shadow.color.b, 0);
    });

    test('brand glow matches the Figma FAB effect', () {
      final shadow = elevation.brandGlow.single;
      expect(shadow.offset, Offset.zero);
      expect(shadow.blurRadius, 24);
      // #7A5AF859 — 35% of the brand violet, no offset.
      expect(shadow.color.a, closeTo(0x59 / 255, 1e-6));
      expect(shadow.color.r, closeTo(0x7A / 255, 1e-6));
      expect(shadow.color.g, closeTo(0x5A / 255, 1e-6));
      expect(shadow.color.b, closeTo(0xF8 / 255, 1e-6));
    });

    test('the glow spreads without dropping, unlike the card shadow', () {
      expect(elevation.brandGlow.single.offset.dy, 0);
      expect(elevation.level3.single.offset.dy, greaterThan(0));
    });
  });

  group('spacing', () {
    const spacing = MonetaSpacing.figma();

    test('matches the observed Figma values', () {
      expect(spacing.all, [2, 4, 6, 8, 10, 12, 14, 16, 20, 24, 28]);
    });

    test('is strictly ascending, with no duplicate steps', () {
      for (var i = 1; i < spacing.all.length; i++) {
        expect(
          spacing.all[i],
          greaterThan(spacing.all[i - 1]),
          reason: 'step $i must be larger than step ${i - 1}',
        );
      }
    });
  });

  group('layout constants', () {
    test('match the Figma frame', () {
      expect(MonetaLayout.frameWidth, 393);
      expect(MonetaLayout.frameHeight, 852);
      expect(MonetaLayout.safeAreaTop, 59);
      expect(MonetaLayout.safeAreaBottom, 34);
      expect(MonetaLayout.contentWidth, 353);
    });

    test('match the component measurements', () {
      expect(MonetaLayout.bottomNavHeight, 64);
      expect(MonetaLayout.fabSize, 56);
      expect(MonetaLayout.iconSize, 24);
      expect(MonetaLayout.iconStrokeWidth, 1.75);
      expect(MonetaLayout.progressBarHeight, 10);
      expect(MonetaLayout.minTouchTarget, 44);
    });

    test('the content column fits inside the frame with room for padding', () {
      expect(MonetaLayout.contentWidth, lessThan(MonetaLayout.frameWidth));
      const sideMargin =
          (MonetaLayout.frameWidth - MonetaLayout.contentWidth) / 2;
      expect(sideMargin, 20);
    });

    test('the FAB overlaps the nav bar rather than clearing it', () {
      expect(MonetaLayout.fabOverlap, greaterThan(0));
      expect(MonetaLayout.fabOverlap, lessThan(MonetaLayout.fabSize));
    });
  });

  group('motion', () {
    const motion = MonetaMotion.defaults();

    test('durations ascend', () {
      expect(motion.fast < motion.normal, isTrue);
      expect(motion.normal < motion.slow, isTrue);
    });

    test('durations are in a range a user perceives as responsive', () {
      expect(motion.fast.inMilliseconds, inInclusiveRange(100, 200));
      expect(motion.slow.inMilliseconds, lessThanOrEqualTo(500));
    });

    test('curves are set', () {
      expect(motion.standard, isNotNull);
      expect(motion.emphasised, isNotNull);
    });
  });
}
