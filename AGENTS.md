# AGENTS.md

Instructions for AI coding agents working in this repository. Human
contributors should also read this — it's the fastest onboarding doc.

## What this project is

Pickllist is a Flutter + Firebase app for managing crop-picking work
on a farm. Workers use it on Android/iOS, the work manager uses it on
Windows (with extra features: Excel import, templates, history).

Single-farm, multi-user, real-time sync.

## Layout

```
lib/
├── main.dart, app.dart, bootstrap.dart   # entry points
├── core/                                 # cross-cutting: routing, theme, platform, logging, providers
├── features/<feature>/
│   ├── domain/        # pure Dart data classes + enums, no Flutter imports in /domain
│   ├── data/          # repositories: abstract + fake + (later) firestore impl
│   ├── application/   # Riverpod providers that expose data to UI
│   └── presentation/  # screens + widgets
└── l10n/              # ARB files + generated AppLocalizations
test/                  # unit + widget tests mirroring lib/ layout
firebase/              # firestore.rules, indexes, firebase.json
.github/workflows/     # CI
docs/                  # setup, architecture, data model
```

## Local commands

```sh
flutter pub get
flutter gen-l10n                 # regenerate l10n after editing .arb files
flutter analyze                  # static analysis (CI uses --fatal-infos)
dart format --set-exit-if-changed .
flutter test                     # all tests
flutter test --coverage          # with coverage
flutter run                      # mobile/desktop device from IDE or CLI
```

## Conventions

- **Null safety, no implicit-dynamic.** Prefer `required` named params.
- **Domain is pure Dart.** `lib/features/*/domain/**` must not import
  `package:flutter/*`. Enums live here, not in `presentation/`.
- **Repositories are abstract + multiple impls.** Every feature that
  talks to Firebase has an abstract class in `data/`, a `fake_*` impl
  used in tests and the POC, and eventually a Firestore impl. Swapping
  is done by overriding the repo's Riverpod provider at app startup
  (see `lib/bootstrap.dart`).
- **Providers live in `application/`.** Screens in `presentation/` only
  read providers; they don't construct repositories.
- **Riverpod caveat:** inside a router redirect or any non-widget
  callback that uses `ref.read`, read the **source** provider, not a
  downstream derived provider. Derived providers only recompute when
  they're being watched; a `ref.read` on a derived provider can return
  a stale cached value. See `lib/core/routing/app_router.dart` —
  `redirect` reads `authStateProvider`, not `currentUserProvider`.
- **Localization.** Every user-visible string goes in `lib/l10n/app_en.arb`
  and mirrored into `app_he.arb` and `app_th.arb`. Run `flutter gen-l10n`
  after edits. No hardcoded strings in `presentation/`.
- **Platform gating.** Manager-only screens (Excel import, templates,
  history, user admin) are gated by `PlatformInfo.managerFeaturesAvailable`,
  which is true only on Windows. Don't add these routes to mobile.
- **Tests alongside features.** Mirror the lib path:
  `lib/features/x/domain/foo.dart` → `test/features/x/domain/foo_test.dart`.
  Every repository gets tests of its happy + failure paths.
- **Firebase client config policy.** Commit `lib/firebase_options.dart`
  (public config, needed for CI builds; protected by App Check — see
  `FIRE-10`). Do **not** commit `google-services.json` or
  `GoogleService-Info.plist` — those regenerate deterministically via
  `flutterfire configure` and are `.gitignore`d. Also don't commit
  anything under `firebase/functions/node_modules/`.

## Adding a new feature

1. Create `lib/features/<name>/{domain,data,application,presentation}/`.
2. Model types in `domain/` — immutable, with `copyWith`, `==`, `toMap`/`fromMap`.
3. Abstract repo in `data/<name>_repository.dart`, fake impl next to it.
4. Providers in `application/<name>_providers.dart`.
5. Screens in `presentation/`. Watch providers, never construct repos.
6. Tests under `test/features/<name>/...`.
7. Add strings to all three `.arb` files and run `flutter gen-l10n`.
8. If Firebase-backed, add Firestore rules in `firebase/firestore.rules`
   and indexes in `firebase/firestore.indexes.json`.

## Firebase

Project ID is recorded in `firebase/.project-id` (`picklist-by`).
`lib/firebase_options.dart` is committed; native client config
(`google-services.json`, `GoogleService-Info.plist`) is gitignored —
regenerate it locally with `flutterfire configure --project=picklist-by`
when you need to build for Android or iOS.

Remaining Firebase wiring:

1. In `lib/bootstrap.dart`, uncomment `Firebase.initializeApp` wiring
   (`FIRE-03`).
2. Implement `FirebaseAuthRepository`, `FirestorePickingListRepository`,
   etc., and override the fake providers in `bootstrap`'s `ProviderScope`.
3. `firebase deploy --only firestore:rules,firestore:indexes` (`FIRE-06`).

See `docs/setup.md` for the full procedure.

## Definition of done

A change is done when:

1. `flutter analyze` is clean (no info-level issues either).
2. `dart format --set-exit-if-changed .` passes.
3. `flutter test` passes.
4. New code has tests.
5. All three `.arb` files have translations for any new strings.
6. CI is green on the PR.

## Things not to do

- Don't call `Firebase.initializeApp()` without guarded options — it
  crashes until the options file is real.
- Don't use `print()` — use the `logging` package via
  `appLogger(name)` from `core/logging/logger.dart`.
- Don't add new dependencies without updating `docs/architecture.md`.
- Don't disable lints file-wide. `// ignore:` on individual lines is fine
  when necessary, with a comment explaining why.
