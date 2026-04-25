import 'dart:async';

import 'package:collection/collection.dart';
import 'package:pickllist/features/auth/data/fake_auth_repository.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';
import 'package:pickllist/features/users/data/user_directory_repository.dart';

/// User directory backed by the fake auth repository seed data.
class FakeUserDirectoryRepository implements UserDirectoryRepository {
  /// Creates a fake user directory from seeded auth data.
  FakeUserDirectoryRepository(this._auth);

  final FakeAuthRepository _auth;

  @override
  Stream<List<AppUser>> watchUsers() async* {
    // Seed data doesn't change during a session, so this is effectively
    // a single-shot stream. Real Firestore version will be live.
    yield _auth.allUsers();
  }

  @override
  Future<AppUser?> userById(String id) async {
    return _auth.allUsers().firstWhereOrNull((u) => u.id == id);
  }
}
