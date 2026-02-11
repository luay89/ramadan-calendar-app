import 'package:hive/hive.dart';
import '../engine/prayer_times_engine.dart';

part 'location_settings.g.dart';

/// إعدادات الموقع الجغرافي
///
/// يدعم:
/// - تحديد الموقع تلقائياً عبر GPS
/// - إدخال يدوي للإحداثيات
/// - اختيار من قائمة المدن
/// - تعديل المنطقة الزمنية
@HiveType(typeId: 50)
class LocationSettings extends HiveObject {
  /// خط العرض
  @HiveField(0)
  double latitude;

  /// خط الطول
  @HiveField(1)
  double longitude;

  /// المنطقة الزمنية (فرق من UTC بالساعات)
  @HiveField(2)
  double timezone;

  /// اسم المدينة/الموقع
  @HiveField(3)
  String? locationName;

  /// اسم البلد
  @HiveField(4)
  String? country;

  /// الارتفاع عن سطح البحر (متر)
  @HiveField(5)
  double? elevation;

  /// هل تم الحصول على الموقع من GPS؟
  @HiveField(6)
  bool isAutoDetected;

  /// تاريخ آخر تحديث للموقع
  @HiveField(7)
  DateTime? lastUpdated;

  LocationSettings({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.locationName,
    this.country,
    this.elevation,
    this.isAutoDetected = false,
    this.lastUpdated,
  });

  /// موقع افتراضي (مكة المكرمة)
  factory LocationSettings.defaultLocation() {
    return LocationSettings(
      latitude: 21.4225,
      longitude: 39.8262,
      timezone: 3.0,
      locationName: 'مكة المكرمة',
      country: 'السعودية',
      elevation: 277,
    );
  }

  /// مدن مشهورة
  static final Map<String, LocationSettings> famousCities = {
    'mecca': LocationSettings(
      latitude: 21.4225,
      longitude: 39.8262,
      timezone: 3.0,
      locationName: 'مكة المكرمة',
      country: 'السعودية',
      elevation: 277,
    ),
    'medina': LocationSettings(
      latitude: 24.4539,
      longitude: 39.6142,
      timezone: 3.0,
      locationName: 'المدينة المنورة',
      country: 'السعودية',
      elevation: 608,
    ),
    'karbala': LocationSettings(
      latitude: 32.6098,
      longitude: 44.0241,
      timezone: 3.0,
      locationName: 'كربلاء',
      country: 'العراق',
      elevation: 30,
    ),
    'najaf': LocationSettings(
      latitude: 31.9889,
      longitude: 44.3359,
      timezone: 3.0,
      locationName: 'النجف',
      country: 'العراق',
      elevation: 53,
    ),
    'baghdad': LocationSettings(
      latitude: 33.3152,
      longitude: 44.3661,
      timezone: 3.0,
      locationName: 'بغداد',
      country: 'العراق',
      elevation: 34,
    ),
    'tehran': LocationSettings(
      latitude: 35.6892,
      longitude: 51.3890,
      timezone: 3.5,
      locationName: 'طهران',
      country: 'إيران',
      elevation: 1189,
    ),
    'qom': LocationSettings(
      latitude: 34.6401,
      longitude: 50.8764,
      timezone: 3.5,
      locationName: 'قم',
      country: 'إيران',
      elevation: 928,
    ),
    'mashhad': LocationSettings(
      latitude: 36.2605,
      longitude: 59.6168,
      timezone: 3.5,
      locationName: 'مشهد',
      country: 'إيران',
      elevation: 999,
    ),
    'beirut': LocationSettings(
      latitude: 33.8938,
      longitude: 35.5018,
      timezone: 2.0,
      locationName: 'بيروت',
      country: 'لبنان',
      elevation: 0,
    ),
    'cairo': LocationSettings(
      latitude: 30.0444,
      longitude: 31.2357,
      timezone: 2.0,
      locationName: 'القاهرة',
      country: 'مصر',
      elevation: 75,
    ),
    'damascus': LocationSettings(
      latitude: 33.5138,
      longitude: 36.2765,
      timezone: 3.0,
      locationName: 'دمشق',
      country: 'سوريا',
      elevation: 680,
    ),
    'kuwait': LocationSettings(
      latitude: 29.3759,
      longitude: 47.9774,
      timezone: 3.0,
      locationName: 'الكويت',
      country: 'الكويت',
      elevation: 17,
    ),
    'bahrain': LocationSettings(
      latitude: 26.0667,
      longitude: 50.5577,
      timezone: 3.0,
      locationName: 'المنامة',
      country: 'البحرين',
      elevation: 2,
    ),
    'doha': LocationSettings(
      latitude: 25.2854,
      longitude: 51.5310,
      timezone: 3.0,
      locationName: 'الدوحة',
      country: 'قطر',
      elevation: 10,
    ),
    'dubai': LocationSettings(
      latitude: 25.2048,
      longitude: 55.2708,
      timezone: 4.0,
      locationName: 'دبي',
      country: 'الإمارات',
      elevation: 16,
    ),
    'istanbul': LocationSettings(
      latitude: 41.0082,
      longitude: 28.9784,
      timezone: 3.0,
      locationName: 'إسطنبول',
      country: 'تركيا',
      elevation: 40,
    ),
    'london': LocationSettings(
      latitude: 51.5074,
      longitude: -0.1278,
      timezone: 0.0,
      locationName: 'لندن',
      country: 'بريطانيا',
      elevation: 11,
    ),
    'paris': LocationSettings(
      latitude: 48.8566,
      longitude: 2.3522,
      timezone: 1.0,
      locationName: 'باريس',
      country: 'فرنسا',
      elevation: 35,
    ),
    'berlin': LocationSettings(
      latitude: 52.5200,
      longitude: 13.4050,
      timezone: 1.0,
      locationName: 'برلين',
      country: 'ألمانيا',
      elevation: 34,
    ),
    'new_york': LocationSettings(
      latitude: 40.7128,
      longitude: -74.0060,
      timezone: -5.0,
      locationName: 'نيويورك',
      country: 'أمريكا',
      elevation: 10,
    ),
    'los_angeles': LocationSettings(
      latitude: 34.0522,
      longitude: -118.2437,
      timezone: -8.0,
      locationName: 'لوس أنجلوس',
      country: 'أمريكا',
      elevation: 71,
    ),
    'sydney': LocationSettings(
      latitude: -33.8688,
      longitude: 151.2093,
      timezone: 10.0,
      locationName: 'سيدني',
      country: 'أستراليا',
      elevation: 58,
    ),
  };

  /// تحويل إلى GeoLocation
  GeoLocation toGeoLocation() {
    return GeoLocation(
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      name: locationName,
    );
  }

  /// نسخ مع تعديلات
  LocationSettings copyWith({
    double? latitude,
    double? longitude,
    double? timezone,
    String? locationName,
    String? country,
    double? elevation,
    bool? isAutoDetected,
    DateTime? lastUpdated,
  }) {
    return LocationSettings(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      locationName: locationName ?? this.locationName,
      country: country ?? this.country,
      elevation: elevation ?? this.elevation,
      isAutoDetected: isAutoDetected ?? this.isAutoDetected,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
