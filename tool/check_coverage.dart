import 'dart:convert';
import 'dart:io';

const _defaultLcovPath = 'coverage/lcov.info';
const _defaultBaselinePath = 'tool/coverage_baseline.json';
const _defaultTouchedFileMinimumPercent = 80.0;
const _shipTargetPercent = 90.0;

Future<void> main(List<String> args) async {
  final config = CoverageCheckConfig.fromArgs(args);
  final report = CoverageReport.parse(
    await File(config.lcovPath).readAsString(),
  );
  final baseline = CoverageBaseline.fromJson(
    jsonDecode(await File(config.baselinePath).readAsString()),
  );
  final baseBaseline = await readBaselineAtRef(
    ref: config.baseRef,
    baselinePath: config.baselinePath,
  );
  final changedFiles = await changedFilesBetween(
    baseRef: config.baseRef,
    headRef: config.headRef,
  );

  final result = evaluateCoverage(
    report: report,
    baseline: baseline,
    baseBaseline: baseBaseline,
    changedFiles: changedFiles,
    touchedFileMinimumPercent: config.touchedFileMinimumPercent,
  );

  if (result.passed) {
    stdout.writeln(
      'Coverage ${report.overallPercent.toStringAsFixed(2)}% meets '
      'baseline ${baseline.overallPercent.toStringAsFixed(2)}%.',
    );
    if (report.overallPercent < _shipTargetPercent) {
      stdout.writeln(
        'Coverage remains below the '
        '${_shipTargetPercent.toStringAsFixed(0)}% pre-ship target.',
      );
    }
    return;
  }

  for (final failure in result.failures) {
    stderr.writeln(failure);
  }
  exitCode = 1;
}

class CoverageCheckConfig {
  CoverageCheckConfig({
    required this.baseRef,
    required this.headRef,
    required this.lcovPath,
    required this.baselinePath,
    required this.touchedFileMinimumPercent,
  });

  factory CoverageCheckConfig.fromArgs(List<String> args) {
    String? baseRef;
    String? headRef;
    var lcovPath = _defaultLcovPath;
    var baselinePath = _defaultBaselinePath;
    var touchedFileMinimumPercent = _defaultTouchedFileMinimumPercent;

    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--base':
          baseRef = _nextValue(args, ++i, '--base');
        case '--head':
          headRef = _nextValue(args, ++i, '--head');
        case '--lcov':
          lcovPath = _nextValue(args, ++i, '--lcov');
        case '--baseline':
          baselinePath = _nextValue(args, ++i, '--baseline');
        case '--touched-min':
          touchedFileMinimumPercent = double.parse(
            _nextValue(args, ++i, '--touched-min'),
          );
        default:
          throw ArgumentError('Unknown argument: ${args[i]}');
      }
    }

    if (baseRef == null || headRef == null) {
      throw ArgumentError('Both --base and --head are required.');
    }

    return CoverageCheckConfig(
      baseRef: baseRef,
      headRef: headRef,
      lcovPath: lcovPath,
      baselinePath: baselinePath,
      touchedFileMinimumPercent: touchedFileMinimumPercent,
    );
  }

  final String baseRef;
  final String headRef;
  final String lcovPath;
  final String baselinePath;
  final double touchedFileMinimumPercent;
}

class CoverageBaseline {
  const CoverageBaseline({required this.overallPercent});

  factory CoverageBaseline.fromJson(Object? json) {
    if (json case {'overallPercent': final num overallPercent}) {
      return CoverageBaseline(overallPercent: overallPercent.toDouble());
    }

    throw const FormatException(
      'Coverage baseline must include numeric overallPercent.',
    );
  }

  final double overallPercent;
}

class CoverageReport {
  CoverageReport({required this.files});

  factory CoverageReport.parse(String lcovContent) {
    final files = <String, FileCoverage>{};
    String? currentPath;
    var linesFound = 0;
    var linesHit = 0;

    for (final rawLine in const LineSplitter().convert(lcovContent)) {
      final line = rawLine.trim();
      if (line.startsWith('SF:')) {
        currentPath = normalizePath(line.substring(3));
        linesFound = 0;
        linesHit = 0;
      } else if (line.startsWith('LF:')) {
        linesFound = int.parse(line.substring(3));
      } else if (line.startsWith('LH:')) {
        linesHit = int.parse(line.substring(3));
      } else if (line == 'end_of_record' && currentPath != null) {
        files[currentPath] = FileCoverage(
          path: currentPath,
          linesFound: linesFound,
          linesHit: linesHit,
        );
        currentPath = null;
      }
    }

    return CoverageReport(files: files);
  }

