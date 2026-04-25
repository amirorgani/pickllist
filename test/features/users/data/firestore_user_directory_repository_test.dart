import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';
import 'package:pickllist/features/users/data/firestore_user_directory_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreUserDirectoryRepository repo;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreUserDirectoryRepository(firestore);
    await firestore.collection('users').doc('u_zoe').set({
      'email': 'zoe@farm.test',
      'displayName': 'Zoe Worker',
      'role': 'worker',
    });
    await firestore.collection('users').doc('u_anna').set({
      'email': 'anna@farm.test',
      'displayName': 'Anna Manager',
      'role': 'manager',
    });
    await firestore.collection('users').doc('u_milo').set({
      'email': 'milo@farm.test',
      'displayName': 'Milo Worker',
      'role': 'worker',
    });
  });

  test('watchUsers streams users sorted by displayName', () async {
    final users = await repo.watchUsers().first;
    expect(users.map((u) => u.displayName), [
      'Anna Manager',
      'Milo Worker',
      'Zoe Worker',
    ]);
    expect(users.first.role, UserRole.manager);
  });

  test('watchUsers emits a new event when a user is added', () async {
    final stream = repo.watchUsers();
    final emissions = <List<AppUser>>[];
    final sub = stream.listen(emissions.add);
    await Future<void>.delayed(Duration.zero);

    await firestore.collection('users').doc('u_bob').set({
      'email': 'bob@farm.test',
      'displayName': 'Bob Worker',
      'role': 'worker',
    });
    await Future<void>.delayed(Duration.zero);

    expect(emissions.last.map((u) => u.displayName), [
      'Anna Manager',
      'Bob Worker',
      'Milo Worker',
      'Zoe Worker',
    ]);
    await sub.cancel();
  });

  test('userById returns the matching AppUser', () async {
    final user = await repo.userById('u_anna');
    expect(user, isNotNull);
    expect(user!.email, 'anna@farm.test');
    expect(user.role, UserRole.manager);
  });

  test('userById returns null for unknown ids', () async {
    expect(await repo.userById('u_missing'), isNull);
  });

  test('falls back to worker for unknown role strings', () async {
    await firestore.collection('users').doc('u_weird').set({
      'email': 'weird@farm.test',
      'displayName': 'Weird User',
      'role': 'astronaut',
    });
    final user = await repo.userById('u_weird');
    expect(user!.role, UserRole.worker);
  });

  test('uses empty strings for missing email and displayName fields', () async {
    await firestore.collection('users').doc('u_partial').set({
      'role': 'worker',
    });
    final user = await repo.userById('u_partial');
    expect(user!.email, '');
    expect(user.displayName, '');
  });
}
