import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pickllist/features/auth/data/auth_repository.dart';
import 'package:pickllist/features/auth/data/firebase_auth_repository.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockUser mockUser;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    mockUser = MockUser(
      uid: 'u_manager',
      email: 'manager@farm.test',
      displayName: 'Firebase Maya',
    );
  });

  Future<void> seedUserDoc({
    String uid = 'u_manager',
    String email = 'manager@farm.test',
    String displayName = 'Maya Manager',
    String role = 'manager',
  }) {
    return firestore.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'role': role,
    });
  }

  test(
    'signIn returns Firestore-backed AppUser and updates currentUser',
    () async {
      await seedUserDoc();
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final repo = FirebaseAuthRepository(auth: auth, firestore: firestore);

      final user = await repo.signIn(
        email: 'manager@farm.test',
        password: 'password123',
      );

      expect(
        user,
        const AppUser(
          id: 'u_manager',
          email: 'manager@farm.test',
          displayName: 'Maya Manager',
          role: UserRole.manager,
        ),
      );
      expect(repo.currentUser, user);
    },
  );

  test(
    'authStateChanges maps Firebase user to AppUser via Firestore',
    () async {
      await seedUserDoc(displayName: 'Manager From Firestore');
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final repo = FirebaseAuthRepository(auth: auth, firestore: firestore);

      final events = <AppUser?>[];
      final sub = repo.authStateChanges().listen(events.add);
      await Future<void>.delayed(Duration.zero);

      await auth.signInWithEmailAndPassword(
        email: 'manager@farm.test',
        password: 'password123',
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        events.last,
        const AppUser(
          id: 'u_manager',
          email: 'manager@farm.test',
          displayName: 'Manager From Firestore',
          role: UserRole.manager,
        ),
      );
      await sub.cancel();
    },
  );

  test('signIn maps FirebaseAuthException codes to AuthException', () async {
    final auth = _MockFirebaseAuth();
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(FirebaseAuthException(code: 'wrong-password'));
    final repo = FirebaseAuthRepository(auth: auth, firestore: firestore);

    await expectLater(
      () => repo.signIn(email: 'manager@farm.test', password: 'bad'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'wrong-password',
        ),
      ),
    );
  });

  test('signIn throws when the Firestore profile is missing', () async {
    final auth = MockFirebaseAuth(mockUser: mockUser);
    final repo = FirebaseAuthRepository(auth: auth, firestore: firestore);

    await expectLater(
      () => repo.signIn(email: 'manager@farm.test', password: 'password123'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'missing-user-profile',
        ),
      ),
    );
    expect(repo.currentUser, isNull);
  });

  test('signOut clears currentUser', () async {
    await seedUserDoc();
    final auth = MockFirebaseAuth(mockUser: mockUser);
    final repo = FirebaseAuthRepository(auth: auth, firestore: firestore);

    await repo.signIn(email: 'manager@farm.test', password: 'password123');
    expect(repo.currentUser, isNotNull);

    await repo.signOut();

    expect(repo.currentUser, isNull);
  });
}
