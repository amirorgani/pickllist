/// Units a picking row can use for planned and actual quantities.
enum QuantityUnit {
  /// Count individual produce items.
  units,

  /// Measure weight in kilograms.
  kg,

  /// Count boxes or crates.
  boxes
  ;

  /// Parses a persisted enum [name], defaulting unknown values to [units].
  static QuantityUnit fromName(String name) => QuantityUnit.values.firstWhere(
    (u) => u.name == name,
    orElse: () => QuantityUnit.units,
  );
}
