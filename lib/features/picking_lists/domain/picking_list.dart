import 'package:meta/meta.dart';

/// Lifecycle state of a manager-created picking list.
enum PickingListStatus {
  /// Still being prepared by the manager.
  draft,

  /// Visible to workers for picking.
  published,

  /// Finished and retained for history.
  completed
  ;

  /// Parses a persisted enum [name], defaulting unknown values to [draft].
  static PickingListStatus fromName(String name) => PickingListStatus.values
      .firstWhere((s) => s.name == name, orElse: () => PickingListStatus.draft);
}

/// A picking list the work manager assembles and publishes to workers.
/// Items live in a subcollection — streamed separately.
@immutable
class PickingList {
  /// Creates a picking list header.
  const PickingList({
    required this.id,
    required this.name,
    required this.scheduledAt,
    required this.status,
    required this.createdBy,
    required this.updatedAt,
  });

  /// Creates a picking list from repository storage.
  factory PickingList.fromMap(Map<String, dynamic> map) => PickingList(
    id: map['id'] as String,
    name: map['name'] as String,
    scheduledAt: DateTime.parse(map['scheduledAt'] as String),
    status: PickingListStatus.fromName(map['status'] as String),
    createdBy: map['createdBy'] as String,
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

  /// Stable list id.
  final String id;

  /// Manager-facing list name.
  final String name;

  /// Date/time the list is scheduled for picking.
  final DateTime scheduledAt;

  /// Publication state.
  final PickingListStatus status;

  /// User id of the manager that created the list.
  final String createdBy;

  /// Last update timestamp used for sorting/history.
  final DateTime updatedAt;

  /// Returns a copy with selected fields replaced.
  PickingList copyWith({
    String? id,
    String? name,
    DateTime? scheduledAt,
    PickingListStatus? status,
    String? createdBy,
    DateTime? updatedAt,
  }) {
    return PickingList(
      id: id ?? this.id,
      name: name ?? this.name,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes this list header for repository storage.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'scheduledAt': scheduledAt.toIso8601String(),
    'status': status.name,
    'createdBy': createdBy,
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PickingList &&
          other.id == id &&
          other.name == name &&
          other.scheduledAt == scheduledAt &&
          other.status == status &&
          other.createdBy == createdBy &&
          other.updatedAt == updatedAt);

  @override
  int get hashCode =>
      Object.hash(id, name, scheduledAt, status, createdBy, updatedAt);
}
