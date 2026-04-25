// Issue-sync script: parse `docs/roadmap.md` and idempotently mirror each
// roadmap entry as a GitHub issue with matching labels.
//
// Usage:
//   dart run tool/sync_issues.dart [--dry-run] [--repo <owner>/<repo>]
//                                  [--roadmap docs/roadmap.md]
//
// Requires the `gh` CLI to be authenticated. Re-running without changes is a
// no-op; bodies, titles, and labels converge on the current roadmap content.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _defaultRoadmapPath = 'docs/roadmap.md';
const _defaultRepoSlug = 'amirorgani/pickllist';
const _bodyHeader =
    'Synced from [docs/roadmap.md]'
    '(https://github.com/amirorgani/pickllist/blob/main/docs/roadmap.md).';

Future<void> main(List<String> args) async {
  final config = SyncConfig.fromArgs(args);
  final source = await File(config.roadmapPath).readAsString();
  final entries = parseRoadmap(source);

  resolveDependencies(entries);

  final github = GitHubClient(repoSlug: config.repoSlug, dryRun: config.dryRun);
  final existingIssues = await github.listIssues();
  final existingLabels = await github.listLabelNames();

  final issuesById = <String, GhIssue>{};
  for (final issue in existingIssues) {
    final id = extractRoadmapId(issue.title);
    if (id != null) issuesById[id] = issue;
  }

  for (final entry in entries) {
    for (final id in entry.blockedBy) {
      final blocker = issuesById[id];
      if (blocker != null) {
        entry.blockedByIssues.add(
          BlockerRef(id: id, number: blocker.number, closed: blocker.closed),
        );
      }
    }
    for (final id in entry.blocks) {
      final blocked = issuesById[id];
      if (blocked != null) {
        entry.blocksIssues.add(blocked.number);
      }
    }
    entry.blockedByIssues.sort((a, b) => a.number.compareTo(b.number));
    entry.blocksIssues.sort();
  }

  final desiredLabels = <String>{};
  for (final entry in entries) {
    desiredLabels.addAll(entry.desiredLabels());
  }
  desiredLabels.add('blocked');

  for (final label in desiredLabels) {
    if (!existingLabels.contains(label)) {
      await github.createLabel(label);
    }
  }

  for (final entry in entries) {
    final desiredTitle = '${entry.id} — ${entry.title}';
    final desiredBody = renderBody(entry);
    final desiredLabelSet = entry.desiredLabels();
    if (entry.isBlockedNow()) desiredLabelSet.add('blocked');

    final existing = issuesById[entry.id];
    if (existing == null) {
      await github.createIssue(
        title: desiredTitle,
        body: desiredBody,
        labels: desiredLabelSet,
      );
      continue;
    }
    final existingLabelSet = existing.labels.toSet();
    final managedExisting = existingLabelSet.where(_isManagedLabel).toSet();
    final addLabels = desiredLabelSet.difference(existingLabelSet);
    final removeLabels = managedExisting.difference(desiredLabelSet);
    final needsTitle = existing.title != desiredTitle;
    final needsBody = existing.body.trim() != desiredBody.trim();
    if (!needsTitle &&
        !needsBody &&
        addLabels.isEmpty &&
        removeLabels.isEmpty) {
      stdout.writeln('= no change: ${existing.number} ${existing.title}');
      continue;
    }
    await github.updateIssue(
      number: existing.number,
      title: needsTitle ? desiredTitle : null,
      body: needsBody ? desiredBody : null,
      addLabels: addLabels,
      removeLabels: removeLabels,
    );
  }
}

const _managedLabelPrefixes = <String>[
  'phase:',
  'type:',
  'priority:',
  'platform:',
  'requires:',
];

bool _isManagedLabel(String label) {
  if (label == 'blocked') return true;
  return _managedLabelPrefixes.any(label.startsWith);
}

class SyncConfig {
  SyncConfig({
    required this.roadmapPath,
    required this.repoSlug,
    required this.dryRun,
  });

  factory SyncConfig.fromArgs(List<String> args) {
    var roadmapPath = _defaultRoadmapPath;
    var repoSlug = _defaultRepoSlug;
    var dryRun = false;
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '--dry-run':
          dryRun = true;
        case '--roadmap':
          roadmapPath = _requireValue(args, ++i, '--roadmap');
        case '--repo':
          repoSlug = _requireValue(args, ++i, '--repo');
        case '--help' || '-h':
          stdout.writeln(_helpText);
          exit(0);
        default:
          throw ArgumentError('Unknown argument: $arg');
      }
    }
    return SyncConfig(
      roadmapPath: roadmapPath,
      repoSlug: repoSlug,
      dryRun: dryRun,
    );
  }

  final String roadmapPath;
  final String repoSlug;
  final bool dryRun;

  static String _requireValue(List<String> args, int index, String flag) {
    if (index >= args.length) {
      throw ArgumentError('$flag requires a value');
    }
    return args[index];
  }
}

