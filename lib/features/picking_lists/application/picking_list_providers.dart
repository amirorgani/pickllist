import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickllist/features/picking_lists/data/fake_picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/data/picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/domain/picking_item.dart';
import 'package:pickllist/features/picking_lists/domain/picking_list.dart';

final pickingListRepositoryProvider = Provider<PickingListRepository>((ref) {
  // Single instance for the whole app. Swap in FirestorePickingListRepository
  // once firebase_options.dart is generated (see docs/architecture.md).
  return FakePickingListRepository();
});

final pickingListsProvider = StreamProvider<List<PickingList>>((ref) {
  return ref.watch(pickingListRepositoryProvider).watchLists();
});

final StreamProviderFamily<List<PickingItem>, String> pickingListItemsProvider =
    StreamProvider.family<List<PickingItem>, String>((ref, listId) {
      return ref.watch(pickingListRepositoryProvider).watchItems(listId);
    });

final ProviderFamily<AsyncValue<PickingList?>, String> pickingListByIdProvider =
    Provider.family<AsyncValue<PickingList?>, String>((ref, listId) {
      return ref
          .watch(pickingListsProvider)
          .whenData(
            (lists) => lists.cast<PickingList?>().firstWhere(
              (l) => l?.id == listId,
              orElse: () => null,
            ),
          );
    });
