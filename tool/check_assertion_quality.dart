// Assertion-quality smoke check (GUARD-05).
//
// Coverage alone lets shallow tests slip through — `expect(x, isNotNull)`
// every line covers the code without proving any meaningful behaviour. This
// script walks test files and fails when the ratio of weak truthy matchers
// (`isNotNull`, `isNotEmpty`, `isTrue`) exceeds the configured threshold of
// all `expect(...)` calls in a file.
//
// Usage:
//   dart run tool/check_assertion_quality.dart [--threshold 0.3]
//                                              [--min-expects 3]
//                                              [path1 path2 ...]
//
// Default scope is `test/features/picking_lists/`, matching the acceptance
// criteria of GUARD-05; pass explicit paths to widen the scan (or `test/`
// for the whole suite).

import 'dart:io';

const _defaultThreshold = 0.30;
const _defaultMinExpects = 3;
const _defaultPaths = <String>['test/features/picking_lists/'];
const truthyMatchers = <String>{'isNotNull', 'isNotEmpty', 'isTrue'};

Future<void> main(List<String> args) async {
  final config = AssertionCheckConfig.fromArgs(args);
  final files = await _collectTestFiles(config.paths);
  final report = analyseFiles(
    files: await _readAll(files),
    threshold: config.threshold,
    minExpects: config.minExpects,
  );
  for (final summary in report.summaries) {
    final pct = (summary.truthyRatio * 100).toStringAsFixed(1);
    stdout.writeln(
      '${summary.path}: ${summary.truthyCount}/${summary.totalExpects}'
      ' truthy ($pct%)',
    );
  }
  if (report.failures.isEmpty) {
    stdout.writeln(
      '\nAll scanned files keep weak matchers under '
      '${(config.threshold * 100).toStringAsFixed(0)}%.',
    );
    return;
  }
  stderr.writeln('\nAssertion-quality failures:');
  for (final failure in report.failures) {
    final pct = (failure.truthyRatio * 100).toStringAsFixed(1);
    stderr.writeln(
      '  ${failure.path}: ${failure.truthyCount}/${failure.totalExpects}'
      ' truthy assertions ($pct%) — replace some with assertions on '
      'specific values.',
    );
  }
  exitCode = 1;
}

class AssertionCheckConfig {
  AssertionCheckConfig({
    required this.threshold,
    required this.minExpects,
    required this.paths,
  });

  factory AssertionCheckConfig.fromArgs(List<String> args) {
    var threshold = _defaultThreshold;
    var minExpects = _defaultMinExpects;
    final paths = <String>[];
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '--threshold':
          threshold = double.parse(_requireValue(args, ++i, '--threshold'));
        case '--min-expects':
          minExpects = int.parse(_requireValue(args, ++i, '--min-expects'));
        case '--help' || '-h':
          stdout.writeln(_buildHelpText());
          exit(0);
        default:
          if (arg.startsWith('--')) {
            throw ArgumentError('Unknown flag: $arg');
          }
          paths.add(arg);
      }
    }
    return AssertionCheckConfig(
      threshold: threshold,
      minExpects: minExpects,
      paths: paths.isEmpty ? _defaultPaths : paths,
    );
  }

  final double threshold;
  final int minExpects;
  final List<String> paths;

  static String _requireValue(List<String> args, int index, String flag) {
    if (index >= args.length) {
      throw ArgumentError('$flag requires a value');
    }
    return args[index];
  }
}

String _buildHelpText() =>
    'Usage: dart run tool/check_assertion_quality.dart [options] [paths...]\n'
    '\n'
    'Options:\n'
    '  --threshold <fraction>  Maximum truthy-assertion ratio (default: 0.3).\n'
    '  --min-expects <count>   Skip files with fewer expects (default: 3).\n'
    '  -h, --help              Show this help.\n'
    '\n'
    'Truthy matchers tracked: ${truthyMatchers.join(', ')}.\n'
    'Default scope (when no paths are passed): ${_defaultPaths.join(', ')}.\n';

class FileAnalysis {
  FileAnalysis({
    required this.path,
    required this.totalExpects,
    required this.truthyCount,
  });

  final String path;
  final int totalExpects;
  final int truthyCount;

  double get truthyRatio => totalExpects == 0 ? 0 : truthyCount / totalExpects;
}

class AssertionReport {
  AssertionReport({required this.summaries, required this.failures});

  final List<FileAnalysis> summaries;
  final List<FileAnalysis> failures;
}

