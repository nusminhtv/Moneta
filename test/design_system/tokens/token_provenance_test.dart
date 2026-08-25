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

  /// Rows keyed by the doc section they appear in, so a colour cannot borrow a
  /// row from the spacing table. `primary` matched `text-primary` and a text
  /// style called `xl` matched the `xl` row of the *spacing* comparison table —
  /// both undocumented values passing a check written to catch exactly that.
  Map<String, Set<String>> documentedByKind() {
    const kindOf = {
      'Colour': 'colour',
      'Typography': 'typography',
      'Radius': 'radius',
      'Elevation': 'elevation',
      'Spacing': 'spacing',
      'Layout': 'layout',
      'Motion': 'motion',
    };
    final rows = <String, Set<String>>{};
    var kind = 'none';
    for (final line in doc.split('\n')) {
      if (line.startsWith('## ')) {
        final heading = line.substring(3).trim();
        kind = kindOf.entries
            .firstWhere(
              (e) => heading.startsWith(e.key),
              orElse: () => const MapEntry('', 'none'),
            )
            .value;
        continue;
      }
      if (!line.startsWith('|')) continue;
      final cells = line.split('|');
      if (cells.length < 3) continue;
      final first = cells[1].trim().replaceAll('`', '');
      if (first.isEmpty || first.startsWith('-') || first == 'Token') continue;
      (rows[kind] ??= <String>{}).add(first.toLowerCase());
    }
    return rows;
  }

  /// The names the doc might use for a camelCase Dart field of a given kind.
  /// Group prefixes are scoped to the kind, so cross-kind borrowing cannot
  /// happen even when two tokens share a bare name.
  Set<String> candidatesFor(String field, String kind) {
    final kebab = field
        .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}-${m[2]}')
        .toLowerCase();
    const groupsByKind = {
      // Only `bg`: the doc's other colour rows are full token names that the
      // camelCase fields already kebab straight onto (`textPrimary` ->
      // `text-primary`). Including `text` as a group let the undocumented field
      // `primary` borrow `text-primary`'s row.
      'colour': ['bg'],
      'typography': [
        'display',
        'heading',
        'title',
        'body',
        'label',
        'caption',
      ],
      'radius': ['radius'],
      'elevation': ['elevation', 'glow', 'shadow'],
      'spacing': ['space'],
    };
    final groups = groupsByKind[kind] ?? const <String>[];
    final head = kebab.split('-').first;
    final tail = kebab.contains('-')
        ? kebab.substring(kebab.indexOf('-') + 1)
        : kebab;
    return {
      kebab,
      if (kind == 'colour') '$kebab-base',
      if (kebab.contains('-') && groups.contains(head)) '$head/$tail',
      for (final group in groups) ...['$group/$kebab', '$group-$kebab'],
      // `space2xs` -> `space/2xs`: the field glues the group to a step name that
      // starts with a digit, so no camelCase boundary exists to split on.
      for (final group in groups)
        if (kebab.startsWith(group))
          '$group/${kebab.substring(group.length).replaceFirst(RegExp('^-'), '')}',
    };
  }

  /// Fields on a token class, as `^  final <Type> <name>;`.
  List<String> fieldsOf(String source, String type) => RegExp(
    '^  final $type (\\w+);',
    multiLine: true,
  ).allMatches(source).map((m) => m.group(1)!).toList();

  void expectAllDocumented(
    List<String> fields,
    String kind,
    Map<String, Set<String>> rows,
  ) {
    expect(
      fields,
      isNotEmpty,
      reason: 'parsed no $kind fields — the check would be vacuous',
    );
    final documented = rows[kind] ?? const <String>{};
    expect(
      documented,
      isNotEmpty,
      reason: 'parsed no $kind rows from the doc — the check would be vacuous',
    );
    final undocumented = fields
        .where((f) => !candidatesFor(f, kind).any(documented.contains))
        .toList();
    expect(
      undocumented,
      isEmpty,
      reason:
          'these $kind values ship with no row in figma-tokens.md, which the '
          'tokens spec says fails verification: ${undocumented.join(', ')}',
    );
  }

  test('the doc has tables this test can actually read', () {
    final rows = documentedByKind();
    expect(rows['colour'], contains('bg-canvas'));
    expect(rows['typography'], contains('body/lg'));
    expect(rows['colour'], contains('border-strong'));
    expect(rows['radius'], isNotEmpty);
    expect(rows['spacing'], isNotEmpty);
  });

  test('a value cannot borrow a row from a different kind of token', () {
    // The guard on the guard. `primary` is not a colour token in this file;
    // `text-primary` is. Matching must not conflate them.
    final rows = documentedByKind();
    expect(
      candidatesFor('primary', 'colour').any(rows['colour']!.contains),
      isFalse,
    );
    expect(
      candidatesFor('xl', 'typography').any(rows['typography']!.contains),
      isFalse,
    );
  });

  test('every text style in `all` has a row naming its Figma source', () {
    final block = typographySource.substring(
      typographySource.indexOf('List<TextStyle> get all => ['),
    );
    final fields = RegExp(r'^\s{4}(\w+),', multiLine: true)
        .allMatches(block.substring(0, block.indexOf('];')))
        .map((m) => m.group(1)!)
        .toList();
    expectAllDocumented(fields, 'typography', documentedByKind());
  });

  test('every colour token has a row naming its Figma source', () {
    expectAllDocumented(
      fieldsOf(colorsSource, 'Color'),
      'colour',
      documentedByKind(),
    );
  });

  test('every radius token has a row naming its Figma source', () {
    expectAllDocumented(
      fieldsOf(
        File('lib/design_system/tokens/radii.dart').readAsStringSync(),
        'double',
      ),
      'radius',
      documentedByKind(),
    );
  });

  test('every Figma-named spacing step has a row', () {
    // Only the `space*` statics — the deprecated instance scale is documented at
    // length as invented, which is the opposite of missing provenance.
    final source = File(
      'lib/design_system/tokens/spacing.dart',
    ).readAsStringSync();
    final fields = RegExp(
      r'^  static const double (space\w+) =',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!).toList();
    expectAllDocumented(fields, 'spacing', documentedByKind());
  });
}
