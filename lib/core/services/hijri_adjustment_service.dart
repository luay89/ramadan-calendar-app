import 'package:shared_preferences/shared_preferences.dart';
import 'package:hijri/hijri_calendar.dart';

/// خدمة تعديل التقويم الهجري
/// تسمح بتعديل التاريخ الهجري بزيادة أو نقصان يوم
class HijriAdjustmentService {
  static const String _adjustmentKey = 'hijri_adjustment_days';
  static HijriAdjustmentService? _instance;

  int _adjustmentDays = 0;

  HijriAdjustmentService._();

  static HijriAdjustmentService get instance {
    _instance ??= HijriAdjustmentService._();
    return _instance!;
  }

  /// الحصول على عدد أيام التعديل الحالية
  int get adjustmentDays => _adjustmentDays;

  /// تحميل قيمة التعديل من التخزين المحلي
  Future<void> loadAdjustment() async {
    final prefs = await SharedPreferences.getInstance();
    _adjustmentDays = prefs.getInt(_adjustmentKey) ?? 0;
  }

  /// حفظ قيمة التعديل في التخزين المحلي
  Future<void> saveAdjustment(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_adjustmentKey, days);
    _adjustmentDays = days;
  }

  /// زيادة يوم واحد
  Future<void> incrementDay() async {
    await saveAdjustment(_adjustmentDays + 1);
  }

  /// نقصان يوم واحد
  Future<void> decrementDay() async {
    await saveAdjustment(_adjustmentDays - 1);
  }

  /// إعادة التعديل إلى الصفر
  Future<void> resetAdjustment() async {
    await saveAdjustment(0);
  }

  /// الحصول على التاريخ الهجري المعدل من تاريخ ميلادي
  HijriCalendar getAdjustedHijriFromGregorian(DateTime gregorian) {
    // إضافة أو طرح أيام التعديل من التاريخ الميلادي
    final adjustedGregorian = gregorian.add(Duration(days: _adjustmentDays));
    return HijriCalendar.fromDate(adjustedGregorian);
  }

  /// الحصول على التاريخ الهجري الحالي المعدل
  HijriCalendar get currentAdjustedHijri {
    return getAdjustedHijriFromGregorian(DateTime.now());
  }

  /// تحويل تاريخ هجري معدل إلى ميلادي
  DateTime hijriToGregorian(HijriCalendar hijri) {
    final gregorian = hijri.hijriToGregorian(
      hijri.hYear,
      hijri.hMonth,
      hijri.hDay,
    );
    // نطرح أيام التعديل للحصول على التاريخ الميلادي الحقيقي
    return gregorian.subtract(Duration(days: _adjustmentDays));
  }

  /// الحصول على أول يوم في الشهر الهجري مع التعديل
  DateTime getFirstDayOfHijriMonth(int year, int month) {
    final hijri = HijriCalendar();
    hijri.hYear = year;
    hijri.hMonth = month;
    hijri.hDay = 1;
    return hijriToGregorian(hijri);
  }

  /// التحقق مما إذا كان التعديل مطبقاً
  bool get hasAdjustment => _adjustmentDays != 0;

  /// الحصول على نص وصفي للتعديل
  String get adjustmentDescription {
    if (_adjustmentDays == 0) {
      return 'بدون تعديل';
    } else if (_adjustmentDays > 0) {
      return 'تقديم $_adjustmentDays ${_adjustmentDays == 1 ? "يوم" : "أيام"}';
    } else {
      return 'تأخير ${_adjustmentDays.abs()} ${_adjustmentDays.abs() == 1 ? "يوم" : "أيام"}';
    }
  }
}
