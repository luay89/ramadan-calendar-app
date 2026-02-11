import 'package:hive/hive.dart';
import '../constants/astronomical_constants.dart';
import '../engine/prayer_times_engine.dart';

part 'calibration_settings.g.dart';

/// إعدادات المعايرة والتعديل
///
/// يسمح بـ:
/// - تعديل أيام التقويم الهجري (±30 يوم)
/// - تعديل أوقات الصلاة (±30 دقيقة لكل صلاة)
/// - اختيار طريقة الحساب
/// - ضبط معاملات العصر ومنتصف الليل
@HiveType(typeId: 51)
class CalibrationSettings extends HiveObject {
  // =================== إعدادات التقويم الهجري ===================

  /// تعديل أيام الهجري (موجب = تقديم، سالب = تأخير)
  @HiveField(0)
  int hijriDayAdjustment;

  // =================== إعدادات مواقيت الصلاة ===================

  /// طريقة الحساب
  @HiveField(1)
  String calculationMethodName;

  /// زاوية الفجر المخصصة (عند استخدام طريقة مخصصة)
  @HiveField(2)
  double? customFajrAngle;

  /// زاوية العشاء المخصصة
  @HiveField(3)
  double? customIshaAngle;

  /// زاوية المغرب المخصصة (طهران فقط)
  @HiveField(4)
  double? customMaghribAngle;

  /// تأخير المغرب بالدقائق
  @HiveField(5)
  int maghribDelay;

  /// فترة العشاء بالدقائق (أم القرى)
  @HiveField(6)
  int? ishaInterval;

  /// طريقة حساب العصر
  @HiveField(7)
  String asrCalculationName;

  /// طريقة حساب منتصف الليل
  @HiveField(8)
  String midnightMethodName;

  /// قاعدة خطوط العرض العالية
  @HiveField(9)
  String highLatitudeRuleName;

  // =================== تعديلات يدوية لأوقات الصلاة ===================

  /// تعديل وقت الفجر (دقائق)
  @HiveField(10)
  int fajrAdjustment;

  /// تعديل وقت الشروق (دقائق)
  @HiveField(11)
  int sunriseAdjustment;

  /// تعديل وقت الظهر (دقائق)
  @HiveField(12)
  int dhuhrAdjustment;

  /// تعديل وقت العصر (دقائق)
  @HiveField(13)
  int asrAdjustment;

  /// تعديل وقت المغرب (دقائق)
  @HiveField(14)
  int maghribAdjustment;

  /// تعديل وقت العشاء (دقائق)
  @HiveField(15)
  int ishaAdjustment;

  CalibrationSettings({
    this.hijriDayAdjustment = 0,
    this.calculationMethodName = 'jafari',
    this.customFajrAngle,
    this.customIshaAngle,
    this.customMaghribAngle,
    this.maghribDelay = 4,
    this.ishaInterval,
    this.asrCalculationName = 'standard',
    this.midnightMethodName = 'jafari',
    this.highLatitudeRuleName = 'middleOfNight',
    this.fajrAdjustment = 0,
    this.sunriseAdjustment = 0,
    this.dhuhrAdjustment = 0,
    this.asrAdjustment = 0,
    this.maghribAdjustment = 0,
    this.ishaAdjustment = 0,
  });

  /// الإعدادات الافتراضية للمذهب الجعفري
  factory CalibrationSettings.jafariDefault() {
    return CalibrationSettings(
      calculationMethodName: 'jafari',
      maghribDelay: 4,
      midnightMethodName: 'jafari',
    );
  }

  /// الحصول على طريقة الحساب
  CalculationMethod get calculationMethod {
    return CalculationMethod.values.firstWhere(
      (m) => m.name == calculationMethodName,
      orElse: () => CalculationMethod.jafari,
    );
  }

  /// تعيين طريقة الحساب
  set calculationMethod(CalculationMethod method) {
    calculationMethodName = method.name;
  }

  /// الحصول على طريقة حساب العصر
  AsrCalculation get asrCalculation {
    return AsrCalculation.values.firstWhere(
      (m) => m.name == asrCalculationName,
      orElse: () => AsrCalculation.standard,
    );
  }

  /// تعيين طريقة حساب العصر
  set asrCalculation(AsrCalculation method) {
    asrCalculationName = method.name;
  }

