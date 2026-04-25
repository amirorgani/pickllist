import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/bootstrap.dart';

void main() {
  group('hasRealFirebaseConfig', () {
    test('returns true for fully populated options', () {
      const options = FirebaseOptions(
        apiKey: 'AIzaSyDVqVZhA4j6DpdNyZ2TQYDN-8axPeF3JzU',
        appId: '1:36769619694:android:55638dde3b88e75f611dff',
        messagingSenderId: '36769619694',
        projectId: 'picklist-by',
      );
      expect(hasRealFirebaseConfig(options), isTrue);
    });

    test('returns false when apiKey is a YOUR-* placeholder', () {
      const options = FirebaseOptions(
        apiKey: 'YOUR-API-KEY',
        appId: '1:0:android:abc',
        messagingSenderId: '0',
        projectId: 'demo',
      );
      expect(hasRealFirebaseConfig(options), isFalse);
    });

    test('returns false when appId is empty', () {
      const options = FirebaseOptions(
        apiKey: 'AIzaSomething',
        appId: '',
        messagingSenderId: '0',
        projectId: 'demo',
      );
      expect(hasRealFirebaseConfig(options), isFalse);
    });

    test('returns false when projectId looks like a placeholder', () {
      const options = FirebaseOptions(
        apiKey: 'AIzaSomething',
        appId: '1:0:android:abc',
        messagingSenderId: '0',
        projectId: 'PLACEHOLDER',
      );
      expect(hasRealFirebaseConfig(options), isFalse);
    });
  });
}
