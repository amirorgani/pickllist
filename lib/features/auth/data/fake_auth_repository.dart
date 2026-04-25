import 'dart:async';

import 'package:pickllist/features/auth/data/auth_repository.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';

/// In-memory auth for the POC and tests. Seeded with a manager and a
/// worker account so the app is usable without a Firebase project.
class FakeAuthRepository implements AuthRepository {
  /// Creates the seeded fake auth repository.
  FakeAuthRepository() : _credentials = _defaultSeed() {
    _controller = StreamController<AppUser?>.broadcast(
      onListen: () => _controller.add(_currentUser),
    );
  }

  final Map<String, _FakeCredential> _credentials; // keyed by lowercased email
  late final StreamController<AppUser?> _controller;
  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    // No simulated latency: tests pump microtasks, not real timers.
    final key = email.trim().toLowerCase();
    final cred = _credentials[key];
    if (cred == null || cred.password != password) {
      throw const AuthException('invalid-credentials');
    }
    _currentUser = cred.user;
    _controller.add(_currentUser);
    return cred.user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  /// Returns all seeded users for fake user-directory lookups.
  List<AppUser> allUsers() =>
      _credentials.values.map((c) => c.user).toList(growable: false);

  static Map<String, _FakeCredential> _defaultSeed() => {
    'manager@farm.test': const _FakeCredential(
      password: 'password123',
      user: AppUser(
        id: 'u_manager',
        email: 'manager@farm.test',
        displayName: 'Maya Manager',
        role: UserRole.manager,
      ),
    ),
    'worker@farm.test': const _FakeCredential(
      password: 'password123',
      user: AppUser(
        id: 'u_worker',
        email: 'worker@farm.test',
        displayName: 'Wendy Worker',
        role: UserRole.worker,
      ),
    ),
    'worker2@farm.test': const _FakeCredential(
      password: 'password123',
      user: AppUser(
        id: 'u_worker2',
        email: 'worker2@farm.test',
        displayName: 'Wattana Worker',
        role: UserRole.worker,
      ),
    ),
  };
}

class _FakeCredential {
  const _FakeCredential({required this.password, required this.user});
  final String password;
  final AppUser user;
}
