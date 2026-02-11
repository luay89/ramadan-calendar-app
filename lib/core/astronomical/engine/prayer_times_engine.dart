import 'dart:math' as math;
import '../constants/astronomical_constants.dart';
import 'astronomical_engine.dart';

/// محرك حساب مواقيت الصلاة الدقيق
///
/// يعتمد على الحسابات الفلكية الداخلية بدون API خارجي
/// يدعم المذهب الجعفري وجميع طرق الحساب الأخرى
class PrayerTimesEngine {
  /// إعدادات الحساب
  final PrayerCalculationSettings settings;

  PrayerTimesEngine({required this.settings});

  /// حساب جميع مواقيت الصلاة ليوم معين
  ///
  /// [date] التاريخ المطلوب
  /// [latitude] خط العرض بالدرجات
  /// [longitude] خط الطول بالدرجات
  /// [timezone] فرق المنطقة الزمنية بالساعات من UTC
  CalculatedPrayerTimes calculate(
    DateTime date,
    double latitude,
    double longitude,
    double timezone,
  ) {
    // Julian Day لمنتصف ليل UTC
    final jd = AstronomicalEngine.dateToJulian(
      DateTime.utc(date.year, date.month, date.day),
    );

    // حساب الأوقات بـ UTC
    final fajrUTC = _calculateFajr(jd, latitude, longitude);
    final sunriseUTC = _calculateSunrise(jd, latitude, longitude);
    final dhuhrUTC = _calculateDhuhr(jd, longitude);
    final asrUTC = _calculateAsr(jd, latitude, longitude, dhuhrUTC);
    final sunsetUTC = _calculateSunset(jd, latitude, longitude);
    final maghribUTC = _calculateMaghrib(jd, latitude, longitude, sunsetUTC);
    final ishaUTC = _calculateIsha(jd, latitude, longitude);

    // تحويل إلى التوقيت المحلي
    final localDate = DateTime(date.year, date.month, date.day);

    DateTime? toLocal(double? utcHours) {
      if (utcHours == null) return null;
      var localHours = utcHours + timezone;
      return AstronomicalEngine.hoursToDateTime(localDate, localHours);
    }

    // حساب منتصف الليل والثلث الأخير
    final midnight = _calculateMidnight(
      maghribUTC ?? sunsetUTC,
      fajrUTC,
      settings.midnightMethod,
    );

    final lastThird = _calculateLastThird(maghribUTC ?? sunsetUTC, fajrUTC);

    // تطبيق التعديلات اليدوية
    DateTime? applyAdjustment(DateTime? time, int minutes) {
      if (time == null) return null;
      return time.add(Duration(minutes: minutes));
    }

    return CalculatedPrayerTimes(
      date: date,
      fajr: applyAdjustment(toLocal(fajrUTC), settings.adjustments.fajr),
      sunrise: applyAdjustment(
        toLocal(sunriseUTC),
        settings.adjustments.sunrise,
      ),
      dhuhr: applyAdjustment(toLocal(dhuhrUTC), settings.adjustments.dhuhr),
      asr: applyAdjustment(toLocal(asrUTC), settings.adjustments.asr),
      sunset: toLocal(sunsetUTC),
      maghrib: applyAdjustment(
        toLocal(maghribUTC),
        settings.adjustments.maghrib,
      ),
      isha: applyAdjustment(toLocal(ishaUTC), settings.adjustments.isha),
      midnight: toLocal(midnight != null ? midnight + timezone : null),
      lastThird: toLocal(lastThird != null ? lastThird + timezone : null),
      calculationMethod: settings.method,
      location: GeoLocation(
        latitude: latitude,
        longitude: longitude,
        timezone: timezone,
      ),
    );
  }

  /// حساب وقت الفجر
  double? _calculateFajr(double jd, double latitude, double longitude) {
    final angle = -settings.fajrAngle;
    var fajr = AstronomicalEngine.sunTimeAtAltitude(
      jd,
      latitude,
      longitude,
      angle,
      false,
    );

    // معالجة خطوط العرض العالية
    fajr ??= _adjustForHighLatitude(jd, latitude, longitude, angle, false);

    return fajr;
  }

  /// حساب وقت الشروق
  double? _calculateSunrise(double jd, double latitude, double longitude) {
    return AstronomicalEngine.sunTimeAtAltitude(
      jd,
      latitude,
      longitude,
      AstronomicalConstants.sunriseAngle,
      false,
    );
  }

