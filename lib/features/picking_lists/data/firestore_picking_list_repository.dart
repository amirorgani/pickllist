import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pickllist/features/picking_lists/data/picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/domain/picking_item.dart';
import 'package:pickllist/features/picking_lists/domain/picking_list.dart';
import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';

/// Firestore-backed picking list store. Mirrors the schema in
/// `docs/data-model.md` (root `pickingLists/{listId}` + `items/`
/// subcollection). Streams use `snapshots()` so the UI stays live, and
/// [claimItem] uses a transaction so two workers tapping "Claim" at the
/// same instant can't both win.
class FirestorePickingListRepository implements PickingListRepository {
  /// Wires the repository to a Firestore instance.
  FirestorePickingListRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _lists =>
      _firestore.collection('pickingLists');

  CollectionReference<Map<String, dynamic>> _items(String listId) =>
      _lists.doc(listId).collection('items');

  @override
  Stream<List<PickingList>> watchLists() {
    return _lists
        .orderBy('scheduledAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => _toList(d.id, d.data()))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<PickingItem>> watchItems(String listId) {
    return _items(listId).snapshots().map(
      (snap) =>
          snap.docs.map((d) => _toItem(d.id, d.data())).toList(growable: false),
    );
  }

  @override
  Future<String> createList({
    required String name,
    required DateTime scheduledAt,
    required String createdBy,
  }) async {
    final ref = await _lists.add({
      'name': name,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': PickingListStatus.draft.name,
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  @override
  Future<String> addItem({
    required String listId,
    required String cropId,
    required String cropName,
    required double quantity,
    required QuantityUnit unit,
    String? note,
    String? assignedTo,
  }) async {
    final ref = await _items(listId).add({
      'cropId': cropId,
      'cropName': cropName,
      'quantity': quantity,
      'unit': unit.name,
      'note': note,
      'assignedTo': assignedTo,
      'pickedQuantity': null,
      'pickedAt': null,
      'completedBy': null,
    });
    await _touchList(listId);
    return ref.id;
  }

  @override
  Future<void> claimItem({
    required String listId,
    required String itemId,
    required String userId,
  }) async {
    final itemRef = _items(listId).doc(itemId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(itemRef);
      if (!snap.exists) {
        throw const RepositoryException('item-not-found');
      }
      final current = snap.data()?['assignedTo'] as String?;
      if (current != null && current != userId) {
        throw const RepositoryException(
          'already-assigned',
          'Row is already assigned to another worker; use reassign.',
        );
      }
      tx.update(itemRef, {'assignedTo': userId});
    });
    await _touchList(listId);
  }

  @override
  Future<void> reassignItem({
    required String listId,
    required String itemId,
    required String? newAssigneeId,
  }) async {
    final itemRef = _items(listId).doc(itemId);
    final snap = await itemRef.get();
    if (!snap.exists) {
      throw const RepositoryException('item-not-found');
    }
    await itemRef.update({'assignedTo': newAssigneeId});
    await _touchList(listId);
  }

  @override
  Future<void> markPicked({
    required String listId,
    required String itemId,
    required double actualQuantity,
    required String byUserId,
    DateTime? at,
  }) async {
    final itemRef = _items(listId).doc(itemId);
    final snap = await itemRef.get();
    if (!snap.exists) {
      throw const RepositoryException('item-not-found');
    }
    await itemRef.update({
      'pickedQuantity': actualQuantity,
      'pickedAt': Timestamp.fromDate(at ?? DateTime.now()),
      'completedBy': byUserId,
    });
    await _touchList(listId);
  }

  Future<void> _touchList(String listId) =>
      _lists.doc(listId).update({'updatedAt': FieldValue.serverTimestamp()});

  static PickingList _toList(String id, Map<String, dynamic> data) {
    return PickingList(
      id: id,
      name: (data['name'] as String?) ?? '',
      scheduledAt: _readTimestamp(data['scheduledAt']) ?? DateTime.now(),
      status: PickingListStatus.fromName(
        (data['status'] as String?) ?? PickingListStatus.draft.name,
      ),
      createdBy: (data['createdBy'] as String?) ?? '',
      updatedAt: _readTimestamp(data['updatedAt']) ?? DateTime.now(),
    );
  }

  static PickingItem _toItem(String id, Map<String, dynamic> data) {
    return PickingItem(
      id: id,
      cropId: (data['cropId'] as String?) ?? '',
      cropName: (data['cropName'] as String?) ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0,
      unit: QuantityUnit.fromName(
        (data['unit'] as String?) ?? QuantityUnit.units.name,
      ),
      note: data['note'] as String?,
      assignedTo: data['assignedTo'] as String?,
      pickedQuantity: (data['pickedQuantity'] as num?)?.toDouble(),
      pickedAt: _readTimestamp(data['pickedAt']),
      completedBy: data['completedBy'] as String?,
    );
  }

  static DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
