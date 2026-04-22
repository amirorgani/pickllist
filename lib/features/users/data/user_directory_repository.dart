import 'package:pickllist/features/auth/domain/app_user.dart';

/// Reads the list of users who can be assigned to picking list rows.
/// In the POC this is sourced from [FakeAuthRepository]'s seed.
abstract class UserDirectoryRepository {
  Stream<List<AppUser>> watchUsers();
  Future<AppUser?> userById(String id);
}
