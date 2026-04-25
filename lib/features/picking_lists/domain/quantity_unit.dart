enum QuantityUnit {
  units,
  kg,
  boxes;

  static QuantityUnit fromName(String name) => QuantityUnit.values.firstWhere(
    (u) => u.name == name,
    orElse: () => QuantityUnit.units,
  );
}
