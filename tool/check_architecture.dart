// Architecture boundary checker.
//
// The analyzer cannot express "layer A may not import layer B", so this script
// does. It is a hard gate in tool/verify.sh and in CI, which means an AI-authored
// change that quietly reaches across a boundary fails before review, not after.
//
// Usage: dart run tool/check_architecture.dart
import 'dart:io';

/// Import rules keyed by the source directory under `lib/`.
///
/// A file in that directory may only import `package:moneta/...` paths whose first
/// segments match one of the allowed prefixes, plus the special token
/// `self` meaning "anything under my own feature".
const Map<String, List<String>> _allowedImports = {
  'core': ['core'],
  'data': ['core', 'data'],
  'design_system': ['core', 'design_system'],
  'features': ['core', 'design_system', 'data', 'self'],
  'app': ['core', 'design_system', 'data', 'features', 'app'],
};

void main(List<String> args) {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('lib/ not found — run from the repository root.');
    exit(2);
  }

  final violations = <String>[];

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final relative = entity.path.replaceFirst('lib/', '');
    final layer = relative.split('/').first;
    final allowed = _allowedImports[layer];
    if (allowed == null) continue;

    final ownFeature = layer == 'features' && relative.split('/').length > 1
        ? relative.split('/')[1]
        : null;

    for (final line in entity.readAsLinesSync()) {
      final match = RegExp(
        r'''^\s*import\s+'package:moneta/([^']+)';''',
      ).firstMatch(line);
      if (match == null) continue;

      final target = match.group(1)!;
      final targetLayer = target.split('/').first;
      final targetFeature =
          targetLayer == 'features' && target.split('/').length > 1
          ? target.split('/')[1]
          : null;

      final sameFeature = ownFeature != null && targetFeature == ownFeature;
      final ok =
          allowed.contains(targetLayer) ||
          (allowed.contains('self') && sameFeature);

      // Cross-feature imports are never allowed; share through core/ or data/.
      final crossFeature =
          layer == 'features' && targetLayer == 'features' && !sameFeature;

      if (!ok || crossFeature) {
        violations.add(
          '  ${entity.path}\n'
          '    imports package:moneta/$target\n'
          '    → "$layer" may only import: ${allowed.join(", ")}'
          '${crossFeature ? " (cross-feature imports are forbidden)" : ""}',
        );
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('✓ architecture: no layer-boundary violations');
    return;
  }

  stderr
    ..writeln('✗ architecture: ${violations.length} violation(s)\n')
    ..writeln(violations.join('\n\n'));
  exit(1);
}
