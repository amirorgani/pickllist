import 'package:pickllist/features/auth/domain/app_user.dart';

/// Abstraction over the identity provider. The POC uses an in-memory
/// [FakeAuthRepository]; production will swap in a Firebase-backed
/// implementation. See `docs/architecture.md`.
abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;

  Future<AppUser> signIn({required String email, required String password});
  Future<void> signOut();
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}
