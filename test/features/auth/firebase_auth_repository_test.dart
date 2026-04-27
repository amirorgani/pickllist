import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:pickllist/features/auth/data/auth_repository.dart';
import 'package:pickllist/features/auth/data/firebase_auth_repository.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';

void main() {
  group('FirebaseAuthRepository.signIn', () {
    test('returns AppUser populated from users/{uid} doc', () async {
      final user = MockUser(
        uid: 'u_manager',
        email: 'manager@farm.test',
        displayName: 'Maya Mock',
      );
      final auth = MockFirebaseAuth(mockUser: user);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u_manager').set({
        'email': 'manager@farm.test',
        'displayName': 'Maya Manager',
        'role': 'manager',
      });

      final repo = FirebaseAuthRepository(auth: auth, firestore: firestore);
      final result = await repo.signIn(
        email: 'manager@farm.test',
        password: 'password123',
      );

      expect(result.id, 'u_manager');
      expect(result.role, UserRole.manager);
      expect(result.displayName, 'Maya Manager');
      expect(repo.currentUser, result);
    });

    test('falls back to worker role when profile role is unknown', () async {
      final user = MockUser(uid: 'u_x', email: 'x@farm.test');
      final auth = MockFirebaseAuth(mockUser: user);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u_x').set({
        'email': 'x@farm.test',
        'displayName': 'X',
        'role': 'unknown_role',
      });

      final repo = FirebaseAuthRepository(auth: auth, firestore: firestore);
      final result = await repo.signIn(email: 'x@farm.test', password: 'pw');

      expect(result.role, UserRole.worker);
    });

    test('throws missing-profile when users/{uid} doc is absent', () async {
      final user = MockUser(uid: 'u_orphan', email: 'orphan@farm.test');
      final auth = MockFirebaseAuth(mockUser: user);
      final firestore = FakeFirebaseFirestore();

      final repo = FirebaseAuthRepository(auth: auth, firestore: firestore);

      expect(
        () => repo.signIn(email: 'orphan@farm.test', password: 'pw'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'missing-profile',
          ),
        ),
      );
    });

    test('maps invalid-credential FirebaseAuthException', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(fb.FirebaseAuthException(code: 'invalid-credential'));
      final firestore = FakeFirebaseFirestore();
      final repo = FirebaseAuthRepository(auth: auth, firestore: firestore);

      expect(
        () => repo.signIn(email: 'bad@farm.test', password: 'wrong'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'invalid-credentials',
          ),
        ),
      );
    });

    test('maps user-disabled FirebaseAuthException', () async {
      final auth = MockFirebaseAuth();
      whenCalling(
        Invocation.method(#signInWithEmailAndPassword, null),
      ).on(auth).thenThrow(fb.FirebaseAuthException(code: 'user-disabled'));
      final repo = FirebaseAuthRepository(
        auth: auth,
        firestore: FakeFirebaseFirestore(),
      );

      expect(
        () => repo.signIn(email: 'd@farm.test', password: 'pw'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'user-disabled',
          ),
        ),
      );
    });

    test('maps too-many-requests FirebaseAuthException', () async {
      final auth = MockFirebaseAuth();
      whenCalling(
        Invocation.method(#signInWithEmailAndPassword, null),
      ).on(auth).thenThrow(fb.FirebaseAuthException(code: 'too-many-requests'));
      final repo = FirebaseAuthRepository(
        auth: auth,
        firestore: FakeFirebaseFirestore(),
      );

      expect(
        () => repo.signIn(email: 'd@farm.test', password: 'pw'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'too-many-requests',
          ),
        ),
      );
    });

    test('maps network-request-failed FirebaseAuthException', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(fb.FirebaseAuthException(code: 'network-request-failed'));
      final repo = FirebaseAuthRepository(
        auth: auth,
        firestore: FakeFirebaseFirestore(),
      );

      expect(
        () => repo.signIn(email: 'd@farm.test', password: 'pw'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'network-error',
          ),
        ),
      );
    });

    test('maps unrecognized codes to unknown-error', () async {
      final auth = MockFirebaseAuth();
      whenCalling(
        Invocation.method(#signInWithEmailAndPassword, null),
      ).on(auth).thenThrow(fb.FirebaseAuthException(code: 'something-weird'));
      final repo = FirebaseAuthRepository(
        auth: auth,
        firestore: FakeFirebaseFirestore(),
      );

      expect(
        () => repo.signIn(email: 'd@farm.test', password: 'pw'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'unknown-error',
          ),
        ),
      );
    });
  });

  group('FirebaseAuthRepository.authStateChanges', () {
    test('emits AppUser when signed in and null after sign-out', () async {
      final user = MockUser(
        uid: 'u_worker',
        email: 'worker@farm.test',
        displayName: 'W',
      );
      final auth = MockFirebaseAuth(mockUser: user);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u_worker').set({
        'email': 'worker@farm.test',
        'displayName': 'Wendy Worker',
        'role': 'worker',
      });
      final repo = FirebaseAuthRepository(auth: auth, firestore: firestore);

      final stream = repo.authStateChanges();
      final events = <AppUser?>[];
      final sub = stream.listen(events.add);

      await repo.signIn(
        email: 'worker@farm.test',
        password: 'password123',
      );
      await Future<void>.delayed(Duration.zero);
      await repo.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(events.last, isNull);
      expect(repo.currentUser, isNull);
      expect(
        events.whereType<AppUser>().any((u) => u.id == 'u_worker'),
        isTrue,
      );
      await sub.cancel();
    });

    test('emits null when profile doc is missing', () async {
      final user = MockUser(uid: 'u_orphan', email: 'orphan@farm.test');
      final auth = MockFirebaseAuth(mockUser: user, signedIn: true);
      final repo = FirebaseAuthRepository(
        auth: auth,
        firestore: FakeFirebaseFirestore(),
      );

      final first = await repo.authStateChanges().first;
      expect(first, isNull);
    });

    test('emits null when user doc has active=false', () async {
      final user = MockUser(uid: 'u_inactive', email: 'inactive@farm.test');
      final auth = MockFirebaseAuth(mockUser: user, signedIn: true);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u_inactive').set({
        'email': 'inactive@farm.test',
        'displayName': 'Inactive Worker',
        'role': 'worker',
        'active': false,
      });

      final repo = FirebaseAuthRepository(auth: auth, firestore: firestore);
      final first = await repo.authStateChanges().first;
      expect(first, isNull);
    });
  });
}
