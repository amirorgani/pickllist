// Architectural fitness test (GUARD-03): ARB translation parity.
//
// All locale ARB files under `lib/l10n/` must define the same set of
// translation keys. Metadata keys (those starting with `@`) are excluded
// from the parity check but still parsed.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every ARB locale defines the same translation keys', () {
    final arbDir = Directory('lib/l10n');
    final files =
        arbDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.arb'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    expect(files, isNotEmpty, reason: 'no ARB files found under lib/l10n');

    final perFile = <String, Set<String>>{};
    for (final f in files) {
      final raw = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      perFile[f.path.replaceAll('\\', '/')] = raw.keys
          .where((k) => !k.startsWith('@'))
          .toSet();
    }

    final union = perFile.values.fold<Set<String>>(
      <String>{},
      (acc, keys) => acc..addAll(keys),
    );

    final missingPerFile = <String, Set<String>>{};
    perFile.forEach((path, keys) {
      final missing = union.difference(keys);
      if (missing.isNotEmpty) missingPerFile[path] = missing;
    });

    expect(
      missingPerFile,
      isEmpty,
      reason:
          'ARB files have drifted out of parity. Add the missing keys '
          '(or remove them everywhere):\n'
          '${missingPerFile.entries.map((e) => '  ${e.key}: missing ${e.value.toList()..sort()}').join('\n')}',
    );
  });
}
