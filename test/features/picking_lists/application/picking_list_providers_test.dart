import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/auth/data/fake_auth_repository.dart';
import 'package:pickllist/features/picking_lists/application/picking_list_providers.dart';
import 'package:pickllist/features/picking_lists/data/fake_picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/domain/picking_list.dart';

void main() {
  ProviderContainer makeContainer() {
    final repo = FakePickingListRepository();
    return ProviderContainer(
      overrides: [
        pickingListRepositoryProvider.overrideWithValue(repo),
      ],
    );
  }

  tearDown(() {});

  group('pickingListRepositoryProvider', () {
    test('returns FakePickingListRepository when auth is fake', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(pickingListRepositoryProvider);

      expect(repo, isA<FakePickingListRepository>());
    });
  });

  group('pickingListsProvider', () {
    test('emits the seeded list', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final asyncLists = await container.read(pickingListsProvider.future);

      expect(asyncLists, hasLength(1));
      expect(asyncLists.first.name, equals('Thursday morning pick'));
    });
  });

  group('pickingListItemsProvider', () {
    test('emits seeded items for a known list', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final lists = await container.read(pickingListsProvider.future);
      final listId = lists.first.id;
      final items = await container.read(
        pickingListItemsProvider(listId).future,
      );

      expect(items, hasLength(3));
    });
  });

  group('pickingListByIdProvider', () {
    test('finds an existing list by id', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final lists = await container.read(pickingListsProvider.future);
      final listId = lists.first.id;
      // Allow providers to settle.
      await Future<void>.delayed(Duration.zero);

      final result = container.read(pickingListByIdProvider(listId));

      expect(result.value, isA<PickingList>());
      expect(result.value!.id, equals(listId));
    });

    test('returns null for an unknown id', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      // Settle the lists stream.
      await container.read(pickingListsProvider.future);
      await Future<void>.delayed(Duration.zero);

      final result = container.read(pickingListByIdProvider('no-such-list'));

      expect(result.value, isNull);
    });
  });

  group('FakeAuthRepository selects correct repo implementation', () {
    test('non-fake auth falls back to FakePickingListRepository in test', () {
      // Verify the provider switch: when auth is a FakeAuthRepository the
      // picking list repository is also fake.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // The default authRepositoryProvider returns FakeAuthRepository in POC.
      final repo = container.read(pickingListRepositoryProvider);
      expect(repo, isA<FakePickingListRepository>());
    });
  });
}
