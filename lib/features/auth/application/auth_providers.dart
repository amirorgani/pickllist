import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickllist/features/auth/data/auth_repository.dart';
import 'package:pickllist/features/auth/data/fake_auth_repository.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';

/// The single auth repository. In the POC this is the fake impl; the
/// Firebase impl will override this provider in `main.dart` once
/// `firebase_options.dart` is generated.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FakeAuthRepository();
});

/// Stream of the current user (null while signed out).
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Synchronous convenience accessor. Returns null until the first auth
/// event arrives. Prefer [authStateProvider] in async UI.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
