// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'רשימת קטיף';

  @override
  String get signIn => 'התחבר';

  @override
  String get signOut => 'התנתק';

  @override
  String get email => 'דוא\"ל';

  @override
  String get password => 'סיסמה';

  @override
  String get loginFailed => 'ההתחברות נכשלה. בדוק את הדוא\"ל והסיסמה.';

  @override
  String get pickingLists => 'רשימות קטיף';

  @override
  String get noPickingLists => 'אין עדיין רשימות קטיף.';

  @override
  String get newList => 'רשימה חדשה';

  @override
  String get listName => 'שם הרשימה';

  @override
  String get scheduledAt => 'מתוכנן ל-';

  @override
  String get status => 'סטטוס';

  @override
  String get statusDraft => 'טיוטה';

  @override
  String get statusPublished => 'פורסם';

  @override
  String get statusCompleted => 'הושלם';

  @override
  String get item => 'פריט';

  @override
  String get quantity => 'כמות';

  @override
  String get unit => 'יחידה';

  @override
  String get unitUnits => 'יחידות';

  @override
  String get unitKg => 'ק\"ג';

  @override
  String get unitBoxes => 'ארגזים';

  @override
  String get note => 'הערה';

  @override
  String get assignedTo => 'אחראי';

  @override
  String get unassigned => 'לא שויך';

  @override
  String get claim => 'קח אחריות';

  @override
  String get reassign => 'שייך מחדש';

  @override
  String get markPicked => 'סמן כנקטף';

  @override
  String get actualQuantity => 'כמות בפועל';

  @override
  String get difference => 'הפרש';

  @override
  String overBy(String amount) {
    return 'עודף של $amount';
  }

  @override
  String underBy(String amount) {
    return 'חסר $amount';
  }

  @override
  String get exactMatch => 'בדיוק';

  @override
  String completedAt(String time) {
    return 'הושלם בשעה $time';
  }

  @override
  String get crops => 'גידולים';

  @override
  String get users => 'משתמשים';

  @override
  String get templates => 'תבניות';

  @override
  String get history => 'היסטוריה';

  @override
  String get importFromExcel => 'ייבוא מאקסל';

  @override
  String get language => 'שפה';

  @override
  String get english => 'English';

  @override
  String get hebrew => 'עברית';

  @override
  String get thai => 'ภาษาไทย';

  @override
  String get save => 'שמור';

  @override
  String get cancel => 'בטל';

  @override
  String get confirm => 'אישור';

  @override
  String get delete => 'מחק';

  @override
  String get edit => 'ערוך';

  @override
  String get add => 'הוסף';
}
