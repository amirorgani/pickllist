import 'package:pickllist/features/auth/data/fake_auth_repository.dart'
    show FakeAuthRepository;
import 'package:pickllist/features/auth/domain/app_user.dart';

/// Abstraction over the identity provider. The POC uses an in-memory
/// [FakeAuthRepository]; production will swap in a Firebase-backed
/// implementation. See `docs/architecture.md`.
abstract class AuthRepository {
  /// Emits the current auth user and every subsequent auth change.
  Stream<AppUser?> authStateChanges();

  /// Synchronous snapshot of the currently signed-in user, if any.
  AppUser? get currentUser;

  /// Signs in a user with email/password credentials.
  Future<AppUser> signIn({required String email, required String password});

  /// Signs out the current user.
  Future<void> signOut();
}

/// Authentication failure with a stable machine-readable [message].
class AuthException implements Exception {
  /// Creates an authentication failure.
  const AuthException(this.message);

  /// Stable error code/message for UI mapping.
  final String message;
  @override
  String toString() => 'AuthException: $message';
}
