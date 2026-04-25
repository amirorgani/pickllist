# Pickllist roadmap: POC → daily-use farm app

**Audience:** AI agents (primary) and the farm owner reviewing their
work. No human writes code in this project. The roadmap is designed
around that constraint.

## Ground rules (read before anything else)

1. **One farm, one codebase.** Do not add multi-tenancy, org switching,
   or configurability for other farms. Every such suggestion is YAGNI.
2. **Quality gates are hard.** A PR that drops coverage below the
   current ratchet, breaks a guardrail test, or adds a dependency
   without justification is rejected automatically by CI. Don't try to
   work around it — improve the change.
3. **Every issue has an owner type.** Either `agent` (default) or
   `human` (the farm owner, tagged `requires:human`). Agents must not
   attempt to auto-complete `requires:human` steps; they should stop
   and surface the requirement.
4. **Small PRs.** One issue per PR, ≤ ~400 net lines changed where
   feasible. Larger issues get split into children.
5. **No unowned code.** If an agent touches a file, that file's tests
   must also be touched (added or updated) in the same PR unless the
   change is purely mechanical (format, import order). This is
   enforced by a CI check against `git diff`.
6. **Guardrails before features.** Phase 0 (guardrails) blocks
   everything else. Without it, Phases 1+ will accumulate untestable
   code that later agents can't safely modify.

## Issue ID scheme

IDs are prefixed by category and are stable across GitHub issue
renumbering:

| Prefix | Meaning                             |
|--------|-------------------------------------|
| `GUARD`| Guardrails / quality infrastructure |
| `INFRA`| Toolchain / CI / deployment         |
| `FIRE` | Firebase wiring (auth, data, rules) |
| `MGMT` | Manager screens (Windows)           |
| `DATA` | Data features (Excel, templates, history) |
| `UX`   | UX polish (RTL, a11y, errors, loading) |
| `OPS`  | Release / ops / observability       |
| `DOC`  | Documentation                       |

## Label taxonomy (set up in `INFRA-01`)

| Label              | Use                                                        |
|--------------------|------------------------------------------------------------|
| `phase:0`–`phase:6`| Rough sequencing. `phase:0` blocks everything.             |
| `type:guardrail`   | Architectural / quality infrastructure                     |
| `type:feature`     | User-visible behavior change                               |
| `type:infra`       | CI, toolchain, deployment, project setup                   |
| `type:test`        | Pure test additions / improvements                         |
| `type:docs`        | Documentation only                                         |
| `type:refactor`    | No behavior change, improves structure                     |
| `type:bug`         | Regression or defect                                       |
| `platform:mobile`  | Android/iOS only                                           |
| `platform:windows` | Windows only                                               |
| `platform:all`     | Cross-platform                                             |
| `priority:p0`      | Blocks daily use                                           |
| `priority:p1`      | Needed for production                                      |
| `priority:p2`      | Nice to have                                               |
| `requires:human`   | A step only the farm owner can execute                     |
| `good-first-ai-task`| Small, well-specified, safe for a less-capable agent      |
| `blocked`          | Waiting on a dependency (auto-set from dependency graph)   |

## Phase gate criteria

A phase is considered "done" only when:

- All its `priority:p0` and `priority:p1` issues are closed.
- CI is green on `main`.
- `docs/` is updated for any behavior change.
- A short "phase review" note is appended to this file's changelog
  at the bottom.

---

# Phase 0 — Guardrails

**Why first:** AI agents with no human reviewer WILL degrade code
quality unless CI forcefully stops them. Phase 0 codifies every "do
not do X" rule as an automated test or CI step. Without Phase 0,
Phases 1+ cannot be trusted.

## `GUARD-01` — Enforce coverage ratchet (CI gate)

- **Type:** `type:guardrail` · **Phase:** `phase:0` · **Platform:** `platform:all`
- **Priority:** `priority:p0` · **Owner:** agent
- **Blocks:** everything else
- **Blocked by:** none

**Description.** Wire a coverage-ratchet check into the CI workflow.
The repo starts well below the long-term target, so the first gate
should prevent regressions instead of freezing all work: PR overall
coverage must not drop below the baseline on `main`, touched files
under `lib/features/**/domain` and `lib/features/**/data` must stay at
≥ 80 %, and 90 % overall remains the pre-ship target.

