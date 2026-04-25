# Guardrails

This repo is AI-operated, so CI guardrails prevent silent quality regressions
before feature work reaches users.

## Coverage ratchet

CI runs `flutter test --coverage` and then `dart run tool/check_coverage.dart`.
The check compares `coverage/lcov.info` against the committed baseline in
`tool/coverage_baseline.json`.

- Overall project coverage must not fall below the committed baseline.
- Touched files under `lib/features/**/domain/` and `lib/features/**/data/`
  must stay at or above 80% line coverage.
- The long-term pre-ship target is 90% overall coverage.

The ratchet only moves upward through an explicit PR change to
`tool/coverage_baseline.json`. When `main` improves, update that file in the
same PR as the improvement so future PRs cannot regress below the new level.

## Assertion quality

Coverage alone lets shallow tests slip through — `expect(thing, isNotNull)`
covers the line without proving any meaningful behaviour. CI runs
`dart run tool/check_assertion_quality.dart` as part of the analyze job and
fails when the ratio of weak truthy matchers (`isNotNull`, `isNotEmpty`,
`isTrue`) exceeds 30% of the `expect(...)` calls in a single file.

The default scope is `test/features/picking_lists/`, the GUARD-05 critical
module. Pass explicit paths to widen the scan locally:

```sh
# Default scope (also what CI runs).
dart run tool/check_assertion_quality.dart

# Whole suite.
dart run tool/check_assertion_quality.dart test/
```

Files with fewer than 3 `expect(...)` calls are skipped — the ratio is too
noisy to be useful below that. When the check fails, the fix is to replace
weak assertions with assertions on specific values (e.g. `equals(...)`,
`hasLength(...)`, `containsAll([...])`) rather than raising the threshold.

## Public API surface snapshot

`test/api_surface_test.dart` walks every `.dart` file under `lib/`, extracts
each public top-level declaration (`class`, `enum`, `mixin`, `extension`,
`typedef`), and compares the rendered surface to the committed snapshot at
`test/api_surface.snapshot.txt`.

If a PR adds, renames, or removes a public symbol, the test fails. The fix is
to regenerate and commit the snapshot in the same PR — that turns silent API
churn into a deliberate, reviewable change:

```sh
dart run tool/generate_api_snapshot.dart --write
```

Generated files (`*.g.dart`, `*.freezed.dart`, `lib/l10n/generated/`,
`lib/firebase_options.dart`) are excluded from the snapshot — they regenerate
deterministically and would only add noise.
