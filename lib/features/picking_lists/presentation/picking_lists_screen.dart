// Presentation layer — GUARD-02 scopes public_member_api_docs to
// core/domain/data only.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickllist/features/auth/application/auth_providers.dart';
import 'package:pickllist/features/picking_lists/application/picking_list_providers.dart';
import 'package:pickllist/features/picking_lists/domain/picking_list.dart';
import 'package:pickllist/l10n/generated/app_localizations.dart';

class PickingListsScreen extends ConsumerWidget {
  const PickingListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lists = ref.watch(pickingListsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.pickingLists),
        actions: [
          if (user != null)
            IconButton(
              tooltip: l.signOut,
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
            ),
        ],
      ),
      body: lists.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(l.noPickingLists));
          }
          return ListView.separated(
            itemBuilder: (_, i) => _PickingListTile(list: items[i]),
            separatorBuilder: (_, _) => const Divider(height: 0),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}

class _PickingListTile extends StatelessWidget {
  const _PickingListTile({required this.list});
  final PickingList list;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheduleFmt = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_Hm();
    final statusLabel = switch (list.status) {
      PickingListStatus.draft => l.statusDraft,
      PickingListStatus.published => l.statusPublished,
      PickingListStatus.completed => l.statusCompleted,
    };
    return ListTile(
      title: Text(list.name),
      subtitle: Text('${scheduleFmt.format(list.scheduledAt)} · $statusLabel'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/lists/${list.id}'),
    );
  }
}
