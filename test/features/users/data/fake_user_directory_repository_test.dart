import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/auth/data/fake_auth_repository.dart';
import 'package:pickllist/features/users/data/fake_user_directory_repository.dart';

void main() {
  late FakeUserDirectoryRepository repo;

  setUp(() {
    repo = FakeUserDirectoryRepository(FakeAuthRepository());
  });

  test('watchUsers emits the seeded assignable users', () async {
    final users = await repo.watchUsers().first;

    expect(users.map((u) => u.id), containsAll(['u_manager', 'u_worker']));
  });

  test('userById returns matching users and null for unknown ids', () async {
    final manager = await repo.userById('u_manager');
    final missing = await repo.userById('missing');

    expect(manager?.email, 'manager@farm.test');
    expect(missing, isNull);
  });
}
