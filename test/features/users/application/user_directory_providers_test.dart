import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';
import 'package:pickllist/features/users/application/user_directory_providers.dart';
import 'package:pickllist/features/users/data/fake_user_directory_repository.dart';

void main() {
  group('userDirectoryRepositoryProvider', () {
    test('returns FakeUserDirectoryRepository when auth is fake', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(userDirectoryRepositoryProvider);

      expect(repo, isA<FakeUserDirectoryRepository>());
    });
  });

  group('userDirectoryProvider', () {
    test('emits the seeded users', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final users = await container.read(userDirectoryProvider.future);

      expect(users, isA<List<AppUser>>());
      expect(users.map((u) => u.id), containsAll(['u_manager', 'u_worker']));
    });

    test('emitted users include manager and worker roles', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final users = await container.read(userDirectoryProvider.future);

      final manager = users.byId('u_manager');
      final worker = users.byId('u_worker');
      expect(manager?.isManager, isTrue);
      expect(worker?.isManager, isFalse);
    });
  });
}
