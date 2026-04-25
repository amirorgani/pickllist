import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pickllist/features/auth/application/auth_providers.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';
import 'package:pickllist/features/picking_lists/application/picking_list_providers.dart';
import 'package:pickllist/features/picking_lists/domain/picking_item.dart';
import 'package:pickllist/features/picking_lists/presentation/widgets/quantity_unit_l10n.dart';
import 'package:pickllist/features/users/application/user_directory_providers.dart';
import 'package:pickllist/l10n/generated/app_localizations.dart';

class PickingItemTile extends ConsumerWidget {
  const PickingItemTile({super.key, required this.listId, required this.item});

  final String listId;
  final PickingItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final me = ref.watch(currentUserProvider);
    final users =
        ref.watch(userDirectoryProvider).valueOrNull ?? const <AppUser>[];
    final assignee = users.byId(item.assignedTo);
    final qty = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(item.quantity);
    final unit = item.unit.localized(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.cropName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (item.isPicked)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const SizedBox(height: 4),
            Text('${l.quantity}: $qty $unit'),
            if (item.note?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text('${l.note}: ${item.note}'),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  assignee == null ? Icons.person_outline : Icons.person,
                  size: 18,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Text(assignee?.displayName ?? l.unassigned),
                const Spacer(),
                _ActionsRow(listId: listId, item: item, me: me, users: users),
              ],
            ),
            if (item.isPicked) ...[
              const Divider(height: 20),
              _PickedSummary(item: item),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionsRow extends ConsumerWidget {
  const _ActionsRow({
    required this.listId,
    required this.item,
    required this.me,
    required this.users,
  });

  final String listId;
  final PickingItem item;
  final AppUser? me;
  final List<AppUser> users;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (me == null) return const SizedBox.shrink();
    final repo = ref.read(pickingListRepositoryProvider);
    final canReassign = me!.isManager || item.assignedTo == me!.id;
    final canClaim = !item.isAssigned;

    return Wrap(
      spacing: 8,
      children: [
        if (canClaim)
          TextButton.icon(
            icon: const Icon(Icons.pan_tool_alt, size: 18),
            label: Text(l.claim),
            onPressed: () =>
                repo.claimItem(listId: listId, itemId: item.id, userId: me!.id),
          ),
        if (canReassign && !item.isPicked)
          TextButton.icon(
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: Text(l.reassign),
            onPressed: () => _showReassignDialog(context, ref),
          ),
        if (!item.isPicked && item.assignedTo == me!.id)
          FilledButton.icon(
            icon: const Icon(Icons.task_alt, size: 18),
            label: Text(l.markPicked),
            onPressed: () => _showMarkPickedDialog(context, ref),
          ),
      ],
    );
  }

  Future<void> _showReassignDialog(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final selected = await showDialog<AppUser?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.reassign),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(l.unassigned),
          ),
          for (final u in users.where(
            (u) => u.role == UserRole.worker || u.isManager,
          ))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, u),
              child: Text(u.displayName),
            ),
        ],
      ),
    );
    if (!context.mounted) return;
    await ref
        .read(pickingListRepositoryProvider)
        .reassignItem(
          listId: listId,
          itemId: item.id,
          newAssigneeId: selected?.id,
        );
  }

  Future<void> _showMarkPickedDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: item.quantity.toString());
    final result = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.markPicked),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l.actualQuantity),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
              Navigator.pop(ctx, v);
            },
            child: Text(l.confirm),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted || me == null) return;
    await ref
        .read(pickingListRepositoryProvider)
        .markPicked(
          listId: listId,
          itemId: item.id,
          actualQuantity: result,
          byUserId: me!.id,
        );
  }
}

class _PickedSummary extends StatelessWidget {
  const _PickedSummary({required this.item});
  final PickingItem item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFmt = NumberFormat.decimalPattern(locale);
    final timeFmt = DateFormat.Hm(locale);
    final diff = item.difference;
    final diffText = diff == null
        ? ''
        : diff == 0
        ? l.exactMatch
        : diff > 0
        ? l.overBy(numberFmt.format(diff))
        : l.underBy(numberFmt.format(-diff));
    final diffColor = diff == null
        ? null
        : diff == 0
        ? Colors.green
        : diff > 0
        ? Colors.orange
        : Colors.red;

    return Row(
      children: [
        Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(l.completedAt(timeFmt.format(item.pickedAt!))),
        const SizedBox(width: 16),
        Text(
          '${l.actualQuantity}: ${numberFmt.format(item.pickedQuantity)} ${item.unit.localized(context)}',
        ),
        const Spacer(),
        if (diffText.isNotEmpty)
          Text(
            diffText,
            style: TextStyle(color: diffColor, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}
