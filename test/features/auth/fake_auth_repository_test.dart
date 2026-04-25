import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/auth/data/auth_repository.dart';
import 'package:pickllist/features/auth/data/fake_auth_repository.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';

void main() {
  late FakeAuthRepository repo;

  setUp(() => repo = FakeAuthRepository());

  test('starts signed out', () {
    expect(repo.currentUser, isNull);
  });

  test('signIn with correct credentials returns the user and emits', () async {
    final events = <AppUser?>[];
    final sub = repo.authStateChanges().listen(events.add);
    await Future<void>.delayed(Duration.zero);

    final user = await repo.signIn(
      email: 'manager@farm.test',
      password: 'password123',
    );
    await Future<void>.delayed(Duration.zero);

    expect(user.role, UserRole.manager);
    expect(repo.currentUser, user);
    expect(events.last, user);
    await sub.cancel();
  });

  test('signIn with bad password throws AuthException', () {
    expect(
      () => repo.signIn(email: 'manager@farm.test', password: 'nope'),
      throwsA(isA<AuthException>()),
    );
  });

  test('AuthException string includes the stable message', () {
    expect(
      const AuthException('invalid-credentials').toString(),
      'AuthException: invalid-credentials',
    );
  });

  test('signIn is case-insensitive on email', () async {
    final user = await repo.signIn(
      email: 'MANAGER@FARM.TEST',
      password: 'password123',
    );
    expect(user.email, 'manager@farm.test');
  });

  test('signOut clears the current user and emits null', () async {
    await repo.signIn(email: 'worker@farm.test', password: 'password123');
    expect(repo.currentUser, isNotNull);
    await repo.signOut();
    expect(repo.currentUser, isNull);
  });
}
