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
      // A row only counts as provenance if some cell actually names a node
      // (`39:243`) or explicitly says the value was not observed. Reading only
      // the name meant `| radius-bogus | | |` — every other cell empty —
      // satisfied a requirement whose words are "naming the Figma node it was
      // read from". The check read the file and ignored the provenance.
      final rest = cells.skip(2).join(' ');
      final hasNode = RegExp(r'\b\d+:\d+\b').hasMatch(rest);
      // "not observed" is only provenance for a value that is genuinely not
      // Figma-derived and says where it *did* come from. On its own it was a
      // free pass: a row reading `| rogue-tint | #00FF00 | not observed |`
      // legitimised an implemented colour, while the spec's own scenario says
      // not-observed means left unimplemented, or implemented from a named
      // non-Figma source.
      final saysDerived =
          RegExp('not observed', caseSensitive: false).hasMatch(rest) &&
          RegExp(
            'derived|material|ours|not figma',
            caseSensitive: false,
          ).hasMatch(rest);
      if (!hasNode && !saysDerived) continue;
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
      'layout': <String>[],
    };
    // A handful of Dart names do not derive from their doc name by any rule:
    // `level3` is documented as `elevation/3`, and `brandGlow` as `glow/brand`
    // with the words the other way round. Aliasing them explicitly is honest
    // where widening the matcher would not be — an alias can only ever match a
    // row that really exists, and a dead alias fails its own test below.
    const aliases = {'level3': 'elevation/3', 'brandGlow': 'glow/brand'};
    final groups = groupsByKind[kind] ?? const <String>[];
    final head = kebab.split('-').first;
    final tail = kebab.contains('-')
        ? kebab.substring(kebab.indexOf('-') + 1)
        : kebab;
    return {
      kebab,
      if (aliases.containsKey(field)) aliases[field]!,
      if (kind == 'colour') '$kebab-base',
      if (kebab.contains('-') && groups.contains(head)) '$head/$tail',
      // Gated on a hyphen unless the kind has exactly one group. `amountXl` ->
      // `amount-xl` genuinely needs `display/amount-xl`, but ungated across
      // typography's six groups the same rule let a style renamed to a bare `sm`
      // borrow the row for `label/sm`. Colour (`bg`), radius (`radius`) and
      // spacing (`space`) each have one group and bare field names — `canvas`
      // must reach `bg-canvas` and `pill` must reach `radius-pill` — so there is
      // only one prefix to borrow from and nothing to confuse it with.
      if (kebab.contains('-') || groups.length == 1)
        for (final group in groups) ...['$group/$kebab', '$group-$kebab'],
      // `space2xs` -> `space/2xs`: the field glues the group to a step name that
      // starts with a digit, so no camelCase boundary exists to split on.
      for (final group in groups)
        if (kebab.startsWith(group))
          '$group/${kebab.substring(group.length).replaceFirst(RegExp('^-'), '')}',
    };
  }

  /// Every identifier in a token file that holds a design value, in **any**
  /// declaration form.
  ///
  /// The previous version matched one form per kind — `^  final Color`,
  /// `^  static const double space…`, and the `all` getter — so a colour
  /// declared `static const`, a text style declared as a getter or left out of
  /// `all`, and a length not prefixed `space` were all invisible. Three separate
  /// probes walked past it. Matching every form is the only version of this that
  /// cannot be evaded by choosing a different keyword.
  List<String> valuesIn(String source, List<String> types) {
    final names = <String>{};
    final typeAlternation = types.map(RegExp.escape).join('|');
    for (final pattern in [
      // `final <Type> x;`   /  `final <Type> x = …`
      '^\\s*final (?:$typeAlternation) (\\w+)\\s*[;=]',
      // `static const <Type> x = …`  /  `const <Type> x = …`
      '^\\s*(?:static\\s+)?const (?:$typeAlternation) (\\w+)\\s*=',
      // `<Type> get x`
      '^\\s*(?:$typeAlternation) get (\\w+)',
      // Untyped, inferred from the initialiser: `static const x = Color(0x…)`.
      // Omitting the annotation defeated every typed pattern — an undocumented
      // `static const oopsUntyped = Color(0xFF123456)` passed the whole gate.
      // `\\s*` rather than `\\s{2}` throughout, because anchoring at
      // class-member indent made a top-level declaration invisible too.
      '^\\s*(?:static\\s+)?(?:const|final) (\\w+)\\s*=\\s*(?:const\\s+)?(?:$typeAlternation)[(.]',
    ]) {
      names.addAll(
        RegExp(pattern, multiLine: true)
            .allMatches(source)
            .map((m) => m.group(1)!)
            .where((n) => !n.startsWith('_')),
      );
    }
    return names.toList();
  }

  /// Every type that appears in a token file's declarations, so `valuesIn` is
  /// driven by the file rather than by a hand-written type list.
  ///
  /// Passing `['Color']` and `['double']` by hand is how `List<BoxShadow>` in
  /// `elevation.dart` stayed outside the check entirely: the parser could read
  /// the section, it was simply never asked about that type.
  List<String> typesIn(String source) => {
    for (final pattern in [
      r'^\s*(?:static\s+)?(?:final|const) ([A-Z]\w*(?:<[^>]*>)?) \w+\s*[;=]',
      // Getters too. Matching only `final`/`const` meant a getter of a novel
      // type — `Shadow get rogueShadow => …` — escaped both the type lookup and
      // the "no unchecked type" guard that exists to catch exactly that.
      r'^\s*([A-Z]\w*(?:<[^>]*>)?) get \w+',
    ])
      ...RegExp(pattern, multiLine: true)
          .allMatches(source)
          .map(
            (m) => m.group(1)!,
          ),
  }.toList();

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

  test('every text style has a row naming its Figma source', () {
    // Every `TextStyle` on the class, not only the ones listed in `all` — a
    // style could be declared, used, and omitted from `all` to escape the count
    // check that used to be the only backstop here.
    expectAllDocumented(
      valuesIn(typographySource, ['TextStyle']),
      'typography',
      documentedByKind(),
    );
  });

  test('the `all` list is the whole type set, not a subset', () {
    // Guards the other direction: a style that exists but is left out of `all`
    // never reaches the theme, which looks like a missing style rather than a
    // wiring bug.
    final block = typographySource.substring(
      typographySource.indexOf('List<TextStyle> get all => ['),
    );
    final listed = RegExp(r'^\s{4}(\w+),', multiLine: true)
        .allMatches(block.substring(0, block.indexOf('];')))
        .map((m) => m.group(1)!)
        .toSet();
    expect(
      valuesIn(typographySource, ['TextStyle']).toSet(),
      listed,
      reason: 'a declared text style is missing from `all`, or vice versa',
    );
  });

  test('every colour token has a row naming its Figma source', () {
    expectAllDocumented(
      valuesIn(colorsSource, ['Color']),
      'colour',
      documentedByKind(),
    );
  });

  test('every radius token has a row naming its Figma source', () {
    expectAllDocumented(
      valuesIn(
        File(
          'lib/design_system/tokens/radii.dart',
        ).readAsStringSync(),
        ['double'],
      ),
      'radius',
      documentedByKind(),
    );
  });

  test('every spacing and layout value has a row', () {
    // RESTORED. Commit b8e8091 — whose stated purpose was making these checks
    // fail closed — deleted this test in the same hunk that added the elevation
    // one. It was passing and load-bearing: without it an undocumented
    // `static const double spaceBogus = 7` in MonetaSpacing, and a `rogueWidth`
    // in MonetaLayout, both pass the entire gate. Meanwhile tasks.md 8.3, 9.3
    // and 9.4, the "Still not fixed" section and figma-tokens.md's Layout
    // heading all went on asserting that this check existed.
    //
    // That is a gate removed without saying so, which CLAUDE.md rule 5 forbids,
    // inside the round that was supposed to end this class of defect. Caught by
    // the sixth review, not by me and not by the gate.
    final source = File(
      'lib/design_system/tokens/spacing.dart',
    ).readAsStringSync();
    final spacingClass = source.substring(
      source.indexOf('class MonetaSpacing'),
      source.indexOf('class MonetaLayout'),
    );
    final layoutClass = source.substring(source.indexOf('class MonetaLayout'));
    final rows = documentedByKind();

    // Selected by declaration form, not by a `space` name prefix: an
    // undocumented `static const double gutter = 21` slipped straight past the
    // prefix filter. Figma's scale is `static const`; the deprecated invented
    // scale is instance `final` fields, documented at length as invented.
    final staticScale = RegExp(
      r'^\s{2}static const double (\w+)\s*=',
      multiLine: true,
    ).allMatches(spacingClass).map((m) => m.group(1)!).toList();
    expect(
      staticScale,
      contains('spaceBase'),
      reason: 'failed to parse the static scale — the check would be vacuous',
    );
    expectAllDocumented(staticScale, 'spacing', rows);
    expectAllDocumented(valuesIn(layoutClass, ['double']), 'layout', rows);
  });

  test('every elevation and effect token has a row', () {
    // `List<BoxShadow>` was outside the check not because the parser could not
    // read the Elevation section but because nobody passed it that type. Types
    // now come from the file.
    final source = File(
      'lib/design_system/tokens/elevation.dart',
    ).readAsStringSync();
    expectAllDocumented(
      valuesIn(source, typesIn(source)),
      'elevation',
      documentedByKind(),
    );
  });

  test('no token file declares a type the check never asks about', () {
    // The guard on the guard, and the one that would have caught
    // `List<BoxShadow>`, the untyped declaration and the top-level declaration
    // before a reviewer did. Every type declared in every token file must be
    // one this suite actually looks up, or explicitly listed as carrying no
    // design value.
    const notDesignValues = {
      // Structural, not design values: the token classes themselves, and the
      // Flutter types they are built out of.
      'MonetaColors', 'MonetaTypography', 'MonetaRadii', 'MonetaElevation',
      'MonetaMotion', 'MonetaChartPalette', 'MonetaSpacing',
      'String', 'bool', 'int', 'Duration', 'Curve', 'FontWeight',
      'BorderRadius', 'Gradient', 'LinearGradient', 'Alignment',
      // Aggregates of values already checked individually: `figmaScale` and
      // `all` list the same twelve `space/*` steps the spacing test above
      // covers, and `List<TextStyle> all` the styles the typography test covers.
      'List<double>',
      'List<TextStyle>',
    };
    const checked = {
      'Color',
      'TextStyle',
      'double',
      'List<BoxShadow>',
      'BoxShadow',
      'List<Color>',
    };
    final unchecked = <String>{};
    for (final file in Directory(
      'lib/design_system/tokens',
    ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      for (final type in typesIn(file.readAsStringSync())) {
        if (!checked.contains(type) && !notDesignValues.contains(type)) {
          unchecked.add('$type (${file.path})');
        }
      }
    }
    expect(
      unchecked,
      isEmpty,
      reason:
          'these declared types hold values nothing checks for provenance. '
          'Either look them up or say why they are not design values: '
          '${unchecked.join(', ')}',
    );
  });

  test('every provenance alias points at a row that exists', () {
    // Aliases are additive, so a stale one cannot make an undocumented value
    // pass — but it can make the map read as more considered than it is, which
    // is what nine dead gallery exemptions did.
    final rows = documentedByKind();
    final all = rows.values.expand((r) => r).toSet();
    for (final target in ['elevation/3', 'glow/brand']) {
      expect(
        all,
        contains(target),
        reason: 'alias target "$target" is not a documented row any more',
      );
    }
  });

  test('the deprecated instance scale is still called out as invented', () {
    // Not provenance — the opposite. If this heading ever loses its warning, the
    // exclusion above silently starts hiding real gaps.
    expect(doc, contains('OUR SCALE IS INVENTED AND WRONGLY NAMED'));
  });
}
