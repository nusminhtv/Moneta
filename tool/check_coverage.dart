// Line-coverage gate.
//
// Reads coverage/lcov.info and fails when total line coverage is below the
// threshold, or when any file listed in tool/coverage_critical.txt is below the
// stricter critical threshold. Domain and data layers must be near-fully covered
// because they encode the money rules; UI shells are allowed to be thinner.
//
// Usage: dart run tool/check_coverage.dart [--min 70] [--critical-min 90]
import 'dart:io';

void main(List<String> args) {
  final minTotal = _argValue(args, '--min', 70);
  final minCritical = _argValue(args, '--critical-min', 90);

  final lcov = File('coverage/lcov.info');
  if (!lcov.existsSync()) {
    stderr.writeln(
      '✗ coverage: coverage/lcov.info not found — run flutter test --coverage',
    );
    exit(1);
  }

  final perFile = <String, ({int hit, int found})>{};
  String? current;
  var found = 0;
  var hit = 0;

  for (final line in lcov.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = line.substring(3);
      found = 0;
      hit = 0;
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      found++;
      if (parts.length > 1 && int.tryParse(parts[1]) != 0) hit++;
    } else if (line == 'end_of_record' && current != null) {
      perFile[current] = (hit: hit, found: found);
      current = null;
    }
  }

  final totalFound = perFile.values.fold(0, (a, b) => a + b.found);
  final totalHit = perFile.values.fold(0, (a, b) => a + b.hit);
  final totalPct = totalFound == 0 ? 100.0 : totalHit / totalFound * 100;

  final criticalGlobs = File('tool/coverage_critical.txt').existsSync()
      ? File('tool/coverage_critical.txt')
            .readAsLinesSync()
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty && !l.startsWith('#'))
            .toList()
      : <String>[];

  final failures = <String>[];
  for (final entry in perFile.entries) {
    if (!criticalGlobs.any(entry.key.contains)) continue;
    final pct = entry.value.found == 0
        ? 100.0
        : entry.value.hit / entry.value.found * 100;
    if (pct < minCritical) {
      failures.add(
        '  ${entry.key}: ${pct.toStringAsFixed(1)}% (critical minimum $minCritical%)',
      );
    }
  }

  stdout.writeln(
    'coverage: ${totalPct.toStringAsFixed(1)}% total '
    '($totalHit/$totalFound lines, ${perFile.length} files)',
  );

  if (totalPct < minTotal) {
    failures.insert(
      0,
      '  total: ${totalPct.toStringAsFixed(1)}% (minimum $minTotal%)',
    );
  }

  if (failures.isNotEmpty) {
    stderr
      ..writeln('✗ coverage below threshold:')
      ..writeln(failures.join('\n'));
    exit(1);
  }

  stdout.writeln('✓ coverage: thresholds met');
}

int _argValue(List<String> args, String flag, int fallback) {
  final i = args.indexOf(flag);
  if (i == -1 || i + 1 >= args.length) return fallback;
  return int.tryParse(args[i + 1]) ?? fallback;
}
