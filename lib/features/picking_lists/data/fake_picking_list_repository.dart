import 'dart:async';

import 'package:pickllist/features/picking_lists/data/picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/domain/picking_item.dart';
import 'package:pickllist/features/picking_lists/domain/picking_list.dart';
import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';

/// In-memory picking list store. Broadcasts changes to listeners so that
/// multiple screens within the same process stay in sync — good enough
/// to demo the "live updates" UX before Firestore is wired.
class FakePickingListRepository implements PickingListRepository {
  /// Creates the seeded fake picking-list repository.
  FakePickingListRepository() {
    _seed();
  }

  final Map<String, PickingList> _lists = {};
  final Map<String, List<PickingItem>> _itemsByList = {}; // listId -> items
  final _listsCtrl = StreamController<List<PickingList>>.broadcast();
  final Map<String, StreamController<List<PickingItem>>> _itemCtrls = {};
  int _idCounter = 1000;

  String _nextId(String prefix) => '${prefix}_${++_idCounter}';

  void _emitLists() {
    final sorted = _lists.values.toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    _listsCtrl.add(List.unmodifiable(sorted));
  }

  void _emitItems(String listId) {
    final ctrl = _itemCtrls[listId];
    if (ctrl == null) return;
    final items = _itemsByList[listId] ?? const <PickingItem>[];
    ctrl.add(List.unmodifiable(items));
  }

  @override
  Stream<List<PickingList>> watchLists() async* {
    // Emit current snapshot on subscribe, then live updates.
    final sorted = _lists.values.toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    yield List.unmodifiable(sorted);
    yield* _listsCtrl.stream;
  }

  @override
  Stream<List<PickingItem>> watchItems(String listId) async* {
    final ctrl = _itemCtrls.putIfAbsent(
      listId,
      StreamController<List<PickingItem>>.broadcast,
    );
    yield List.unmodifiable(_itemsByList[listId] ?? const []);
    yield* ctrl.stream;
  }

  @override
  Future<String> createList({
    required String name,
    required DateTime scheduledAt,
    required String createdBy,
  }) async {
    final id = _nextId('list');
    _lists[id] = PickingList(
      id: id,
      name: name,
      scheduledAt: scheduledAt,
      status: PickingListStatus.draft,
      createdBy: createdBy,
      updatedAt: DateTime.now(),
    );
    _itemsByList[id] = [];
    _emitLists();
    return id;
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
    final items = _itemsByList.putIfAbsent(listId, () => []);
    final id = _nextId('item');
    items.add(
      PickingItem(
        id: id,
        cropId: cropId,
        cropName: cropName,
        quantity: quantity,
        unit: unit,
        note: note,
        assignedTo: assignedTo,
      ),
    );
    _touchList(listId);
    _emitItems(listId);
    return id;
  }

  int _itemIndex(String listId, String itemId) {
    final items = _itemsByList[listId];
    if (items == null) {
      throw const RepositoryException('list-not-found');
    }
    final i = items.indexWhere((it) => it.id == itemId);
    if (i < 0) throw const RepositoryException('item-not-found');
    return i;
  }

  @override
  Future<void> claimItem({
    required String listId,
    required String itemId,
    required String userId,
  }) async {
    final items = _itemsByList[listId]!;
    final i = _itemIndex(listId, itemId);
    final current = items[i];
    if (current.assignedTo != null && current.assignedTo != userId) {
      throw const RepositoryException(
        'already-assigned',
        'Row is already assigned to another worker; use reassign.',
      );
    }
    items[i] = current.copyWith(assignedTo: userId);
    _touchList(listId);
    _emitItems(listId);
  }

  @override
  Future<void> reassignItem({
    required String listId,
    required String itemId,
    required String? newAssigneeId,
  }) async {
    final items = _itemsByList[listId]!;
    final i = _itemIndex(listId, itemId);
    items[i] = items[i].copyWith(
      assignedTo: newAssigneeId,
      clearAssignedTo: newAssigneeId == null,
    );
    _touchList(listId);
    _emitItems(listId);
  }

  @override
  Future<void> markPicked({
    required String listId,
    required String itemId,
    required double actualQuantity,
    required String byUserId,
    DateTime? at,
  }) async {
    final items = _itemsByList[listId]!;
    final i = _itemIndex(listId, itemId);
    items[i] = items[i].copyWith(
      pickedQuantity: actualQuantity,
      pickedAt: at ?? DateTime.now(),
      completedBy: byUserId,
    );
    _touchList(listId);
    _emitItems(listId);
  }

  void _touchList(String listId) {
    final current = _lists[listId];
    if (current == null) return;
    _lists[listId] = current.copyWith(updatedAt: DateTime.now());
    _emitLists();
  }

  void _seed() {
    final now = DateTime.now();
    final listId = _nextId('list');
    _lists[listId] = PickingList(
      id: listId,
      name: 'Thursday morning pick',
      scheduledAt: DateTime(now.year, now.month, now.day, 6),
      status: PickingListStatus.published,
      createdBy: 'u_manager',
      updatedAt: now,
    );
    _itemsByList[listId] = [
      PickingItem(
        id: _nextId('item'),
        cropId: 'c_tomato',
        cropName: 'Tomatoes',
        quantity: 120,
        unit: QuantityUnit.kg,
        note: 'Cherry variety — greenhouse 3',
      ),
      PickingItem(
        id: _nextId('item'),
        cropId: 'c_cucumber',
        cropName: 'Cucumbers',
        quantity: 30,
        unit: QuantityUnit.boxes,
        assignedTo: 'u_worker',
      ),
      PickingItem(
        id: _nextId('item'),
        cropId: 'c_pepper',
        cropName: 'Bell peppers',
        quantity: 200,
        unit: QuantityUnit.units,
      ),
    ];
  }
}
