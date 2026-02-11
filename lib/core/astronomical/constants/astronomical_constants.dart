/// ثوابت فلكية أساسية للحسابات
///
/// هذه الثوابت مأخوذة من:
/// - US Naval Observatory
/// - Astronomical Algorithms by Jean Meeus
/// - IERS Conventions
class AstronomicalConstants {
  AstronomicalConstants._();

  // ══════════════════════════════════════════════════════════════════
  // ثوابت الزمن
  // ══════════════════════════════════════════════════════════════════

  /// Julian Date للحظة J2000.0 (1 يناير 2000، 12:00 TT)
  static const double j2000 = 2451545.0;

  /// عدد أيام القرن اليولياني
  static const double julianCentury = 36525.0;

  /// الفرق بين التوقيت الأرضي والتوقيت العالمي (ثواني تقريبية)
  /// يتغير مع الوقت، هذه قيمة تقريبية
  static const double deltaT2020 = 69.36;

  // ══════════════════════════════════════════════════════════════════
  // ثوابت هندسية
  // ══════════════════════════════════════════════════════════════════

  /// نصف قطر الأرض بالكيلومتر
  static const double earthRadius = 6371.0;

  /// الميل المحوري للأرض بالدرجات (تقريبي)
  static const double earthObliquity = 23.4397;

  /// معامل الانكسار الجوي القياسي بالدرجات
  static const double standardRefraction = 0.5667;

  /// نصف قطر الشمس الزاوي بالدرجات
  static const double sunAngularRadius = 0.2666;

  // ══════════════════════════════════════════════════════════════════
  // زوايا حساب المواقيت
  // ══════════════════════════════════════════════════════════════════

  /// زاوية الغروب/الشروق (مع الانكسار ونصف القطر الشمسي)
  static const double sunriseAngle = -0.8333; // -50 دقيقة قوسية

  /// زاوية الفجر - المذهب الجعفري
  static const double fajrAngleJafari = 16.0;

  /// زاوية العشاء - المذهب الجعفري
  static const double ishaAngleJafari = 14.0;

  /// زاوية الفجر - رابطة العالم الإسلامي
  static const double fajrAngleMWL = 18.0;

  /// زاوية العشاء - رابطة العالم الإسلامي
  static const double ishaAngleMWL = 17.0;

  /// زاوية الفجر - الهيئة المصرية
  static const double fajrAngleEgyptian = 19.5;

  /// زاوية العشاء - الهيئة المصرية
  static const double ishaAngleEgyptian = 17.5;

  /// زاوية الفجر - أم القرى
  static const double fajrAngleUmmAlQura = 18.5;

  // ══════════════════════════════════════════════════════════════════
  // تعديلات خاصة بالمذهب الجعفري
  // ══════════════════════════════════════════════════════════════════

  /// تأخير المغرب بالدقائق (بعد غروب الشمس)
  /// المذهب الجعفري يعتبر المغرب بعد زوال الحمرة المشرقية
  static const int maghribDelayJafari = 4;

  /// منتصف الليل الشرعي (من المغرب للفجر)
  static const bool useShariMidnight = true;

  // ══════════════════════════════════════════════════════════════════
  // ثوابت التقويم الهجري
  // ══════════════════════════════════════════════════════════════════

  /// طول الشهر القمري المتوسط بالأيام
  static const double lunarMonth = 29.530588853;

  /// طول السنة القمرية بالأيام
  static const double lunarYear = 354.36707;

  /// Julian Date لبداية التقويم الهجري (16 يوليو 622 م)
  static const double hijriEpoch = 1948439.5;

  /// دورة الشهور القمرية (19 سنة)
  static const int metonicCycle = 19;

  // ══════════════════════════════════════════════════════════════════
  // ثوابت رياضية
  // ══════════════════════════════════════════════════════════════════

  /// باي
  static const double pi = 3.14159265358979323846;

  /// تحويل الدرجات إلى راديان
  static const double deg2rad = pi / 180.0;

  /// تحويل الراديان إلى درجات
  static const double rad2deg = 180.0 / pi;

  /// الدقائق في الدرجة
  static const double minutesPerDegree = 60.0;

  /// الثواني في الدرجة
  static const double secondsPerDegree = 3600.0;
}

/// أنماط حساب مواقيت الصلاة
enum CalculationMethod {
  jafari, // المذهب الجعفري (شيعة إثنا عشرية)
  tehran, // معهد الجيوفيزياء - طهران
  mwl, // رابطة العالم الإسلامي
  isna, // الجمعية الإسلامية لأمريكا الشمالية
  egyptian, // الهيئة المصرية العامة للمساحة
  ummAlQura, // أم القرى
  karachi, // جامعة العلوم الإسلامية - كراتشي
  custom, // مخصص
}

/// طريقة حساب العصر
enum AsrCalculation {
  standard, // المثل (الشافعي، المالكي، الحنبلي، الجعفري)
  hanafi, // المثلين (الحنفي)
}

/// طريقة حساب منتصف الليل
enum MidnightMethod {
  standard, // منتصف الليل الفلكي (غروب لشروق)
  jafari, // منتصف الليل الشرعي (غروب لفجر)
}

/// قاعدة خطوط العرض العالية
enum HighLatitudeRule {
  none, // بدون تعديل
  middleOfNight, // نسبة من منتصف الليل
  seventhOfNight, // سُبع الليل
  twilightAngle, // زاوية الشفق
}
