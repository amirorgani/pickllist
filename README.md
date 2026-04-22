# Pickllist

Agricultural picking-list manager. Workers use the mobile app
(Android/iOS) to claim rows on a daily picking list and record the
quantities they actually picked; the work manager uses a Windows desktop
app to build the lists, import them from Excel, reuse templates, and
review history.

Single-farm deployment. Real-time sync between all devices.

Built with **Flutter** + **Riverpod** + **Firebase** (Auth + Firestore
+ Cloud Messaging). Tri-lingual: English, Hebrew, Thai.

## Status

**Proof of concept.** Runs today against an in-memory fake backend so
you can demo the UX without a Firebase project. The repository layer is
already abstracted; swapping in Firestore when the Firebase project is
created is a drop-in change — see [`docs/setup.md`](docs/setup.md).

What works:
- Email + password login (seeded: `manager@farm.test` / `worker@farm.test`, password `password123`).
- Picking-lists index screen and row detail.
- Claim / reassign / mark picked with actual quantity and auto-computed diff.
- Real-time updates across screens within one process.
- Localized into he / en / th.

What's next (not in POC):
- Firebase wiring (Auth + Firestore + security rules).
- Push notifications on assignment changes (FCM + Cloud Function).
- Windows-only: Excel import, templates, history view, user admin.

## Quick start

Prerequisites: Flutter 3.41+ (Dart 3.11+).

```sh
flutter pub get
flutter gen-l10n
flutter run               # picks a connected device; Windows, Android emulator, iOS sim
flutter test              # 23 tests
flutter analyze
```

## Repo layout

See [`AGENTS.md`](AGENTS.md) for the full tour — it's the canonical
onboarding doc for humans and coding agents. In short:

```
lib/core/            cross-cutting: routing, theme, platform, logging
lib/features/<f>/    domain / data / application / presentation layers
lib/l10n/            ARB translations (+ generated AppLocalizations)
firebase/            firestore rules, indexes, emulator config
test/                mirrors lib/ layout
docs/                setup, architecture, data model
```

## Docs

- [AGENTS.md](AGENTS.md) — conventions, commands, how to add a feature.
- [docs/architecture.md](docs/architecture.md) — Riverpod layering, repo
  abstraction, known gotchas.
- [docs/data-model.md](docs/data-model.md) — Firestore collections +
  the security-rule rationale.
- [docs/setup.md](docs/setup.md) — wiring a real Firebase project.