const _helpText =
    '''
Usage: dart run tool/sync_issues.dart [options]

Options:
  --dry-run         Print intended changes without calling the GitHub API.
  --repo <slug>     GitHub repository (default: $_defaultRepoSlug).
  --roadmap <path>  Roadmap file (default: $_defaultRoadmapPath).
  -h, --help        Show this help.
''';

class RoadmapEntry {
  RoadmapEntry({
    required this.id,
    required this.title,
    required this.metadataLines,
    required this.descriptionLines,
    required this.acceptanceLines,
    required this.blockedByRaw,
    required this.blocksRaw,
    required this.blockedBy,
    required this.blocks,
    required this.requires,
    required this.type,
    required this.phase,
    required this.priority,
    required this.owner,
  });

  final String id;
  final String title;
  final List<String> metadataLines;
  final List<String> descriptionLines;
  final List<String> acceptanceLines;
  final String? blockedByRaw;
  final String? blocksRaw;
  final List<String> blockedBy;
  final List<String> blocks;
  final String? requires;
  final String? type;
  final String? phase;
  final String? priority;
  final String? owner;

  final List<BlockerRef> blockedByIssues = [];
  final List<int> blocksIssues = [];

  Set<String> desiredLabels() {
    final labels = <String>{};
    if (phase != null) labels.add(phase!);
    if (type != null) labels.add(type!);
    if (priority != null) labels.add(priority!);
    if (requires != null) labels.add(_extractRequiresLabel(requires!));
    final lower = metadataLines.join(' ').toLowerCase();
    if (lower.contains('platform:mobile')) labels.add('platform:mobile');
    if (lower.contains('platform:windows')) labels.add('platform:windows');
    if (lower.contains('platform:all')) labels.add('platform:all');
    return labels;
  }

  bool isBlockedNow() {
    if (blockedByIssues.isEmpty) return false;
    return blockedByIssues.any((b) => !b.closed);
  }
}

String _extractRequiresLabel(String raw) {
  final match = RegExp(r'`([^`]+)`').firstMatch(raw);
  return match?.group(1) ?? 'requires:human';
}

class BlockerRef {
  BlockerRef({required this.id, required this.number, required this.closed});

  final String id;
  final int number;
  final bool closed;
}

List<RoadmapEntry> parseRoadmap(String source) {
  final lines = source.split('\n');
  final headerRegex = RegExp(r'^## `([A-Z]+-\d+)` — (.+)$');
  final entries = <RoadmapEntry>[];
  var i = 0;
  while (i < lines.length) {
    final match = headerRegex.firstMatch(lines[i]);
    if (match == null) {
      i++;
      continue;
    }
    final id = match.group(1)!;
    final title = match.group(2)!.trim();
    i++;
    // skip blank lines
    while (i < lines.length && lines[i].trim().isEmpty) {
      i++;
    }
    final metadataLines = <String>[];
    while (i < lines.length && lines[i].startsWith('- **')) {
      metadataLines.add(lines[i]);
      i++;
    }
    while (i < lines.length && lines[i].trim().isEmpty) {
      i++;
    }
    final descriptionLines = <String>[];
    final acceptanceLines = <String>[];
    if (i < lines.length && lines[i].startsWith('**Description.**')) {
      // collect until **Acceptance criteria:** or next entry
      final firstLine = lines[i].replaceFirst('**Description.**', '').trim();
      if (firstLine.isNotEmpty) descriptionLines.add(firstLine);
      i++;
      while (i < lines.length &&
          !lines[i].startsWith('**Acceptance criteria:**') &&
          !headerRegex.hasMatch(lines[i]) &&
          !lines[i].startsWith('---') &&
          !lines[i].startsWith('# ')) {
        descriptionLines.add(lines[i]);
        i++;
      }
      while (descriptionLines.isNotEmpty &&
          descriptionLines.last.trim().isEmpty) {
        descriptionLines.removeLast();
      }
    }
    if (i < lines.length && lines[i].startsWith('**Acceptance criteria:**')) {
      i++;
      while (i < lines.length &&
          !headerRegex.hasMatch(lines[i]) &&
          !lines[i].startsWith('---') &&
          !lines[i].startsWith('# ') &&
          !lines[i].startsWith('**')) {
        acceptanceLines.add(lines[i]);
        i++;
      }
      while (acceptanceLines.isNotEmpty &&
          acceptanceLines.last.trim().isEmpty) {
        acceptanceLines.removeLast();
      }
    }
    final meta = _parseMetadata(metadataLines);
    entries.add(
      RoadmapEntry(
        id: id,
        title: title,
        metadataLines: metadataLines,
        descriptionLines: descriptionLines,
        acceptanceLines: acceptanceLines,
        blockedByRaw: meta['blocked by'],
        blocksRaw: meta['blocks'],
        blockedBy: <String>[],
        blocks: <String>[],
        requires: meta['requires'],
        type: _normalizeLabel(meta['type'], 'type'),
        phase: _normalizeLabel(meta['phase'], 'phase'),
        priority: _normalizeLabel(meta['priority'], 'priority'),
        owner: meta['owner'],
      ),
    );
  }
  return entries;
}

