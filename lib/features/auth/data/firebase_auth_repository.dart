import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:pickllist/features/auth/data/auth_repository.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';

/// Maps a [fb.User] together with its `users/{uid}` profile doc into an
/// [AppUser]. Returning `null` lets callers distinguish "signed out" from
/// "signed in but missing profile" — the latter throws
/// [AuthException] from [FirebaseAuthRepository.signIn] but yields
/// `null` from the auth-state stream so the UI shows the login screen.
typedef AppUserBuilder =
    Future<AppUser?> Function(
      fb.User user,
      DocumentSnapshot<Map<String, dynamic>> profile,
    );

/// Firebase-backed [AuthRepository]. Maps `firebase_auth` users into
/// [AppUser] by reading the `users/{uid}` Firestore document for the
/// role and display name.
class FirebaseAuthRepository implements AuthRepository {
  /// Wires the repository to the live Firebase services.
  FirebaseAuthRepository({
    required fb.FirebaseAuth auth,
    required FirebaseFirestore firestore,
    AppUserBuilder? builder,
  }) : _auth = auth,
       _firestore = firestore,
       _builder = builder ?? _defaultBuilder;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AppUserBuilder _builder;

  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _currentUser = null;
        return null;
      }
      final profile = await _profileDoc(user.uid).get();
      final mapped = await _builder(user, profile);
      _currentUser = mapped;
      return mapped;
    });
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const AuthException('unknown-error');
      }
      final profile = await _profileDoc(user.uid).get();
      final mapped = await _builder(user, profile);
      if (mapped == null) {
        throw const AuthException('missing-profile');
      }
      _currentUser = mapped;
      return mapped;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapCode(e.code));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
  }

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  static String _mapCode(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'invalid-email':
      case 'user-not-found':
      case 'wrong-password':
        return 'invalid-credentials';
      case 'user-disabled':
        return 'user-disabled';
      case 'too-many-requests':
        return 'too-many-requests';
      case 'network-request-failed':
        return 'network-error';
      default:
        return 'unknown-error';
    }
  }

  static Future<AppUser?> _defaultBuilder(
    fb.User user,
    DocumentSnapshot<Map<String, dynamic>> profile,
  ) async {
    final data = profile.data();
    if (!profile.exists || data == null) return null;
    final roleName = data['role'] as String? ?? UserRole.worker.name;
    final displayName =
        (data['displayName'] as String?) ??
        user.displayName ??
        user.email ??
        user.uid;
    final email = (data['email'] as String?) ?? user.email ?? '';
    return AppUser(
      id: user.uid,
      email: email,
      displayName: displayName,
      role: UserRole.fromName(roleName),
    );
  }
}
