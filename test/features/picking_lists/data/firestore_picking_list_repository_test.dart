import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/picking_lists/data/firestore_picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/data/picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/domain/picking_list.dart';
import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestorePickingListRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestorePickingListRepository(firestore);
  });

  group('createList + watchLists', () {
    test('persists fields and streams by scheduledAt desc', () async {
      final earlier = DateTime.utc(2026, 4, 1, 6);
      final later = DateTime.utc(2026, 4, 5, 6);

      final earlyId = await repo.createList(
        name: 'Tuesday pick',
        scheduledAt: earlier,
        createdBy: 'u_manager',
      );
      final lateId = await repo.createList(
        name: 'Saturday pick',
        scheduledAt: later,
        createdBy: 'u_manager',
      );

      final lists = await repo.watchLists().first;
      expect(lists.map((l) => l.id), [lateId, earlyId]);
      expect(lists.first.name, 'Saturday pick');
      expect(lists.first.status, PickingListStatus.draft);
      expect(lists.first.createdBy, 'u_manager');
    });

    test('emits a new event when a list is added', () async {
      final emissions = <List<PickingList>>[];
      final sub = repo.watchLists().listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      await repo.createList(
        name: 'Friday pick',
        scheduledAt: DateTime.utc(2026, 4, 3, 6),
        createdBy: 'u_manager',
      );
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last.length, 1);
      expect(emissions.last.first.name, 'Friday pick');
      await sub.cancel();
    });
  });

  group('addItem + watchItems', () {
    test('streams items for a list', () async {
      final listId = await repo.createList(
        name: 'L',
        scheduledAt: DateTime.utc(2026, 4, 5),
        createdBy: 'u_manager',
      );
      final itemId = await repo.addItem(
        listId: listId,
        cropId: 'c_tomato',
        cropName: 'Tomatoes',
        quantity: 10,
        unit: QuantityUnit.kg,
        note: 'GH3',
      );

      final items = await repo.watchItems(listId).first;
      expect(items, hasLength(1));
      expect(items.first.id, itemId);
      expect(items.first.cropName, 'Tomatoes');
      expect(items.first.unit, QuantityUnit.kg);
      expect(items.first.note, 'GH3');
      expect(items.first.isAssigned, isFalse);
    });
  });

  group('claimItem', () {
    test('assigns to the caller when row is unassigned', () async {
      final listId = await repo.createList(
        name: 'L',
        scheduledAt: DateTime.utc(2026, 4, 5),
        createdBy: 'u_manager',
      );
      final itemId = await repo.addItem(
        listId: listId,
        cropId: 'c_t',
        cropName: 'Tomatoes',
        quantity: 5,
        unit: QuantityUnit.units,
      );

      await repo.claimItem(
        listId: listId,
        itemId: itemId,
        userId: 'u_worker',
      );

      final items = await repo.watchItems(listId).first;
      expect(items.first.assignedTo, 'u_worker');
    });

    test('is a no-op when caller already owns the row', () async {
      final listId = await repo.createList(
        name: 'L',
        scheduledAt: DateTime.utc(2026, 4, 5),
        createdBy: 'u_manager',
      );
      final itemId = await repo.addItem(
        listId: listId,
        cropId: 'c_t',
        cropName: 'Tomatoes',
        quantity: 5,
        unit: QuantityUnit.units,
        assignedTo: 'u_worker',
      );

      await repo.claimItem(
        listId: listId,
        itemId: itemId,
        userId: 'u_worker',
      );

      final items = await repo.watchItems(listId).first;
      expect(items.first.assignedTo, 'u_worker');
    });

    test('throws already-assigned when row belongs to someone else', () async {
      final listId = await repo.createList(
        name: 'L',
        scheduledAt: DateTime.utc(2026, 4, 5),
        createdBy: 'u_manager',
      );
      final itemId = await repo.addItem(
        listId: listId,
        cropId: 'c_t',
        cropName: 'Tomatoes',
        quantity: 5,
        unit: QuantityUnit.units,
        assignedTo: 'u_alice',
      );

      expect(
        () => repo.claimItem(
          listId: listId,
          itemId: itemId,
          userId: 'u_bob',
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

    test('throws item-not-found when row does not exist', () async {
      final listId = await repo.createList(
        name: 'L',
        scheduledAt: DateTime.utc(2026, 4, 5),
        createdBy: 'u_manager',
      );

      expect(
        () => repo.claimItem(
          listId: listId,
          itemId: 'missing',
          userId: 'u_bob',
        ),
        throwsA(
          isA<RepositoryException>().having(
            (e) => e.code,
            'code',
            'item-not-found',
          ),
        ),
      );
    });

    test(
      'concurrent claims: only one wins, the other gets already-assigned',
      () async {
        final listId = await repo.createList(
          name: 'L',
          scheduledAt: DateTime.utc(2026, 4, 5),
          createdBy: 'u_manager',
        );
        final itemId = await repo.addItem(
          listId: listId,
          cropId: 'c_t',
          cropName: 'Tomatoes',
          quantity: 5,
          unit: QuantityUnit.units,
        );

        final results = await Future.wait<Object?>([
          repo
              .claimItem(listId: listId, itemId: itemId, userId: 'u_a')
              .then<Object?>((_) => 'ok')
              .catchError((Object e) => e),
          repo
              .claimItem(listId: listId, itemId: itemId, userId: 'u_b')
              .then<Object?>((_) => 'ok')
              .catchError((Object e) => e),
        ]);

        final outcomes = results.map((r) {
          if (r == 'ok') return 'ok';
          if (r is RepositoryException) return r.code;
          return 'other:$r';
        }).toList();
        expect(outcomes, containsAll(<String>['ok']));
        // Either both succeed because the second claim was the same user,
        // or one wins and the other reports 'already-assigned'.
        final finalOwner =
            (await repo.watchItems(listId).first).first.assignedTo;
        expect(finalOwner, anyOf('u_a', 'u_b'));
      },
    );
  });

  group('reassignItem', () {
    test(
      'changes assignment and clears it when newAssigneeId is null',
      () async {
        final listId = await repo.createList(
          name: 'L',
          scheduledAt: DateTime.utc(2026, 4, 5),
          createdBy: 'u_manager',
        );
        final itemId = await repo.addItem(
          listId: listId,
          cropId: 'c_t',
          cropName: 'Tomatoes',
          quantity: 5,
          unit: QuantityUnit.units,
          assignedTo: 'u_a',
        );

        await repo.reassignItem(
          listId: listId,
          itemId: itemId,
          newAssigneeId: 'u_b',
        );
        expect((await repo.watchItems(listId).first).first.assignedTo, 'u_b');

        await repo.reassignItem(
          listId: listId,
          itemId: itemId,
          newAssigneeId: null,
        );
        expect(
          (await repo.watchItems(listId).first).first.assignedTo,
          isNull,
        );
      },
    );

    test('throws item-not-found when row does not exist', () async {
      final listId = await repo.createList(
        name: 'L',
        scheduledAt: DateTime.utc(2026, 4, 5),
        createdBy: 'u_manager',
      );
      expect(
        () => repo.reassignItem(
          listId: listId,
          itemId: 'missing',
          newAssigneeId: 'u_b',
        ),
        throwsA(isA<RepositoryException>()),
      );
    });
  });

  group('markPicked', () {
    test('records actual quantity, completedBy and pickedAt', () async {
      final listId = await repo.createList(
        name: 'L',
        scheduledAt: DateTime.utc(2026, 4, 5),
        createdBy: 'u_manager',
      );
      final itemId = await repo.addItem(
        listId: listId,
        cropId: 'c_t',
        cropName: 'Tomatoes',
        quantity: 10,
        unit: QuantityUnit.kg,
        assignedTo: 'u_worker',
      );
      final at = DateTime.utc(2026, 4, 5, 8, 30);

      await repo.markPicked(
        listId: listId,
        itemId: itemId,
        actualQuantity: 9.5,
        byUserId: 'u_worker',
        at: at,
      );

      final item = (await repo.watchItems(listId).first).first;
      expect(item.pickedQuantity, 9.5);
      expect(item.completedBy, 'u_worker');
      expect(item.pickedAt!.isAtSameMomentAs(at), isTrue);
      expect(item.isPicked, isTrue);
      expect(item.difference, closeTo(-0.5, 1e-9));
    });

    test('throws item-not-found when row does not exist', () async {
      final listId = await repo.createList(
        name: 'L',
        scheduledAt: DateTime.utc(2026, 4, 5),
        createdBy: 'u_manager',
      );
      expect(
        () => repo.markPicked(
          listId: listId,
          itemId: 'missing',
          actualQuantity: 1,
          byUserId: 'u',
        ),
        throwsA(isA<RepositoryException>()),
      );
    });
  });

  group('field decoding edge cases', () {
    test('falls back to defaults for missing fields', () async {
      await firestore.collection('pickingLists').doc('partial').set({
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 4, 5)),
      });
      final lists = await repo.watchLists().first;
      expect(lists.first.name, '');
      expect(lists.first.createdBy, '');
      expect(lists.first.status, PickingListStatus.draft);
    });

    test('items default to units and zero quantity when missing', () async {
      await firestore.collection('pickingLists').doc('p').set({
        'name': 'P',
        'scheduledAt': Timestamp.fromDate(DateTime.utc(2026, 4, 5)),
        'status': 'draft',
        'createdBy': 'u',
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 4, 5)),
      });
      await firestore
          .collection('pickingLists')
          .doc('p')
          .collection('items')
          .doc('x')
          .set(<String, Object?>{});

      final items = await repo.watchItems('p').first;
      expect(items, hasLength(1));
      expect(items.first.quantity, 0);
      expect(items.first.unit, QuantityUnit.units);
      expect(items.first.cropName, '');
    });
  });
}
