# AGENTS.md

Operational rules for AI coding agents in Pickllist.

This repo is AI-operated. Assume no human will write or review code before it
reaches users. Treat every "must" as a merge requirement. If a rule cannot be
followed, document the blocker and do not mark the PR mergeable.

## Project

Pickllist is a Flutter + Firebase app for crop-picking work on a farm. Workers
use Android/iOS; the farm manager uses Windows for extra features such as Excel
import, templates, history, and user admin. Single-farm, multi-user,
real-time sync.

Layout:

```text
lib/
  core/                 # routing, theme, platform, logging, shared providers
  features/<feature>/
    domain/             # pure Dart models and enums
    data/               # abstract repos + fake + Firebase/Firestore impls
    application/        # Riverpod providers
    presentation/       # screens and widgets
  l10n/                 # ARB files + generated localizations
test/                   # mirrors lib/
firebase/               # rules, indexes, firebase.json
docs/                   # setup, architecture, data model, dependencies
```

## Default Working Mode

- Default to working until the issue is complete. Do not pause for feedback
  unless the next decision is genuinely blocked, the manager explicitly asks for
  an interactive checkpoint, or manager testing is part of the acceptance
  criteria.
- For interactive work, keep the branch usable and let the manager test on that
  branch. Incorporate feedback or move it to a follow-up issue before PR merge.
- Ask concise questions only when requirements are unclear enough that guessing
  would risk the wrong product behavior, data model, security rule, or platform
  support.

## Required Workflow

All repository work follows:

1. **Issue.** Create or update a GitHub issue before changing files. Capture
   the user role/platform, problem, acceptance criteria, edge cases, and any
   data, Firebase, localization, platform-gating, or test impact.
2. **Branch.** Branch from the issue once it is clear enough to implement. Use
   an issue-numbered name such as `feat/123-import-picking-template`.
3. **Implement.** Keep the branch focused on one issue. Update the issue if
   scope or acceptance criteria change.
4. **PR.** Open a PR linked with `Closes #<issue>`. Include summary, tests,
   docs/dependency notes, localization/platform notes, and `Self CR`.
5. **Merge.** Merge only after required checks pass, self CR is documented, and
   manager feedback is incorporated or deferred to a follow-up issue.
6. **Return to main.** After the PR is merged, check out `main` and update it
   to the merged remote state before starting or ending further work.

Do not code on `main`, start work without an issue, or open an unlinked PR.

## Engineering Rules

- Check `git status --short --branch` before editing. Preserve unrelated user
  changes; never revert work you did not make.
- Read the files you change and their closest tests before editing.
- Keep PRs small. Split broad work; explain unavoidable PRs over 600 changed
  lines.
- Prefer existing patterns over new abstractions. Leave no dead code,
  placeholder implementations, broad TODOs, skipped tests, or unused APIs.
- Do not claim a command passed unless you ran it in this workspace.
- Treat failures as caused by your change until proven otherwise.
- User-visible behavior, data contracts, security rules, dependencies, tests,
  and docs must change together.

## Architecture Rules

- `domain/` is pure Dart: no Flutter, Firebase, Riverpod, platform, or
  presentation imports. Enums live in `domain/`.
- Keep null safety strict: no implicit dynamic, avoid unnecessary nullable
  values, and avoid force unwraps when control flow can prove safety.
- Models are immutable and explicit: required named params, value equality,
  `copyWith`, and structured `toMap`/`fromMap` or existing generated serializers.
- Repositories have an abstract interface plus fake and backend implementations.
  Swap implementations through provider overrides at app startup.
- Providers live in `application/`; presentation reads providers and does not
  construct repositories.
- In router redirects or non-widget callbacks, `ref.read` source providers, not
  derived providers that may be stale unless watched.
- All user-visible presentation strings must be in `app_en.arb`, `app_he.arb`,
  and `app_th.arb`; run `flutter gen-l10n`.
- Manager-only features must stay behind
  `PlatformInfo.managerFeaturesAvailable` and must not appear on mobile routes.
- Authorization belongs in `firebase/firestore.rules`, not only UI gates.
- Commit `lib/firebase_options.dart`; do not commit `google-services.json`,
  `GoogleService-Info.plist`, secrets, or `firebase/functions/node_modules/`.

## Commands

Run from the repo root:

```sh
flutter pub get
flutter gen-l10n
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
dart run custom_lint
flutter test --coverage
```

Use narrower tests while iterating, but before merge run the relevant full
checks. Run `dart run custom_lint` for Riverpod/provider changes and preferably
for every non-doc PR. Add emulator, build runner, smoke, or feature-specific
checks when touched files require them.

## Testing

- Tests must prove behavior with meaningful assertions, not just execute lines.
- Mirror paths: `lib/features/x/domain/foo.dart` ->
  `test/features/x/domain/foo_test.dart`.
- Every repository implementation needs happy-path and failure-path tests.
- Changes to `lib/` must touch tests unless purely mechanical; document any
  exception in the PR.
- Widget changes need tests for visible states, important interactions,
  localization-sensitive text, and platform gating.
- Do not skip, weaken, or delete tests to make CI pass.

## Dependencies And Firebase

- Add dependencies only when the SDK or existing packages cannot reasonably
  solve the problem.
- Any `pubspec.yaml` dependency change must update `docs/dependencies.md`; also
  update `docs/architecture.md` if architecture or tooling changes.
- After dependency changes, run `flutter pub get` and review `pubspec.lock`.
- Regenerate native Firebase config locally when needed with
  `flutterfire configure --project=picklist-by`; keep native config ignored.
- Deploy rules/indexes with
  `firebase deploy --only firestore:rules,firestore:indexes`.

## Mandatory Self CR

Before a PR is ready or merged, run a critical self code review after final
edits and required checks:

1. Re-read the issue, this file, and relevant docs.
2. Review the final diff with `git diff --stat origin/main...HEAD` and
   `git diff origin/main...HEAD` for PR branches, or plain `git diff --stat`
   and `git diff` for local-only work.
3. Try to block the PR. Look for correctness bugs, weak tests, stale provider
   reads, localization misses, platform-gating mistakes, Firestore rule gaps,
   dependency drift, race conditions, null-safety holes, and unrelated changes.
4. Fix blockers, rerun affected checks, and repeat self CR for non-trivial
   fixes.
5. Document `Self CR` in the PR: commands run, issues found/fixed, and residual
   risks or "none known".

No documented self CR means no merge.

## Definition Of Done

- Issue -> branch -> PR -> merge was followed.
- Acceptance criteria are met without unrelated changes.
- Architecture, localization, platform, Firebase, dependency, and docs rules
  above are satisfied.
- Meaningful tests cover new or changed behavior.
- `dart format --set-exit-if-changed .`, `flutter analyze --fatal-infos`, and
  `flutter test --coverage` pass for code changes.
- Critical self CR is documented and CI is green.

## Do Not

- Do not call `Firebase.initializeApp()` without guarded real options.
- Do not use `print()`; use `appLogger(name)`.
- Do not hardcode user-visible strings in presentation code.
- Do not disable lints file-wide.
- Do not merge skipped tests, red CI, undocumented self CR, or unexplained local
  command failures.