  /// الحصول على طريقة منتصف الليل
  MidnightMethod get midnightMethod {
    return MidnightMethod.values.firstWhere(
      (m) => m.name == midnightMethodName,
      orElse: () => MidnightMethod.jafari,
    );
  }

  /// تعيين طريقة منتصف الليل
  set midnightMethod(MidnightMethod method) {
    midnightMethodName = method.name;
  }

  /// الحصول على قاعدة خطوط العرض العالية
  HighLatitudeRule get highLatitudeRule {
    return HighLatitudeRule.values.firstWhere(
      (m) => m.name == highLatitudeRuleName,
      orElse: () => HighLatitudeRule.middleOfNight,
    );
  }

  /// تعيين قاعدة خطوط العرض العالية
  set highLatitudeRule(HighLatitudeRule rule) {
    highLatitudeRuleName = rule.name;
  }

  /// تحويل إلى إعدادات حساب مواقيت الصلاة
  PrayerCalculationSettings toPrayerSettings() {
    final method = calculationMethod;

    double fajrAngle;
    double ishaAngle;
    double? maghribAngle;
    int ishaInt = 0;

    switch (method) {
      case CalculationMethod.jafari:
        fajrAngle = AstronomicalConstants.fajrAngleJafari;
        ishaAngle = AstronomicalConstants.ishaAngleJafari;
        break;
      case CalculationMethod.tehran:
        fajrAngle = 17.7;
        ishaAngle = 14.0;
        maghribAngle = 4.5;
        break;
      case CalculationMethod.mwl:
        fajrAngle = AstronomicalConstants.fajrAngleMWL;
        ishaAngle = AstronomicalConstants.ishaAngleMWL;
        break;
      case CalculationMethod.isna:
        fajrAngle = 15.0;
        ishaAngle = 15.0;
        break;
      case CalculationMethod.egyptian:
        fajrAngle = AstronomicalConstants.fajrAngleEgyptian;
        ishaAngle = AstronomicalConstants.ishaAngleEgyptian;
        break;
      case CalculationMethod.ummAlQura:
        fajrAngle = AstronomicalConstants.fajrAngleUmmAlQura;
        ishaAngle = 0;
        ishaInt = 90;
        break;
      case CalculationMethod.karachi:
        fajrAngle = 18.0;
        ishaAngle = 18.0;
        break;
      case CalculationMethod.custom:
        fajrAngle = customFajrAngle ?? 16.0;
        ishaAngle = customIshaAngle ?? 14.0;
        maghribAngle = customMaghribAngle;
        break;
    }

    return PrayerCalculationSettings(
      method: method,
      fajrAngle: fajrAngle,
      ishaAngle: ishaAngle,
      maghribAngle: maghribAngle,
      maghribDelay: maghribDelay,
      ishaInterval: ishaInterval ?? (ishaInt > 0 ? ishaInt : null),
      asrCalculation: asrCalculation,
      midnightMethod: midnightMethod,
      highLatitudeRule: highLatitudeRule,
      adjustments: PrayerAdjustments(
        fajr: fajrAdjustment,
        sunrise: sunriseAdjustment,
        dhuhr: dhuhrAdjustment,
        asr: asrAdjustment,
        maghrib: maghribAdjustment,
        isha: ishaAdjustment,
      ),
    );
  }

  /// نسخ مع تعديلات
  CalibrationSettings copyWith({
    int? hijriDayAdjustment,
    String? calculationMethodName,
    double? customFajrAngle,
    double? customIshaAngle,
    double? customMaghribAngle,
    int? maghribDelay,
    int? ishaInterval,
    String? asrCalculationName,
    String? midnightMethodName,
    String? highLatitudeRuleName,
    int? fajrAdjustment,
    int? sunriseAdjustment,
    int? dhuhrAdjustment,
    int? asrAdjustment,
    int? maghribAdjustment,
    int? ishaAdjustment,
  }) {
    return CalibrationSettings(
      hijriDayAdjustment: hijriDayAdjustment ?? this.hijriDayAdjustment,
      calculationMethodName:
          calculationMethodName ?? this.calculationMethodName,
      customFajrAngle: customFajrAngle ?? this.customFajrAngle,
      customIshaAngle: customIshaAngle ?? this.customIshaAngle,
      customMaghribAngle: customMaghribAngle ?? this.customMaghribAngle,
      maghribDelay: maghribDelay ?? this.maghribDelay,
      ishaInterval: ishaInterval ?? this.ishaInterval,
      asrCalculationName: asrCalculationName ?? this.asrCalculationName,
      midnightMethodName: midnightMethodName ?? this.midnightMethodName,
      highLatitudeRuleName: highLatitudeRuleName ?? this.highLatitudeRuleName,
      fajrAdjustment: fajrAdjustment ?? this.fajrAdjustment,
      sunriseAdjustment: sunriseAdjustment ?? this.sunriseAdjustment,
      dhuhrAdjustment: dhuhrAdjustment ?? this.dhuhrAdjustment,
      asrAdjustment: asrAdjustment ?? this.asrAdjustment,
      maghribAdjustment: maghribAdjustment ?? this.maghribAdjustment,
      ishaAdjustment: ishaAdjustment ?? this.ishaAdjustment,
    );
  }