  /// حساب وقت الظهر (الزوال)
  double _calculateDhuhr(double jd, double longitude) {
    return AstronomicalEngine.solarNoon(jd, longitude);
  }

  /// حساب وقت العصر
  double? _calculateAsr(
    double jd,
    double latitude,
    double longitude,
    double dhuhr,
  ) {
    final declination = AstronomicalEngine.solarDeclination(jd + dhuhr / 24.0);
    final latRad = latitude * AstronomicalConstants.deg2rad;
    final decRad = declination * AstronomicalConstants.deg2rad;

    // حساب زاوية ظل العصر
    final shadowFactor =
        settings.asrCalculation == AsrCalculation.hanafi ? 2.0 : 1.0;

    // طول الظل عند الزوال
    final noonShadow = math.tan((latRad - decRad).abs());

    // زاوية الارتفاع عند العصر
    final asrAltitude =
        AstronomicalConstants.rad2deg *
        math.atan(1 / (shadowFactor + noonShadow));

    return AstronomicalEngine.sunTimeAtAltitude(
      jd,
      latitude,
      longitude,
      asrAltitude,
      true,
    );
  }

  /// حساب وقت الغروب
  double? _calculateSunset(double jd, double latitude, double longitude) {
    return AstronomicalEngine.sunTimeAtAltitude(
      jd,
      latitude,
      longitude,
      AstronomicalConstants.sunriseAngle,
      true,
    );
  }

  /// حساب وقت المغرب
  double? _calculateMaghrib(
    double jd,
    double latitude,
    double longitude,
    double? sunset,
  ) {
    if (settings.maghribAngle != null) {
      // استخدام زاوية خاصة (مثل طريقة طهران)
      return AstronomicalEngine.sunTimeAtAltitude(
        jd,
        latitude,
        longitude,
        -settings.maghribAngle!,
        true,
      );
    }

    // المغرب = الغروب + التأخير (المذهب الجعفري: 4 دقائق)
    if (sunset == null) return null;
    return sunset + settings.maghribDelay / 60.0;
  }

  /// حساب وقت العشاء
  double? _calculateIsha(double jd, double latitude, double longitude) {
    if (settings.ishaInterval != null) {
      // أم القرى: العشاء = المغرب + 90 دقيقة
      final maghrib = _calculateMaghrib(
        jd,
        latitude,
        longitude,
        _calculateSunset(jd, latitude, longitude),
      );
      if (maghrib == null) return null;
      return maghrib + settings.ishaInterval! / 60.0;
    }

    final angle = -settings.ishaAngle;
    var isha = AstronomicalEngine.sunTimeAtAltitude(
      jd,
      latitude,
      longitude,
      angle,
      true,
    );

    // معالجة خطوط العرض العالية
    isha ??= _adjustForHighLatitude(jd, latitude, longitude, angle, true);

    return isha;
  }

  /// حساب منتصف الليل
  double? _calculateMidnight(
    double? maghrib,
    double? fajr,
    MidnightMethod method,
  ) {
    if (maghrib == null) return null;

    if (method == MidnightMethod.jafari) {
      // منتصف الليل الشرعي: بين المغرب والفجر
      if (fajr == null) return null;
      var duration = fajr - maghrib;
      if (duration < 0) duration += 24;
      return maghrib + duration / 2;
    } else {
      // منتصف الليل الفلكي: بين الغروب والشروق (تقريب: 6 ساعات بعد المغرب)
      return maghrib + 6.0;
    }
  }

  /// حساب الثلث الأخير من الليل
  double? _calculateLastThird(double? maghrib, double? fajr) {
    if (maghrib == null || fajr == null) return null;

    var nightDuration = fajr - maghrib;
    if (nightDuration < 0) nightDuration += 24;

    return maghrib + (nightDuration * 2 / 3);
  }

