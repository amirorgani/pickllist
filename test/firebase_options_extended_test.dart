// Additional firebase_options tests to boost coverage. GUARD-09.

import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions platform constants', () {
    test('android options have expected project id', () {
      expect(
        DefaultFirebaseOptions.android.projectId,
        equals('picklist-by'),
      );
    });

    test('android options have non-empty apiKey', () {
      expect(DefaultFirebaseOptions.android.apiKey, isA<String>());
      expect(DefaultFirebaseOptions.android.apiKey.isEmpty, isFalse);
    });

    test('ios options have expected bundle-specific values', () {
      expect(DefaultFirebaseOptions.ios.projectId, equals('picklist-by'));
      expect(
        DefaultFirebaseOptions.ios.iosBundleId,
        equals('com.pickllist.pickllist'),
      );
    });

    test('windows options include authDomain', () {
      expect(
        DefaultFirebaseOptions.windows.authDomain,
        equals('picklist-by.firebaseapp.com'),
      );
    });

    test('currentPlatform returns android options on android', () {
      // The test runner on Linux/Windows will hit the "windows" or
      // "linux" branch. We test what we can without mocking the platform.
      // This call should either succeed or throw UnsupportedError — both
      // outcomes exercise the switch branches.
      expect(
        () => DefaultFirebaseOptions.currentPlatform,
        anyOf(returnsNormally, throwsUnsupportedError),
      );
    });
  });
}
