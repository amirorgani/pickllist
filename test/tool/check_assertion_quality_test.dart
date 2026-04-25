import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_assertion_quality.dart';

void main() {
  group('analyseSource', () {
    test('counts every matcher and flags truthy ones', () {
      const source = '''
expect(value, equals(42));
expect(thing, isNotNull);
expect(things, isNotEmpty);
expect(flag, isTrue);
expect(other, isFalse);
''';
      final result = analyseSource(
        source: source,
        path: 'test/sample_test.dart',
      );
      expect(result.totalExpects, 5);
      expect(result.truthyCount, 3);
    });

    test('handles multi-line expect calls', () {
      const source = '''
expect(
  computeResult(),
  isNotNull,
);
expect(
  computeResult(),
  equals(42),
);
''';
      final result = analyseSource(
        source: source,
        path: 'test/sample_test.dart',
      );
      expect(result.totalExpects, 2);
      expect(result.truthyCount, 1);
    });

    test('ignores expects inside comments and string literals', () {
      const source = r'''
// expect(buried, isTrue);
final s = "expect(also, isTrue)";
expect(real, equals(1));
''';
      final result = analyseSource(
        source: source,
        path: 'test/sample_test.dart',
      );
      expect(result.totalExpects, 1);
      expect(result.truthyCount, 0);
    });

    test('counts expectLater calls', () {
      const source = '''
expectLater(stream, emits('hi'));
expectLater(future, completes);
''';
      final result = analyseSource(
        source: source,
        path: 'test/sample_test.dart',
      );
      expect(result.totalExpects, 2);
      expect(result.truthyCount, 0);
    });

    test('strips matcher arguments before classifying', () {
      const source = '''
expect(map, isNotEmpty);
expect(map, isA<Map<String, int>>());
''';
      final result = analyseSource(
        source: source,
        path: 'test/sample_test.dart',
      );
      expect(result.totalExpects, 2);
      // isNotEmpty is the only weak truthy matcher; isA<...> is specific.
      expect(result.truthyCount, 1);
    });
  });

  group('analyseFiles', () {
    test('flags files exceeding the threshold above the min-expects floor', () {
      final files = [
        FileSource(
          path: 'test/strong_test.dart',
          source: '''
expect(a, equals(1));
expect(b, equals(2));
expect(c, equals(3));
expect(d, isTrue);
''',
        ),
        FileSource(
          path: 'test/weak_test.dart',
          source: '''
expect(a, isNotNull);
expect(b, isNotEmpty);
expect(c, isTrue);
expect(d, isNotNull);
''',
        ),
      ];
      final report = analyseFiles(files: files, threshold: 0.30, minExpects: 3);
      expect(report.summaries, hasLength(2));
      expect(
        report.failures.map((f) => f.path),
        contains('test/weak_test.dart'),
      );
      expect(
        report.failures.map((f) => f.path),
        isNot(contains('test/strong_test.dart')),
      );
    });

    test('skips files below the min-expects floor', () {
      final files = [
        FileSource(
          path: 'test/tiny_test.dart',
          source: 'expect(value, isNotNull);\n',
        ),
      ];
      final report = analyseFiles(files: files, threshold: 0.30, minExpects: 3);
      expect(report.failures, isEmpty);
    });
  });

  group('AssertionCheckConfig.fromArgs', () {
    test('parses defaults', () {
      final config = AssertionCheckConfig.fromArgs(const []);
      expect(config.threshold, 0.30);
      expect(config.minExpects, 3);
      expect(config.paths, isNotEmpty);
    });

    test('parses overrides and explicit paths', () {
      final config = AssertionCheckConfig.fromArgs(const [
        '--threshold',
        '0.5',
        '--min-expects',
        '5',
        'test/foo/',
        'test/bar_test.dart',
      ]);
      expect(config.threshold, 0.5);
      expect(config.minExpects, 5);
      expect(config.paths, ['test/foo/', 'test/bar_test.dart']);
    });

    test('rejects unknown flags', () {
      expect(
        () => AssertionCheckConfig.fromArgs(const ['--bogus']),
        throwsArgumentError,
      );
    });
  });

  group('truthyMatchers', () {
    test('contains exactly the three weak matchers from the spec', () {
      expect(truthyMatchers, {'isNotNull', 'isNotEmpty', 'isTrue'});
    });
  });
}
