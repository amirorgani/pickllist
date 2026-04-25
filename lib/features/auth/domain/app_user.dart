import 'package:collection/collection.dart';

/// Role granted to a signed-in app user.
enum UserRole {
  /// Can use Windows-only management features and reassign work.
  manager,

  /// Can view assigned picking rows and record picked quantities.
  worker
  ;

  /// Parses a persisted enum [name], defaulting unknown values to [worker].
  static UserRole fromName(String name) => UserRole.values.firstWhere(
    (r) => r.name == name,
    orElse: () => UserRole.worker,
  );
}

/// A user in the farm's directory. Same shape for auth identity and for
/// the "assignable worker" list shown in picking list rows.
class AppUser {
  /// Creates a user directory entry.
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  /// Creates a user from a serialized map.
  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'] as String,
    email: map['email'] as String,
    displayName: map['displayName'] as String,
    role: UserRole.fromName(map['role'] as String),
  );

  /// Stable user id from the auth/user store.
  final String id;

  /// Login email address.
  final String email;

  /// Human-readable name displayed in assignment UIs.
  final String displayName;

  /// Authorization role for feature gating.
  final UserRole role;

  /// Whether this user can access manager-only features.
  bool get isManager => role == UserRole.manager;

  /// Returns a copy with selected fields replaced.
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
    );
  }

  /// Serializes this user for repository storage.
  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'role': role.name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUser &&
          other.id == id &&
          other.email == email &&
          other.displayName == displayName &&
          other.role == role);

  @override
  int get hashCode => Object.hash(id, email, displayName, role);

  @override
  String toString() => 'AppUser(id: $id, email: $email, role: ${role.name})';
}

/// Convenience lookups for user collections.
extension AppUserListX on Iterable<AppUser> {
  /// Finds a user by [id], returning null for null or unknown ids.
  AppUser? byId(String? id) =>
      id == null ? null : firstWhereOrNull((u) => u.id == id);
}
