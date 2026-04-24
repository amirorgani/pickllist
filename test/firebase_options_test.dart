import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions', () {
    test('android, ios, and windows all point at picklist-by', () {
      expect(DefaultFirebaseOptions.android.projectId, 'picklist-by');
      expect(DefaultFirebaseOptions.ios.projectId, 'picklist-by');
      expect(DefaultFirebaseOptions.windows.projectId, 'picklist-by');
    });

    test('each platform has non-empty apiKey and appId', () {
      for (final options in [
        DefaultFirebaseOptions.android,
        DefaultFirebaseOptions.ios,
        DefaultFirebaseOptions.windows,
      ]) {
        expect(options.apiKey, isNotEmpty);
        expect(options.appId, isNotEmpty);
        expect(options.messagingSenderId, isNotEmpty);
      }
    });

    test('ios options carry the bundle id + client id needed for sign-in', () {
      expect(
        DefaultFirebaseOptions.ios.iosBundleId,
        'com.pickllist.pickllist',
      );
      expect(DefaultFirebaseOptions.ios.iosClientId, isNotEmpty);
    });
  });
}
