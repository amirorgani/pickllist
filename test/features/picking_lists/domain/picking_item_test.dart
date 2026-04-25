import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/picking_lists/domain/picking_item.dart';
import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';

void main() {
  PickingItem seed({double? picked}) => PickingItem(
    id: 'i1',
    cropId: 'c1',
    cropName: 'Tomatoes',
    quantity: 100,
    unit: QuantityUnit.kg,
    pickedQuantity: picked,
    pickedAt: picked == null ? null : DateTime(2026),
  );

  group('PickingItem.difference', () {
    test('is null while not picked', () {
      expect(seed().difference, isNull);
      expect(seed().isPicked, isFalse);
    });

    test('is zero on exact match', () {
      expect(seed(picked: 100).difference, 0);
    });

    test('is positive when over-picked', () {
      expect(seed(picked: 120).difference, 20);
    });

    test('is negative when under-picked', () {
      expect(seed(picked: 80).difference, -20);
    });
  });

  group('PickingItem.copyWith', () {
    test('clearAssignedTo wipes the current assignee', () {
      final withAssignee = seed().copyWith(assignedTo: 'u1');
      expect(withAssignee.assignedTo, 'u1');

      final cleared = withAssignee.copyWith(clearAssignedTo: true);
      expect(cleared.assignedTo, isNull);
      expect(cleared.isAssigned, isFalse);
    });

    test('preserves unrelated fields', () {
      final base = seed();
      final updated = base.copyWith(note: 'wet field');
      expect(updated.note, 'wet field');
      expect(updated.quantity, base.quantity);
      expect(updated.cropName, base.cropName);
    });
  });

  test('fromMap/toMap round-trips all fields', () {
    final original = PickingItem(
      id: 'x',
      cropId: 'c',
      cropName: 'Peppers',
      quantity: 12.5,
      unit: QuantityUnit.boxes,
      note: 'n',
      assignedTo: 'u9',
      pickedQuantity: 10,
      pickedAt: DateTime.utc(2026, 4, 22, 8, 30),
      completedBy: 'u9',
    );
    final round = PickingItem.fromMap(original.toMap());
    expect(round, equals(original));
  });
}