**Acceptance criteria:**
- [ ] `flutter test --coverage` runs in CI (already does).
- [ ] A post-step parses `coverage/lcov.info` and fails if PR overall
      coverage drops below the baseline / ratchet from `main`.
- [ ] A secondary check verifies touched-file thresholds for `domain/`
      and `data/`.
- [ ] The ratchet only moves upward when `main` improves; updating it
      requires a deliberate change in the same PR.
- [ ] Implementation tool: a small Dart script in `tool/check_coverage.dart`
      (not a shell `awk` — must be testable).
- [ ] The script itself is tested (`test/tool/check_coverage_test.dart`).
- [ ] `docs/guardrails.md` documents the ratchet and the 90 % ship target.

## `GUARD-02` — Tighter analyzer rules

- **Type:** `type:guardrail` · **Phase:** `phase:0` · **Priority:** `priority:p0`
- **Owner:** agent · **Blocks:** all feature work

**Description.** Replace `flutter_lints` with `very_good_analysis` (or
equivalent) and enable the strict set. Specifically forbid:

- `avoid_dynamic_calls`, `avoid_returning_this`, `prefer_const_constructors`
- `public_member_api_docs` on every file in `lib/core/` and
  `lib/features/*/domain/` and `lib/features/*/data/`
- `require_trailing_commas`
- `unawaited_futures` as error
- No `dynamic`, no implicit casts (set in `analysis_options.yaml`)

**Acceptance criteria:**
- [ ] `analysis_options.yaml` updated.
- [ ] All existing code passes the stricter lints (fix in this PR).
- [ ] CI runs `flutter analyze --fatal-infos` (it does; verify still clean).

## `GUARD-03` — Architectural fitness tests

- **Type:** `type:guardrail` · **Phase:** `phase:0` · **Priority:** `priority:p0`
- **Owner:** agent

**Description.** Add a suite under `test/architecture/` that asserts
invariants by parsing source files. Using Dart's `analyzer` package,
check:

- Every file in `lib/features/*/domain/` imports ONLY from
  `package:pickllist/features/*/domain/`, `package:collection`, or
  `dart:*` — never Flutter, Firebase, or Riverpod.
- Every file in `lib/features/*/data/` imports ONLY from `domain/` or
  Dart/Firebase/third-party packages — never `presentation/`.
- Every file in `lib/features/*/presentation/` does not import other
  features' `data/` directly (only cross-feature `application/` is allowed).
- Every abstract repository in `data/` has at least one concrete `Fake*`
  implementation in the same directory.
- No file exceeds 400 lines of code (excluding comments / blank lines).
  Measured by the test; files over the limit fail CI with a decomposition
  hint.
- Every `.arb` file has the same set of keys (no missing translation).

**Acceptance criteria:**
- [ ] `test/architecture/layer_boundaries_test.dart` covers the
      import-rule invariants.
- [ ] `test/architecture/file_size_test.dart` covers the 400-line limit.
- [ ] `test/architecture/arb_parity_test.dart` covers translation parity.
- [ ] `test/architecture/repository_pairing_test.dart` verifies the
      abstract/fake pairing invariant.
- [ ] `docs/guardrails.md` documents each rule and how to add new ones.

## `GUARD-04` — Formatting + commit hygiene

- **Type:** `type:guardrail` · **Phase:** `phase:0` · **Priority:** `priority:p1`
- **Owner:** agent

**Description.** Enforce conventional commits and keep PRs small.

**Acceptance criteria:**
- [ ] `.github/pull_request_template.md` with a checklist
      (coverage, guardrails, docs, i18n).
