import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// Transcription test for Figma's real spacing collection, node `107:75`.
///
/// The project previously shipped a scale reverse-engineered from literal gaps in
/// component nodes, asserted under the name "matches the observed Figma values".
/// It matched nothing that had been read from Figma. These are the values that
/// were read.
void main() {
  group("Figma's collection", () {
    test('every token has the authored value', () {
      expect(MonetaSpacing.space0, 0);
      expect(MonetaSpacing.space2xs, 2);
      expect(MonetaSpacing.spaceXs, 4);
      expect(MonetaSpacing.spaceSm, 8);
      expect(MonetaSpacing.spaceMd, 12);
      expect(MonetaSpacing.spaceBase, 16);
      expect(MonetaSpacing.spaceLg, 20);
      expect(MonetaSpacing.spaceXl, 24);
      expect(MonetaSpacing.space2xl, 32);
      expect(MonetaSpacing.space3xl, 40);
      expect(MonetaSpacing.space4xl, 48);
      expect(MonetaSpacing.space5xl, 64);
    });

    test('has exactly twelve steps, strictly ascending', () {
      expect(MonetaSpacing.figmaScale, hasLength(12));
      for (var i = 1; i < MonetaSpacing.figmaScale.length; i++) {
        expect(
          MonetaSpacing.figmaScale[i],
          greaterThan(MonetaSpacing.figmaScale[i - 1]),
        );
      }
    });

    test('the screen gutter is 20, which is what screens must use', () {
      // Figma's stated purpose for space/lg. Every screen frame is 393 wide with
      // a 353 content column, and (393 - 353) / 2 = 20.
      expect(MonetaSpacing.spaceLg, 20);
    });
  });

  group('the deprecated scale', () {
    const old = MonetaSpacing.figma();

    test('is still present so existing widgets compile', () {
      expect(old.all, hasLength(11));
    });

    test(
      'disagrees with Figma on every name past xs — which is why it is going',
      () {
        // Recorded as a test so the defect cannot be forgotten before the
        // migration lands.
        expect(old.xxs, MonetaSpacing.space2xs, reason: '2 — agrees');
        expect(old.xs, MonetaSpacing.spaceXs, reason: '4 — agrees');

        expect(old.sm, isNot(MonetaSpacing.spaceSm), reason: '6 vs 8');
        expect(old.md, isNot(MonetaSpacing.spaceMd), reason: '8 vs 12');
        expect(old.lg, isNot(MonetaSpacing.spaceLg), reason: '10 vs 20');
        expect(old.xl, isNot(MonetaSpacing.spaceXl), reason: '12 vs 24');
      },
    );

    test('contains four steps that are not spacing tokens at all', () {
      for (final orphan in [old.sm, old.lg, old.xxl, old.x6l]) {
        expect(
          MonetaSpacing.figmaScale,
          isNot(contains(orphan)),
          reason: "$orphan is not in Figma's spacing collection",
        );
      }
    });
  });
}
