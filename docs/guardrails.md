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
