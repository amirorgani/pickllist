import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_dependency_docs.dart';

void main() {
  group('DependencyDocsCheckConfig.fromArgs', () {
    test('parses required refs and optional paths', () {
      final config = DependencyDocsCheckConfig.fromArgs([
        '--base',
        'origin/main',
        '--head',
        'HEAD',
        '--pubspec',
        'custom/pubspec.yaml',
        '--docs',
        'docs/custom.md',
      ]);

      expect(config.baseRef, 'origin/main');
      expect(config.headRef, 'HEAD');
      expect(config.pubspecPath, 'custom/pubspec.yaml');
      expect(config.docsPath, 'docs/custom.md');
    });

    test('throws when refs are missing', () {
      expect(
        () => DependencyDocsCheckConfig.fromArgs(['--base', 'main']),
        throwsArgumentError,
      );
    });
  });

  group('extractDependencySections', () {
    test('keeps dependency and dev dependency entries only', () {
      const pubspec = '''
name: pickllist
description: demo

dependencies:
  flutter:
    sdk: flutter
  go_router: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0

flutter:
  uses-material-design: true
''';

      expect(extractDependencySections(pubspec), '''
dependencies:
  flutter:
    sdk: flutter
  go_router: ^1.0.0
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0''');
    });

    test('ignores comments and unrelated top-level sections', () {
      const pubspec = '''
dependencies:
  # Routing
  go_router: ^1.0.0

dependency_overrides:
  go_router: ^2.0.0

dev_dependencies:
  # Tests
  mocktail: ^1.0.0
''';

      expect(extractDependencySections(pubspec), '''
dependencies:
  go_router: ^1.0.0
dev_dependencies:
  mocktail: ^1.0.0''');
    });
  });
}
