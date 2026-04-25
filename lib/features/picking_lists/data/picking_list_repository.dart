import 'package:pickllist/features/picking_lists/data/fake_picking_list_repository.dart'
    show FakePickingListRepository;
import 'package:pickllist/features/picking_lists/domain/picking_item.dart';
import 'package:pickllist/features/picking_lists/domain/picking_list.dart';
import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';

/// Reads and writes picking lists. Implemented today by
/// [FakePickingListRepository]; will have a Firestore impl when the
/// Firebase project is configured.
abstract class PickingListRepository {
  /// Watches all picking list headers ordered for index screens.
  Stream<List<PickingList>> watchLists();

  /// Watches the row items that belong to [listId].
  Stream<List<PickingItem>> watchItems(String listId);

  /// Creates a draft picking list and returns its id.
  Future<String> createList({
    required String name,
    required DateTime scheduledAt,
    required String createdBy,
  });

  /// Adds a row to an existing picking list and returns the row id.
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

  /// Reassigns a row, or clears assignment when [newAssigneeId] is null.
  Future<void> reassignItem({
    required String listId,
    required String itemId,
    required String? newAssigneeId,
  });

  /// Marks a row picked with the actual quantity and completing user.
  Future<void> markPicked({
    required String listId,
    required String itemId,
    required double actualQuantity,
    required String byUserId,
    DateTime? at,
  });
}

/// Repository failure with a stable [code] and optional human message.
class RepositoryException implements Exception {
  /// Creates a repository failure.
  const RepositoryException(this.code, [this.message]);

  /// Stable machine-readable error code.
  final String code;

  /// Optional detail suitable for logs or simple UI text.
  final String? message;
  @override
  String toString() =>
      'RepositoryException($code${message == null ? '' : ': $message'})';
}
