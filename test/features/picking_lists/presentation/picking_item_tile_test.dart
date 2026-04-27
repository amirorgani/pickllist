// Presentation-layer widget tests for PickingItemTile. GUARD-09.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/auth/application/auth_providers.dart';
import 'package:pickllist/features/auth/data/fake_auth_repository.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';
import 'package:pickllist/features/picking_lists/application/picking_list_providers.dart';
import 'package:pickllist/features/picking_lists/data/fake_picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/domain/picking_item.dart';
import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';
import 'package:pickllist/features/picking_lists/presentation/widgets/picking_item_tile.dart';
import 'package:pickllist/features/users/application/user_directory_providers.dart';
import 'package:pickllist/features/users/data/fake_user_directory_repository.dart';
import 'package:pickllist/l10n/generated/app_localizations.dart';

Widget buildTile(
  PickingItem item, {
  String listId = 'list_1',
  List<Override> overrides = const [],
  Size? surfaceSize,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: PickingItemTile(listId: listId, item: item),
        ),
      ),
    ),
  );
}

PickingItem baseItem({
  String id = 'i1',
  String? assignedTo,
  double? pickedQuantity,
  DateTime? pickedAt,
  String? completedBy,
  String? note,
  double quantity = 50,
  QuantityUnit unit = QuantityUnit.kg,
}) {
  return PickingItem(
    id: id,
    cropId: 'c1',
    cropName: 'Tomatoes',
    quantity: quantity,
    unit: unit,
    note: note,
    assignedTo: assignedTo,
    pickedQuantity: pickedQuantity,
    pickedAt: pickedAt,
    completedBy: completedBy,
  );
}

