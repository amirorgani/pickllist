# Dependencies

This file records why each dependency exists. Any change to
`pubspec.yaml` under `dependencies:` or `dev_dependencies:` must update
this file in the same PR.

## Runtime

| Dependency | Why it exists |
|------------|---------------|
| `flutter` | Core Flutter SDK for the app UI and platform integration. |
| `flutter_localizations` | Built-in localization delegates for the shipped locales. |
| `flutter_riverpod` | App-wide state management and dependency injection. |
| `riverpod_annotation` | Annotations used when adopting generated Riverpod providers. |
| `go_router` | Declarative routing and auth redirects. |
| `intl` | Date, number, and localization formatting. |
| `freezed_annotation` | Immutable model annotations for future/generated data classes. |
| `json_annotation` | JSON serialization annotations for model mapping. |
| `meta` | Pure-Dart annotations such as `@immutable` for domain models. |
| `collection` | Small collection helpers allowed in pure Dart layers. |
| `cupertino_icons` | iOS-style icon set bundled with Flutter apps. |
| `firebase_core` | Firebase app bootstrap once the real backend is enabled. |
| `firebase_auth` | Email/password authentication against Firebase Auth. |
| `cloud_firestore` | Real-time picking-list, user, and crop data storage. |
| `firebase_messaging` | Push notifications for assignment updates. |
| `logging` | Structured application logging instead of `print()`. |

## Development

| Dependency | Why it exists |
|------------|---------------|
| `flutter_test` | Unit and widget test framework. |
| `integration_test` | Flutter integration test harness. |
| `very_good_analysis` | Strict Dart and Flutter lint baseline for analyzer guardrails. |
| `build_runner` | Code generation runner for Dart builders. |
| `freezed` | Generates immutable classes and helpers from annotations. |
| `json_serializable` | Generates JSON serializers from annotations. |
| `riverpod_generator` | Generates Riverpod provider boilerplate from annotations. |
| `custom_lint` | Runs custom lint plugins in the repo. |
| `riverpod_lint` | Riverpod-specific lint rules. |
| `mocktail` | Lightweight mocking/stubbing in tests. |
| `fake_cloud_firestore` | Firestore-backed tests without a live backend. |
| `firebase_auth_mocks` | Firebase Auth test doubles for repository tests. |
