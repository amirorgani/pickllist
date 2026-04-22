import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/picking_lists/data/fake_picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/data/picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';

void main() {
  late FakePickingListRepository repo;

  setUp(() {
    repo = FakePickingListRepository();
  });

  test('seed produces exactly one published list with three items', () async {
    final lists = await repo.watchLists().first;
    expect(lists, hasLength(1));
    final items = await repo.watchItems(lists.single.id).first;
    expect(items, hasLength(3));
  });

  test('createList adds a new list and emits', () async {
    final id = await repo.createList(
      name: 'Friday pick',
      scheduledAt: DateTime(2026, 4, 25, 6),
      createdBy: 'u_manager',
    );
    final lists = await repo.watchLists().first;
    expect(lists.any((l) => l.id == id && l.name == 'Friday pick'), isTrue);
  });

  test('claimItem sets assignedTo when row is free', () async {
    final lists = await repo.watchLists().first;
    final listId = lists.single.id;
    final items = await repo.watchItems(listId).first;
    final unassigned = items.firstWhere((i) => !i.isAssigned);

    await repo.claimItem(
      listId: listId,
      itemId: unassigned.id,
      userId: 'u_worker2',
    );

    final updated = await repo.watchItems(listId).first;
    final claimed = updated.firstWhere((i) => i.id == unassigned.id);
    expect(claimed.assignedTo, 'u_worker2');
  });

  test('claimItem throws when already assigned to someone else', () async {
    final lists = await repo.watchLists().first;
    final listId = lists.single.id;
    final items = await repo.watchItems(listId).first;
    final assigned = items.firstWhere((i) => i.assignedTo != null);

    expect(
      () => repo.claimItem(
        listId: listId,
        itemId: assigned.id,
        userId: 'u_someone_else',
      ),
      throwsA(
        isA<RepositoryException>().having(
          (e) => e.code,
          'code',
          'already-assigned',
        ),
      ),
    );
  });

  test('claimItem is idempotent when the same user re-claims', () async {
    final lists = await repo.watchLists().first;
    final listId = lists.single.id;
    final items = await repo.watchItems(listId).first;
    final assigned = items.firstWhere((i) => i.assignedTo == 'u_worker');

    await repo.claimItem(
      listId: listId,
      itemId: assigned.id,
      userId: 'u_worker',
    );
    final updated = await repo.watchItems(listId).first;
    expect(
      updated.firstWhere((i) => i.id == assigned.id).assignedTo,
      'u_worker',
    );
  });

  test('reassignItem with null clears the assignee', () async {
    final lists = await repo.watchLists().first;
    final listId = lists.single.id;
    final items = await repo.watchItems(listId).first;
    final assigned = items.firstWhere((i) => i.isAssigned);

    await repo.reassignItem(
      listId: listId,
      itemId: assigned.id,
      newAssigneeId: null,
    );
    final updated = await repo.watchItems(listId).first;
    expect(updated.firstWhere((i) => i.id == assigned.id).assignedTo, isNull);
  });

  test('markPicked records quantity, timestamp, and completedBy', () async {
    final lists = await repo.watchLists().first;
    final listId = lists.single.id;
    final items = await repo.watchItems(listId).first;
    final target = items.first;
    final before = DateTime.now();

    await repo.markPicked(
      listId: listId,
      itemId: target.id,
      actualQuantity: target.quantity - 5,
      byUserId: 'u_worker',
    );
    final updated = await repo.watchItems(listId).first;
    final done = updated.firstWhere((i) => i.id == target.id);
    expect(done.isPicked, isTrue);
    expect(done.pickedQuantity, target.quantity - 5);
    expect(done.difference, -5);
    expect(done.completedBy, 'u_worker');
    expect(done.pickedAt!.isBefore(before), isFalse);
  });

  test('watchItems emits on updates', () async {
    final lists = await repo.watchLists().first;
    final listId = lists.single.id;

    final stream = repo.watchItems(listId);
    final seen = <int>[];
    final sub = stream.listen((items) => seen.add(items.length));

    await Future<void>.delayed(Duration.zero);
    await repo.addItem(
      listId: listId,
      cropId: 'c_new',
      cropName: 'Lettuce',
      quantity: 10,
      unit: QuantityUnit.boxes,
    );
    await Future<void>.delayed(Duration.zero);

    await sub.cancel();
    expect(seen.last, 4); // was 3, added 1
  });
}
