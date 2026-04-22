enum PickingListStatus {
  draft,
  published,
  completed;

  static PickingListStatus fromName(String name) => PickingListStatus.values
      .firstWhere((s) => s.name == name, orElse: () => PickingListStatus.draft);
}

/// A picking list the work manager assembles and publishes to workers.
/// Items live in a subcollection — streamed separately.
class PickingList {
  const PickingList({
    required this.id,
    required this.name,
    required this.scheduledAt,
    required this.status,
    required this.createdBy,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DateTime scheduledAt;
  final PickingListStatus status;
  final String createdBy;
  final DateTime updatedAt;

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

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'scheduledAt': scheduledAt.toIso8601String(),
    'status': status.name,
    'createdBy': createdBy,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PickingList.fromMap(Map<String, dynamic> map) => PickingList(
    id: map['id'] as String,
    name: map['name'] as String,
    scheduledAt: DateTime.parse(map['scheduledAt'] as String),
    status: PickingListStatus.fromName(map['status'] as String),
    createdBy: map['createdBy'] as String,
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

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
