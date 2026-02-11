import 'package:adhan/adhan.dart';
import '../constants/app_constants.dart';

/// أدوات حساب مواقيت الصلاة وفق المذهب الجعفري
class PrayerTimeUtils {
  PrayerTimeUtils._();

  /// الحصول على مواقيت الصلاة لتاريخ ومكان محددين
  static PrayerTimes getPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
  }) {
    final coordinates = Coordinates(latitude, longitude);
    final params = _getJafariCalculationParameters();
    final dateComponents = DateComponents.from(date);

    return PrayerTimes(coordinates, dateComponents, params);
  }

  /// معاملات الحساب الجعفري
  static CalculationParameters _getJafariCalculationParameters() {
    // استخدام معاملات مخصصة للمذهب الجعفري
    final params = CalculationMethod.tehran.getParameters();

    // تعديل الزوايا للمذهب الجعفري
    params.fajrAngle = AppConstants.fajrAngle;
    params.ishaAngle = AppConstants.ishaAngle;

    // إضافة تأخير للمغرب (4 دقائق بعد غروب الشمس)
    params.adjustments.maghrib = 4;

    // تعديل طريقة حساب منتصف الليل
    params.highLatitudeRule = HighLatitudeRule.middle_of_the_night;

    return params;
  }

  /// الحصول على وقت السحور (قبل الفجر بـ 10 دقائق)
  static DateTime getSuhoorTime(PrayerTimes prayerTimes) {
    return prayerTimes.fajr.subtract(const Duration(minutes: 10));
  }

  /// الحصول على وقت الإفطار (وقت المغرب)
  static DateTime getIftarTime(PrayerTimes prayerTimes) {
    return prayerTimes.maghrib;
  }

  /// الحصول على وقت منتصف الليل الشرعي
  static DateTime getMidnightTime(PrayerTimes prayerTimes) {
    // منتصف الليل الشرعي = (المغرب + الفجر) / 2
    final maghrib = prayerTimes.maghrib;
    final nextFajr = prayerTimes.fajr.add(const Duration(days: 1));
    final diff = nextFajr.difference(maghrib);
    return maghrib.add(Duration(minutes: diff.inMinutes ~/ 2));
  }

  /// الحصول على وقت الثلث الأخير من الليل
  static DateTime getLastThirdOfNight(PrayerTimes prayerTimes) {
    final maghrib = prayerTimes.maghrib;
    final nextFajr = prayerTimes.fajr.add(const Duration(days: 1));
    final diff = nextFajr.difference(maghrib);
    return maghrib.add(Duration(minutes: (diff.inMinutes * 2) ~/ 3));
  }

  /// الحصول على اسم الصلاة الحالية
  static String getCurrentPrayerName(PrayerTimes prayerTimes) {
    final now = DateTime.now();

    if (now.isBefore(prayerTimes.fajr)) {
      return 'قبل الفجر';
    } else if (now.isBefore(prayerTimes.sunrise)) {
      return 'الفجر';
    } else if (now.isBefore(prayerTimes.dhuhr)) {
      return 'الشروق';
    } else if (now.isBefore(prayerTimes.asr)) {
      return 'الظهر';
    } else if (now.isBefore(prayerTimes.maghrib)) {
      return 'العصر';
    } else if (now.isBefore(prayerTimes.isha)) {
      return 'المغرب';
    } else {
      return 'العشاء';
    }
  }

  /// الحصول على الصلاة القادمة
  static MapEntry<String, DateTime> getNextPrayer(PrayerTimes prayerTimes) {
    final now = DateTime.now();

    if (now.isBefore(prayerTimes.fajr)) {
      return MapEntry('الفجر', prayerTimes.fajr);
    } else if (now.isBefore(prayerTimes.sunrise)) {
      return MapEntry('الشروق', prayerTimes.sunrise);
    } else if (now.isBefore(prayerTimes.dhuhr)) {
      return MapEntry('الظهر', prayerTimes.dhuhr);
    } else if (now.isBefore(prayerTimes.asr)) {
      return MapEntry('العصر', prayerTimes.asr);
    } else if (now.isBefore(prayerTimes.maghrib)) {
      return MapEntry('المغرب', prayerTimes.maghrib);
    } else if (now.isBefore(prayerTimes.isha)) {
      return MapEntry('العشاء', prayerTimes.isha);
    } else {
      // الفجر في اليوم التالي
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowPrayers = getPrayerTimes(
        date: tomorrow,
        latitude: prayerTimes.coordinates.latitude,
        longitude: prayerTimes.coordinates.longitude,
      );
      return MapEntry('الفجر', tomorrowPrayers.fajr);
    }
  }

  /// الحصول على الوقت المتبقي للصلاة القادمة
  static Duration getTimeUntilNextPrayer(PrayerTimes prayerTimes) {
    final nextPrayer = getNextPrayer(prayerTimes);
    return nextPrayer.value.difference(DateTime.now());
  }

  /// تحويل الدقائق إلى تنسيق مقروء
  static String formatRemainingTime(Duration duration) {
    if (duration.isNegative) return 'حان الوقت';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// الحصول على قائمة أوقات الصلاة
  static Map<String, DateTime> getAllPrayerTimes(PrayerTimes prayerTimes) {
    return {
      'الفجر': prayerTimes.fajr,
      'الشروق': prayerTimes.sunrise,
      'الظهر': prayerTimes.dhuhr,
      'العصر': prayerTimes.asr,
      'المغرب': prayerTimes.maghrib,
      'العشاء': prayerTimes.isha,
    };
  }
}
