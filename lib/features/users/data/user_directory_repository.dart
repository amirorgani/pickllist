import 'package:pickllist/features/auth/data/fake_auth_repository.dart'
    show FakeAuthRepository;
import 'package:pickllist/features/auth/domain/app_user.dart';

/// Reads the list of users who can be assigned to picking list rows.
/// In the POC this is sourced from [FakeAuthRepository]'s seed.
abstract class UserDirectoryRepository {
  /// Watches every user assignable to picking-list rows.
  Stream<List<AppUser>> watchUsers();

  /// Looks up a single assignable user by id.
  Future<AppUser?> userById(String id);
}