class FileSource {
  FileSource({required this.path, required this.source});

  final String path;
  final String source;
}

Future<List<FileSource>> _readAll(List<File> files) async {
  final out = <FileSource>[];
  for (final file in files) {
    final source = await file.readAsString();
    out.add(FileSource(path: file.path.replaceAll('\\', '/'), source: source));
  }
  return out;
}

AssertionReport analyseFiles({
  required List<FileSource> files,
  required double threshold,
  required int minExpects,
}) {
  final summaries = <FileAnalysis>[];
  final failures = <FileAnalysis>[];
  for (final file in files) {
    final analysis = analyseSource(source: file.source, path: file.path);
    summaries.add(analysis);
    if (analysis.totalExpects >= minExpects &&
        analysis.truthyRatio > threshold) {
      failures.add(analysis);
    }
  }
  summaries.sort((a, b) => a.path.compareTo(b.path));
  return AssertionReport(summaries: summaries, failures: failures);
}

FileAnalysis analyseSource({required String source, required String path}) {
  final stripped = _stripCommentsAndStrings(source);
  final matchers = _collectMatchers(stripped);
  var truthy = 0;
  for (final matcher in matchers) {
    if (truthyMatchers.contains(matcher)) truthy++;
  }
  return FileAnalysis(
    path: path,
    totalExpects: matchers.length,
    truthyCount: truthy,
  );
}

List<String> _collectMatchers(String source) {
  final matchers = <String>[];
  final pattern = RegExp(r'\bexpect(?:Later)?\s*\(');
  for (final match in pattern.allMatches(source)) {
    final start = match.end;
    final args = _splitTopLevelArgs(source, start);
    if (args.length < 2) continue;
    final matcher = args[1].trim();
    final identifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*').firstMatch(matcher);
    matchers.add(identifier?.group(0) ?? matcher);
  }
  return matchers;
}

List<String> _splitTopLevelArgs(String source, int start) {
  final args = <String>[];
  final buffer = StringBuffer();
  var depth = 1;
  for (var i = start; i < source.length; i++) {
    final ch = source[i];
    if (ch == '(' || ch == '[' || ch == '{' || ch == '<') {
      depth++;
      buffer.write(ch);
    } else if (ch == ')' || ch == ']' || ch == '}' || ch == '>') {
      depth--;
      if (depth == 0) {
        if (buffer.isNotEmpty) args.add(buffer.toString());
        return args;
      }
      buffer.write(ch);
    } else if (ch == ',' && depth == 1) {
      args.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(ch);
    }
  }
  return args;
}

String _stripCommentsAndStrings(String source) {
  final buffer = StringBuffer();
  var i = 0;
  while (i < source.length) {
    final ch = source[i];
    if (ch == '/' && i + 1 < source.length && source[i + 1] == '/') {
      while (i < source.length && source[i] != '\n') {
        i++;
      }
      continue;
    }
    if (ch == '/' && i + 1 < source.length && source[i + 1] == '*') {
      i += 2;
      while (i + 1 < source.length &&
          !(source[i] == '*' && source[i + 1] == '/')) {
        i++;
      }
      i += 2;
      continue;
    }
    if (ch == "'" || ch == '"') {
      final quote = ch;
      final triple =
          i + 2 < source.length &&
          source[i + 1] == quote &&
          source[i + 2] == quote;
      if (triple) {
        i += 3;
        while (i + 2 < source.length &&
            !(source[i] == quote &&
                source[i + 1] == quote &&
                source[i + 2] == quote)) {
          i++;
        }
        i += 3;
        continue;
      }
      i++;
      while (i < source.length && source[i] != quote) {
        if (source[i] == '\\' && i + 1 < source.length) i++;
        i++;
      }
      i++;
      continue;
    }
    buffer.write(ch);
    i++;
  }
  return buffer.toString();
}

Future<List<File>> _collectTestFiles(List<String> paths) async {
  final files = <File>[];
  for (final raw in paths) {
    final entity = FileSystemEntity.typeSync(raw);
    if (entity == FileSystemEntityType.file) {
      files.add(File(raw));
      continue;
    }
    if (entity == FileSystemEntityType.directory) {
      await for (final f in Directory(raw).list(recursive: true)) {
        if (f is File && f.path.endsWith('_test.dart')) files.add(f);
      }
      continue;
    }
    throw StateError('Path not found: $raw');
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}
