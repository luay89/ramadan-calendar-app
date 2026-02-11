import '../constants/astronomical_constants.dart';
import 'astronomical_engine.dart';
import 'dart:math' as math;

/// محرك التقويم الهجري الدقيق
///
/// يعتمد على الحساب الفلكي لدورة القمر
/// يدعم التعديل اليدوي (±أيام) للمعايرة
class HijriCalendarEngine {
  /// تعديل أيام الهجري (موجب = تقديم، سالب = تأخير)
  final int dayAdjustment;

  HijriCalendarEngine({this.dayAdjustment = 0});

  /// تحويل من ميلادي إلى هجري
  HijriDate gregorianToHijri(DateTime gregorian) {
    final jd = AstronomicalEngine.dateToJulian(gregorian);
    return _julianToHijri(jd + dayAdjustment);
  }

  /// تحويل من هجري إلى ميلادي
  DateTime hijriToGregorian(HijriDate hijri) {
    final jd = _hijriToJulian(hijri);
    return AstronomicalEngine.julianToDate(jd - dayAdjustment);
  }

  /// حساب Julian Day من تاريخ هجري
  /// خوارزمية محسنة من Astronomical Algorithms
  double _hijriToJulian(HijriDate hijri) {
    final y = hijri.year;
    final m = hijri.month;
    final d = hijri.day;

    // خوارزمية تحويل الهجري إلى Julian Day
    // الصيغة الصحيحة من: https://www.fourmilab.ch/documents/calendar/
    // JD = floor((11 * Y + 3) / 30) + 354 * Y + 30 * M - floor((M - 1) / 2) + D + 1948440 - 385

    final jd =
        ((11 * y + 3) / 30).floor() +
        354 * y +
        30 * m -
        ((m - 1) / 2).floor() +
        d +
        1948440 -
        385;

    return jd.toDouble();
  }

  /// حساب تاريخ هجري من Julian Day
  HijriDate _julianToHijri(double jd) {
    final l =
        (jd - AstronomicalConstants.hijriEpoch + 0.5).floor() + 10632 + 14;
    final n = ((l - 1) / 10631).floor();
    final l1 = l - 10631 * n + 354;
    final j =
        ((10985 - l1) / 5316).floor() * ((50 * l1) / 17719).floor() +
        (l1 / 5670).floor() * ((43 * l1) / 15238).floor();
    final l2 =
        l1 -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;
    final m = ((24 * l2) / 709).floor();
    final d = l2 - ((709 * m) / 24).floor();
    final y = 30 * n + j - 30;

    return HijriDate(year: y, month: m, day: d);
  }

  /// عدد أيام الشهر الهجري
  int daysInHijriMonth(int year, int month) {
    // الأشهر الفردية 30 يوم، الزوجية 29 يوم
    // ذو الحجة في السنة الكبيسة 30 يوم
    if (month == 12 && _isHijriLeapYear(year)) {
      return 30;
    }
    return month.isOdd ? 30 : 29;
  }

  /// هل السنة الهجرية كبيسة؟
  bool _isHijriLeapYear(int year) {
    // دورة 30 سنة: السنوات 2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29 كبيسة
    final remainder = year % 30;
    return const [2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29].contains(remainder);
  }

  /// عدد أيام السنة الهجرية
  int daysInHijriYear(int year) {
    return _isHijriLeapYear(year) ? 355 : 354;
  }

  /// أيام الأسبوع
  int dayOfWeek(HijriDate hijri) {
    final jd = _hijriToJulian(hijri);
    return ((jd + 1.5) % 7).toInt();
  }

  /// حساب عمر الهلال عند غروب الشمس
  ///
  /// [gregorian] التاريخ الميلادي
  /// [latitude] خط العرض
  /// [longitude] خط الطول
  /// Returns: عمر الهلال بالساعات
  double moonAgeAtSunset(
    DateTime gregorian,
    double latitude,
    double longitude,
  ) {
    final jd = AstronomicalEngine.dateToJulian(gregorian);

    // حساب وقت الغروب
    final sunset = AstronomicalEngine.sunTimeAtAltitude(
      jd,
      latitude,
      longitude,
      AstronomicalConstants.sunriseAngle,
      true,
    );

    if (sunset == null) return 0;

    final jdSunset = jd + sunset / 24.0;

    // حساب طور القمر
    final moonPhase = _calculateMoonPhase(jdSunset);

    // عمر الهلال = الزمن منذ آخر اقتران
    return moonPhase * AstronomicalConstants.lunarMonth * 24; // بالساعات
  }

