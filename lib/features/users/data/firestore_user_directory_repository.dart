import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';
import 'package:pickllist/features/users/data/user_directory_repository.dart';

/// Firestore-backed user directory. Streams `users/` ordered by
/// `displayName` so the assignee picker is alphabetised without
/// client-side sort cost.
class FirestoreUserDirectoryRepository implements UserDirectoryRepository {
  /// Wires the repository to a Firestore instance.
  FirestoreUserDirectoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<List<AppUser>> watchUsers() {
    return _users
        .orderBy('displayName')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => _toAppUser(d.id, d.data()))
              .toList(growable: false),
        );
  }

  @override
  Future<AppUser?> userById(String id) async {
    final doc = await _users.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return _toAppUser(doc.id, data);
  }

  static AppUser _toAppUser(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      role: UserRole.fromName(
        (data['role'] as String?) ?? UserRole.worker.name,
      ),
    );
  }
}