  /// إعادة التعديلات للقيم الافتراضية
  void resetAdjustments() {
    fajrAdjustment = 0;
    sunriseAdjustment = 0;
    dhuhrAdjustment = 0;
    asrAdjustment = 0;
    maghribAdjustment = 0;
    ishaAdjustment = 0;
  }

  /// إعادة كل الإعدادات للقيم الافتراضية
  void resetToDefaults() {
    hijriDayAdjustment = 0;
    calculationMethodName = 'jafari';
    customFajrAngle = null;
    customIshaAngle = null;
    customMaghribAngle = null;
    maghribDelay = 4;
    ishaInterval = null;
    asrCalculationName = 'standard';
    midnightMethodName = 'jafari';
    highLatitudeRuleName = 'middleOfNight';
    resetAdjustments();
  }
}

/// معلومات طريقة الحساب
class CalculationMethodInfo {
  final CalculationMethod method;
  final String arabicName;
  final double fajrAngle;
  final double ishaAngle;
  final double? maghribAngle;
  final int? ishaMinutes;
  final String description;

  const CalculationMethodInfo({
    required this.method,
    required this.arabicName,
    required this.fajrAngle,
    required this.ishaAngle,
    this.maghribAngle,
    this.ishaMinutes,
    required this.description,
  });

  /// قائمة طرق الحساب المتاحة
  static const List<CalculationMethodInfo> availableMethods = [
    CalculationMethodInfo(
      method: CalculationMethod.jafari,
      arabicName: 'المذهب الجعفري',
      fajrAngle: 16.0,
      ishaAngle: 14.0,
      description: 'الشيعة الإثنا عشرية - المغرب بعد زوال الحمرة المشرقية',
    ),
    CalculationMethodInfo(
      method: CalculationMethod.tehran,
      arabicName: 'جامعة طهران',
      fajrAngle: 17.7,
      ishaAngle: 14.0,
      maghribAngle: 4.5,
      description: 'معهد الجيوفيزياء - جامعة طهران',
    ),
    CalculationMethodInfo(
      method: CalculationMethod.mwl,
      arabicName: 'رابطة العالم الإسلامي',
      fajrAngle: 18.0,
      ishaAngle: 17.0,
      description: 'رابطة العالم الإسلامي - مكة المكرمة',
    ),
    CalculationMethodInfo(
      method: CalculationMethod.isna,
      arabicName: 'ISNA',
      fajrAngle: 15.0,
      ishaAngle: 15.0,
      description: 'الجمعية الإسلامية لأمريكا الشمالية',
    ),
    CalculationMethodInfo(
      method: CalculationMethod.egyptian,
      arabicName: 'الهيئة المصرية',
      fajrAngle: 19.5,
      ishaAngle: 17.5,
      description: 'الهيئة المصرية العامة للمساحة',
    ),
    CalculationMethodInfo(
      method: CalculationMethod.ummAlQura,
      arabicName: 'أم القرى',
      fajrAngle: 18.5,
      ishaAngle: 0,
      ishaMinutes: 90,
      description: 'جامعة أم القرى - السعودية (العشاء 90 دقيقة بعد المغرب)',
    ),
    CalculationMethodInfo(
      method: CalculationMethod.karachi,
      arabicName: 'كراتشي',
      fajrAngle: 18.0,
      ishaAngle: 18.0,
      description: 'جامعة العلوم الإسلامية - كراتشي',
    ),
  ];
}
