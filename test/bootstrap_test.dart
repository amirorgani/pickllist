import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/bootstrap.dart';
import 'package:pickllist/firebase_options.dart';

void main() {
  group('hasConfiguredFirebaseOptions', () {
    test('accepts the committed Android/iOS/Windows Firebase options', () {
      expect(
        hasConfiguredFirebaseOptions(DefaultFirebaseOptions.android),
        isTrue,
      );
      expect(hasConfiguredFirebaseOptions(DefaultFirebaseOptions.ios), isTrue);
      expect(
        hasConfiguredFirebaseOptions(DefaultFirebaseOptions.windows),
        isTrue,
      );
    });

    test('rejects placeholder-like Firebase options', () {
      const placeholder = FirebaseOptions(
        apiKey: 'YOUR_API_KEY',
        appId: 'YOUR_APP_ID',
        messagingSenderId: '1234567890',
        projectId: 'YOUR_PROJECT_ID',
      );

      expect(hasConfiguredFirebaseOptions(placeholder), isFalse);
    });
  });

  group('configuredFirebaseOptionsForPlatform', () {
    test(
      'returns a configured option for the current supported test platform',
      () {
        final options = configuredFirebaseOptionsForPlatform();

        expect(options, isNotNull);
        expect(options?.projectId, 'picklist-by');
      },
    );
  });
}