  /// تعديل للمناطق ذات خطوط العرض العالية
  double? _adjustForHighLatitude(
    double jd,
    double latitude,
    double longitude,
    double angle,
    bool afterNoon,
  ) {
    switch (settings.highLatitudeRule) {
      case HighLatitudeRule.none:
        return null;

      case HighLatitudeRule.middleOfNight:
        // استخدام نسبة من نصف الليل
        final sunrise = _calculateSunrise(jd, latitude, longitude);
        final sunset = _calculateSunset(jd, latitude, longitude);
        if (sunrise == null || sunset == null) return null;

        var nightDuration = sunrise - sunset;
        if (nightDuration < 0) nightDuration += 24;
        final portion = angle.abs() / 60.0;

        if (afterNoon) {
          return sunset + nightDuration * portion;
        } else {
          return sunrise - nightDuration * portion;
        }

      case HighLatitudeRule.seventhOfNight:
        // سُبع الليل
        final sunrise = _calculateSunrise(jd, latitude, longitude);
        final sunset = _calculateSunset(jd, latitude, longitude);
        if (sunrise == null || sunset == null) return null;

        var nightDuration = sunrise - sunset;
        if (nightDuration < 0) nightDuration += 24;

        if (afterNoon) {
          return sunset + nightDuration / 7;
        } else {
          return sunrise - nightDuration / 7;
        }

      case HighLatitudeRule.twilightAngle:
        // استخدام زاوية شفق أصغر
        final twilightAngle = latitude > 0 ? -4.0 : -4.0;
        return AstronomicalEngine.sunTimeAtAltitude(
          jd,
          latitude,
          longitude,
          twilightAngle,
          afterNoon,
        );
    }
  }
}

/// إعدادات حساب مواقيت الصلاة
class PrayerCalculationSettings {
  /// طريقة الحساب
  final CalculationMethod method;

  /// زاوية الفجر
  final double fajrAngle;

  /// زاوية العشاء
  final double ishaAngle;

  /// زاوية المغرب (اختياري)
  final double? maghribAngle;

  /// تأخير المغرب بالدقائق
  final int maghribDelay;

  /// فترة العشاء بالدقائق (لأم القرى)
  final int? ishaInterval;

  /// طريقة حساب العصر
  final AsrCalculation asrCalculation;

  /// طريقة حساب منتصف الليل
  final MidnightMethod midnightMethod;

  /// قاعدة خطوط العرض العالية
  final HighLatitudeRule highLatitudeRule;

  /// التعديلات اليدوية
  final PrayerAdjustments adjustments;

  const PrayerCalculationSettings({
    this.method = CalculationMethod.jafari,
    this.fajrAngle = AstronomicalConstants.fajrAngleJafari,
    this.ishaAngle = AstronomicalConstants.ishaAngleJafari,
    this.maghribAngle,
    this.maghribDelay = AstronomicalConstants.maghribDelayJafari,
    this.ishaInterval,
    this.asrCalculation = AsrCalculation.standard,
    this.midnightMethod = MidnightMethod.jafari,
    this.highLatitudeRule = HighLatitudeRule.middleOfNight,
    this.adjustments = const PrayerAdjustments(),
  });

  /// إعدادات المذهب الجعفري
  factory PrayerCalculationSettings.jafari() {
    return const PrayerCalculationSettings(
      method: CalculationMethod.jafari,
      fajrAngle: 16.0,
      ishaAngle: 14.0,
      maghribDelay: 4,
      asrCalculation: AsrCalculation.standard,
      midnightMethod: MidnightMethod.jafari,
    );
  }

  /// إعدادات طهران
  factory PrayerCalculationSettings.tehran() {
    return const PrayerCalculationSettings(
      method: CalculationMethod.tehran,
      fajrAngle: 17.7,
      ishaAngle: 14.0,
      maghribAngle: 4.5,
      maghribDelay: 0,
    );
  }

  /// إعدادات رابطة العالم الإسلامي
  factory PrayerCalculationSettings.mwl() {
    return const PrayerCalculationSettings(
      method: CalculationMethod.mwl,
      fajrAngle: 18.0,
      ishaAngle: 17.0,
      maghribDelay: 0,
    );
  }

  /// إعدادات أم القرى
  factory PrayerCalculationSettings.ummAlQura() {
    return const PrayerCalculationSettings(
      method: CalculationMethod.ummAlQura,
      fajrAngle: 18.5,
      ishaAngle: 0,
      ishaInterval: 90,
      maghribDelay: 0,
    );
  }

