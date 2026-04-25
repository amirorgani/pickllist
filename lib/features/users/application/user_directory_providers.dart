// Application layer — GUARD-02 scopes public_member_api_docs to
// core/domain/data only.
// ignore_for_file: public_member_api_docs

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickllist/features/auth/application/auth_providers.dart';
import 'package:pickllist/features/auth/data/fake_auth_repository.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';
import 'package:pickllist/features/users/data/fake_user_directory_repository.dart';
import 'package:pickllist/features/users/data/user_directory_repository.dart';

final userDirectoryRepositoryProvider = Provider<UserDirectoryRepository>((
  ref,
) {
  final auth = ref.watch(authRepositoryProvider);
  if (auth is FakeAuthRepository) {
    return FakeUserDirectoryRepository(auth);
  }
  throw UnimplementedError(
    'Firestore-backed UserDirectoryRepository not wired yet. '
    'See docs/architecture.md.',
  );
});

final userDirectoryProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userDirectoryRepositoryProvider).watchUsers();
});
