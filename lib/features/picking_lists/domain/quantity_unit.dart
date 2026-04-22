import 'package:flutter/widgets.dart';
import 'package:pickllist/l10n/generated/app_localizations.dart';

enum QuantityUnit {
  units,
  kg,
  boxes;

  static QuantityUnit fromName(String name) => QuantityUnit.values.firstWhere(
    (u) => u.name == name,
    orElse: () => QuantityUnit.units,
  );

  String localized(BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (this) {
      case QuantityUnit.units:
        return l.unitUnits;
      case QuantityUnit.kg:
        return l.unitKg;
      case QuantityUnit.boxes:
        return l.unitBoxes;
    }
  }
}
