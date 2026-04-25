// Public API surface snapshot generator.
//
// Walks `lib/`, extracts every public top-level declaration (class, enum,
// mixin, extension, typedef), and writes a sorted snapshot to
// `test/api_surface.snapshot.txt`.
//
// Run with `--write` to update the committed snapshot. Without flags, prints
// the snapshot to stdout — useful for inspecting drift before committing.
//
// `test/api_surface_test.dart` enforces parity by comparing the live surface
// to the committed snapshot.

import 'dart:io';

const defaultLibDir = 'lib';
const defaultSnapshotPath = 'test/api_surface.snapshot.txt';

Future<void> main(List<String> args) async {
  final write = args.contains('--write');
  final symbols = await collectPublicApi(libDir: defaultLibDir);
  final content = renderSnapshot(symbols);
  if (write) {
    await File(defaultSnapshotPath).writeAsString(content);
    stdout.writeln('Wrote ${symbols.length} symbols to $defaultSnapshotPath.');
    return;
  }
  stdout.write(content);
}

class ApiSymbol implements Comparable<ApiSymbol> {
  const ApiSymbol({required this.path, required this.declaration});

  final String path;
  final String declaration;

  String get line => '$path::$declaration';

  @override
  int compareTo(ApiSymbol other) => line.compareTo(other.line);

  @override
  bool operator ==(Object other) =>
      other is ApiSymbol &&
      other.path == path &&
      other.declaration == declaration;

  @override
  int get hashCode => Object.hash(path, declaration);
}

String renderSnapshot(List<ApiSymbol> symbols) {
  final sorted = [...symbols]..sort();
  final buffer = StringBuffer();
  for (final symbol in sorted) {
    buffer.writeln(symbol.line);
  }
  return buffer.toString();
}

Future<List<ApiSymbol>> collectPublicApi({required String libDir}) async {
  final root = Directory(libDir);
  if (!root.existsSync()) {
    throw StateError('lib directory not found at $libDir');
  }
  final symbols = <ApiSymbol>[];
  await for (final entity in root.list(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    final relative = entity.path.replaceAll(r'\', '/');
    if (_isExcluded(relative)) continue;
    final source = await entity.readAsString();
    symbols.addAll(extractSymbols(source: source, path: relative));
  }
  return symbols;
}

bool _isExcluded(String path) {
  if (path.endsWith('.g.dart')) return true;
  if (path.endsWith('.freezed.dart')) return true;
  if (path.endsWith('.gr.dart')) return true;
  if (path.contains('/l10n/generated/')) return true;
  if (path.endsWith('firebase_options.dart')) return true;
  return false;
}

final _patterns = <RegExp>[
  RegExp(
    r'^(?:abstract\s+|sealed\s+|base\s+|interface\s+|final\s+|mixin\s+)*'
    r'class\s+([A-Z][A-Za-z0-9_]*)',
  ),
  RegExp(r'^mixin\s+([A-Z][A-Za-z0-9_]*)\b'),
  RegExp(r'^enum\s+([A-Z][A-Za-z0-9_]*)\b'),
  RegExp(r'^extension\s+([A-Z][A-Za-z0-9_]*)\b'),
  RegExp(r'^typedef\s+([A-Z][A-Za-z0-9_]*)\b'),
];

List<ApiSymbol> extractSymbols({required String source, required String path}) {
  final results = <ApiSymbol>[];
  final lines = source.split('\n');
  for (final raw in lines) {
    final line = raw.trimRight();
    if (line.isEmpty || line.startsWith('//')) continue;
    if (!_isLikelyDeclaration(line)) continue;
    final declaration = _normaliseDeclaration(line);
    if (declaration == null) continue;
    if (!_patterns.any((p) => p.hasMatch(declaration))) continue;
    results.add(ApiSymbol(path: path, declaration: declaration));
  }
  return results;
}

bool _isLikelyDeclaration(String line) {
  return line.startsWith('abstract ') ||
      line.startsWith('sealed ') ||
      line.startsWith('base ') ||
      line.startsWith('interface ') ||
      line.startsWith('final class') ||
      line.startsWith('mixin ') ||
      line.startsWith('class ') ||
      line.startsWith('enum ') ||
      line.startsWith('extension ') ||
      line.startsWith('typedef ');
}

String? _normaliseDeclaration(String line) {
  // Trim trailing `{`, `extends ...`, `implements ...`, generics, `with ...`.
  // We keep the keyword + name only so the snapshot stays readable.
  final stripIndex = _firstIndexOfAny(line, const [
    ' extends ',
    ' implements ',
    ' with ',
    ' on ',
    '{',
    '<',
    '=',
  ]);
  final stripped = stripIndex < 0
      ? line.trimRight()
      : line.substring(0, stripIndex).trimRight();
  final tokens = stripped.split(RegExp(r'\s+'));
  if (tokens.isEmpty) return null;
  final name = tokens.last;
  if (name.startsWith('_')) return null;
  if (!RegExp(r'^[A-Z][A-Za-z0-9_]*$').hasMatch(name)) return null;
  return stripped;
}

int _firstIndexOfAny(String haystack, List<String> needles) {
  var earliest = -1;
  for (final needle in needles) {
    final idx = haystack.indexOf(needle);
    if (idx < 0) continue;
    if (earliest < 0 || idx < earliest) earliest = idx;
  }
  return earliest;
}
