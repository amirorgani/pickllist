import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/picking_lists/domain/picking_item.dart';
import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';

void main() {
  PickingItem seed() => const PickingItem(
    id: 'i1',
    cropId: 'c1',
    cropName: 'Tomatoes',
    quantity: 100,
    unit: QuantityUnit.kg,
    note: 'base note',
    assignedTo: 'u_worker',
    pickedQuantity: 95,
    completedBy: 'u_worker',
  );

  group('PickingItem.copyWith — clear flags', () {
    test('clearPickedQuantity sets pickedQuantity to null', () {
      final cleared = seed().copyWith(clearPickedQuantity: true);

      expect(cleared.pickedQuantity, isNull);
      expect(cleared.cropName, equals('Tomatoes'));
    });

    test('clearPickedAt sets pickedAt to null', () {
      final withPickedAt = seed().copyWith(
        pickedAt: DateTime(2026, 4),
      );
      final cleared = withPickedAt.copyWith(clearPickedAt: true);

      expect(cleared.pickedAt, isNull);
      expect(cleared.isPicked, isFalse);
    });

    test('clearCompletedBy sets completedBy to null', () {
      final cleared = seed().copyWith(clearCompletedBy: true);

      expect(cleared.completedBy, isNull);
      expect(cleared.cropId, equals('c1'));
    });

    test('copyWith can update unit independently', () {
      final updated = seed().copyWith(unit: QuantityUnit.boxes);

      expect(updated.unit, equals(QuantityUnit.boxes));
      expect(updated.quantity, equals(100));
    });

    test('copyWith can update cropId and cropName', () {
      final updated = seed().copyWith(
        cropId: 'c2',
        cropName: 'Cucumbers',
        quantity: 30,
      );

      expect(updated.cropId, equals('c2'));
      expect(updated.cropName, equals('Cucumbers'));
      expect(updated.quantity, equals(30));
    });
  });

  group('PickingItem equality and hashCode', () {
    test('two identical items are equal', () {
      final a = seed();
      final b = seed();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('items with different assignedTo are not equal', () {
      final a = seed();
      final b = seed().copyWith(assignedTo: 'u_manager');

      expect(a, isNot(equals(b)));
    });
  });

  group('PickingItem.fromMap handles null optional fields', () {
    test('fromMap with all nulls for optional fields', () {
      final item = PickingItem.fromMap({
        'id': 'i2',
        'cropId': 'c2',
        'cropName': 'Peppers',
        'quantity': 10,
        'unit': 'boxes',
        'note': null,
        'assignedTo': null,
        'pickedQuantity': null,
        'pickedAt': null,
        'completedBy': null,
      });

      expect(item.id, equals('i2'));
      expect(item.note, isNull);
      expect(item.assignedTo, isNull);
      expect(item.isPicked, isFalse);
      expect(item.isAssigned, isFalse);
      expect(item.difference, isNull);
    });
  });
}
