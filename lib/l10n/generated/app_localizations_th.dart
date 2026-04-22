// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Pickllist';

  @override
  String get signIn => 'เข้าสู่ระบบ';

  @override
  String get signOut => 'ออกจากระบบ';

  @override
  String get email => 'อีเมล';

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get loginFailed => 'เข้าสู่ระบบไม่สำเร็จ ตรวจสอบอีเมลและรหัสผ่าน';

  @override
  String get pickingLists => 'รายการเก็บเกี่ยว';

  @override
  String get noPickingLists => 'ยังไม่มีรายการเก็บเกี่ยว';

  @override
  String get newList => 'รายการใหม่';

  @override
  String get listName => 'ชื่อรายการ';

  @override
  String get scheduledAt => 'กำหนดเวลา';

  @override
  String get status => 'สถานะ';

  @override
  String get statusDraft => 'ร่าง';

  @override
  String get statusPublished => 'เผยแพร่';

  @override
  String get statusCompleted => 'เสร็จสมบูรณ์';

  @override
  String get item => 'รายการ';

  @override
  String get quantity => 'จำนวน';

  @override
  String get unit => 'หน่วย';

  @override
  String get unitUnits => 'หน่วย';

  @override
  String get unitKg => 'กิโลกรัม';

  @override
  String get unitBoxes => 'ลัง';

  @override
  String get note => 'หมายเหตุ';

  @override
  String get assignedTo => 'ผู้รับผิดชอบ';

  @override
  String get unassigned => 'ยังไม่มีผู้รับผิดชอบ';

  @override
  String get claim => 'รับผิดชอบ';

  @override
  String get reassign => 'มอบหมายใหม่';

  @override
  String get markPicked => 'ทำเครื่องหมายว่าเก็บเกี่ยวแล้ว';

  @override
  String get actualQuantity => 'จำนวนจริง';

  @override
  String get difference => 'ส่วนต่าง';

  @override
  String overBy(String amount) {
    return 'เกิน $amount';
  }

  @override
  String underBy(String amount) {
    return 'ขาด $amount';
  }

  @override
  String get exactMatch => 'ตรงตามจำนวน';

  @override
  String completedAt(String time) {
    return 'เสร็จเมื่อ $time';
  }

  @override
  String get crops => 'พืชผล';

  @override
  String get users => 'ผู้ใช้';

  @override
  String get templates => 'เทมเพลต';

  @override
  String get history => 'ประวัติ';

  @override
  String get importFromExcel => 'นำเข้าจาก Excel';

  @override
  String get language => 'ภาษา';

  @override
  String get english => 'English';

  @override
  String get hebrew => 'עברית';

  @override
  String get thai => 'ภาษาไทย';

  @override
  String get save => 'บันทึก';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get delete => 'ลบ';

  @override
  String get edit => 'แก้ไข';

  @override
  String get add => 'เพิ่ม';
}
