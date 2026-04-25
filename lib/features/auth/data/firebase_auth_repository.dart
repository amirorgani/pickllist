import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:pickllist/core/logging/logger.dart';
import 'package:pickllist/features/auth/data/auth_repository.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';

/// Firebase-backed implementation of [AuthRepository].
class FirebaseAuthRepository implements AuthRepository {
  /// Creates a Firebase-backed auth repository.
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Logger _logger = appLogger('FirebaseAuthRepository');

  AppUser? _currentUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        return null;
      }

      final appUser = await _loadAppUser(firebaseUser);
      if (appUser == null) {
        _currentUser = null;
        unawaited(_auth.signOut());
        return null;
      }

      _currentUser = appUser;
      return appUser;
    });
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException('user-not-found');
      }

      final appUser = await _loadAppUser(firebaseUser);
      if (appUser == null) {
        await _auth.signOut();
        throw const AuthException('missing-user-profile');
      }

      _currentUser = appUser;
      return appUser;
    } on FirebaseAuthException catch (error) {
      throw AuthException(error.code);
    }
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _auth.signOut();
  }

  Future<AppUser?> _loadAppUser(User firebaseUser) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      _logger.warning(
        'Missing users/${firebaseUser.uid} profile for signed-in Firebase user.',
      );
      return null;
    }

    return AppUser(
      id: snapshot.id,
      email: ((data['email'] as String?) ?? firebaseUser.email ?? '')
          .trim()
          .toLowerCase(),
      displayName:
          (data['displayName'] as String?) ??
          firebaseUser.displayName ??
          firebaseUser.email ??
          snapshot.id,
      role: UserRole.fromName(
        (data['role'] as String?) ?? UserRole.worker.name,
      ),
    );
  }
}
