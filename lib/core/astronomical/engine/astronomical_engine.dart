import 'dart:math' as math;
import '../constants/astronomical_constants.dart';

/// محرك الحسابات الفلكية الأساسية
///
/// يحتوي على الدوال الرياضية الفلكية الأساسية:
/// - حساب موقع الشمس
/// - حساب زاوية الساعة
/// - تحويلات الإحداثيات
/// - حسابات الزمن اليولياني
class AstronomicalEngine {
  AstronomicalEngine._();

  // ══════════════════════════════════════════════════════════════════
  // دوال الزمن اليولياني
  // ══════════════════════════════════════════════════════════════════

  /// تحويل التاريخ الميلادي إلى Julian Day Number
  ///
  /// الخوارزمية من: Astronomical Algorithms by Jean Meeus
  static double dateToJulian(DateTime date) {
    int year = date.year;
    int month = date.month;
    final day =
        date.day +
        (date.hour + (date.minute + date.second / 60.0) / 60.0) / 24.0;

    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();

    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;
  }

  /// تحويل Julian Day إلى تاريخ ميلادي
  static DateTime julianToDate(double jd) {
    final z = (jd + 0.5).floor();
    final f = jd + 0.5 - z;

    int a;
    if (z < 2299161) {
      a = z;
    } else {
      final alpha = ((z - 1867216.25) / 36524.25).floor();
      a = z + 1 + alpha - (alpha / 4).floor();
    }

    final b = a + 1524;
    final c = ((b - 122.1) / 365.25).floor();
    final d = (365.25 * c).floor();
    final e = ((b - d) / 30.6001).floor();

    final day = b - d - (30.6001 * e).floor();
    final month = e < 14 ? e - 1 : e - 13;
    final year = month > 2 ? c - 4716 : c - 4715;

    final hours = f * 24;
    final hour = hours.floor();
    final minutes = (hours - hour) * 60;
    final minute = minutes.floor();
    final second = ((minutes - minute) * 60).floor();

    return DateTime(year, month, day, hour, minute, second);
  }

  /// حساب القرن اليولياني من J2000.0
  static double julianCentury(double jd) {
    return (jd - AstronomicalConstants.j2000) /
        AstronomicalConstants.julianCentury;
  }

  // ══════════════════════════════════════════════════════════════════
  // دوال حساب موقع الشمس
  // ══════════════════════════════════════════════════════════════════

  /// حساب المعادلة الشمسية المتوسطة (Mean Solar Longitude)
  static double meanSolarLongitude(double t) {
    var l0 =
        280.4664567 +
        360007.6982779 * t +
        0.03032028 * t * t +
        t * t * t / 49931 -
        t * t * t * t / 15300 -
        t * t * t * t * t / 2000000;
    return _normalizeAngle(l0);
  }

  /// حساب الشذوذ الشمسي المتوسط (Mean Anomaly of Sun)
  static double meanSolarAnomaly(double t) {
    var m =
        357.5291092 +
        35999.0502909 * t -
        0.0001536 * t * t +
        t * t * t / 24490000;
    return _normalizeAngle(m);
  }

  /// حساب انحراف مدار الأرض (Eccentricity of Earth's Orbit)
  static double earthOrbitEccentricity(double t) {
    return 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;
  }

  /// حساب معادلة المركز الشمسي (Equation of Center)
  static double sunEquationOfCenter(double t) {
    final m = meanSolarAnomaly(t);
    final mRad = m * AstronomicalConstants.deg2rad;

    return (1.9146 - 0.004817 * t - 0.000014 * t * t) * math.sin(mRad) +
        (0.019993 - 0.000101 * t) * math.sin(2 * mRad) +
        0.00029 * math.sin(3 * mRad);
  }

  /// حساب خط الطول الشمسي الحقيقي (True Solar Longitude)
  static double sunTrueLongitude(double t) {
    return _normalizeAngle(meanSolarLongitude(t) + sunEquationOfCenter(t));
  }

  /// حساب خط الطول الظاهري للشمس (Apparent Solar Longitude)
  static double sunApparentLongitude(double t) {
    final omega = 125.04 - 1934.136 * t;
    return sunTrueLongitude(t) -
        0.00569 -
        0.00478 * math.sin(omega * AstronomicalConstants.deg2rad);
  }

  /// حساب الميل المحوري للأرض (Obliquity of Ecliptic)
  static double obliquityOfEcliptic(double t) {
    final seconds =
        21.448 - 46.8150 * t - 0.00059 * t * t + 0.001813 * t * t * t;
    return 23.0 + (26.0 + seconds / 60.0) / 60.0;
  }

  /// حساب الميل المحوري المصحح (Corrected Obliquity)
  static double correctedObliquity(double t) {
    final omega = 125.04 - 1934.136 * t;
    return obliquityOfEcliptic(t) +
        0.00256 * math.cos(omega * AstronomicalConstants.deg2rad);
  }

  /// حساب الميل الشمسي (Solar Declination)
  ///
  /// هذا هو زاوية الشمس شمال أو جنوب خط الاستواء السماوي
  static double solarDeclination(double jd) {
    final t = julianCentury(jd);
    final lambda = sunApparentLongitude(t) * AstronomicalConstants.deg2rad;
    final epsilon = correctedObliquity(t) * AstronomicalConstants.deg2rad;

    return AstronomicalConstants.rad2deg *
        math.asin(math.sin(epsilon) * math.sin(lambda));
  }

