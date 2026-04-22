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

**Do this when you're ready to leave the POC behind.**

1. Create the project at <https://console.firebase.google.com>. Turn on
   Authentication (Email/Password provider) and Firestore (start in
   production mode).

2. From the repo root:

   ```sh
   firebase login
   flutterfire configure --project=<your-project-id>
   ```

   This writes `lib/firebase_options.dart` (gitignored).

3. In `lib/bootstrap.dart`, replace the no-op `bootstrap` with a real
   `Firebase.initializeApp` call and add provider overrides for
   `FirebaseAuthRepository`, `FirestorePickingListRepository`, and
   `FirestoreUserDirectoryRepository` (not yet implemented — see the
   issue list).

4. Deploy the rules and indexes:

   ```sh
   cd firebase
   firebase use <your-project-id>
   firebase deploy --only firestore:rules,firestore:indexes
   ```

5. Provision the first manager account manually in the Firebase Auth
   console, then create their `users/<uid>` document in Firestore with
   `role: "manager"`. After that the manager creates workers from the
   Windows app.

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
report as an artifact. No secrets are required for the POC; once
Firebase is wired we'll add a workflow job that runs the rules tests
against the Firestore emulator.
