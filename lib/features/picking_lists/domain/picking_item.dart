import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';

/// A single row in a picking list: one crop, how much to pick, and
/// (eventually) how much was actually picked.
///
/// `difference` is derived from [pickedQuantity] and [quantity] and is
/// positive when picked more than planned, negative when less.
class PickingItem {
  /// Creates a picking row.
  const PickingItem({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.quantity,
    required this.unit,
    this.note,
    this.assignedTo,
    this.pickedQuantity,
    this.pickedAt,
    this.completedBy,
  });

  /// Creates a picking row from repository storage.
  factory PickingItem.fromMap(Map<String, dynamic> map) => PickingItem(
    id: map['id'] as String,
    cropId: map['cropId'] as String,
    cropName: map['cropName'] as String,
    quantity: (map['quantity'] as num).toDouble(),
    unit: QuantityUnit.fromName(map['unit'] as String),
    note: map['note'] as String?,
    assignedTo: map['assignedTo'] as String?,
    pickedQuantity: (map['pickedQuantity'] as num?)?.toDouble(),
    pickedAt: map['pickedAt'] == null
        ? null
        : DateTime.parse(map['pickedAt'] as String),
    completedBy: map['completedBy'] as String?,
  );

  /// Stable row id within its list.
  final String id;

  /// Catalog crop id.
  final String cropId;

  /// Crop name captured for display/history.
  final String cropName;

  /// Planned quantity to pick.
  final double quantity;

  /// Unit for [quantity] and [pickedQuantity].
  final QuantityUnit unit;

  /// Optional manager note for the worker.
  final String? note;

  /// User id currently assigned to this row.
  final String? assignedTo; // user id

  /// Actual quantity picked once completed.
  final double? pickedQuantity;

  /// Completion timestamp.
  final DateTime? pickedAt;

  /// User id that marked the row picked.
  final String? completedBy; // user id who marked it picked

  /// Whether this row has been marked picked.
  bool get isPicked => pickedAt != null;

  /// Whether this row is assigned to a worker.
  bool get isAssigned => assignedTo != null;

  /// Actual minus planned; null until the row is marked picked.
  double? get difference =>
      pickedQuantity == null ? null : pickedQuantity! - quantity;

  /// Returns a copy with selected fields replaced or cleared.
  PickingItem copyWith({
    String? id,
    String? cropId,
    String? cropName,
    double? quantity,
    QuantityUnit? unit,
    String? note,
    String? assignedTo,
    bool clearAssignedTo = false,
    double? pickedQuantity,
    bool clearPickedQuantity = false,
    DateTime? pickedAt,
    bool clearPickedAt = false,
    String? completedBy,
    bool clearCompletedBy = false,
  }) {
    return PickingItem(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      assignedTo: clearAssignedTo ? null : assignedTo ?? this.assignedTo,
      pickedQuantity: clearPickedQuantity
          ? null
          : pickedQuantity ?? this.pickedQuantity,
      pickedAt: clearPickedAt ? null : pickedAt ?? this.pickedAt,
      completedBy: clearCompletedBy ? null : completedBy ?? this.completedBy,
    );
  }

  /// Serializes this row for repository storage.
  Map<String, dynamic> toMap() => {
    'id': id,
    'cropId': cropId,
    'cropName': cropName,
    'quantity': quantity,
    'unit': unit.name,
    'note': note,
    'assignedTo': assignedTo,
    'pickedQuantity': pickedQuantity,
    'pickedAt': pickedAt?.toIso8601String(),
    'completedBy': completedBy,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PickingItem &&
          other.id == id &&
          other.cropId == cropId &&
          other.cropName == cropName &&
          other.quantity == quantity &&
          other.unit == unit &&
          other.note == note &&
          other.assignedTo == assignedTo &&
          other.pickedQuantity == pickedQuantity &&
          other.pickedAt == pickedAt &&
          other.completedBy == completedBy);

  @override
  int get hashCode => Object.hash(
    id,
    cropId,
    cropName,
    quantity,
    unit,
    note,
    assignedTo,
    pickedQuantity,
    pickedAt,
    completedBy,
  );
}