  /// حساب المطلع المستقيم للشمس (Right Ascension)
  static double solarRightAscension(double jd) {
    final t = julianCentury(jd);
    final lambda = sunApparentLongitude(t) * AstronomicalConstants.deg2rad;
    final epsilon = correctedObliquity(t) * AstronomicalConstants.deg2rad;

    return AstronomicalConstants.rad2deg *
        math.atan2(math.cos(epsilon) * math.sin(lambda), math.cos(lambda));
  }

  /// حساب معادلة الزمن (Equation of Time) بالدقائق
  ///
  /// الفرق بين الزمن الشمسي الظاهري والزمن الشمسي المتوسط
  static double equationOfTime(double jd) {
    final t = julianCentury(jd);
    final l0 = meanSolarLongitude(t) * AstronomicalConstants.deg2rad;
    final e = earthOrbitEccentricity(t);
    final m = meanSolarAnomaly(t) * AstronomicalConstants.deg2rad;
    final epsilon = obliquityOfEcliptic(t) * AstronomicalConstants.deg2rad;

    var y = math.tan(epsilon / 2);
    y *= y;

    final eqTime =
        y * math.sin(2 * l0) -
        2 * e * math.sin(m) +
        4 * e * y * math.sin(m) * math.cos(2 * l0) -
        0.5 * y * y * math.sin(4 * l0) -
        1.25 * e * e * math.sin(2 * m);

    return 4 * AstronomicalConstants.rad2deg * eqTime; // تحويل إلى دقائق
  }

  // ══════════════════════════════════════════════════════════════════
  // دوال حساب زاوية الساعة
  // ══════════════════════════════════════════════════════════════════

  /// حساب زاوية الساعة للشمس عند ارتفاع معين
  ///
  /// [latitude] خط العرض بالدرجات
  /// [declination] الميل الشمسي بالدرجات
  /// [altitude] الارتفاع المطلوب بالدرجات
  ///
  /// يُرجع زاوية الساعة بالدرجات، أو null إذا كان الحدث مستحيلاً
  static double? hourAngle(
    double latitude,
    double declination,
    double altitude,
  ) {
    final latRad = latitude * AstronomicalConstants.deg2rad;
    final decRad = declination * AstronomicalConstants.deg2rad;
    final altRad = altitude * AstronomicalConstants.deg2rad;

    final cosH =
        (math.sin(altRad) - math.sin(latRad) * math.sin(decRad)) /
        (math.cos(latRad) * math.cos(decRad));

    // التحقق من أن الحدث ممكن
    if (cosH < -1 || cosH > 1) {
      return null; // الشمس لا تصل لهذا الارتفاع
    }

    return AstronomicalConstants.rad2deg * math.acos(cosH);
  }

  /// حساب وقت الزوال (Solar Noon / Transit)
  ///
  /// [jd] Julian Day للتاريخ (منتصف الليل UTC)
  /// [longitude] خط الطول بالدرجات (موجب شرقاً)
  ///
  /// يُرجع الوقت بالساعات من منتصف الليل UTC
  static double solarNoon(double jd, double longitude) {
    final t = julianCentury(jd);
    final eqTime = equationOfTime(jd);

    // الزوال المحلي = 12:00 - معادلة الزمن - (خط الطول / 15)
    var noon = 12.0 - eqTime / 60.0 - longitude / 15.0;

    // تكرار للدقة
    final jdNoon = jd + noon / 24.0;
    final eqTimeNoon = equationOfTime(jdNoon);
    noon = 12.0 - eqTimeNoon / 60.0 - longitude / 15.0;

    return noon;
  }

  /// حساب وقت حدث شمسي (شروق، غروب، فجر، عشاء)
  ///
  /// [jd] Julian Day للتاريخ
  /// [latitude] خط العرض
  /// [longitude] خط الطول
  /// [altitude] زاوية الارتفاع
  /// [afterNoon] true للأحداث بعد الزوال (غروب، عشاء)
  static double? sunTimeAtAltitude(
    double jd,
    double latitude,
    double longitude,
    double altitude,
    bool afterNoon,
  ) {
    final noon = solarNoon(jd, longitude);
    final declination = solarDeclination(jd + noon / 24.0);
    final ha = hourAngle(latitude, declination, altitude);

    if (ha == null) return null;

    final time = noon + (afterNoon ? ha : -ha) / 15.0;

    // تكرار لتحسين الدقة
    final jdTime = jd + time / 24.0;
    final decTime = solarDeclination(jdTime);
    final haTime = hourAngle(latitude, decTime, altitude);

    if (haTime == null) return null;

    return noon + (afterNoon ? haTime : -haTime) / 15.0;
  }

  // ══════════════════════════════════════════════════════════════════
  // دوال مساعدة
  // ══════════════════════════════════════════════════════════════════

  /// تطبيع الزاوية إلى النطاق [0, 360)
  static double _normalizeAngle(double angle) {
    var result = angle % 360;
    if (result < 0) result += 360;
    return result;
  }

  /// تحويل الساعات إلى DateTime
  static DateTime hoursToDateTime(DateTime date, double hours) {
    final totalSeconds = (hours * 3600).round();
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;

    var result = DateTime(date.year, date.month, date.day, h, m, s);

    // معالجة تجاوز اليوم
    if (hours >= 24) {
      result = result.add(Duration(days: (hours / 24).floor()));
    } else if (hours < 0) {
      result = result.subtract(Duration(days: (-hours / 24).floor() + 1));
    }

    return result;
  }

  /// تحويل DateTime إلى ساعات من منتصف الليل
  static double dateTimeToHours(DateTime dt) {
    return dt.hour + dt.minute / 60.0 + dt.second / 3600.0;
  }
}
