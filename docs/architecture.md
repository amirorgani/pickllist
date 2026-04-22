# Architecture

## Layers

Each feature is split into four layers; there are no shortcuts between
them. The layer you're in determines what you can import.

```
presentation  ──watches──>  application  ──reads──>  data  ──returns──>  domain
```

- **`domain/`** — pure Dart: models, enums, value objects. No Flutter,
  no Firebase, no Riverpod. Fully unit-testable.
- **`data/`** — repository interfaces + implementations. Each
  repository has an abstract class so we can have a `Fake*` impl
  (used in the POC and in tests) and a Firebase-backed one
  (used in production). No UI code.
- **`application/`** — Riverpod providers. This is where dependency
  injection lives; providers expose repositories and derived streams
  to the UI. No widgets.
- **`presentation/`** — Flutter widgets. `ConsumerWidget` /
  `ConsumerStatefulWidget` reads providers with `ref.watch`. Never
  instantiates a repository directly.

## Riverpod usage

- Use `Provider` for singletons (repositories), `StreamProvider` for
  reactive data, `StateProvider` only for trivial mutable UI state
  (e.g. the current locale).
- `ref.watch` subscribes a widget / provider to a dependency. `ref.read`
  is a one-shot lookup.

### Gotcha: `ref.read` on derived providers returns stale values

If nothing is `ref.watch`ing a derived provider, Riverpod does not
recompute it when its upstream changes. A subsequent `ref.read` will
return the cached initial value. This bit the router's `redirect`
callback during initial development: it read `currentUserProvider`
(derived from `authStateProvider`), saw `null` forever, and never
redirected away from `/login` after sign-in.

**Fix:** inside callbacks that use `ref.read`, prefer to read the
*source* provider that is already being watched elsewhere. In our case,
the router's `ref.listen(authStateProvider, ...)` keeps
`authStateProvider` hot, so the redirect reads it directly:

```dart
final user = ref.read(authStateProvider).valueOrNull;
```

## Swapping fake → Firebase

Every repository provider is overridable. When the Firebase project is
live:

```dart
// lib/bootstrap.dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
runApp(ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(FirebaseAuthRepository(...)),
    pickingListRepositoryProvider.overrideWithValue(FirestorePickingListRepository(...)),
    userDirectoryRepositoryProvider.overrideWithValue(FirestoreUserDirectoryRepository(...)),
  ],
  child: const PickllistApp(),
));
```

## Routing

`go_router` with a redirect-based auth guard. The router is built
inside a Riverpod `Provider` so it can listen to auth state and refresh
itself.

Routes:
- `/login` — public
- `/` — lists index (signed-in only)
- `/lists/:listId` — list detail (signed-in only)

Manager-only Windows routes (`/crops`, `/users`, `/templates`,
`/history`, `/import`) will be added behind a
`PlatformInfo.managerFeaturesAvailable` guard.

## Localization

Shipped locales: `en`, `he`, `th`. ARB files in `lib/l10n/` are the
source of truth; `flutter gen-l10n` emits typed accessors into
`lib/l10n/generated/app_localizations*.dart`. The generated files are
checked in so CI builds don't need a codegen step beyond `gen-l10n`.

Hebrew is RTL; Flutter handles direction automatically from the locale,
but widgets that use explicit alignment must prefer directional
equivalents (`AlignmentDirectional.centerStart`, `EdgeInsetsDirectional`).

## Logging

`core/logging/logger.dart` wraps `package:logging` and pipes records to
`dart:developer.log`. Call `configureLogging()` once at startup (already
done in `bootstrap.dart`). Use `appLogger('AuthRepository')` to get a
named logger — never `print`.

## Tests

- Domain and data layers: plain `flutter test`, no widget tree.
- Providers: exercise through repos; or `ProviderContainer` directly.
- Widgets: `testWidgets` with a `ProviderScope` at the root, optionally
  with `overrides` to inject fakes.
- Firestore security rules (future): `firebase emulators:exec` running
  the Firestore emulator against a Node-based rule test harness.

Target coverage: ≥80% on `domain/` and `data/` of every feature.
Presentation can be lower but every screen needs a boot smoke test.
