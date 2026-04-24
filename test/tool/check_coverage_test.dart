import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_coverage.dart';

void main() {
  group('CoverageCheckConfig.fromArgs', () {
    test('parses required refs and optional thresholds', () {
      final config = CoverageCheckConfig.fromArgs([
        '--base',
        'origin/main',
        '--head',
        'HEAD',
        '--lcov',
        'custom/lcov.info',
        '--baseline',
        'custom/baseline.json',
        '--touched-min',
        '75.5',
      ]);

      expect(config.baseRef, 'origin/main');
      expect(config.headRef, 'HEAD');
      expect(config.lcovPath, 'custom/lcov.info');
      expect(config.baselinePath, 'custom/baseline.json');
      expect(config.touchedFileMinimumPercent, 75.5);
    });

    test('throws when refs are missing', () {
      expect(
        () => CoverageCheckConfig.fromArgs(['--base', 'origin/main']),
        throwsArgumentError,
      );
    });
  });

  group('CoverageBaseline.fromJson', () {
    test('reads overall baseline percentage', () {
      final baseline = CoverageBaseline.fromJson(
        jsonDecode('{"overallPercent": 42.5}'),
      );

      expect(baseline.overallPercent, 42.5);
    });

    test('rejects missing overall percentage', () {
      expect(
        () => CoverageBaseline.fromJson(jsonDecode('{"coverage": 42.5}')),
        throwsFormatException,
      );
    });
  });

  group('CoverageReport.parse', () {
    test('normalizes paths and computes file and overall coverage', () {
      final report = CoverageReport.parse('''
SF:lib\\features\\auth\\data\\auth_repository.dart
DA:1,1
DA:2,0
LF:2
LH:1
end_of_record
SF:lib/features/auth/domain/app_user.dart
DA:1,1
DA:2,1
LF:2
LH:2
end_of_record
''');

      expect(
        report.files.keys,
        contains('lib/features/auth/data/auth_repository.dart'),
      );
      expect(
        report.files['lib/features/auth/data/auth_repository.dart']?.percent,
        50,
      );
      expect(report.overallPercent, 75);
    });
  });

  group('evaluateCoverage', () {
    test('passes when overall and touched domain/data files meet gates', () {
      final report = CoverageReport.parse('''
SF:lib/features/picking_lists/domain/picking_item.dart
LF:10
LH:9
end_of_record
SF:lib/app.dart
LF:10
LH:1
end_of_record
''');

      final result = evaluateCoverage(
        report: report,
        baseline: const CoverageBaseline(overallPercent: 50),
        baseBaseline: const CoverageBaseline(overallPercent: 50),
        changedFiles: [
          'lib/features/picking_lists/domain/picking_item.dart',
          'lib/app.dart',
        ],
        touchedFileMinimumPercent: 80,
      );

      expect(result.passed, isTrue);
    });

    test('fails when overall coverage drops below baseline', () {
      final report = CoverageReport.parse('''
SF:lib/features/auth/data/auth_repository.dart
LF:10
LH:4
end_of_record
''');

      final result = evaluateCoverage(
        report: report,
        baseline: const CoverageBaseline(overallPercent: 50),
        baseBaseline: const CoverageBaseline(overallPercent: 50),
        changedFiles: const [],
        touchedFileMinimumPercent: 80,
      );

      expect(result.passed, isFalse);
      expect(result.failures.single, contains('below baseline 50.00%'));
    });

    test('fails touched domain/data files below threshold', () {
      final report = CoverageReport.parse('''
SF:lib/features/auth/data/auth_repository.dart
LF:10
LH:7
end_of_record
''');

      final result = evaluateCoverage(
        report: report,
        baseline: const CoverageBaseline(overallPercent: 10),
        baseBaseline: const CoverageBaseline(overallPercent: 10),
        changedFiles: const ['lib/features/auth/data/auth_repository.dart'],
        touchedFileMinimumPercent: 80,
      );

      expect(result.passed, isFalse);
      expect(result.failures.single, contains('coverage 70.00% is below 80%'));
    });

    test('fails touched domain/data files missing from lcov', () {
      final report = CoverageReport.parse('''
SF:lib/app.dart
LF:10
LH:10
end_of_record
''');

      final result = evaluateCoverage(
        report: report,
        baseline: const CoverageBaseline(overallPercent: 10),
        baseBaseline: const CoverageBaseline(overallPercent: 10),
        changedFiles: const ['lib/features/auth/domain/app_user.dart'],
        touchedFileMinimumPercent: 80,
      );

      expect(result.passed, isFalse);
      expect(result.failures.single, contains('has no coverage entry'));
    });

    test('allows first baseline when base branch has no baseline file', () {
      final report = CoverageReport.parse('''
SF:lib/app.dart
LF:10
LH:5
end_of_record
''');

      final result = evaluateCoverage(
        report: report,
        baseline: const CoverageBaseline(overallPercent: 50),
        baseBaseline: null,
        changedFiles: const [],
        touchedFileMinimumPercent: 80,
      );

      expect(result.passed, isTrue);
    });

    test('allows upward baseline changes', () {
      final report = CoverageReport.parse('''
SF:lib/app.dart
LF:10
LH:7
end_of_record
''');

      final result = evaluateCoverage(
        report: report,
        baseline: const CoverageBaseline(overallPercent: 60),
        baseBaseline: const CoverageBaseline(overallPercent: 50),
        changedFiles: const [],
        touchedFileMinimumPercent: 80,
      );

      expect(result.passed, isTrue);
    });

    test('rejects downward baseline changes', () {
      final report = CoverageReport.parse('''
SF:lib/app.dart
LF:10
LH:7
end_of_record
''');

      final result = evaluateCoverage(
        report: report,
        baseline: const CoverageBaseline(overallPercent: 40),
        baseBaseline: const CoverageBaseline(overallPercent: 50),
        changedFiles: const [],
        touchedFileMinimumPercent: 80,
      );

      expect(result.passed, isFalse);
      expect(
        result.failures.single,
        contains('below base branch baseline 50.00%'),
      );
    });
  });

  group('isThresholdedPath', () {
    test('matches feature domain and data dart files only', () {
      expect(
        isThresholdedPath('lib/features/auth/domain/app_user.dart'),
        isTrue,
      );
      expect(
        isThresholdedPath('lib/features/auth/data/auth_repository.dart'),
        isTrue,
      );
      expect(
        isThresholdedPath('lib/features/auth/presentation/login.dart'),
        isFalse,
      );
      expect(
        isThresholdedPath('test/features/auth/data/auth_repository_test.dart'),
        isFalse,
      );
      expect(isThresholdedPath('lib/core/router.dart'), isFalse);
    });
  });
}
