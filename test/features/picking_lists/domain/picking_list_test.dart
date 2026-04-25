import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/picking_lists/domain/picking_list.dart';

void main() {
  final list = PickingList(
    id: 'list_1',
    name: 'Morning pick',
    scheduledAt: DateTime.utc(2026, 4, 25, 6),
    status: PickingListStatus.published,
    createdBy: 'u_manager',
    updatedAt: DateTime.utc(2026, 4, 24, 12),
  );

  test('PickingListStatus.fromName falls back to draft', () {
    expect(
      PickingListStatus.fromName('completed'),
      PickingListStatus.completed,
    );
    expect(PickingListStatus.fromName('unknown'), PickingListStatus.draft);
  });

  test('fromMap and toMap round-trip all list fields', () {
    final roundTrip = PickingList.fromMap(list.toMap());

    expect(roundTrip, list);
    expect(roundTrip.hashCode, list.hashCode);
  });

  test('copyWith replaces selected fields only', () {
    final updated = list.copyWith(
      name: 'Afternoon pick',
      status: PickingListStatus.completed,
    );

    expect(updated.id, list.id);
    expect(updated.name, 'Afternoon pick');
    expect(updated.status, PickingListStatus.completed);
    expect(updated.updatedAt, list.updatedAt);
  });
}
