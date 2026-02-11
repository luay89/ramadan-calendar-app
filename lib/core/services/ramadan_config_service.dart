import 'package:shared_preferences/shared_preferences.dart';

/// خدمة إعدادات رمضان
/// تسمح بتعديل تاريخ بداية شهر رمضان
class RamadanConfigService {
  static const String _ramadanStartYearKey = 'ramadan_start_year';
  static const String _ramadanStartMonthKey = 'ramadan_start_month';
  static const String _ramadanStartDayKey = 'ramadan_start_day';
  static const String _ramadanHijriYearKey = 'ramadan_hijri_year';

  static RamadanConfigService? _instance;

  // القيم الافتراضية - رمضان 1447 يبدأ يوم الخميس 26 فبراير 2026
  int _startYear = 2026;
  int _startMonth = 2; // فبراير
  int _startDay = 26; // الخميس
  int _hijriYear = 1447;

  RamadanConfigService._();

  static RamadanConfigService get instance {
    _instance ??= RamadanConfigService._();
    return _instance!;
  }

  /// سنة بداية رمضان الميلادية
  int get startYear => _startYear;

  /// شهر بداية رمضان الميلادي
  int get startMonth => _startMonth;

  /// يوم بداية رمضان الميلادي
  int get startDay => _startDay;

  /// السنة الهجرية لرمضان
  int get hijriYear => _hijriYear;

  /// تاريخ بداية رمضان
  DateTime get ramadanStartDate => DateTime(_startYear, _startMonth, _startDay);

  /// اسم يوم بداية رمضان
  String get startDayName {
    final weekdays = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    return weekdays[ramadanStartDate.weekday % 7];
  }

  /// تحميل الإعدادات من التخزين المحلي
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _startYear = prefs.getInt(_ramadanStartYearKey) ?? 2026;
    _startMonth = prefs.getInt(_ramadanStartMonthKey) ?? 2;
    _startDay = prefs.getInt(_ramadanStartDayKey) ?? 26;
    _hijriYear = prefs.getInt(_ramadanHijriYearKey) ?? 1447;
  }

  /// حفظ الإعدادات في التخزين المحلي
  Future<void> saveSettings({
    required int year,
    required int month,
    required int day,
    int? hijriYear,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ramadanStartYearKey, year);
    await prefs.setInt(_ramadanStartMonthKey, month);
    await prefs.setInt(_ramadanStartDayKey, day);
    if (hijriYear != null) {
      await prefs.setInt(_ramadanHijriYearKey, hijriYear);
    }

    _startYear = year;
    _startMonth = month;
    _startDay = day;
    if (hijriYear != null) {
      _hijriYear = hijriYear;
    }
  }

  /// تعيين تاريخ بداية رمضان
  Future<void> setRamadanStart(DateTime date, {int? hijriYear}) async {
    await saveSettings(
      year: date.year,
      month: date.month,
      day: date.day,
      hijriYear: hijriYear,
    );
  }

  /// الحصول على تاريخ يوم معين من رمضان
  DateTime getRamadanDay(int day) {
    return ramadanStartDate.add(Duration(days: day - 1));
  }

  /// التحقق مما إذا كان التاريخ في رمضان
  bool isDateInRamadan(DateTime date) {
    final start = ramadanStartDate;
    final end = start.add(const Duration(days: 29)); // 30 يوم
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }

  /// الحصول على رقم اليوم في رمضان
  int? getRamadanDayNumber(DateTime date) {
    if (!isDateInRamadan(date)) return null;
    return date.difference(ramadanStartDate).inDays + 1;
  }

  /// إعادة الإعدادات إلى القيم الافتراضية
  Future<void> resetToDefaults() async {
    await saveSettings(year: 2026, month: 2, day: 26, hijriYear: 1447);
  }

  /// الحصول على معلومات رمضان كنص
  String getRamadanInfo() {
    final months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return 'رمضان $_hijriYear هـ يبدأ يوم $startDayName $_startDay ${months[_startMonth]} $_startYear م';
  }
}