Map<String, String> _parseMetadata(List<String> lines) {
  final result = <String, String>{};
  for (final line in lines) {
    var rest = line.startsWith('- ') ? line.substring(2) : line;
    final pieces = rest.split(' · ');
    for (final piece in pieces) {
      final keyMatch = RegExp(r'^\*\*([^:]+):\*\*\s*(.*)$').firstMatch(piece);
      if (keyMatch == null) continue;
      final key = keyMatch.group(1)!.trim().toLowerCase();
      final value = keyMatch.group(2)!.trim();
      result[key] = value;
    }
  }
  return result;
}

String? _normalizeLabel(String? raw, String prefix) {
  if (raw == null) return null;
  final match = RegExp('`($prefix:[a-z0-9]+)`').firstMatch(raw);
  return match?.group(1);
}

void resolveDependencies(List<RoadmapEntry> entries) {
  final allIds = entries.map((e) => e.id).toList();
  for (final entry in entries) {
    final ids = _expandIdList(entry.blockedByRaw, allIds);
    entry.blockedBy
      ..clear()
      ..addAll(ids);
  }
  // Compute Blocks reverse graph: any other entry whose Blocked-by contains
  // this id — but only when the source-of-truth is the explicit Blocks list.
  for (final entry in entries) {
    final blocksIds = _expandIdList(entry.blocksRaw, allIds);
    final reverse = entries
        .where((other) => other.blockedBy.contains(entry.id))
        .map((other) => other.id);
    final union = <String>{...blocksIds, ...reverse};
    entry.blocks
      ..clear()
      ..addAll(union.toList()..sort(_compareIds));
  }
}

int _compareIds(String a, String b) {
  final ra = RegExp(r'^([A-Z]+)-(\d+)$').firstMatch(a);
  final rb = RegExp(r'^([A-Z]+)-(\d+)$').firstMatch(b);
  if (ra == null || rb == null) return a.compareTo(b);
  final prefixCmp = ra.group(1)!.compareTo(rb.group(1)!);
  if (prefixCmp != 0) return prefixCmp;
  return int.parse(ra.group(2)!).compareTo(int.parse(rb.group(2)!));
}

