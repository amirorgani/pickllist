import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pickllist/features/picking_lists/data/firestore_picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/data/picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';

/// Stub Firebase options that satisfy [Firebase.initializeApp] in an emulated
/// environment. The actual values are not validated by the emulator, so fake
/// constants are sufficient here.
const _kOptions = FirebaseOptions(
  apiKey: 'fake',
  appId: '1:0:android:0',
  messagingSenderId: '0',
  projectId: 'demo-pickllist',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late FirestorePickingListRepository repo;

  setUpAll(() async {
    await Firebase.initializeApp(options: _kOptions);
    firestore = FirebaseFirestore.instance
      ..useFirestoreEmulator('localhost', 8080);
  });

  setUp(() {
    // Each test gets a fresh repository instance pointing at the same
    // emulator instance. Firestore state carries over between tests, but
    // each test creates its own list/item ids so tests remain independent.
    repo = FirestorePickingListRepository(firestore);
  });

  testWidgets('createList then getList returns the created list', (
    tester,
  ) async {
    final scheduled = DateTime(2025, 6, 1, 8);

    final id = await repo.createList(
      name: 'Morning run',
      scheduledAt: scheduled,
      createdBy: 'user-manager',
    );

    expect(id, isNotEmpty);

    // watchLists emits at least one snapshot that contains our new list.
    final lists = await repo.watchLists().first;
    final match = lists.where((l) => l.id == id).toList();

    expect(match, hasLength(1));
    expect(match.first.name, 'Morning run');
    expect(match.first.createdBy, 'user-manager');
    expect(
      match.first.scheduledAt.toUtc(),
      scheduled.toUtc(),
    );
  });

  testWidgets('addItem then watchItems emits the item', (tester) async {
    final listId = await repo.createList(
      name: 'Afternoon run',
      scheduledAt: DateTime(2025, 6, 2, 14),
      createdBy: 'user-manager',
    );

    final itemId = await repo.addItem(
      listId: listId,
      cropId: 'crop-tomato',
      cropName: 'Tomato',
      quantity: 5,
      unit: QuantityUnit.kg,
      note: 'Handle gently',
    );

    expect(itemId, isNotEmpty);

    final items = await repo
        .watchItems(listId)
        .firstWhere((list) => list.any((i) => i.id == itemId));

    final item = items.firstWhere((i) => i.id == itemId);
    expect(item.cropName, 'Tomato');
    expect(item.quantity, 5.0);
    expect(item.unit, QuantityUnit.kg);
    expect(item.note, 'Handle gently');
    expect(item.assignedTo, isNull);
  });

  testWidgets('concurrent claimItem: only one caller wins', (tester) async {
    final listId = await repo.createList(
      name: 'Concurrency test',
      scheduledAt: DateTime(2025, 6, 3, 9),
      createdBy: 'user-manager',
    );

    final itemId = await repo.addItem(
      listId: listId,
      cropId: 'crop-pepper',
      cropName: 'Pepper',
      quantity: 3,
      unit: QuantityUnit.boxes,
    );

    // Fire two concurrent claim calls for different users.
    final results = await Future.wait<Object?>([
      repo
          .claimItem(listId: listId, itemId: itemId, userId: 'worker-a')
          .then<Object?>((_) => 'worker-a')
          .onError<RepositoryException>((e, _) => e),
      repo
          .claimItem(listId: listId, itemId: itemId, userId: 'worker-b')
          .then<Object?>((_) => 'worker-b')
          .onError<RepositoryException>((e, _) => e),
    ]);

    final successes = results.whereType<String>().toList();
    final failures = results.whereType<RepositoryException>().toList();

    // Exactly one caller wins; the other gets 'already-assigned'.
    expect(successes, hasLength(1));
    expect(failures, hasLength(1));
    expect(failures.first.code, 'already-assigned');

    // The winning user id is persisted in Firestore.
    final items = await repo.watchItems(listId).first;
    final item = items.firstWhere((i) => i.id == itemId);
    expect(item.assignedTo, successes.first);
  });
}
