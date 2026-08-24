// Design-token discipline checker.
//
// Moneta is built design-system-first from Figma. Every colour, radius, spacing
// and text style must resolve through lib/design_system/tokens. Hard-coded values
// outside the design system are the single most common way AI-generated UI drifts
// away from the source design, so they fail the build.
//
// Usage: dart run tool/check_design_tokens.dart
import 'dart:io';

final _bannedPatterns = <String, RegExp>{
  'raw ARGB colour': RegExp(r'Color\(0x'),
  'Colors.* palette': RegExp(r'\bColors\.[a-zA-Z]'),
  'inline TextStyle': RegExp(r'\bTextStyle\('),
  'magic EdgeInsets': RegExp(r'EdgeInsets\.(all|symmetric|only|fromLTRB)\('),
  'magic BorderRadius': RegExp(r'BorderRadius\.circular\('),
};

/// Paths where raw values are legitimate: the token definitions themselves.
const _exemptPrefixes = <String>[
  'lib/design_system/tokens/',
  'lib/design_system/theme/',
];

void main(List<String> args) {
  final violations = <String>[];

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (_exemptPrefixes.any(entity.path.startsWith)) continue;

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trimLeft().startsWith('//')) continue;
      if (line.contains('// design-token-ignore')) continue;

      for (final entry in _bannedPatterns.entries) {
        if (entry.value.hasMatch(line)) {
          violations.add(
            '  ${entity.path}:${i + 1}  ${entry.key}\n'
            '    ${line.trim()}',
          );
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln(
      '✓ design tokens: no hard-coded design values outside tokens/',
    );
    return;
  }

  stderr
    ..writeln('✗ design tokens: ${violations.length} violation(s)\n')
    ..writeln(violations.join('\n'))
    ..writeln(
      '\nUse MonetaTokens / Theme.of(context).extension<MonetaTheme>() instead.\n'
      'If a raw value is genuinely required, append "// design-token-ignore" '
      'with a reason on the same line.',
    );
  exit(1);
}