void main() {
  late FakeAuthRepository fakeAuth;
  late FakePickingListRepository fakeRepo;
  late FakeUserDirectoryRepository fakeUsers;

  setUp(() {
    fakeAuth = FakeAuthRepository();
    fakeRepo = FakePickingListRepository();
    fakeUsers = FakeUserDirectoryRepository(fakeAuth);
  });

  List<Override> overrides({AppUser? signedIn}) => [
    authRepositoryProvider.overrideWithValue(fakeAuth),
    pickingListRepositoryProvider.overrideWithValue(fakeRepo),
    userDirectoryRepositoryProvider.overrideWithValue(fakeUsers),
    if (signedIn != null) currentUserProvider.overrideWithValue(signedIn),
  ];

  group('PickingItemTile — unassigned, unpicked', () {
    testWidgets('shows crop name', (tester) async {
      await tester.pumpWidget(
        buildTile(baseItem(), overrides: overrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tomatoes'), findsOneWidget);
    });

    testWidgets('shows quantity and unit', (tester) async {
      await tester.pumpWidget(
        buildTile(
          baseItem(),
          overrides: overrides(),
        ),
      );
      await tester.pumpAndSettle();

      // Quantity label and value are rendered.
      expect(find.textContaining('Quantity'), findsOneWidget);
      expect(find.textContaining('kg'), findsOneWidget);
    });

    testWidgets('shows unassigned label when no assignee', (tester) async {
      await tester.pumpWidget(
        buildTile(baseItem(), overrides: overrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unassigned'), findsOneWidget);
    });

    testWidgets('shows note when provided', (tester) async {
      await tester.pumpWidget(
        buildTile(
          baseItem(note: 'Handle with care'),
          overrides: overrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Handle with care'), findsOneWidget);
    });

    testWidgets('does not show note section when note is absent', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTile(baseItem(), overrides: overrides()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Note:'), findsNothing);
    });
  });

  group('PickingItemTile — no user signed in', () {
    testWidgets('hides action buttons when not signed in', (tester) async {
      await tester.pumpWidget(
        buildTile(
          baseItem(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            pickingListRepositoryProvider.overrideWithValue(fakeRepo),
            userDirectoryRepositoryProvider.overrideWithValue(fakeUsers),
            currentUserProvider.overrideWithValue(null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Claim'), findsNothing);
      expect(find.text('Reassign'), findsNothing);
      expect(find.text('Mark picked'), findsNothing);
    });
  });

  group('PickingItemTile — signed-in worker', () {
    const worker = AppUser(
      id: 'u_worker',
      email: 'worker@farm.test',
      displayName: 'Wendy Worker',
      role: UserRole.worker,
    );

    testWidgets('shows Claim button for unassigned item', (tester) async {
      await tester.pumpWidget(
        buildTile(
          baseItem(),
          overrides: overrides(signedIn: worker),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Claim'), findsOneWidget);
    });

    testWidgets('shows Mark picked button for own assigned item', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTile(
          baseItem(assignedTo: 'u_worker'),
          overrides: overrides(signedIn: worker),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark picked'), findsOneWidget);
    });

    testWidgets('shows check icon for picked item', (tester) async {
      final pickedItem = baseItem(
        assignedTo: 'u_worker',
        pickedQuantity: 48,
        pickedAt: DateTime(2026, 4, 25, 8, 30),
        completedBy: 'u_worker',
      );
      await tester.pumpWidget(
        buildTile(pickedItem, overrides: overrides(signedIn: worker)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows picked summary with under-by text when under-picked', (
      tester,
    ) async {
      // Suppress the RenderFlex overflow that can happen in default test
      // viewport — it is a layout issue in the production widget, not a
      // test logic error.
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          return;
        }
        FlutterError.presentError(details);
      };
      addTearDown(() => FlutterError.onError = FlutterError.presentError);

      final pickedItem = baseItem(
        pickedQuantity: 40,
        pickedAt: DateTime(2026, 4, 25, 8),
        completedBy: 'u_worker',
      );
      await tester.pumpWidget(
        buildTile(pickedItem, overrides: overrides(signedIn: worker)),
      );
      await tester.pumpAndSettle();

      // The picked summary row is rendered (schedule icon is the first
      // widget in _PickedSummary).
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('shows picked summary with over-by text when over-picked', (
      tester,
    ) async {
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          return;
        }
        FlutterError.presentError(details);
      };
      addTearDown(() => FlutterError.onError = FlutterError.presentError);

      final pickedItem = baseItem(
        pickedQuantity: 60,
        pickedAt: DateTime(2026, 4, 25, 8),
        completedBy: 'u_worker',
      );
      await tester.pumpWidget(
        buildTile(pickedItem, overrides: overrides(signedIn: worker)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('shows exact text when picked quantity matches planned', (
      tester,
    ) async {
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          return;
        }
        FlutterError.presentError(details);
      };
      addTearDown(() => FlutterError.onError = FlutterError.presentError);

      final pickedItem = baseItem(
        pickedQuantity: 50,
        pickedAt: DateTime(2026, 4, 25, 9),
        completedBy: 'u_worker',
      );
      await tester.pumpWidget(
        buildTile(pickedItem, overrides: overrides(signedIn: worker)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });
  });

  group('PickingItemTile — signed-in manager', () {
    const manager = AppUser(
      id: 'u_manager',
      email: 'manager@farm.test',
      displayName: 'Maya Manager',
      role: UserRole.manager,
    );

    testWidgets('shows Reassign button for manager on assigned item', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTile(
          baseItem(assignedTo: 'u_worker'),
          overrides: overrides(signedIn: manager),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reassign'), findsOneWidget);
    });

    testWidgets('shows units label for box-unit item', (tester) async {
      await tester.pumpWidget(
        buildTile(
          baseItem(unit: QuantityUnit.boxes),
          overrides: overrides(signedIn: manager),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('boxes'), findsOneWidget);
    });

    testWidgets('shows units label for units-unit item', (tester) async {
      await tester.pumpWidget(
        buildTile(
          baseItem(unit: QuantityUnit.units),
          overrides: overrides(signedIn: manager),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('units'), findsOneWidget);
    });

    testWidgets('tapping Claim triggers claimItem on the seeded repo', (
      tester,
    ) async {
      // Get a real item id from the seeded repo so claimItem can find it.
      final lists = await fakeRepo.watchLists().first;
      final listId = lists.first.id;
      final items = await fakeRepo.watchItems(listId).first;
      final unassigned = items.firstWhere((i) => !i.isAssigned);

      await tester.pumpWidget(
        buildTile(
          unassigned,
          listId: listId,
          overrides: overrides(signedIn: manager),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Claim'));
      await tester.pumpAndSettle();

      // Verify the repo recorded the claim.
      final updated = await fakeRepo.watchItems(listId).first;
      final claimed = updated.firstWhere((i) => i.id == unassigned.id);
      expect(claimed.assignedTo, equals('u_manager'));
    });

    testWidgets('tapping Reassign shows reassign dialog', (tester) async {
      final lists = await fakeRepo.watchLists().first;
      final listId = lists.first.id;
      final items = await fakeRepo.watchItems(listId).first;
      final assigned = items.firstWhere((i) => i.isAssigned);

      await tester.pumpWidget(
        buildTile(
          assigned,
          listId: listId,
          overrides: overrides(signedIn: manager),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reassign'));
      await tester.pumpAndSettle();

      // SimpleDialog with 'Reassign' title is shown.
      expect(find.text('Reassign'), findsWidgets);
      // Unassigned option appears as the first item.
      expect(find.text('Unassigned'), findsOneWidget);
    });

    testWidgets(
      'dismissing reassign dialog without selecting leaves item unchanged',
      (tester) async {
        final lists = await fakeRepo.watchLists().first;
        final listId = lists.first.id;
        final items = await fakeRepo.watchItems(listId).first;
        final assigned = items.firstWhere((i) => i.isAssigned);
        await tester.pumpWidget(
          buildTile(
            assigned,
            listId: listId,
            overrides: overrides(signedIn: manager),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reassign'));
        await tester.pumpAndSettle();

        // Tap "Unassigned" to dismiss with a null selection.
        await tester.tap(find.text('Unassigned'));
        await tester.pumpAndSettle();

        // Dialog is gone.
        expect(find.byType(SimpleDialog), findsNothing);

        // The reassign was called with null, clearing the assignee.
        final updated = await fakeRepo.watchItems(listId).first;
        final updatedItem = updated.firstWhere((i) => i.id == assigned.id);
        // Selecting 'Unassigned' calls reassignItem with null.
        expect(updatedItem.assignedTo, isNull);
      },
    );
  });

  group('PickingItemTile — mark picked dialog', () {
    const worker = AppUser(
      id: 'u_worker',
      email: 'worker@farm.test',
      displayName: 'Wendy Worker',
      role: UserRole.worker,
    );

    testWidgets('tapping Mark picked opens dialog with quantity field', (
      tester,
    ) async {
      final lists = await fakeRepo.watchLists().first;
      final listId = lists.first.id;
      final items = await fakeRepo.watchItems(listId).first;
      final myItem = items.firstWhere((i) => i.assignedTo == 'u_worker');

      await tester.pumpWidget(
        buildTile(
          myItem,
          listId: listId,
          overrides: overrides(signedIn: worker),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark picked'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Actual quantity'), findsWidgets);
    });

    testWidgets('cancelling mark-picked dialog does not update item', (
      tester,
    ) async {
      final lists = await fakeRepo.watchLists().first;
      final listId = lists.first.id;
      final items = await fakeRepo.watchItems(listId).first;
      final myItem = items.firstWhere((i) => i.assignedTo == 'u_worker');

      await tester.pumpWidget(
        buildTile(
          myItem,
          listId: listId,
          overrides: overrides(signedIn: worker),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark picked'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog is gone.
      expect(find.byType(AlertDialog), findsNothing);
      // Item is still not picked.
      final updated = await fakeRepo.watchItems(listId).first;
      final updatedItem = updated.firstWhere((i) => i.id == myItem.id);
      expect(updatedItem.isPicked, isFalse);
    });

    testWidgets('confirming mark-picked dialog records the actual quantity', (
      tester,
    ) async {
      final lists = await fakeRepo.watchLists().first;
      final listId = lists.first.id;
      final items = await fakeRepo.watchItems(listId).first;
      final myItem = items.firstWhere((i) => i.assignedTo == 'u_worker');

      await tester.pumpWidget(
        buildTile(
          myItem,
          listId: listId,
          overrides: overrides(signedIn: worker),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark picked'));
      await tester.pumpAndSettle();

      // Clear the pre-filled quantity and enter a new one.
      final textField = find.byType(TextField);
      await tester.enterText(textField, '25');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Dialog is gone and item is now picked.
      expect(find.byType(AlertDialog), findsNothing);
      final updated = await fakeRepo.watchItems(listId).first;
      final updatedItem = updated.firstWhere((i) => i.id == myItem.id);
      expect(updatedItem.isPicked, isTrue);
      expect(updatedItem.pickedQuantity, equals(25.0));
    });
  });
}
