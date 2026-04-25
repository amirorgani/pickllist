// Architectural fitness test (GUARD-03): 400-line file ceiling.
//
// Counts non-blank, non-comment lines under `lib/` and fails when any
// hand-written file exceeds 400. Generated files (l10n, freezed, etc.)
// are excluded — they regenerate deterministically.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _maxLines = 400;

void main() {
  test('no hand-written lib file exceeds $_maxLines significant lines', () {
    final offenders = <String, int>{};
    for (final file in _dartFilesUnder(Directory('lib'))) {
      if (_isGenerated(file.path)) continue;
      final count = _countSignificantLines(file.readAsStringSync());
      if (count > _maxLines) {
        offenders[file.path.replaceAll(r'\', '/')] = count;
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Files exceed the $_maxLines-line ceiling. Decompose into focused '
          'units (extract widgets, split repos by aggregate, etc.):\n'
          '${offenders.entries.map((e) {
            return '  ${e.key}: ${e.value} lines';
          }).join('\n')}',
    );
  });
}

bool _isGenerated(String path) {
  final normalised = path.replaceAll(r'\', '/');
  if (normalised.endsWith('.g.dart')) return true;
  if (normalised.endsWith('.freezed.dart')) return true;
  if (normalised.endsWith('.gr.dart')) return true;
  if (normalised.contains('/l10n/generated/')) return true;
  if (normalised.endsWith('firebase_options.dart')) return true;
  return false;
}

int _countSignificantLines(String source) {
  var inBlockComment = false;
  var count = 0;
  for (final raw in source.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (inBlockComment) {
      final end = line.indexOf('*/');
      if (end >= 0) {
        inBlockComment = false;
        final after = line.substring(end + 2).trim();
        if (after.isNotEmpty && !after.startsWith('//')) count++;
      }
      continue;
    }
    if (line.startsWith('//')) continue;
    if (line.startsWith('/*')) {
      if (!line.contains('*/')) inBlockComment = true;
      continue;
    }
    count++;
  }
  return count;
}

Iterable<File> _dartFilesUnder(Directory root) sync* {
  if (!root.existsSync()) return;
  for (final entity in root.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}