  /// نسخ مع تعديلات
  PrayerCalculationSettings copyWith({
    CalculationMethod? method,
    double? fajrAngle,
    double? ishaAngle,
    double? maghribAngle,
    int? maghribDelay,
    int? ishaInterval,
    AsrCalculation? asrCalculation,
    MidnightMethod? midnightMethod,
    HighLatitudeRule? highLatitudeRule,
    PrayerAdjustments? adjustments,
  }) {
    return PrayerCalculationSettings(
      method: method ?? this.method,
      fajrAngle: fajrAngle ?? this.fajrAngle,
      ishaAngle: ishaAngle ?? this.ishaAngle,
      maghribAngle: maghribAngle ?? this.maghribAngle,
      maghribDelay: maghribDelay ?? this.maghribDelay,
      ishaInterval: ishaInterval ?? this.ishaInterval,
      asrCalculation: asrCalculation ?? this.asrCalculation,
      midnightMethod: midnightMethod ?? this.midnightMethod,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      adjustments: adjustments ?? this.adjustments,
    );
  }
}

/// التعديلات اليدوية لأوقات الصلاة (بالدقائق)
class PrayerAdjustments {
  final int fajr;
  final int sunrise;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;

  const PrayerAdjustments({
    this.fajr = 0,
    this.sunrise = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.isha = 0,
  });

  PrayerAdjustments copyWith({
    int? fajr,
    int? sunrise,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? isha,
  }) {
    return PrayerAdjustments(
      fajr: fajr ?? this.fajr,
      sunrise: sunrise ?? this.sunrise,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }
}

/// نتيجة حساب مواقيت الصلاة
class CalculatedPrayerTimes {
  final DateTime date;
  final DateTime? fajr;
  final DateTime? sunrise;
  final DateTime? dhuhr;
  final DateTime? asr;
  final DateTime? sunset;
  final DateTime? maghrib;
  final DateTime? isha;
  final DateTime? midnight;
  final DateTime? lastThird;
  final CalculationMethod calculationMethod;
  final GeoLocation location;

  const CalculatedPrayerTimes({
    required this.date,
    this.fajr,
    this.sunrise,
    this.dhuhr,
    this.asr,
    this.sunset,
    this.maghrib,
    this.isha,
    this.midnight,
    this.lastThird,
    required this.calculationMethod,
    required this.location,
  });

  /// الحصول على الصلاة الحالية
  Prayer currentPrayer(DateTime now) {
    if (isha != null && now.isAfter(isha!)) return Prayer.isha;
    if (maghrib != null && now.isAfter(maghrib!)) return Prayer.maghrib;
    if (asr != null && now.isAfter(asr!)) return Prayer.asr;
    if (dhuhr != null && now.isAfter(dhuhr!)) return Prayer.dhuhr;
    if (sunrise != null && now.isAfter(sunrise!)) return Prayer.sunrise;
    if (fajr != null && now.isAfter(fajr!)) return Prayer.fajr;
    return Prayer.isha; // قبل الفجر
  }

  /// الحصول على الصلاة القادمة
  Prayer nextPrayer(DateTime now) {
    if (fajr != null && now.isBefore(fajr!)) return Prayer.fajr;
    if (sunrise != null && now.isBefore(sunrise!)) return Prayer.sunrise;
    if (dhuhr != null && now.isBefore(dhuhr!)) return Prayer.dhuhr;
    if (asr != null && now.isBefore(asr!)) return Prayer.asr;
    if (maghrib != null && now.isBefore(maghrib!)) return Prayer.maghrib;
    if (isha != null && now.isBefore(isha!)) return Prayer.isha;
    return Prayer.fajr; // الفجر التالي
  }

  /// الحصول على وقت الصلاة القادمة
  DateTime? nextPrayerTime(DateTime now) {
    final next = nextPrayer(now);
    return timeForPrayer(next);
  }

  /// الحصول على وقت صلاة معينة
  DateTime? timeForPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return fajr;
      case Prayer.sunrise:
        return sunrise;
      case Prayer.dhuhr:
        return dhuhr;
      case Prayer.asr:
        return asr;
      case Prayer.maghrib:
        return maghrib;
      case Prayer.isha:
        return isha;
    }
  }
}

/// أسماء الصلوات
enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension PrayerExtension on Prayer {
  String get arabicName {
    switch (this) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
    }
  }
}

/// الموقع الجغرافي
class GeoLocation {
  final double latitude;
  final double longitude;
  final double timezone;
  final String? name;

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.name,
  });
}
