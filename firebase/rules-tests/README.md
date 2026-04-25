# Firestore rules tests

Automated tests for `firebase/firestore.rules` using
[`@firebase/rules-unit-testing`](https://firebase.google.com/docs/rules/unit-tests).
The tests stand up a Firestore emulator, seed a small fixture, and assert
which reads and writes are allowed for managers, workers, and unsigned
clients.

## Running locally

```bash
# From firebase/rules-tests/
npm ci
npm run emulators:exec
```

That runs `firebase emulators:exec --only firestore "npm test"`, which
starts the emulator on the port declared in `../firebase.json` and runs
the Node test suite against it.

CI runs the same command in a dedicated job in `.github/workflows/ci.yml`.

## Adding cases

Each `*.test.mjs` file is a Node `node:test` suite. Use
`getFirestore(...)` from a context returned by `testEnv.authenticatedContext`
or `testEnv.unauthenticatedContext` to get a Firestore client whose
requests carry the simulated identity. Wrap rule-passing reads with
`assertSucceeds(...)` and rule-failing ones with `assertFails(...)`.
