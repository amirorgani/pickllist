# Pickllist Firebase Functions

TypeScript workspace for Firebase Cloud Functions. The first exported
function is a lightweight `health` endpoint so CI can build and smoke-test the
workspace before product functions are added.

## Commands

Run from `firebase/functions/`:

```sh
npm ci
npm run build
npm test
npm run smoke
```

Run the local Firebase emulators from this directory:

```sh
npm run emulators
```

This requires the Firebase CLI (`npm install -g firebase-tools`) and starts
Firestore, Auth, and Functions using `firebase/firebase.json`. Use
`npm run emulators:exec` to run the test suite with those emulators available.

## Deployment note

Local emulators do not require billing, but deploying Cloud Functions to the
real `picklist-by` project requires the Firebase project to be on the Blaze
plan.
