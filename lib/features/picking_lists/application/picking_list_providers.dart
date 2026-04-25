// Application layer — GUARD-02 scopes public_member_api_docs to
// core/domain/data only.
// ignore_for_file: public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickllist/features/auth/application/auth_providers.dart';
import 'package:pickllist/features/auth/data/fake_auth_repository.dart';
import 'package:pickllist/features/picking_lists/data/fake_picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/data/firestore_picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/data/picking_list_repository.dart';
import 'package:pickllist/features/picking_lists/domain/picking_item.dart';
import 'package:pickllist/features/picking_lists/domain/picking_list.dart';

final pickingListRepositoryProvider = Provider<PickingListRepository>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  if (auth is FakeAuthRepository) {
    return FakePickingListRepository();
  }
  return FirestorePickingListRepository(FirebaseFirestore.instance);
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