List<String> _expandIdList(String? raw, List<String> allIds) {
  if (raw == null) return const [];
  final cleaned = raw.replaceAll('`', '');
  final tokens = cleaned
      .split(RegExp(r',|\band\b'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty);
  final ids = <String>{};
  for (final token in tokens) {
    final wildcardMatch = RegExp(
      r'([A-Z]+)-\*',
    ).firstMatch(token.replaceAll('all ', ''));
    if (wildcardMatch != null) {
      final prefix = wildcardMatch.group(1)!;
      ids.addAll(allIds.where((id) => id.startsWith('$prefix-')));
      continue;
    }
    final exact = RegExp(r'([A-Z]+-\d+)').firstMatch(token);
    if (exact != null) ids.add(exact.group(1)!);
  }
  final sorted = ids.toList()..sort(_compareIds);
  return sorted;
}

String renderBody(RoadmapEntry entry) {
  final buffer = StringBuffer()
    ..writeln(_bodyHeader)
    ..writeln()
    ..writeln('**Metadata**')
    ..writeln('- Roadmap ID: `${entry.id}`');
  if (entry.type != null) buffer.writeln('- Type: `${entry.type}`');
  if (entry.phase != null) buffer.writeln('- Phase: `${entry.phase}`');
  if (entry.priority != null) buffer.writeln('- Priority: `${entry.priority}`');
  if (entry.requires != null) buffer.writeln('- Requires: ${entry.requires}');
  if (entry.owner != null) buffer.writeln('- Owner: ${entry.owner}');
  if (entry.blocksRaw != null) {
    buffer.writeln('- Roadmap blocks field: ${entry.blocksRaw}');
  }
  if (entry.blockedByRaw != null) {
    buffer.writeln('- Roadmap blocked by field: ${entry.blockedByRaw}');
  }
  if (entry.descriptionLines.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('**Description**');
    for (final line in entry.descriptionLines) {
      buffer.writeln(line);
    }
  }
  if (entry.acceptanceLines.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('**Acceptance Criteria**');
    for (final line in entry.acceptanceLines) {
      buffer.writeln(line);
    }
  }
  if (entry.blockedByIssues.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('**Blocked By**');
    for (final ref in entry.blockedByIssues) {
      buffer.writeln('- [${ref.closed ? "x" : " "}] #${ref.number}');
    }
  }
  if (entry.blocksIssues.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('**Blocks**');
    for (final n in entry.blocksIssues) {
      buffer.writeln('- #$n');
    }
  }
  return buffer.toString().trimRight();
}

String? extractRoadmapId(String title) {
  final match = RegExp(r'^([A-Z]+-\d+)').firstMatch(title);
  return match?.group(1);
}

class GhIssue {
  GhIssue({
    required this.number,
    required this.title,
    required this.body,
    required this.labels,
    required this.closed,
  });

  final int number;
  final String title;
  final String body;
  final List<String> labels;
  final bool closed;
}

class GitHubClient {
  GitHubClient({required this.repoSlug, required this.dryRun});

  final String repoSlug;
  final bool dryRun;

  Future<List<GhIssue>> listIssues() async {
    final raw = await _gh([
      'issue',
      'list',
      '--repo',
      repoSlug,
      '--state',
      'all',
      '--limit',
      '500',
      '--json',
      'number,title,body,labels,state',
    ]);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) {
      final m = e as Map<String, dynamic>;
      final labels = (m['labels'] as List<dynamic>)
          .map((l) => (l as Map<String, dynamic>)['name'] as String)
          .toList();
      return GhIssue(
        number: m['number'] as int,
        title: m['title'] as String,
        body: (m['body'] as String?) ?? '',
        labels: labels,
        closed: (m['state'] as String).toUpperCase() == 'CLOSED',
      );
    }).toList();
  }

  Future<Set<String>> listLabelNames() async {
    final raw = await _gh([
      'label',
      'list',
      '--repo',
      repoSlug,
      '--limit',
      '500',
      '--json',
      'name',
    ]);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => (e as Map<String, dynamic>)['name'] as String)
        .toSet();
  }

  Future<void> createLabel(String name) async {
    stdout.writeln('+ create label: $name');
    if (dryRun) return;
    await _gh(['label', 'create', name, '--repo', repoSlug, '--force']);
  }

  Future<void> createIssue({
    required String title,
    required String body,
    required Set<String> labels,
  }) async {
    stdout.writeln('+ create issue: $title (labels: ${labels.join(",")})');
    if (dryRun) return;
    final args = <String>[
      'issue',
      'create',
      '--repo',
      repoSlug,
      '--title',
      title,
      '--body',
      body,
    ];
    for (final label in labels) {
      args
        ..add('--label')
        ..add(label);
    }
    await _gh(args);
  }

  Future<void> updateIssue({
    required int number,
    String? title,
    String? body,
    Set<String> addLabels = const <String>{},
    Set<String> removeLabels = const <String>{},
  }) async {
    stdout.writeln(
      '~ update issue #$number'
      '${title != null ? " title" : ""}'
      '${body != null ? " body" : ""}'
      '${addLabels.isNotEmpty ? " +${addLabels.join(",")}" : ""}'
      '${removeLabels.isNotEmpty ? " -${removeLabels.join(",")}" : ""}',
    );
    if (dryRun) return;
    final args = <String>['issue', 'edit', '$number', '--repo', repoSlug];
    if (title != null) args.addAll(['--title', title]);
    if (body != null) args.addAll(['--body', body]);
    if (addLabels.isNotEmpty) {
      args
        ..add('--add-label')
        ..add(addLabels.join(','));
    }
    if (removeLabels.isNotEmpty) {
      args
        ..add('--remove-label')
        ..add(removeLabels.join(','));
    }
    await _gh(args);
  }

  Future<String> _gh(List<String> args) async {
    final result = await Process.run('gh', args, stdoutEncoding: utf8);
    if (result.exitCode != 0) {
      throw StateError('gh ${args.join(" ")} failed: ${result.stderr}');
    }
    return result.stdout as String;
  }
}
