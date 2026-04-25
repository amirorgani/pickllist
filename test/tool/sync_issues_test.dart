import 'package:flutter_test/flutter_test.dart';

import '../../tool/sync_issues.dart';

const _sampleRoadmap = '''
# Phase 0 — Guardrails

## `GUARD-02` — Tighter analyzer rules

- **Type:** `type:guardrail` · **Phase:** `phase:0` · **Priority:** `priority:p0`
- **Owner:** agent · **Blocks:** all feature work

**Description.** Replace `flutter_lints` with `very_good_analysis`.

- bullet inside description

**Acceptance criteria:**
- [ ] `analysis_options.yaml` updated.
- [ ] All existing code passes the stricter lints.

## `FIRE-01` — Create Firebase project

- **Type:** `type:infra` · **Phase:** `phase:1` · **Priority:** `priority:p0`
- **Requires:** `requires:human`
- **Blocks:** `FIRE-02`, `FIRE-03`
- **Owner:** human

**Description.** Create the Firebase project.

## `FIRE-02` — Commit options strategy

- **Type:** `type:infra` · **Phase:** `phase:1` · **Priority:** `priority:p0`
- **Blocked by:** `FIRE-01`
- **Owner:** agent

**Description.** Commit `firebase_options.dart`.

## `FIRE-03` — Auth repo

- **Type:** `type:feature` · **Phase:** `phase:1` · **Priority:** `priority:p0`
- **Blocked by:** `FIRE-01`, `FIRE-02`, all `GUARD-*`
- **Owner:** agent

**Description.** Real auth implementation.
''';

void main() {
  group('parseRoadmap', () {
    test('extracts entries with metadata, description, and acceptance', () {
      final entries = parseRoadmap(_sampleRoadmap);
      expect(entries, hasLength(4));

      final guard02 = entries[0];
      expect(guard02.id, 'GUARD-02');
      expect(guard02.title, 'Tighter analyzer rules');
      expect(guard02.type, 'type:guardrail');
      expect(guard02.phase, 'phase:0');
      expect(guard02.priority, 'priority:p0');
      expect(guard02.owner, 'agent');
      expect(guard02.blocksRaw, 'all feature work');
      expect(guard02.blockedByRaw, isNull);
      expect(
        guard02.descriptionLines.first,
        contains('Replace `flutter_lints`'),
      );
      expect(guard02.acceptanceLines, hasLength(2));
      expect(guard02.acceptanceLines.first, startsWith('- [ ] '));
    });

    test('captures requires and resolves explicit blocked-by ids', () {
      final entries = parseRoadmap(_sampleRoadmap);
      resolveDependencies(entries);
      final fire02 = entries.firstWhere((e) => e.id == 'FIRE-02');
      expect(fire02.requires, isNull);
      expect(fire02.blockedBy, ['FIRE-01']);

      final fire01 = entries.firstWhere((e) => e.id == 'FIRE-01');
      expect(fire01.requires, '`requires:human`');
      // Reverse graph derives Blocks from other entries pointing at FIRE-01.
      expect(fire01.blocks, containsAll(['FIRE-02', 'FIRE-03']));
    });

    test('expands wildcard blocked-by patterns', () {
      const source =
          '$_sampleRoadmap'
          '\n## `GUARD-01` — Other guardrail\n\n'
          '- **Type:** `type:guardrail` · **Phase:** `phase:0` · '
          '**Priority:** `priority:p0`\n'
          '- **Owner:** agent\n';
      final entries = parseRoadmap(source);
      resolveDependencies(entries);
      final fire03 = entries.firstWhere((e) => e.id == 'FIRE-03');
      expect(
        fire03.blockedBy,
        containsAll(['FIRE-01', 'FIRE-02', 'GUARD-01', 'GUARD-02']),
      );
    });
  });

  group('renderBody', () {
    test('produces sections in the canonical order', () {
      final entries = parseRoadmap(_sampleRoadmap);
      resolveDependencies(entries);
      final fire02 = entries.firstWhere((e) => e.id == 'FIRE-02');
      // Simulate an existing closed FIRE-01 issue at #9.
      fire02.blockedByIssues.add(
        BlockerRef(id: 'FIRE-01', number: 9, closed: true),
      );
      final body = renderBody(fire02);
      expect(body, contains('Synced from [docs/roadmap.md]'));
      expect(body, contains('**Metadata**'));
      expect(body, contains('- Roadmap ID: `FIRE-02`'));
      expect(body, contains('- Type: `type:infra`'));
      expect(body, contains('- Roadmap blocked by field: `FIRE-01`'));
      expect(body, contains('**Description**'));
      expect(body, contains('**Blocked By**'));
      expect(body, contains('- [x] #9'));
    });
  });

  group('RoadmapEntry.desiredLabels', () {
    test('emits phase, type, priority, and requires labels', () {
      final entries = parseRoadmap(_sampleRoadmap);
      final fire01 = entries.firstWhere((e) => e.id == 'FIRE-01');
      expect(
        fire01.desiredLabels(),
        containsAll(<String>{
          'phase:1',
          'type:infra',
          'priority:p0',
          'requires:human',
        }),
      );
    });
  });

  group('extractRoadmapId', () {
    test('parses prefix from issue titles', () {
      expect(extractRoadmapId('GUARD-02 — Tighter analyzer rules'), 'GUARD-02');
      expect(extractRoadmapId('FIRE-12 — Cloud Function'), 'FIRE-12');
      expect(extractRoadmapId('Random title'), isNull);
    });
  });

  group('SyncConfig.fromArgs', () {
    test('parses defaults', () {
      final config = SyncConfig.fromArgs(const []);
      expect(config.dryRun, isFalse);
      expect(config.roadmapPath, 'docs/roadmap.md');
    });

    test('parses --dry-run and overrides', () {
      final config = SyncConfig.fromArgs(const [
        '--dry-run',
        '--roadmap',
        'custom.md',
        '--repo',
        'foo/bar',
      ]);
      expect(config.dryRun, isTrue);
      expect(config.roadmapPath, 'custom.md');
      expect(config.repoSlug, 'foo/bar');
    });

    test('rejects unknown flags', () {
      expect(() => SyncConfig.fromArgs(const ['--bogus']), throwsArgumentError);
    });
  });
}
