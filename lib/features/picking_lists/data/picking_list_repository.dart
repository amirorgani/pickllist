import 'package:pickllist/features/picking_lists/domain/picking_item.dart';
import 'package:pickllist/features/picking_lists/domain/picking_list.dart';
import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';

/// Reads and writes picking lists. Implemented today by
/// [FakePickingListRepository]; will have a Firestore impl when the
/// Firebase project is configured.
abstract class PickingListRepository {
  Stream<List<PickingList>> watchLists();
  Stream<List<PickingItem>> watchItems(String listId);

  Future<String> createList({
    required String name,
    required DateTime scheduledAt,
    required String createdBy,
  });

  Future<String> addItem({
    required String listId,
    required String cropId,
    required String cropName,
    required double quantity,
    required QuantityUnit unit,
    String? note,
    String? assignedTo,
  });

  /// Claim `itemId` for `userId`. Must fail when the row is already
  /// assigned to someone else (the caller should reassign instead).
  Future<void> claimItem({
    required String listId,
    required String itemId,
    required String userId,
  });

  Future<void> reassignItem({
    required String listId,
    required String itemId,
    required String? newAssigneeId,
  });

  Future<void> markPicked({
    required String listId,
    required String itemId,
    required double actualQuantity,
    required String byUserId,
    DateTime? at,
  });
}

class RepositoryException implements Exception {
  const RepositoryException(this.code, [this.message]);
  final String code;
  final String? message;
  @override
  String toString() =>
      'RepositoryException($code${message == null ? '' : ': $message'})';
}
