import 'package:collection/collection.dart';

enum UserRole {
  manager,
  worker;

  static UserRole fromName(String name) => UserRole.values.firstWhere(
    (r) => r.name == name,
    orElse: () => UserRole.worker,
  );
}

/// A user in the farm's directory. Same shape for auth identity and for
/// the "assignable worker" list shown in picking list rows.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;

  bool get isManager => role == UserRole.manager;

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

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'role': role.name,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'] as String,
    email: map['email'] as String,
    displayName: map['displayName'] as String,
    role: UserRole.fromName(map['role'] as String),
  );

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

extension AppUserListX on Iterable<AppUser> {
  AppUser? byId(String? id) =>
      id == null ? null : firstWhereOrNull((u) => u.id == id);
}
