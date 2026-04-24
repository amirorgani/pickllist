# Release Process

This document describes how to cut a Pickllist release, how versions are
named, and how to roll back if a release causes trouble in the field.

## Current status

As of the current POC, releases are not fully automated yet. The release
flow below is the target process once these roadmap issues land:

- `OPS-01` Android signing + APK distribution
- `OPS-02` iOS signing + TestFlight
- `OPS-03` Windows installer
- `OPS-04` Crashlytics integration

Until then, treat this document as the runbook we are building toward.

## Version scheme

Pickllist uses Flutter's `version` field from `pubspec.yaml`:

```yaml
version: MAJOR.MINOR.PATCH+BUILD
```

Use it like this:

- `MAJOR`: incompatible workflow or data-shape changes that require
  coordinated rollout.
- `MINOR`: new features or meaningful user-facing improvements that stay
  backward compatible.
- `PATCH`: fixes, polish, documentation, or low-risk guardrail changes.
- `BUILD`: monotonically increasing build number for store/test
  submissions.

Examples:

- `0.3.0+12` for a new manager feature set.
- `0.3.1+13` for a bug-fix follow-up.

Git tags should match the semantic portion: `v0.3.1`.

## Release checklist

Before creating a release:

1. Make sure the target changes are already merged to `main`.
2. Confirm GitHub Actions is green on the exact commit being released.
3. Run the standard local checks if the release commit was prepared
   locally:
   - `flutter analyze --fatal-infos`
   - `flutter test`
4. Update `pubspec.yaml` with the new `version`.
5. Review the user-facing changes and write release notes:
   - what changed
   - who is affected
   - known caveats
   - rollback trigger, if any
6. Verify platform prerequisites are in place:
   - Android keystore and GitHub secrets
   - Apple signing/TestFlight access
   - Windows packaging/signing assets, if shipping desktop
7. Tag the release commit with `vMAJOR.MINOR.PATCH`.

## Cut a release

### 1. Prepare the release commit

1. Branch from `main`.
2. Update `pubspec.yaml` to the target version.
3. Update any release notes or changelog text for the release.
4. Run checks locally.
5. Open and merge a PR with the version bump if it was not done directly
   on the release commit.

### 2. Tag the release

From the merged release commit:

```sh
git checkout main
git pull --ff-only
git tag v0.3.1
git push origin v0.3.1
```

Tagged releases should trigger the packaging/distribution workflows once
`OPS-01` through `OPS-03` are complete.

### 3. Publish platform builds

Android:

- Build the signed APK or app bundle in CI.
- Upload the build to Firebase App Distribution.
- Add tester notes for workers and managers if behavior changed.

iOS:

- Build and upload through the iOS/TestFlight pipeline.
- Verify the correct tester group receives the build.

Windows:

- Build the MSIX installer in CI.
- Sign it if signing is configured.
- Share the installer or release artifact with the manager.

### 4. Announce the release

Send a short release message to the farm owner / testers covering:

- version number
- platforms included
- key changes
- whether users must update immediately or can roll forward later

## Rollback procedure

Use rollback when a release blocks picking-day work, breaks login/data
access, or introduces a serious workflow regression.

### Application rollback

1. Identify the last known good version and commit/tag.
2. Stop promoting the bad build:
   - remove or expire the Android App Distribution build
   - pause TestFlight rollout / instruct testers not to install
   - stop sharing the Windows installer
3. Rebuild and redistribute the previous good version if needed.
4. Open a `type:bug` issue describing the regression, impact, and
   affected version.

### Configuration or backend rollback

If the failure came from backend config rather than the client build:

1. Revert the offending commit on `main`.
2. Redeploy only the affected backend artifact:
   - Firestore rules/indexes
   - Cloud Functions
   - Firebase configuration
3. Verify sign-in and the core list flows against production.

### Communication during rollback

Always communicate three things:

1. what is broken
2. which version users should be on
3. when to expect the next update

## After-action follow-up

After any release, especially a rollback:

1. Capture what went well and what was painful.
2. Add or update guardrails/tests for the failure mode.
3. Update this document if the real process differed from the written
   process.
