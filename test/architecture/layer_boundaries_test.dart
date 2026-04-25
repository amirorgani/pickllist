// Architectural fitness tests (GUARD-03): import-rule invariants.
//
// These tests parse `lib/` source files and assert the layering rules
// documented in `docs/guardrails.md`:
//
// - `lib/features/*/domain/` files import only other domain files,
//   `package:collection`, or `dart:*` — never Flutter/Firebase/Riverpod.
// - `lib/features/*/data/` files do not import `presentation/`.
// - `lib/features/*/presentation/` files do not reach into another
//   feature's `data/` directly. Cross-feature collaboration goes
//   through `application/`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final featuresDir = Directory('lib/features');

  test('domain imports stay inside the domain allowlist', () {
    final violations = <String>[];
    for (final file in _dartFilesIn(featuresDir, layer: 'domain')) {
      for (final import in _packageImports(file)) {
        if (_isAllowedDomainImport(import)) continue;
        violations.add('${_rel(file)}: $import');
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'domain files may only import other domain files, '
          'package:collection, or dart:* — move framework dependencies up to '
          'presentation/data:\n'
          '${violations.join('\n')}',
    );
  });

  test('data files do not import presentation', () {
    final violations = <String>[];
    for (final file in _dartFilesIn(featuresDir, layer: 'data')) {
      for (final import in _packageImports(file)) {
        if (import.startsWith('package:pickllist/features/') &&
            import.contains('/presentation/')) {
          violations.add('${_rel(file)}: $import');
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'data files must not depend on presentation:\n'
          '${violations.join('\n')}',
    );
  });

  test("presentation files do not reach into another feature's data", () {
    final violations = <String>[];
    for (final file in _dartFilesIn(featuresDir, layer: 'presentation')) {
      final ownFeature = _featureOf(file);
      for (final import in _packageImports(file)) {
        if (!import.startsWith('package:pickllist/features/')) continue;
        if (!import.contains('/data/')) continue;
        final targetFeature = _featureFromImport(import);
        if (targetFeature == ownFeature) continue;
        violations.add('${_rel(file)}: $import');
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'presentation files must collaborate with other features via '
          'application/, not data/:\n'
          '${violations.join('\n')}',
    );
  });
}

bool _isAllowedDomainImport(String import) {
  if (import.startsWith('dart:')) return true;
  if (import == 'package:collection/collection.dart' ||
      import.startsWith('package:collection/')) {
    return true;
  }
  if (import.startsWith('package:pickllist/features/') &&
      import.contains('/domain/')) {
    return true;
  }
  // Relative imports inside a domain/ folder are sibling-only by Dart's
  // resolution rules — `import 'quantity_unit.dart';` cannot escape the
  // current directory, so it stays within domain.
  if (!import.startsWith('package:') && !import.contains('/')) return true;
  return false;
}

String? _featureOf(File file) {
  final segments = file.path.replaceAll(r'\', '/').split('/');
  final idx = segments.indexOf('features');
  if (idx < 0 || idx + 1 >= segments.length) return null;
  return segments[idx + 1];
}

String? _featureFromImport(String import) {
  const prefix = 'package:pickllist/features/';
  if (!import.startsWith(prefix)) return null;
  final rest = import.substring(prefix.length);
  final slash = rest.indexOf('/');
  if (slash < 0) return null;
  return rest.substring(0, slash);
}

Iterable<File> _dartFilesIn(Directory root, {required String layer}) sync* {
  if (!root.existsSync()) return;
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    final normalised = entity.path.replaceAll(r'\', '/');
    if (normalised.contains('/$layer/')) yield entity;
  }
}

Iterable<String> _packageImports(File file) sync* {
  final pattern = RegExp('^import\\s+[\'"]([^\'"]+)[\'"]', multiLine: true);
  for (final m in pattern.allMatches(file.readAsStringSync())) {
    yield m.group(1)!;
  }
}

String _rel(File file) => file.path.replaceAll(r'\', '/');
