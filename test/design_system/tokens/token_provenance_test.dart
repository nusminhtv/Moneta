import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the contract `docs/design-system/figma-tokens.md` states in its own
/// first line: every design value used in code names the Figma node it was read
/// from.
///
/// The tokens spec delta in `onboarding-flow` asserts that a token with no row in
/// that file fails verification. It said so before anything checked it — the same
/// defect as a requirement stating a style count: a claim about enforcement with
/// no enforcement behind it. `border-strong` and `body/lg` both shipped in UI for
/// a whole change with no row, and adding an eleventh style with no row passed
/// 269 token tests.
///
/// A plain `test()`, not `testWidgets`: file I/O in a FakeAsync zone never
/// completes and would hang rather than fail. See CLAUDE.md.
void main() {
  late String doc;
  late String typographySource;
  late String colorsSource;

  setUpAll(() {
    doc = File('docs/design-system/figma-tokens.md').readAsStringSync();
    typographySource = File(
      'lib/design_system/tokens/typography.dart',
    ).readAsStringSync();
    colorsSource = File(
      'lib/design_system/tokens/colors.dart',
    ).readAsStringSync();
  });

  /// Every row's first cell in the doc's tables, lowercased.
  Set<String> documentedTokens() {
    final names = <String>{};
    for (final line in doc.split('\n')) {
      if (!line.startsWith('|')) continue;
      final cells = line.split('|');
      if (cells.length < 3) continue;
      final first = cells[1].trim().replaceAll('`', '');
      if (first.isEmpty || first.startsWith('-') || first == 'Token') continue;
      names.add(first.toLowerCase());
    }
    return names;
  }

  /// `amountXl` -> `display/amount-xl` style candidates, since the doc names
  /// tokens as Figma does and the Dart fields are camelCase.
  /// `amountXl` -> the names the doc might use for it. The doc names tokens as
  /// Figma does: a `bg-`/`text-` prefix, a `display/` group, or a `-base`
  /// suffix on a semantic colour. The Dart fields are camelCase and drop all of
  /// that, so a small set of candidates is tried rather than one rigid rule.
  Set<String> candidatesFor(String field) {
    final kebab = field
        .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}-${m[2]}')
        .toLowerCase();
    const groups = [
      'display',
      'heading',
      'title',
      'body',
      'label',
      'caption',
      'text',
      'bg',
      'border',
      'brand',
      'chart',
    ];
    // amountXl -> amount-xl; the doc groups it as display/amount-xl. bodyLg ->
    // body-lg, documented as body/lg, so the leading word may become the group.
    final head = kebab.split('-').first;
    final tail = kebab.contains('-')
        ? kebab.substring(kebab.indexOf('-') + 1)
        : kebab;
    return {
      kebab,
      '$kebab-base',
      if (kebab.contains('-')) '$head/$tail',
      for (final group in groups) ...['$group/$kebab', '$group-$kebab'],
    };
  }

  test('the doc has tables this test can actually read', () {
    final documented = documentedTokens();
    expect(
      documented,
      isNotEmpty,
      reason: 'parsed no token rows — this check would pass vacuously',
    );
    // Spot-check a few known rows so a reformat that breaks parsing is loud.
    expect(documented, contains('bg-canvas'));
    expect(documented, contains('body/lg'));
    expect(documented, contains('border-strong'));
  });

  test('every text style in `all` has a row naming its Figma source', () {
    final documented = documentedTokens();
    // The fields listed in `all`, which is what ships.
    final block = typographySource.substring(
      typographySource.indexOf('List<TextStyle> get all => ['),
    );
    final fields = RegExp(r'^\s{4}(\w+),', multiLine: true)
        .allMatches(block.substring(0, block.indexOf('];')))
        .map((m) => m.group(1)!)
        .toList();

    expect(
      fields,
      hasLength(greaterThan(5)),
      reason: 'failed to parse the `all` list — the check would be vacuous',
    );

    final undocumented = <String>[];
    for (final field in fields) {
      if (!candidatesFor(field).any(documented.contains)) {
        undocumented.add(field);
      }
    }
    expect(
      undocumented,
      isEmpty,
      reason:
          'these text styles ship with no row in figma-tokens.md, which the '
          'tokens spec says fails verification: ${undocumented.join(', ')}',
    );
  });

  test('every colour token has a row naming its Figma source', () {
    final documented = documentedTokens();
    // Top-level `final Color x` fields on MonetaColors. Nested palettes (chart,
    // brand) carry their own tables and are matched by prefix above.
    final fields = RegExp(
      r'^\s{2}final Color (\w+);',
      multiLine: true,
    ).allMatches(colorsSource).map((m) => m.group(1)!).toList();

    expect(
      fields,
      hasLength(greaterThan(5)),
      reason: 'failed to parse the colour fields — the check would be vacuous',
    );

    final undocumented = <String>[];
    for (final field in fields) {
      if (!candidatesFor(field).any(documented.contains)) {
        undocumented.add(field);
      }
    }
    expect(
      undocumented,
      isEmpty,
      reason:
          'these colours ship with no row in figma-tokens.md: '
          '${undocumented.join(', ')}',
    );
  });
}
