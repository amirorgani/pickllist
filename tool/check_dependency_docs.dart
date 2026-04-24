import 'dart:convert';
import 'dart:io';

const _pubspecPath = 'pubspec.yaml';
const _docsPath = 'docs/dependencies.md';

Future<void> main(List<String> args) async {
  final config = DependencyDocsCheckConfig.fromArgs(args);

  if (!await dependenciesChanged(
    baseRef: config.baseRef,
    headRef: config.headRef,
    pubspecPath: config.pubspecPath,
  )) {
    stdout.writeln('No dependency changes detected.');
    return;
  }

  if (await docsChanged(
    baseRef: config.baseRef,
    headRef: config.headRef,
    docsPath: config.docsPath,
  )) {
    stdout.writeln('Dependency docs changed alongside pubspec dependencies.');
    return;
  }

  stderr.writeln(
    'Dependency changes were detected in ${config.pubspecPath}, but '
    '${config.docsPath} was not updated.',
  );
  exitCode = 1;
}

class DependencyDocsCheckConfig {
  DependencyDocsCheckConfig({
    required this.baseRef,
    required this.headRef,
    required this.pubspecPath,
    required this.docsPath,
  });

  factory DependencyDocsCheckConfig.fromArgs(List<String> args) {
    String? baseRef;
    String? headRef;
    var pubspecPath = _pubspecPath;
    var docsPath = _docsPath;

    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--base':
          baseRef = _nextValue(args, ++i, '--base');
        case '--head':
          headRef = _nextValue(args, ++i, '--head');
        case '--pubspec':
          pubspecPath = _nextValue(args, ++i, '--pubspec');
        case '--docs':
          docsPath = _nextValue(args, ++i, '--docs');
        default:
          throw ArgumentError('Unknown argument: ${args[i]}');
      }
    }

    if (baseRef == null || headRef == null) {
      throw ArgumentError('Both --base and --head are required.');
    }

    return DependencyDocsCheckConfig(
      baseRef: baseRef,
      headRef: headRef,
      pubspecPath: pubspecPath,
      docsPath: docsPath,
    );
  }

  final String baseRef;
  final String headRef;
  final String pubspecPath;
  final String docsPath;
}

String _nextValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    throw ArgumentError('Missing value for $flag.');
  }
  return args[index];
}

Future<bool> dependenciesChanged({
  required String baseRef,
  required String headRef,
  required String pubspecPath,
}) async {
  final basePubspec = await readFileAtRef(baseRef, pubspecPath);
  final headPubspec = await readFileAtRef(headRef, pubspecPath);

  return extractDependencySections(basePubspec) !=
      extractDependencySections(headPubspec);
}

Future<bool> docsChanged({
  required String baseRef,
  required String headRef,
  required String docsPath,
}) async {
  final result = await Process.run('git', [
    'diff',
    '--name-only',
    baseRef,
    headRef,
    '--',
    docsPath,
  ]);

  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      ['diff', '--name-only', baseRef, headRef, '--', docsPath],
      result.stderr.toString(),
      result.exitCode,
    );
  }

  return result.stdout.toString().trim().isNotEmpty;
}

Future<String> readFileAtRef(String ref, String path) async {
  final result = await Process.run('git', ['show', '$ref:$path']);
  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      ['show', '$ref:$path'],
      result.stderr.toString(),
      result.exitCode,
    );
  }

  return result.stdout.toString();
}

String extractDependencySections(String pubspecContent) {
  final lines = const LineSplitter().convert(pubspecContent);
  final kept = <String>[];
  String? currentSection;

  for (final line in lines) {
    final trimmedRight = line.trimRight();
    final trimmed = trimmedRight.trimLeft();

    if (trimmedRight.isEmpty || trimmed.startsWith('#')) {
      continue;
    }

    if (!line.startsWith(' ')) {
      if (trimmedRight == 'dependencies:' ||
          trimmedRight == 'dev_dependencies:') {
        currentSection = trimmedRight;
        kept.add(trimmedRight);
      } else {
        currentSection = null;
      }
      continue;
    }

    if (currentSection != null) {
      kept.add(trimmedRight);
    }
  }

  return kept.join('\n');
}
