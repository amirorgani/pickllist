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

## Architectural fitness tests

`test/architecture/` parses source files and asserts layering invariants
that are easy to violate accidentally and expensive to unwind later.
Each rule lives in its own test file so failures point at exactly which
invariant slipped:

- **`layer_boundaries_test.dart`** — `lib/features/*/domain/` may import
  only other domain files, `package:collection`, or `dart:*`; data files
  must not depend on presentation; presentation files may not reach into
  another feature's `data/` directly (collaborate via `application/`).
- **`file_size_test.dart`** — no hand-written file under `lib/` may
  exceed 400 significant lines (blank lines and comments excluded).
  Generated files (`*.g.dart`, `*.freezed.dart`, `lib/l10n/generated/`,
  `lib/firebase_options.dart`) are skipped.
- **`arb_parity_test.dart`** — every locale ARB under `lib/l10n/`
  defines the same set of translation keys (metadata `@…` keys are
  ignored). Drift fails CI with the missing keys per file.
- **`repository_pairing_test.dart`** — every abstract repository in
  `lib/features/*/data/` has a `Fake*` sibling in the same directory,
  so the test surface stays honest.

To add a new architectural rule, drop a file under `test/architecture/`
that walks `lib/` (or another scope), asserts the invariant, and emits
a `reason:` message that names the offending files. Keep each rule in
its own test file — a single mega-test that breaks on every kind of
violation is harder to triage.

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
