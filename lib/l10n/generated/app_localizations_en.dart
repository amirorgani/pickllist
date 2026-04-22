// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pickllist';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginFailed => 'Could not sign in. Check your email and password.';

  @override
  String get pickingLists => 'Picking lists';

  @override
  String get noPickingLists => 'No picking lists yet.';

  @override
  String get newList => 'New list';

  @override
  String get listName => 'List name';

  @override
  String get scheduledAt => 'Scheduled for';

  @override
  String get status => 'Status';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPublished => 'Published';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get item => 'Item';

  @override
  String get quantity => 'Quantity';

  @override
  String get unit => 'Unit';

  @override
  String get unitUnits => 'units';

  @override
  String get unitKg => 'kg';

  @override
  String get unitBoxes => 'boxes';

  @override
  String get note => 'Note';

  @override
  String get assignedTo => 'Assigned to';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get claim => 'Claim';

  @override
  String get reassign => 'Reassign';

  @override
  String get markPicked => 'Mark picked';

  @override
  String get actualQuantity => 'Actual quantity';

  @override
  String get difference => 'Difference';

  @override
  String overBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String underBy(String amount) {
    return 'Under by $amount';
  }

  @override
  String get exactMatch => 'Exact';

  @override
  String completedAt(String time) {
    return 'Completed at $time';
  }

  @override
  String get crops => 'Crops';

  @override
  String get users => 'Users';

  @override
  String get templates => 'Templates';

  @override
  String get history => 'History';

  @override
  String get importFromExcel => 'Import from Excel';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hebrew => 'עברית';

  @override
  String get thai => 'ภาษาไทย';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';
}