- [ ] A CI job that parses PR title for conventional-commit prefix
      (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`).
- [ ] A CI job that warns (does not fail) when PR diff > 600 lines.
- [ ] A CI job that fails when a PR modifies `lib/` but no
      corresponding `test/` file is touched (uses `git diff`).

## `GUARD-05` — Mutation-testing smoke

- **Type:** `type:guardrail` · **Phase:** `phase:0` · **Priority:** `priority:p2`
- **Owner:** agent

**Description.** Coverage alone lets agents write shallow tests
(`expect(thing, isNotNull)` everywhere) that don't actually exercise
logic. Add a lightweight mutation-testing step on critical modules.

If no mature Dart mutation tool exists at the time this runs, substitute
a simpler "truthy-assertion" detector: fail the build if a test file's
ratio of `expect(..., isNotNull)` / `expect(..., isNotEmpty)` / `expect(..., isTrue)`
exceeds 30 % of all `expect` calls in that file.

**Acceptance criteria:**
- [ ] One of: (a) `mutation_test` or similar configured for
      `lib/features/picking_lists/domain/`, or (b) the
      assertion-quality heuristic described above.
- [ ] Documented in `docs/guardrails.md`.

## `GUARD-06` — Dependency change review

- **Type:** `type:guardrail` · **Phase:** `phase:0` · **Priority:** `priority:p1`
- **Owner:** agent

**Description.** Any change to `pubspec.yaml` dependencies must update
`docs/dependencies.md` with a one-line justification. CI enforces that
both files change together.

**Acceptance criteria:**
- [ ] `docs/dependencies.md` seeded with every current dependency + reason.
- [ ] CI check: if `pubspec.yaml` changes under `dependencies:` or
      `dev_dependencies:`, `docs/dependencies.md` must also change.

## `GUARD-07` — Public API surface snapshot

- **Type:** `type:guardrail` · **Phase:** `phase:0` · **Priority:** `priority:p2`
- **Owner:** agent

**Description.** Prevent agents from silently renaming / deleting
public APIs. A generated file `test/api_surface.snapshot.txt` lists
every public class and top-level symbol exported from `lib/`. A test
regenerates the snapshot and fails if it differs — the fix is to
update the snapshot *deliberately* in the same PR, which forces a
conscious choice.

**Acceptance criteria:**
- [ ] `tool/generate_api_snapshot.dart`.
- [ ] `test/api_surface_test.dart` compares current surface to snapshot.
- [ ] Initial snapshot committed.
- [ ] Documented in `docs/guardrails.md`.

## `GUARD-08` — Branch protection

- **Type:** `type:guardrail` · **Phase:** `phase:0` · **Priority:** `priority:p0`
- **Requires:** `requires:human`
- **Owner:** human (farm owner)

**Description.** Configure GitHub branch protection on `main`:
- Require CI status checks to pass (all jobs from `ci.yml`).
- Require PRs (no direct push to main).
- Require the PR checklist to be ticked (via a status check added by
  `GUARD-04`).
- No force-push on `main`.

Self-review by the agent is part of the coding process; there are no
human reviewer gates (no CODEOWNERS, no required approvals, so stale-
approval dismissal is moot).

**Acceptance criteria:** (human)
- [ ] Branch protection configured in GitHub settings.
- [ ] An agent attempting to push directly to `main` is rejected.

## `GUARD-09` — Raise coverage ratchet to 90 %

- **Type:** `type:guardrail` · **Phase:** `phase:0` · **Priority:** `priority:p1`
- **Owner:** agent
- **Blocked by:** `GUARD-01`

**Description.** `GUARD-01` set the floor; this issue closes the gap to
the 90 % long-term target documented in `docs/guardrails.md`. The
ratchet only moves when `tool/coverage_baseline.json` is bumped, so
this is a deliberate program of work rather than a single PR. Approach:

1. Audit `flutter test --coverage` to find the 5–10 files with the
   largest absolute uncovered-line counts. Prioritise `domain/` and
   `data/` since they already have the 80 % per-file floor.
2. Backfill focused tests for uncovered branches. Prefer specific-value
   matchers (`equals`, `hasLength`, `containsAll`) over weak truthy
   ones — `GUARD-05` will reject filler.
3. Bump `overallPercent` in `tool/coverage_baseline.json` in the same
   PR as the improvement so the new floor sticks.
4. Repeat until overall coverage ≥ 90 %.

**Acceptance criteria:**
- [ ] `tool/coverage_baseline.json` `overallPercent` reaches 90.0.
- [ ] Per-file 80 % floor under `lib/features/**/domain/` and
      `lib/features/**/data/` is held throughout.
- [ ] No `GUARD-05` regressions (new tests stay under the 30 %
      truthy-matcher ratio).
- [ ] `docs/guardrails.md` updated when the long-term target is
      reached (drop the "pre-ship target is 90 %" line, replace with
      the steady-state value).

---

# Phase 1 — Firebase foundation

**Goal:** Move from the in-memory fake repo to a real Firebase backend
that can serve multiple devices live.

## `FIRE-01` — Create Firebase project

- **Type:** `type:infra` · **Phase:** `phase:1` · **Priority:** `priority:p0`
- **Requires:** `requires:human`
- **Blocks:** `FIRE-02`, `FIRE-03`, `FIRE-04`, `FIRE-05`, all `MGMT-*`
- **Owner:** human

**Description.** Create the Firebase project at
<https://console.firebase.google.com>. Turn on:
- **Authentication** → Email/Password provider
- **Cloud Firestore** in production mode (any region)
- **Cloud Messaging** (for Phase 4)
- **Billing** (Blaze plan — required before Cloud Functions in
  `INFRA-02`, `MGMT-02`, and `FIRE-12`; don't defer it past Phase 1)

**Deliverables (human):**
- [ ] Project ID recorded in a new file `firebase/.project-id` (just the ID, one line).
- [ ] Farm owner runs `firebase login` locally.
- [ ] Farm owner runs `flutterfire configure --project=<id>` — this
      generates `lib/firebase_options.dart`; commit/ignore policy is
      finalized in `FIRE-02`.

## `FIRE-02` — Commit `firebase_options.dart` strategy

- **Type:** `type:infra` · **Phase:** `phase:1` · **Priority:** `priority:p0`
- **Blocked by:** `FIRE-01`
- **Owner:** agent

**Description.** `firebase_options.dart` contains public client config,
but the repo currently has conflicting instructions about which Firebase
files are committed. Adopt one policy and update the docs / ignore rules
together:

- Commit `lib/firebase_options.dart`.
- Decide explicitly whether `google-services.json` and
  `GoogleService-Info.plist` are committed or ignored, then write the
  same policy in `.gitignore`, `AGENTS.md`, and `docs/setup.md`.
- Enable Firebase App Check (separate follow-up: `FIRE-10`) so committed
  client config is not the only line of defense.

**Acceptance criteria:**
- [ ] `.gitignore`, `AGENTS.md`, and `docs/setup.md` agree on the policy.
- [ ] `firebase_options.dart` committed.
- [ ] Decision recorded for Android/iOS client config files before FCM
      work begins.
- [ ] Follow-up issue opened for App Check (separate: `FIRE-10`).

## `FIRE-03` — `FirebaseAuthRepository`

- **Type:** `type:feature` · **Phase:** `phase:1` · **Priority:** `priority:p0`
- **Blocked by:** `FIRE-01`, `FIRE-02`, all `GUARD-*`
- **Owner:** agent

**Description.** Real implementation of `AuthRepository` against
`firebase_auth`. Wire in `bootstrap.dart` via provider override. Fake
remains for tests.

**Acceptance criteria:**
- [ ] `lib/features/auth/data/firebase_auth_repository.dart`.
- [ ] `authStateChanges()` maps FirebaseAuth → `AppUser` via the
      `users/{uid}` Firestore document to populate role + displayName.
- [ ] `signIn` maps `FirebaseAuthException` codes to our `AuthException`.
- [ ] Tests with `firebase_auth_mocks`.
- [ ] `bootstrap.dart` gated: if `FirebaseOptions` has non-placeholder
      values, use Firebase; else use fake.
- [ ] Manual QA: sign in works against the live project.

## `FIRE-04` — `FirestorePickingListRepository`

- **Type:** `type:feature` · **Phase:** `phase:1` · **Priority:** `priority:p0`
- **Blocked by:** `FIRE-03`
- **Owner:** agent

**Description.** Real implementation against Firestore. Reflects the
schema in `docs/data-model.md`.

**Acceptance criteria:**
- [ ] `lib/features/picking_lists/data/firestore_picking_list_repository.dart`.
- [ ] Uses `snapshots()` for live streams (matches the real-time UX).
- [ ] `claimItem` uses a transaction to prevent lost-update when two
      workers tap "Claim" at once.
- [ ] Tests with `fake_cloud_firestore`.
- [ ] Integration test against the Firestore emulator (new job in `ci.yml`).

## `FIRE-05` — `FirestoreUserDirectoryRepository`

- **Type:** `type:feature` · **Phase:** `phase:1` · **Priority:** `priority:p0`
- **Blocked by:** `FIRE-03`
- **Owner:** agent

**Description.** Streams `users/` collection for the assignee picker.

**Acceptance criteria:**
- [ ] Implementation + tests.
- [ ] Sort by `displayName`.

## `FIRE-06` — Deploy initial Firestore rules + indexes

- **Type:** `type:infra` · **Phase:** `phase:1` · **Priority:** `priority:p0`
- **Blocked by:** `FIRE-01`, `FIRE-04`
- **Requires:** `requires:human` (for the `firebase deploy`)
- **Owner:** human (runs deploy), agent (drafts any rule updates)

**Acceptance criteria:**
- [ ] `firebase deploy --only firestore:rules,firestore:indexes`
      run by human.
- [ ] Rules-simulator scripted tests pass (see `FIRE-07`).

## `FIRE-07` — Firestore security rules tests

- **Type:** `type:test` · **Phase:** `phase:1` · **Priority:** `priority:p0`
- **Blocked by:** `FIRE-04`
- **Owner:** agent

**Description.** Automated tests of `firestore.rules` using
`@firebase/rules-unit-testing` (Node). Runs in CI against the emulator.

**Acceptance criteria:**
- [ ] `firebase/rules-tests/` with at least: worker-claim, worker-cannot-reassign,
      worker-cannot-write-arbitrary-fields, worker-cannot-read-draft-list,
      inactive-user-cannot-read-or-write, manager-can-do-anything.
- [ ] New CI job installs Node, runs `firebase emulators:exec`.

## `INFRA-02` — Firebase Functions workspace + CI

- **Type:** `type:infra` · **Phase:** `phase:1` · **Priority:** `priority:p1`
- **Blocked by:** `FIRE-01`
- **Owner:** agent

**Description.** Phase 2 user admin and Phase 4 notifications both rely
on Cloud Functions. Set up the Node/TypeScript workspace, local
emulator flow, and CI before the first function feature so those later
issues stay feature-sized instead of infrastructure-heavy.

**Acceptance criteria:**
- [ ] `firebase/functions/` scaffolded with `package.json`,
      `tsconfig.json`, `src/`, and shared build/test scripts.
- [ ] Local emulator workflow can run Firestore + Auth + Functions
      together, and the steps are documented.
- [ ] CI installs function dependencies and runs at least build + test
      or smoke checks.
- [ ] `docs/setup.md` documents the Blaze prerequisite and the local
      Functions workflow.

## `FIRE-08` — Seed the first manager account

- **Type:** `type:infra` · **Phase:** `phase:1` · **Priority:** `priority:p0`
- **Blocked by:** `FIRE-01`, `FIRE-06`
- **Requires:** `requires:human`
- **Owner:** human

**Description.** Human creates a manager Firebase Auth user and the
corresponding `users/{uid}` document with `role: 'manager'`. From then
on, managers create workers from the app.

**Acceptance criteria:**
- [ ] Manager can sign into the mobile and Windows apps.

## `FIRE-09` — Migrate POC fake seed to `tool/seed_emulator.dart`

- **Type:** `type:infra` · **Phase:** `phase:1` · **Priority:** `priority:p1`
- **Blocked by:** `FIRE-04`
- **Owner:** agent

**Description.** The current fake seeds "Thursday morning pick" at
startup. Move that data into a standalone script that seeds the
Firestore emulator, so developers / agents can `flutter run` against
a hydrated emulator.

## `FIRE-10` — Enable Firebase App Check

- **Type:** `type:infra` · **Phase:** `phase:1` · **Priority:** `priority:p1`
- **Requires:** `requires:human` (registration in Firebase console)
- **Owner:** human + agent

---

# Phase 2 — Manager MVP (enough to run a real day)

**Goal:** At the end of Phase 2, the farm owner can log in on Windows,
create workers, add crops, build a picking list, publish it, and watch
workers complete it in real time. That unlocks actual daily use.

## `MGMT-01` — Platform-aware shell

- **Type:** `type:feature` · **Phase:** `phase:2` · **Platform:** `platform:windows`
- **Priority:** `priority:p0` · **Blocked by:** `FIRE-03`

**Description.** Give the Windows build a NavigationRail / drawer with
sections: "Picking lists", "Crops", "Users", later "Templates" and
"History". Mobile keeps its current single-stack flow.

**Acceptance criteria:**
- [ ] Mobile layout unchanged.
- [ ] Windows shows the nav rail with at least the two Phase-2 sections live.
- [ ] All gated by `PlatformInfo.managerFeaturesAvailable`.
- [ ] Widget tests for both layouts.

## `MGMT-02` — Users admin (Windows)

- **Type:** `type:feature` · **Phase:** `phase:2` · **Platform:** `platform:windows`
- **Priority:** `priority:p0` · **Blocked by:** `MGMT-01`, `FIRE-05`, `FIRE-06`, `INFRA-02`

**Description.** Manager lists users, creates new worker accounts
(email + temporary password), edits display name / role, deactivates
accounts. Deactivation is a two-part operation: disable the Firebase
Auth account and set `users/{uid}.active = false` so rules and client
queries can treat the account as inactive immediately.

Creating a Firebase Auth user requires the Admin SDK. Two options:
(a) ship a small Cloud Function `createWorker` that the manager calls
(keeps admin creds server-side) — preferred; (b) direct Admin SDK
call from a desktop-only path — rejected (admin creds on a client).

**Acceptance criteria:**
- [ ] Manager-only callable Functions cover worker creation and
      activation-state changes (`createWorker`, `setUserActive`, or
      equivalent), each with an auth check requiring `role: manager`.
- [ ] UI to list, invite, edit, deactivate.
- [ ] `users/{uid}` schema updated with `active: bool`, and
      `docs/data-model.md` documents the field.
- [ ] Deactivate flow disables the Firebase Auth account and sets
      `users/{uid}.active = false`.
- [ ] Rules updated so inactive users can't read or write; disabled
      accounts are rejected at sign-in by Firebase Auth.
- [ ] Tests for Cloud Function (rule-tests or offline mocks).
- [ ] ≥ 90 % coverage on the new feature.

## `MGMT-03` — Crops catalog (Windows)

- **Type:** `type:feature` · **Phase:** `phase:2` · **Platform:** `platform:windows`
- **Priority:** `priority:p0` · **Blocked by:** `MGMT-01`

**Description.** CRUD over `crops/`. Soft-delete via `active: false`.

**Acceptance criteria:**
- [ ] Create / edit / archive / restore.
- [ ] Validation: name unique (case-insensitive), `defaultUnit` required.
- [ ] Tests + widget tests.

## `MGMT-04` — Create / edit picking list (Windows)

- **Type:** `type:feature` · **Phase:** `phase:2` · **Platform:** `platform:windows`
- **Priority:** `priority:p0` · **Blocked by:** `MGMT-03`, `FIRE-04`

**Description.** Manager creates a list (name, scheduled date/time),
adds items (crop from the catalog, quantity, unit, note, assignee).
Publish button moves `status` from `draft` → `published` (visible to
workers).

**Acceptance criteria:**
- [ ] New list screen.
- [ ] Add row dialog with crop autocomplete.
- [ ] Re-order rows (optional, `priority:p2`).
- [ ] Publish / unpublish.
- [ ] Completion flow is defined and implemented: only managers can mark
      a list `completed`, and completed lists become read-only outside
      history.
- [ ] Delete list (draft only; published lists can only be completed).
- [ ] Tests.

## `MGMT-05` — Assignee picker in list detail

- **Type:** `type:feature` · **Phase:** `phase:2` · **Priority:** `priority:p0`
- **Blocked by:** `MGMT-04`, `FIRE-05`

**Description.** Replace the current alphabetical `SimpleDialog` with
a searchable picker (important when worker count grows).

## `MGMT-06` — Mobile: show only published lists

- **Type:** `type:feature` · **Phase:** `phase:2` · **Platform:** `platform:mobile`
- **Priority:** `priority:p0` · **Blocked by:** `FIRE-04`

**Description.** Workers see `status == 'published'` lists ordered by
`scheduledAt` (today's first). Drafts are manager-only in both the UI
query and Firestore rules.

## `MGMT-07` — End-of-phase: run one real day

- **Type:** `type:infra` · **Phase:** `phase:2` · **Priority:** `priority:p0`
- **Requires:** `requires:human`
- **Owner:** human

**Description.** Farm owner uses the app for one real picking day.
Record friction points as new issues. Don't proceed to Phase 3 until
this is logged.

---

# Phase 3 — Excel import + templates (scale manager productivity)

## `DATA-01` — Excel import: file picker + parser

- **Type:** `type:feature` · **Phase:** `phase:3` · **Platform:** `platform:windows`
- **Priority:** `priority:p1` · **Blocked by:** `MGMT-04`

**Description.** Farm owner uploads an `.xlsx` file from Windows,
we parse it with the `excel` package, show a preview grid, then import.

**Acceptance criteria:**
- [ ] Column-mapping dialog (source column → `cropName` / `quantity` /
      `unit` / `assignee email` / `note`).
- [ ] Row-level validation (unknown crop, bad unit, unknown assignee email).
- [ ] Errors rendered inline; import blocked until all rows valid or
      explicitly skipped.
- [ ] Tests with a fixture `.xlsx` under `test/fixtures/`.
- [ ] Happy path + 3 failure modes covered.

## `DATA-02` — Template save / load

- **Type:** `type:feature` · **Phase:** `phase:3` · **Platform:** `platform:windows`
- **Priority:** `priority:p1` · **Blocked by:** `MGMT-04`

**Description.** "Save as template" on any list; "Create from template"
when starting a new list. Templates live at `templates/{id}` with
items minus `assignedTo` / picked fields.

## `DATA-03` — History view (Windows)

- **Type:** `type:feature` · **Phase:** `phase:3` · **Platform:** `platform:windows`
- **Priority:** `priority:p1` · **Blocked by:** `MGMT-04`

**Description.** Past lists filterable by date range + name.
Manager can open a past list and adjust quantities / assignees post-hoc
(useful for correcting data entry errors).

**Acceptance criteria:**
- [ ] Date-range picker + name search.
- [ ] Paged / infinite-scroll list.
- [ ] Edit mode restricted to `role: manager`.
- [ ] Audit log entry every time a historical row is edited (new
      subcollection `audit/`).

---

# Phase 4 — Notifications (close the feedback loop)

## `FIRE-11` — FCM client setup

- **Type:** `type:feature` · **Phase:** `phase:4` · **Priority:** `priority:p1`
- **Blocked by:** `FIRE-03`

**Description.** Request notification permission, store device FCM
token on `users/{uid}.fcmTokens`. Handle token refresh + app-foreground
messages.

## `FIRE-12` — Cloud Function: `onAssignmentChanged`

- **Type:** `type:feature` · **Phase:** `phase:4` · **Priority:** `priority:p1`
- **Blocked by:** `FIRE-11`, `FIRE-06`, `INFRA-02`

**Description.** Firestore trigger on `pickingLists/*/items/*`: when
`assignedTo` is added or the row's `quantity`/`note` changes while the
row has an assignee, send a push to that worker.

**Acceptance criteria:**
- [ ] Function in `firebase/functions/src/onAssignmentChanged.ts`.
- [ ] Suppresses notifications for changes made by the assignee themselves.
- [ ] Unit-tested against the Functions test SDK.
- [ ] Deep link opens the specific list / row on tap.

## `FIRE-13` — Deep-linking from notifications

- **Type:** `type:feature` · **Phase:** `phase:4` · **Priority:** `priority:p2`
- **Blocked by:** `FIRE-11`

---

# Phase 5 — Polish & robustness

## `UX-01` — Offline UX

- **Type:** `type:feature` · **Phase:** `phase:5` · **Priority:** `priority:p1`

**Description.** Firestore handles offline cache automatically; the
question is what the UI shows. Add a connectivity banner, pending-write
indicators on items, and conflict-handling copy.

## `UX-02` — Error boundaries + toasts

- **Type:** `type:feature` · **Phase:** `phase:5` · **Priority:** `priority:p1`

**Description.** Global error boundary around the router; repository
errors surface as snackbars with retry. No silent `catch`.

## `UX-03` — Loading skeletons

- **Type:** `type:feature` · **Phase:** `phase:5` · **Priority:** `priority:p2`

## `UX-04` — RTL audit (Hebrew)

- **Type:** `type:feature` · **Phase:** `phase:5` · **Priority:** `priority:p1`

**Description.** Walk every screen with `locale: Locale('he')` in tests
and verify no hard-coded LTR offsets / alignments. Add golden tests
for three key screens in each of en / he / th.

## `UX-05` — Thai font verification

- **Type:** `type:feature` · **Phase:** `phase:5` · **Priority:** `priority:p1`

**Description.** Verify Material Design default fonts render Thai on
Android / iOS / Windows; if not, ship Noto Sans Thai.

## `UX-06` — A11y pass

- **Type:** `type:feature` · **Phase:** `phase:5` · **Priority:** `priority:p2`

---

# Phase 6 — Ship

## `OPS-01` — Android signing + APK distribution

- **Type:** `type:infra` · **Phase:** `phase:6` · **Platform:** `platform:mobile`
- **Priority:** `priority:p0` · **Requires:** `requires:human`
- **Blocked by:** all `priority:p0` issues in Phases 1–2

**Description.** Generate the Android release keystore (human), store
in GitHub Secrets. CI builds signed APK on tagged releases. Distribute
via Firebase App Distribution to workers' devices.

**Human steps:**
- [ ] Generate keystore, back up securely.
- [ ] Add secrets to GitHub.
- [ ] Add worker devices to Firebase App Distribution.

## `OPS-02` — iOS signing + TestFlight

- **Type:** `type:infra` · **Phase:** `phase:6` · **Priority:** `priority:p0`
- **Requires:** `requires:human`

**Description.** Apple Developer account (human) + Fastlane +
TestFlight.

## `OPS-03` — Windows installer

- **Type:** `type:infra` · **Phase:** `phase:6` · **Priority:** `priority:p0`
- **Requires:** `requires:human` (for code-signing cert)

**Description.** MSIX installer built in CI, optionally signed with an
EV cert.

## `OPS-04` — Crashlytics integration

- **Type:** `type:infra` · **Phase:** `phase:6` · **Priority:** `priority:p1`

## `OPS-05` — Release process documentation

- **Type:** `type:docs` · **Phase:** `phase:6` · **Priority:** `priority:p1`

**Description.** `docs/release.md`: how to cut a release, the version
scheme, rollback procedure.

---

# Dependency graph (abridged)

```
GUARD-01..09   (phase 0; block all feature work)
    │
    ▼
FIRE-01 (human) ── FIRE-02 ── FIRE-03 ── FIRE-04 ── FIRE-06 (human) ── FIRE-07
                             │                        │
                             └── FIRE-05              └── FIRE-08 (human)
FIRE-01 (human) ── INFRA-02
FIRE-03 ── MGMT-01 ── MGMT-03 ── MGMT-04 ── MGMT-05
FIRE-05 + FIRE-06 + INFRA-02 + MGMT-01 ── MGMT-02
FIRE-04 ── MGMT-06
MGMT-02..06 ── MGMT-07 (human: one real day)
MGMT-04 ── DATA-01 ∥ DATA-02 ∥ DATA-03
FIRE-11 + FIRE-06 + INFRA-02 ── FIRE-12 ── FIRE-13
MGMT-07 ── UX-01..06 ── OPS-01..05 (human-heavy)
```

# Human-only checklist (condensed)

Issues tagged `requires:human`, in rough order:

1. `GUARD-08` — Branch protection.
2. `FIRE-01` — Create Firebase project, enable Blaze, run `flutterfire configure`.
3. `FIRE-06` — Deploy initial rules + indexes.
4. `FIRE-08` — Seed the first manager account.
5. `FIRE-10` — Register apps for App Check.
6. `MGMT-07` — Run one real day and report friction.
7. `OPS-01` — Android keystore + distribution list.
8. `OPS-02` — Apple Developer account, TestFlight invitees.
9. `OPS-03` — Windows code-signing cert (optional but recommended).

---

# Converting to GitHub issues

`INFRA-01` (below) will add a script `tool/sync_issues.dart` that
reads this file, extracts each `## <ID> — Title` section, and
creates a GitHub issue per entry with the labels listed. Dependencies
become task-list references (`- [ ] Blocked by #<n>`) in the issue body.
The stable IDs (`GUARD-01`, etc.) stay in the titles so this file and
GitHub remain linked.

## `INFRA-01` — Issue sync script

- **Type:** `type:infra` · **Phase:** `phase:0` · **Priority:** `priority:p1`
- **Owner:** agent

**Acceptance criteria:**
- [ ] `tool/sync_issues.dart` parses this file.
- [ ] Idempotent: re-running updates existing issues instead of creating duplicates.
- [ ] Creates labels if missing.
- [ ] Sets `blocked` label automatically based on the "Blocked by" field.
- [ ] One dry-run flag (prints what it would do).

---

# Changelog of this roadmap

- 2026-04-22: initial version, drafted alongside the POC commit.
- 2026-04-22: clarified Firebase config policy, Functions sequencing,
  draft/inactive-user security checks, and the list-completion lifecycle.
