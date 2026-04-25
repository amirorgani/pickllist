import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/generate_api_snapshot.dart';

void main() {
  test('public API matches committed snapshot', () async {
    final symbols = await collectPublicApi(libDir: defaultLibDir);
    final actual = renderSnapshot(symbols);
    final expected = await File(defaultSnapshotPath).readAsString();
    if (actual != expected) {
      fail(
        'Public API surface diverged from $defaultSnapshotPath.\n'
        'If the change is intentional, regenerate and commit the new '
        'snapshot in the same PR:\n'
        '  dart run tool/generate_api_snapshot.dart --write\n'
        'Diff (expected vs actual):\n'
        '${_renderDiff(expected: expected, actual: actual)}',
      );
    }
  });

  group('extractSymbols', () {
    test('captures the canonical declaration keywords', () {
      final source = '''
class Foo {}
abstract class Bar {}
sealed class Baz {}
final class Qux extends Foo {}
mixin Mixed on Foo {}
mixin class HybridMixin {}
enum Color { red, green }
extension OnFoo on Foo { void m() {} }
typedef Callback = void Function(int);
class _Private {}
''';
      final symbols = extractSymbols(source: source, path: 'lib/sample.dart');
      final declarations = symbols.map((s) => s.declaration).toList();
      expect(declarations, contains('class Foo'));
      expect(declarations, contains('abstract class Bar'));
      expect(declarations, contains('sealed class Baz'));
      expect(declarations, contains('final class Qux'));
      expect(declarations, contains('mixin Mixed'));
      expect(declarations, contains('mixin class HybridMixin'));
      expect(declarations, contains('enum Color'));
      expect(declarations, contains('extension OnFoo'));
      expect(declarations, contains('typedef Callback'));
      expect(
        declarations.where((d) => d.contains('_Private')),
        isEmpty,
        reason: 'Private declarations must not enter the surface snapshot.',
      );
    });

    test('strips inheritance, generics, and trailing braces', () {
      final source = '''
class Generic<T extends Object?> with Mixed implements Foo {}
class WithBody { void m() {} }
''';
      final symbols = extractSymbols(source: source, path: 'lib/x.dart');
      final declarations = symbols.map((s) => s.declaration).toSet();
      expect(declarations.contains('class Generic'), isTrue);
      expect(declarations.contains('class WithBody'), isTrue);
    });

    test('ignores comments and indented declarations', () {
      final source = '''
// class CommentedOut {}
   class Indented {}
''';
      final symbols = extractSymbols(source: source, path: 'lib/x.dart');
      expect(symbols, isEmpty);
    });
  });

  group('renderSnapshot', () {
    test('sorts symbols alphabetically by their full line', () {
      final unsorted = [
        ApiSymbol(path: 'lib/b.dart', declaration: 'class B'),
        ApiSymbol(path: 'lib/a.dart', declaration: 'class Z'),
        ApiSymbol(path: 'lib/a.dart', declaration: 'class A'),
      ];
      final rendered = renderSnapshot(unsorted);
      expect(
        rendered,
        'lib/a.dart::class A\n'
        'lib/a.dart::class Z\n'
        'lib/b.dart::class B\n',
      );
    });
  });
}

String _renderDiff({required String expected, required String actual}) {
  final expectedLines = expected.split('\n').toSet();
  final actualLines = actual.split('\n').toSet();
  final removed = expectedLines.difference(actualLines).toList()..sort();
  final added = actualLines.difference(expectedLines).toList()..sort();
  final buffer = StringBuffer();
  for (final line in removed) {
    if (line.isEmpty) continue;
    buffer.writeln('- $line');
  }
  for (final line in added) {
    if (line.isEmpty) continue;
    buffer.writeln('+ $line');
  }
  return buffer.toString();
}
