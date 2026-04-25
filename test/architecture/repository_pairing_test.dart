// Architectural fitness test (GUARD-03): abstract/fake repository pairing.
//
// Every abstract repository under `lib/features/*/data/` must have at
// least one concrete `Fake*` implementation in the same directory. This
// keeps the test surface honest: when someone adds a new abstract repo,
// they cannot forget the in-memory fake that the rest of the suite
// relies on.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every abstract repository has a Fake* sibling', () {
    final orphans = <String>[];
    for (final dataDir in _dataDirs()) {
      final files = dataDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      final declarations = <String, File>{};
      for (final file in files) {
        for (final name in _classDeclarations(file.readAsStringSync())) {
          declarations[name] = file;
        }
      }
      for (final entry in declarations.entries) {
        final name = entry.key;
        if (!_isAbstract(entry.value.readAsStringSync(), name)) continue;
        if (!name.endsWith('Repository')) continue;
        final fakeName = 'Fake$name';
        if (!declarations.containsKey(fakeName)) {
          orphans.add(
            '${entry.value.path.replaceAll(r'\', '/')}: '
            '$name has no $fakeName sibling in the same directory',
          );
        }
      }
    }
    expect(
      orphans,
      isEmpty,
      reason:
          'Add an in-memory Fake* implementation alongside each abstract '
          'repository so tests have something to wire up:\n'
          '${orphans.join('\n')}',
    );
  });
}

Iterable<Directory> _dataDirs() sync* {
  final root = Directory('lib/features');
  if (!root.existsSync()) return;
  for (final feature in root.listSync().whereType<Directory>()) {
    final data = Directory('${feature.path}/data');
    if (data.existsSync()) yield data;
  }
}

Iterable<String> _classDeclarations(String source) sync* {
  final pattern = RegExp(
    r'^(?:abstract\s+|sealed\s+|base\s+|interface\s+|final\s+|mixin\s+)*'
    r'class\s+([A-Z][A-Za-z0-9_]*)',
    multiLine: true,
  );
  for (final m in pattern.allMatches(source)) {
    yield m.group(1)!;
  }
}

bool _isAbstract(String source, String className) {
  final pattern = RegExp(
    r'^abstract\s+(?:class|interface\s+class|base\s+class|sealed\s+class)\s+'
    '$className'
    r'\b',
    multiLine: true,
  );
  return pattern.hasMatch(source);
}
