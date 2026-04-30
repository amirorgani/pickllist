// Emulator-backed integration tests for [FirestorePickingListRepository].
//
// Prerequisites: `firebase emulators:start --only firestore --project
// demo-pickllist` (the CI job handles this via `emulators:exec`).
//
// Run locally:
//   cd firebase && firebase emulators:exec --only firestore \
//     --project demo-pickllist "flutter test integration_test/ -d chrome"
//
// Or from the repo root if the emulator is already running:
//   flutter test integration_test/ -d chrome
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pickllist/features/picking_lists/data/firestore_picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/domain/picking_list.dart';
import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';

/// Minimal stub options that satisfy Firebase SDK validation.
/// The SDK never uses these values when the emulator is active.
const _kOptions = FirebaseOptions(
  apiKey: 'fake-api-key',
  appId: '1:000000000000:web:000000000000',
  messagingSenderId: '000000000000',
  projectId: 'demo-pickllist',
  storageBucket: 'demo-pickllist.appspot.com',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late FirestorePickingListRepository repo;

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: _kOptions);
    firestore = FirebaseFirestore.instance
      // Point all Firestore calls at the local emulator.
      ..useFirestoreEmulator('localhost', 8080);
    repo = FirestorePickingListRepository(firestore);
  });

  test('createList persists a draft list readable via watchLists', () async {
    final listId = await repo.createList(
      name: 'Emulator smoke list',
      scheduledAt: DateTime(2026, 5),
      createdBy: 'manager_emulator',
    );

    expect(listId, isNotEmpty);

    final lists = await repo.watchLists().first;
    final created = lists.where((l) => l.id == listId).toList();
    expect(created, hasLength(1));
    expect(created.first.name, 'Emulator smoke list');
    expect(created.first.status, PickingListStatus.draft);
    expect(created.first.createdBy, 'manager_emulator');
  });

  test('addItem persists a row and watchItems streams it back', () async {
    final listId = await repo.createList(
      name: 'Items smoke list',
      scheduledAt: DateTime(2026, 5),
      createdBy: 'manager_emulator',
    );

    final itemId = await repo.addItem(
      listId: listId,
      cropId: 'c_tomato',
      cropName: 'Tomatoes',
      quantity: 10,
      unit: QuantityUnit.kg,
    );

    expect(itemId, isNotEmpty);

    final items = await repo.watchItems(listId).first;
    expect(items, hasLength(1));
    expect(items.first.id, itemId);
    expect(items.first.cropName, 'Tomatoes');
    expect(items.first.quantity, 10);
    expect(items.first.unit, QuantityUnit.kg);
    expect(items.first.assignedTo, isNull);
  });

  test('claimItem assigns the row to the requesting worker', () async {
    final listId = await repo.createList(
      name: 'Claim smoke list',
      scheduledAt: DateTime(2026, 5),
      createdBy: 'manager_emulator',
    );
    final itemId = await repo.addItem(
      listId: listId,
      cropId: 'c_pepper',
      cropName: 'Peppers',
      quantity: 5,
      unit: QuantityUnit.units,
    );

    await repo.claimItem(
      listId: listId,
      itemId: itemId,
      userId: 'worker_emulator',
    );

    final items = await repo.watchItems(listId).first;
    final claimed = items.firstWhere((i) => i.id == itemId);
    expect(claimed.assignedTo, 'worker_emulator');
  });

  test('concurrent claimItem race: exactly one worker wins', () async {
    // Create a fresh unassigned row so neither worker has an advantage.
    final listId = await repo.createList(
      name: 'Race list',
      scheduledAt: DateTime(2026, 5),
      createdBy: 'manager_emulator',
    );
    final itemId = await repo.addItem(
      listId: listId,
      cropId: 'c_lettuce',
      cropName: 'Lettuce',
      quantity: 20,
      unit: QuantityUnit.kg,
    );

    // Two repository instances backed by the same Firestore instance race to
    // claim the same row.  One transaction must win; the other must be
    // rejected with already-assigned (possibly after the SDK retries).
    final repoA = FirestorePickingListRepository(firestore);
    final repoB = FirestorePickingListRepository(firestore);

    String? winner;
    var failures = 0;

    await Future.wait([
      repoA
          .claimItem(listId: listId, itemId: itemId, userId: 'worker_a')
          .then((_) {
            winner = 'worker_a';
          })
          .catchError((_) {
            failures++;
          }),
      repoB
          .claimItem(listId: listId, itemId: itemId, userId: 'worker_b')
          .then((_) {
            winner ??= 'worker_b';
          })
          .catchError((_) {
            failures++;
          }),
    ]);

    // Exactly one claim succeeded and one failed.
    expect(failures, 1, reason: 'exactly one claimItem should be rejected');
    expect(winner, isNotNull, reason: 'exactly one worker should win');

    // The winning UID is on the item in Firestore.
    final items = await repo.watchItems(listId).first;
    final raced = items.firstWhere((i) => i.id == itemId);
    expect(raced.assignedTo, winner);
  });
}
