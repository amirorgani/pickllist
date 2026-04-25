// Presentation layer — GUARD-02 scopes public_member_api_docs to
// core/domain/data only.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:pickllist/features/picking_lists/domain/quantity_unit.dart';
import 'package:pickllist/l10n/generated/app_localizations.dart';

extension QuantityUnitL10n on QuantityUnit {
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
