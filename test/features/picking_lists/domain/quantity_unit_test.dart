import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';

void main() {
  group('QuantityUnit.fromName', () {
    test('resolves a known enum name', () {
      expect(QuantityUnit.fromName('kg'), QuantityUnit.kg);
      expect(QuantityUnit.fromName('boxes'), QuantityUnit.boxes);
      expect(QuantityUnit.fromName('units'), QuantityUnit.units);
    });

    test('falls back to units for an unknown name', () {
      expect(QuantityUnit.fromName('unknown-unit'), QuantityUnit.units);
      expect(QuantityUnit.fromName(''), QuantityUnit.units);
    });
  });
}
