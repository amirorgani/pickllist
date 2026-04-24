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
