import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../services/hijri_adjustment_service.dart';

/// أدوات التاريخ الهجري والميلادي
class AppDateUtils {
  AppDateUtils._();

  /// خدمة تعديل التقويم الهجري
  static HijriAdjustmentService get _adjustmentService =>
      HijriAdjustmentService.instance;

  /// الحصول على التاريخ الهجري الحالي (مع تطبيق التعديل)
  static HijriCalendar get currentHijri =>
      _adjustmentService.currentAdjustedHijri;

  /// الحصول على التاريخ الميلادي الحالي
  static DateTime get currentGregorian => DateTime.now();

  /// تحويل تاريخ ميلادي إلى هجري (مع تطبيق التعديل)
  static HijriCalendar gregorianToHijri(DateTime date) {
    return _adjustmentService.getAdjustedHijriFromGregorian(date);
  }

  /// تحويل تاريخ هجري إلى ميلادي (مع تطبيق التعديل)
  static DateTime hijriToGregorian(HijriCalendar hijri) {
    return _adjustmentService.hijriToGregorian(hijri);
  }

  /// الحصول على عدد أيام تعديل التقويم الهجري
  static int get hijriAdjustmentDays => _adjustmentService.adjustmentDays;

  /// تعديل التقويم الهجري بعدد أيام معين
  static Future<void> setHijriAdjustment(int days) async {
    await _adjustmentService.saveAdjustment(days);
  }

  /// زيادة يوم في التقويم الهجري
  static Future<void> incrementHijriDay() async {
    await _adjustmentService.incrementDay();
  }

  /// نقصان يوم في التقويم الهجري
  static Future<void> decrementHijriDay() async {
    await _adjustmentService.decrementDay();
  }

  /// إعادة تعديل التقويم الهجري إلى الصفر
  static Future<void> resetHijriAdjustment() async {
    await _adjustmentService.resetAdjustment();
  }

  /// تحميل تعديل التقويم الهجري من التخزين
  static Future<void> loadHijriAdjustment() async {
    await _adjustmentService.loadAdjustment();
  }

  /// الحصول على وصف تعديل التقويم الهجري
  static String get hijriAdjustmentDescription =>
      _adjustmentService.adjustmentDescription;

  /// تنسيق التاريخ الهجري بالعربية
  static String formatHijriArabic(HijriCalendar hijri) {
    final monthName = HijriMonths.arabicNames[hijri.hMonth - 1];
    return '${hijri.hDay} $monthName ${hijri.hYear}';
  }

  /// تنسيق التاريخ الميلادي بالعربية
  static String formatGregorianArabic(DateTime date) {
    return DateFormat('d MMMM yyyy', 'ar').format(date);
  }

  /// تنسيق التاريخ الكامل (هجري + ميلادي)
  static String formatFullDate(DateTime date) {
    final hijri = gregorianToHijri(date);
    return '${formatHijriArabic(hijri)} - ${formatGregorianArabic(date)}';
  }

  /// الحصول على اسم اليوم بالعربية
  static String getDayNameArabic(DateTime date) {
    return WeekDays.arabicNames[date.weekday % 7];
  }

  /// الحصول على اسم الشهر الهجري
  static String getHijriMonthName(int month) {
    if (month < 1 || month > 12) return '';
    return HijriMonths.arabicNames[month - 1];
  }

  /// التحقق من ليلة الجمعة (ليلة الخميس)
  static bool isFridayNight(DateTime date) {
    return date.weekday == DateTime.thursday;
  }

  /// التحقق من الليالي البيض
  static bool isWhiteNight(HijriCalendar hijri) {
    return SpecialNights.whitNights.contains(hijri.hDay);
  }

  /// التحقق من ليالي القدر
  static bool isLaylatalQadrNight(HijriCalendar hijri) {
    return hijri.hMonth == HijriMonths.ramadan &&
        SpecialNights.laylatalQadrNights.contains(hijri.hDay);
  }

  /// التحقق من شهر رمضان
  static bool isRamadan(HijriCalendar hijri) {
    return hijri.hMonth == HijriMonths.ramadan;
  }

  /// التحقق من شهر رجب
  static bool isRajab(HijriCalendar hijri) {
    return hijri.hMonth == HijriMonths.rajab;
  }

  /// التحقق من شهر شعبان
  static bool isShaban(HijriCalendar hijri) {
    return hijri.hMonth == HijriMonths.shaban;
  }

  /// الحصول على عدد أيام الشهر الهجري
  static int getHijriMonthDays(int year, int month) {
    final hijri = HijriCalendar();
    return hijri.getDaysInMonth(year, month);
  }

  /// الحصول على أول يوم في الشهر الهجري (مع تطبيق التعديل)
  static DateTime getFirstDayOfHijriMonth(int year, int month) {
    return _adjustmentService.getFirstDayOfHijriMonth(year, month);
  }

  /// الحصول على الأيام المتبقية في رمضان
  static int? getRemainingRamadanDays() {
    final hijri = currentHijri;
    if (hijri.hMonth != HijriMonths.ramadan) return null;
    return getHijriMonthDays(hijri.hYear, HijriMonths.ramadan) - hijri.hDay;
  }

  /// تنسيق الوقت
  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a', 'ar').format(time);
  }

  /// تنسيق الوقت بصيغة 24 ساعة
  static String formatTime24(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// الحصول على الفرق بين وقتين
  static Duration getTimeDifference(DateTime from, DateTime to) {
    return to.difference(from);
  }

  /// تنسيق المدة الزمنية
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours ساعة و $minutes دقيقة';
    }
    return '$minutes دقيقة';
  }
}
