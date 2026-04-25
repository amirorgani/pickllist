# Setup

## Prerequisites

- **Flutter** 3.41+ (Dart 3.11+). `flutter doctor` should be green
  for your target platforms (Windows, Android, iOS).
- **Node.js** LTS + **Firebase CLI** (only needed once we wire
  Firebase): `npm install -g firebase-tools`.
- **FlutterFire CLI**: `dart pub global activate flutterfire_cli`.

## Run the POC

The current codebase runs against an in-memory backend — no Firebase
project needed.

```sh
flutter pub get
flutter gen-l10n
flutter run -d windows          # or your Android/iOS device
```

Seeded accounts:

| Email                   | Password      | Role    |
|-------------------------|---------------|---------|
| `manager@farm.test`     | `password123` | manager |
| `worker@farm.test`      | `password123` | worker  |
| `worker2@farm.test`     | `password123` | worker  |

## Wire up a real Firebase project

The project `picklist-by` already exists (see `firebase/.project-id`).
`lib/firebase_options.dart` is committed, so a fresh clone can build
for Windows without re-running `flutterfire configure`.

### Client config policy

| File | Committed? | Why |
|------|-----------|-----|
| `lib/firebase_options.dart` | Yes | Public config; needed for CI builds. Protected by App Check (`FIRE-10`) and Firestore rules (`FIRE-06`), not by obscurity. |
| `android/app/google-services.json` | No | Regenerated deterministically by `flutterfire configure` when mobile Firebase-native config is needed. The POC debug APK CI build does not require it. |
| `ios/Runner/GoogleService-Info.plist` | No | Same reason. |

### Regenerate native client config (Android / iOS)

Only needed when you want to build for mobile:

```sh
firebase login
flutterfire configure --project=picklist-by
```

This (re-)writes `lib/firebase_options.dart` and drops the two native
config files into `android/app/` and `ios/Runner/`. Don't stage the
native files — `.gitignore` already excludes them. If `firebase_options.dart`
regenerates with a meaningful diff on your machine, commit it — that's
the expected update path when apps are added/removed.

### Remaining wiring (tracked as issues)

1. In `lib/bootstrap.dart`, replace the no-op `bootstrap` with a real
   `Firebase.initializeApp` call and add provider overrides for
   `FirebaseAuthRepository`, `FirestorePickingListRepository`, and
   `FirestoreUserDirectoryRepository` (`FIRE-03`, `FIRE-04`, `FIRE-05`).

2. Deploy the rules and indexes (`FIRE-06`):

   ```sh
   cd firebase
   firebase use picklist-by
   firebase deploy --only firestore:rules,firestore:indexes
   ```

3. Provision the first manager account (`FIRE-08`): create them in the
   Firebase Auth console, then create their `users/<uid>` document in
   Firestore with `role: "manager"`. After that the manager creates
   workers from the Windows app.

## Local Firestore emulator

Useful during development so you don't thrash the real project.

```sh
cd firebase
firebase emulators:start
```

The emulator UI runs at <http://127.0.0.1:4000>. Tell the app to hit
it by setting env vars before `flutter run`:

```sh
export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
export FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
```

The Firebase impls will read these at startup.

## CI

GitHub Actions in `.github/workflows/ci.yml` runs on every push + PR:
`flutter pub get → dart format check → flutter analyze --fatal-infos →
flutter gen-l10n → flutter test --coverage` and uploads the lcov
report as an artifact. CI also builds the Windows desktop app with
`flutter build windows --debug` on a Windows runner and uploads the
debug build output for smoke checks. It builds a debug-signed Android
APK with `flutter build apk --debug` on a Linux runner and uploads
`app-debug.apk` for smoke checks. Production Android keystore signing,
Firebase App Distribution, and release deployment are separate release
work, not part of the CI APK build. No secrets are required for the POC;
once Firebase is wired we'll add a workflow job that runs the rules tests
against the Firestore emulator.