  final Map<String, FileCoverage> files;

  int get linesFound =>
      files.values.fold(0, (total, file) => total + file.linesFound);

  int get linesHit =>
      files.values.fold(0, (total, file) => total + file.linesHit);

  double get overallPercent =>
      percentage(linesHit: linesHit, linesFound: linesFound);
}

class FileCoverage {
  const FileCoverage({
    required this.path,
    required this.linesFound,
    required this.linesHit,
  });

  final String path;
  final int linesFound;
  final int linesHit;

  double get percent => percentage(linesHit: linesHit, linesFound: linesFound);
}

class CoverageCheckResult {
  const CoverageCheckResult({required this.failures});

  final List<String> failures;

  bool get passed => failures.isEmpty;
}

CoverageCheckResult evaluateCoverage({
  required CoverageReport report,
  required CoverageBaseline baseline,
  required CoverageBaseline? baseBaseline,
  required Iterable<String> changedFiles,
  required double touchedFileMinimumPercent,
}) {
  final failures = <String>[];

  if (baseBaseline != null &&
      baseline.overallPercent < baseBaseline.overallPercent) {
    failures.add(
      'Coverage baseline ${baseline.overallPercent.toStringAsFixed(2)}% is below '
      'base branch baseline ${baseBaseline.overallPercent.toStringAsFixed(2)}%.',
    );
  }

  if (report.overallPercent < baseline.overallPercent) {
    failures.add(
      'Overall coverage ${report.overallPercent.toStringAsFixed(2)}% is below '
      'baseline ${baseline.overallPercent.toStringAsFixed(2)}%.',
    );
  }

  for (final path in changedFiles.map(normalizePath).where(isThresholdedPath)) {
    final coverage = report.files[path];
    if (coverage == null) {
      failures.add(
        '$path has no coverage entry; touched domain/data files require '
        '${touchedFileMinimumPercent.toStringAsFixed(0)}% coverage.',
      );
      continue;
    }

    if (coverage.percent < touchedFileMinimumPercent) {
      failures.add(
        '$path coverage ${coverage.percent.toStringAsFixed(2)}% is below '
        '${touchedFileMinimumPercent.toStringAsFixed(0)}%.',
      );
    }
  }

  return CoverageCheckResult(failures: failures);
}

Future<List<String>> changedFilesBetween({
  required String baseRef,
  required String headRef,
}) async {
  final result = await Process.run('git', [
    'diff',
    '--name-only',
    '--diff-filter=ACMRT',
    baseRef,
    headRef,
  ]);

  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      ['diff', '--name-only', '--diff-filter=ACMRT', baseRef, headRef],
      result.stderr.toString(),
      result.exitCode,
    );
  }

  return const LineSplitter()
      .convert(result.stdout.toString())
      .map(normalizePath)
      .where((path) => path.isNotEmpty)
      .toList(growable: false);
}

Future<CoverageBaseline?> readBaselineAtRef({
  required String ref,
  required String baselinePath,
}) async {
  final result = await Process.run('git', ['show', '$ref:$baselinePath']);

  if (result.exitCode != 0) {
    return null;
  }

  return CoverageBaseline.fromJson(jsonDecode(result.stdout.toString()));
}

bool isThresholdedPath(String path) {
  final normalized = normalizePath(path);
  return normalized.startsWith('lib/features/') &&
      (normalized.contains('/domain/') || normalized.contains('/data/')) &&
      normalized.endsWith('.dart');
}

double percentage({required int linesHit, required int linesFound}) {
  if (linesFound == 0) {
    return 100;
  }

  return linesHit / linesFound * 100;
}

String normalizePath(String path) => path.replaceAll('\\', '/');

String _nextValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    throw ArgumentError('Missing value for $flag.');
  }
  return args[index];
}