  /// حساب طور القمر (0 = محاق، 0.5 = بدر)
  double _calculateMoonPhase(double jd) {
    final t = AstronomicalEngine.julianCentury(jd);

    // معادلات حساب القمر المبسطة
    final D =
        297.8501921 +
        445267.1114034 * t -
        0.0018819 * t * t +
        t * t * t / 545868.0 -
        t * t * t * t / 113065000.0;

    final M =
        357.5291092 +
        35999.0502909 * t -
        0.0001536 * t * t +
        t * t * t / 24490000.0;

    final Mp =
        134.9633964 +
        477198.8675055 * t +
        0.0087414 * t * t +
        t * t * t / 69699.0 -
        t * t * t * t / 14712000.0;

    // تحويل إلى راديان
    final Dr = D * AstronomicalConstants.deg2rad;
    final Mr = M * AstronomicalConstants.deg2rad;
    final Mpr = Mp * AstronomicalConstants.deg2rad;

    // حساب الطور
    var i =
        180 -
        D -
        6.289 * math.sin(Mpr) +
        2.100 * math.sin(Mr) -
        1.274 * math.sin(2 * Dr - Mpr) -
        0.658 * math.sin(2 * Dr) -
        0.214 * math.sin(2 * Mpr) -
        0.110 * math.sin(Dr);

    i = _normalizeAngle(i);

    return i / 360.0;
  }

  /// حساب تاريخ الاقتران (المحاق) التالي
  DateTime nextNewMoon(DateTime after) {
    final jd = AstronomicalEngine.dateToJulian(after);
    var phase = _calculateMoonPhase(jd);

    // البحث عن المحاق التالي
    var searchJd = jd;
    while (phase > 0.01 && phase < 0.99) {
      searchJd += 0.5;
      phase = _calculateMoonPhase(searchJd);
    }

    return AstronomicalEngine.julianToDate(searchJd);
  }

  /// حساب تاريخ البدر التالي
  DateTime nextFullMoon(DateTime after) {
    final jd = AstronomicalEngine.dateToJulian(after);
    var phase = _calculateMoonPhase(jd);

    // البحث عن البدر (الطور ~0.5)
    var searchJd = jd;
    while ((phase - 0.5).abs() > 0.01) {
      searchJd += 0.5;
      phase = _calculateMoonPhase(searchJd);
    }

    return AstronomicalEngine.julianToDate(searchJd);
  }

  double _normalizeAngle(double angle) {
    var result = angle % 360;
    if (result < 0) result += 360;
    return result;
  }
}

/// التاريخ الهجري
class HijriDate {
  final int year;
  final int month;
  final int day;

  const HijriDate({required this.year, required this.month, required this.day});

  /// اسم الشهر بالعربي
  String get monthName => hijriMonthNames[month - 1];

  /// اسم الشهر مختصر
  String get monthShortName => hijriMonthShortNames[month - 1];

  /// التنسيق العربي
  String toArabicString() => '$day $monthName $year هـ';

  /// التنسيق المختصر
  String toShortString() => '$day/$month/$year';

  @override
  String toString() => 'HijriDate($year-$month-$day)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HijriDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;

  /// مقارنة التواريخ
  bool isBefore(HijriDate other) {
    if (year != other.year) return year < other.year;
    if (month != other.month) return month < other.month;
    return day < other.day;
  }

  bool isAfter(HijriDate other) => other.isBefore(this);

  bool isSameDay(HijriDate other) =>
      year == other.year && month == other.month && day == other.day;
}

/// أسماء الأشهر الهجرية
const List<String> hijriMonthNames = [
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الثاني',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

/// أسماء الأشهر الهجرية مختصرة
const List<String> hijriMonthShortNames = [
  'مح',
  'صف',
  'رب١',
  'رب٢',
  'جم١',
  'جم٢',
  'رج',
  'شع',
  'رم',
  'شو',
  'ذق',
  'ذح',
];

/// أسماء أيام الأسبوع
const List<String> weekDayNames = [
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];

/// أسماء أيام الأسبوع مختصرة
const List<String> weekDayShortNames = [
  'أح',
  'اث',
  'ثل',
  'أر',
  'خم',
  'جم',
  'سب',
];

/// امتداد للتاريخ الميلادي
extension DateTimeHijriExtension on DateTime {
  /// تحويل إلى هجري
  HijriDate toHijri({int adjustment = 0}) {
    final engine = HijriCalendarEngine(dayAdjustment: adjustment);
    return engine.gregorianToHijri(this);
  }
}

/// امتداد للتاريخ الهجري
extension HijriDateExtension on HijriDate {
  /// تحويل إلى ميلادي
  DateTime toGregorian({int adjustment = 0}) {
    final engine = HijriCalendarEngine(dayAdjustment: adjustment);
    return engine.hijriToGregorian(this);
  }
}
