// Design-token discipline checker.
//
// Moneta is built design-system-first from Figma. Every colour, radius, spacing
// and text style must resolve through lib/design_system/tokens. Hard-coded values
// outside the design system are the single most common way AI-generated UI drifts
// away from the source design, so they fail the build.
//
// The rules live in design_token_rules.dart so they can be unit-tested; see
// test/tool/design_token_rules_test.dart.
//
// Usage: dart run tool/check_design_tokens.dart
import 'dart:io';

import 'design_token_rules.dart';

void main(List<String> args) {
  final violations = <String>[];

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (isExempt(entity.path)) continue;

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      for (final rule in violationsIn(lines[i])) {
        violations.add(
          '  ${entity.path}:${i + 1}  ${rule.description}\n'
          '    ${lines[i].trim()}',
        );
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
      '\nUse context.moneta tokens instead.\n'
      'If a raw value is genuinely required, append "$ignoreMarker" '
      'with a reason on the same line.',
    );
  exit(1);
}
