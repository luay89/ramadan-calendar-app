import '../engine/prayer_times_engine.dart';
import '../engine/hijri_calendar_engine.dart';
import '../settings/location_settings.dart';
import '../settings/calibration_settings.dart';

/// خدمة حساب التقويم ومواقيت الصلاة الموحدة
///
/// تجمع بين:
/// - محرك الحساب الفلكي
/// - محرك التقويم الهجري
/// - محرك مواقيت الصلاة
/// - إعدادات الموقع والمعايرة
class AstronomicalService {
  final LocationSettings location;
  final CalibrationSettings calibration;

  late final HijriCalendarEngine _hijriEngine;
  late final PrayerTimesEngine _prayerEngine;

  AstronomicalService({required this.location, required this.calibration}) {
    _hijriEngine = HijriCalendarEngine(
      dayAdjustment: calibration.hijriDayAdjustment,
    );
    _prayerEngine = PrayerTimesEngine(settings: calibration.toPrayerSettings());
  }

  // =================== التقويم الهجري ===================

  /// تحويل من ميلادي إلى هجري
  HijriDate toHijri(DateTime gregorian) {
    return _hijriEngine.gregorianToHijri(gregorian);
  }

  /// تحويل من هجري إلى ميلادي
  DateTime toGregorian(HijriDate hijri) {
    return _hijriEngine.hijriToGregorian(hijri);
  }

  /// التاريخ الهجري اليوم
  HijriDate get todayHijri => toHijri(DateTime.now());

  /// عدد أيام الشهر الهجري
  int daysInMonth(int year, int month) {
    return _hijriEngine.daysInHijriMonth(year, month);
  }

  /// يوم الأسبوع للتاريخ الهجري (0 = الأحد)
  int dayOfWeek(HijriDate hijri) {
    return _hijriEngine.dayOfWeek(hijri);
  }

  /// عمر الهلال عند الغروب (بالساعات)
  double moonAge(DateTime date) {
    return _hijriEngine.moonAgeAtSunset(
      date,
      location.latitude,
      location.longitude,
    );
  }

  /// تاريخ الاقتران (المحاق) التالي
  DateTime nextNewMoon() {
    return _hijriEngine.nextNewMoon(DateTime.now());
  }

  /// تاريخ البدر التالي
  DateTime nextFullMoon() {
    return _hijriEngine.nextFullMoon(DateTime.now());
  }

  // =================== مواقيت الصلاة ===================

  /// حساب مواقيت الصلاة ليوم معين
  CalculatedPrayerTimes getPrayerTimes(DateTime date) {
    return _prayerEngine.calculate(
      date,
      location.latitude,
      location.longitude,
      location.timezone,
    );
  }

  /// مواقيت الصلاة لليوم
  CalculatedPrayerTimes get todayPrayerTimes => getPrayerTimes(DateTime.now());

  /// مواقيت الصلاة لغد
  CalculatedPrayerTimes get tomorrowPrayerTimes {
    return getPrayerTimes(DateTime.now().add(const Duration(days: 1)));
  }

  /// الصلاة الحالية
  Prayer currentPrayer() {
    return todayPrayerTimes.currentPrayer(DateTime.now());
  }

  /// الصلاة القادمة
  Prayer nextPrayer() {
    final now = DateTime.now();
    final today = todayPrayerTimes;
    final next = today.nextPrayer(now);

    // إذا كان الفجر التالي، احسب من مواقيت الغد
    if (next == Prayer.fajr && today.isha != null && now.isAfter(today.isha!)) {
      return Prayer.fajr;
    }

    return next;
  }

  /// وقت الصلاة القادمة
  DateTime? nextPrayerTime() {
    final now = DateTime.now();
    final today = todayPrayerTimes;
    final nextTime = today.nextPrayerTime(now);

    // إذا لم يكن هناك وقت (بعد العشاء)، أرجع فجر الغد
    if (nextTime == null || nextTime.isBefore(now)) {
      return tomorrowPrayerTimes.fajr;
    }

    return nextTime;
  }

  /// الوقت المتبقي للصلاة القادمة
  Duration? timeUntilNextPrayer() {
    final next = nextPrayerTime();
    if (next == null) return null;
    return next.difference(DateTime.now());
  }

  // =================== مواقيت شهر كامل ===================

  /// مواقيت الصلاة لشهر ميلادي كامل
  List<CalculatedPrayerTimes> getMonthPrayerTimes(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final times = <CalculatedPrayerTimes>[];

    for (int day = 1; day <= daysInMonth; day++) {
      times.add(getPrayerTimes(DateTime(year, month, day)));
    }

    return times;
  }

