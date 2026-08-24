import 'package:flutter_test/flutter_test.dart';

import '../../tool/design_token_rules.dart';

/// Tests for the gate itself.
///
/// The design-token checker is the main defence against AI-authored UI drifting
/// away from Figma. If it silently stops matching, nothing else notices — so it
/// gets the same treatment as production code.
void main() {
  List<String> names(String line) =>
      violationsIn(line).map((r) => r.description).toList();

  group('catches hard-coded values', () {
    test('raw ARGB colours', () {
      expect(
        names('  color: const Color(0xFF123456),'),
        contains('raw ARGB colour'),
      );
    });

    test('the Material palette', () {
      expect(names('  color: Colors.red,'), contains('Colors.* palette'));
      expect(names('  color: Colors.white70,'), contains('Colors.* palette'));
    });

    test('inline text styles', () {
      expect(
        names('  style: TextStyle(fontSize: 14),'),
        contains('inline TextStyle'),
      );
      expect(
        names('  const TextStyle(color: x)'),
        contains('inline TextStyle'),
      );
    });

    test('literal EdgeInsets in every constructor form', () {
      for (final line in [
        'padding: const EdgeInsets.all(16),',
        'padding: const EdgeInsets.symmetric(horizontal: 20),',
        'padding: const EdgeInsets.only(top: 8),',
        'padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),',
      ]) {
        expect(
          names(line),
          contains('hard-coded EdgeInsets value'),
          reason: line,
        );
      }
    });

    test('literal BorderRadius', () {
      expect(
        names('borderRadius: BorderRadius.circular(24),'),
        contains('hard-coded BorderRadius value'),
      );
      expect(
        names('borderRadius: BorderRadius.circular( 18 ),'),
        contains('hard-coded BorderRadius value'),
      );
    });
  });

  group('allows token-derived values', () {
    test('a radius read from a token', () {
      // This is the false positive that the original blunt rule produced, and
      // the reason the rules were tightened.
      expect(
        names('borderRadius: BorderRadius.circular(size.fillRadius),'),
        isEmpty,
      );
      expect(
        names('borderRadius: BorderRadius.circular(theme.radii.xl),'),
        isEmpty,
      );
    });

    test('insets read from the spacing scale', () {
      expect(
        names('padding: EdgeInsets.all(theme.spacing.x3l),'),
        isEmpty,
      );
      expect(
        names('padding: EdgeInsets.symmetric(horizontal: spacing.x4l),'),
        isEmpty,
      );
    });

    test('a token name containing a digit is not a literal', () {
      // `x3l` must not read as the number 3.
      expect(names('padding: EdgeInsets.only(top: spacing.x3l),'), isEmpty);
      expect(names('BorderRadius.circular(radii.borderLg.x)'), isEmpty);
    });

    test('applying an existing style is not defining one', () {
      expect(names('style: theme.text.titleMd,'), isEmpty);
      expect(
        names('style: context.moneta.text.bodyMd.copyWith(height: 1),'),
        isEmpty,
      );
    });
  });

  group('escape hatches', () {
    test('a comment line is never a violation', () {
      expect(names('// color: Colors.red,'), isEmpty);
      expect(names('   // padding: EdgeInsets.all(16)'), isEmpty);
    });

    test('the ignore marker suppresses the line', () {
      expect(
        names('color: Colors.red, $ignoreMarker platform requirement'),
        isEmpty,
      );
    });

    test('the marker suppresses every rule on the line, not just one', () {
      expect(
        names(
          'const TextStyle(color: Color(0xFF000000)) $ignoreMarker vendor SDK',
        ),
        isEmpty,
      );
    });
  });

  group('exempt paths', () {
    test('the token and theme layers are exempt', () {
      expect(isExempt('lib/design_system/tokens/colors.dart'), isTrue);
      expect(isExempt('lib/design_system/theme/moneta_theme.dart'), isTrue);
    });

    test('everything else is checked', () {
      expect(isExempt('lib/design_system/atoms/moneta_icon.dart'), isFalse);
      expect(
        isExempt('lib/features/home/presentation/home_screen.dart'),
        isFalse,
      );
      expect(isExempt('lib/app/app.dart'), isFalse);
      // A path that merely mentions tokens must not slip through.
      expect(isExempt('lib/features/tokens/thing.dart'), isFalse);
    });
  });

  group('rule set', () {
    test('every rule has a description and a pattern', () {
      expect(designTokenRules, isNotEmpty);
      for (final rule in designTokenRules) {
        expect(rule.description, isNotEmpty);
        expect(rule.pattern.pattern, isNotEmpty);
      }
    });

    test('descriptions are unique, so failure output is unambiguous', () {
      final descriptions = designTokenRules.map((r) => r.description).toSet();
      expect(descriptions, hasLength(designTokenRules.length));
    });
  });
}
