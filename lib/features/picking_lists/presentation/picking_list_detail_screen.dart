import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pickllist/features/picking_lists/application/picking_list_providers.dart';
import 'package:pickllist/features/picking_lists/presentation/widgets/picking_item_tile.dart';
import 'package:pickllist/l10n/generated/app_localizations.dart';

class PickingListDetailScreen extends ConsumerWidget {
  const PickingListDetailScreen({super.key, required this.listId});
  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final listAsync = ref.watch(pickingListByIdProvider(listId));
    final itemsAsync = ref.watch(pickingListItemsProvider(listId));

    return Scaffold(
      appBar: AppBar(
        title: listAsync.maybeWhen(
          data: (list) => Text(list?.name ?? l.pickingLists),
          orElse: () => Text(l.pickingLists),
        ),
      ),
      body: Column(
        children: [
          listAsync.maybeWhen(
            data: (list) {
              if (list == null) return const SizedBox.shrink();
              final fmt = DateFormat.yMMMd(
                Localizations.localeOf(context).toLanguageTag(),
              ).add_Hm();
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${l.scheduledAt}: ${fmt.format(list.scheduledAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (items) => ListView.builder(
                itemBuilder: (_, i) =>
                    PickingItemTile(listId: listId, item: items[i]),
                itemCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