  /// إمساكية شهر رمضان
  List<ImsakiyaDay> getRamadanImsakiya(int hijriYear) {
    final ramadanDays = <ImsakiyaDay>[];

    for (int day = 1; day <= 30; day++) {
      final hijriDate = HijriDate(year: hijriYear, month: 9, day: day);
      final gregorian = toGregorian(hijriDate);
      final times = getPrayerTimes(gregorian);

      // التحقق من أن اليوم لا يزال في رمضان
      final checkHijri = toHijri(gregorian);
      if (checkHijri.month != 9) break;

      ramadanDays.add(
        ImsakiyaDay(
          day: day,
          hijriDate: hijriDate,
          gregorianDate: gregorian,
          imsak: times.fajr?.subtract(const Duration(minutes: 10)),
          fajr: times.fajr,
          sunrise: times.sunrise,
          dhuhr: times.dhuhr,
          asr: times.asr,
          maghrib: times.maghrib,
          isha: times.isha,
        ),
      );
    }

    return ramadanDays;
  }

  // =================== أوقات خاصة ===================

  /// وقت السحر (الثلث الأخير من الليل)
  DateTime? saharTime(DateTime date) {
    final times = getPrayerTimes(date);
    return times.lastThird;
  }

  /// منتصف الليل الشرعي
  DateTime? midnightTime(DateTime date) {
    final times = getPrayerTimes(date);
    return times.midnight;
  }

  /// هل نحن في وقت الصلاة؟
  bool isPrayerTime(
    Prayer prayer, {
    Duration tolerance = const Duration(minutes: 10),
  }) {
    final times = todayPrayerTimes;
    final prayerTime = times.timeForPrayer(prayer);
    if (prayerTime == null) return false;

    final now = DateTime.now();
    final diff = now.difference(prayerTime).abs();
    return diff <= tolerance;
  }

  // =================== المناسبات الإسلامية ===================

  /// هل هذا اليوم من ليالي القدر المحتملة؟
  bool isLailatAlQadrCandidate(HijriDate hijri) {
    if (hijri.month != 9) return false; // رمضان فقط
    return const [19, 21, 23, 25, 27, 29].contains(hijri.day);
  }

  /// هل هذا اليوم عيد الفطر؟
  bool isEidAlFitr(HijriDate hijri) {
    return hijri.month == 10 && hijri.day == 1;
  }

  /// هل هذا اليوم عيد الأضحى؟
  bool isEidAlAdha(HijriDate hijri) {
    return hijri.month == 12 && hijri.day == 10;
  }

  /// هل هذا اليوم من أيام التشريق؟
  bool isTashreeqDay(HijriDate hijri) {
    return hijri.month == 12 && hijri.day >= 11 && hijri.day <= 13;
  }

  /// هل هذا اليوم يوم عاشوراء؟
  bool isAshura(HijriDate hijri) {
    return hijri.month == 1 && hijri.day == 10;
  }

  /// هل هذا اليوم يوم الأربعين؟
  bool isArbaeen(HijriDate hijri) {
    return hijri.month == 2 && hijri.day == 20;
  }

  /// هل هذا اليوم ميلاد النبي صلى الله عليه وآله؟
  bool isMawlidProphet(HijriDate hijri) {
    // 17 ربيع الأول عند الشيعة
    return hijri.month == 3 && hijri.day == 17;
  }

  /// هل هذا اليوم ليلة النصف من شعبان؟
  bool isMidShaban(HijriDate hijri) {
    return hijri.month == 8 && hijri.day == 15;
  }

  /// إنشاء خدمة جديدة مع إعدادات معدلة
  AstronomicalService copyWith({
    LocationSettings? location,
    CalibrationSettings? calibration,
  }) {
    return AstronomicalService(
      location: location ?? this.location,
      calibration: calibration ?? this.calibration,
    );
  }
}

/// يوم في الإمساكية
class ImsakiyaDay {
  final int day;
  final HijriDate hijriDate;
  final DateTime gregorianDate;
  final DateTime? imsak;
  final DateTime? fajr;
  final DateTime? sunrise;
  final DateTime? dhuhr;
  final DateTime? asr;
  final DateTime? maghrib;
  final DateTime? isha;

  const ImsakiyaDay({
    required this.day,
    required this.hijriDate,
    required this.gregorianDate,
    this.imsak,
    this.fajr,
    this.sunrise,
    this.dhuhr,
    this.asr,
    this.maghrib,
    this.isha,
  });

  /// مدة الصيام
  Duration? get fastingDuration {
    if (imsak == null || maghrib == null) return null;
    return maghrib!.difference(imsak!);
  }

  /// مدة الليل
  Duration? get nightDuration {
    if (maghrib == null || fajr == null) return null;
    var fajrNext = fajr!.add(const Duration(days: 1));
    return fajrNext.difference(maghrib!);
  }
}
