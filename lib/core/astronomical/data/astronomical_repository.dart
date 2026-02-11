import 'package:hive/hive.dart';
import '../constants/astronomical_constants.dart';
import '../engine/prayer_times_engine.dart';
import '../settings/location_settings.dart';
import '../settings/calibration_settings.dart';
import '../services/location_service.dart';
import '../services/astronomical_service.dart';

/// مصدر البيانات المحلي للإعدادات الفلكية
class AstronomicalLocalDataSource {
  static const String _locationBoxName = 'location_settings';
  static const String _calibrationBoxName = 'calibration_settings';
  static const String _locationKey = 'current_location';
  static const String _calibrationKey = 'current_calibration';

  Box<LocationSettings>? _locationBox;
  Box<CalibrationSettings>? _calibrationBox;

  /// تهيئة قاعدة البيانات
  Future<void> init() async {
    // تسجيل المحولات إذا لم تكن مسجلة
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(LocationSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(51)) {
      Hive.registerAdapter(CalibrationSettingsAdapter());
    }

    _locationBox = await Hive.openBox<LocationSettings>(_locationBoxName);
    _calibrationBox = await Hive.openBox<CalibrationSettings>(
      _calibrationBoxName,
    );
  }

  /// إغلاق قاعدة البيانات
  Future<void> close() async {
    await _locationBox?.close();
    await _calibrationBox?.close();
  }

  // =================== إعدادات الموقع ===================

  /// حفظ إعدادات الموقع
  Future<void> saveLocationSettings(LocationSettings settings) async {
    await _locationBox?.put(_locationKey, settings);
  }

  /// قراءة إعدادات الموقع
  LocationSettings? getLocationSettings() {
    return _locationBox?.get(_locationKey);
  }

  /// قراءة إعدادات الموقع أو الافتراضية
  LocationSettings getLocationSettingsOrDefault() {
    return getLocationSettings() ?? LocationSettings.defaultLocation();
  }

  /// حذف إعدادات الموقع
  Future<void> deleteLocationSettings() async {
    await _locationBox?.delete(_locationKey);
  }

  // =================== إعدادات المعايرة ===================

  /// حفظ إعدادات المعايرة
  Future<void> saveCalibrationSettings(CalibrationSettings settings) async {
    await _calibrationBox?.put(_calibrationKey, settings);
  }

  /// قراءة إعدادات المعايرة
  CalibrationSettings? getCalibrationSettings() {
    return _calibrationBox?.get(_calibrationKey);
  }

  /// قراءة إعدادات المعايرة أو الافتراضية
  CalibrationSettings getCalibrationSettingsOrDefault() {
    return getCalibrationSettings() ?? CalibrationSettings.jafariDefault();
  }

  /// حذف إعدادات المعايرة
  Future<void> deleteCalibrationSettings() async {
    await _calibrationBox?.delete(_calibrationKey);
  }

  // =================== إعادة الضبط ===================

  /// إعادة ضبط جميع الإعدادات
  Future<void> resetAllSettings() async {
    await deleteLocationSettings();
    await deleteCalibrationSettings();
  }
}

/// Repository للإعدادات الفلكية
class AstronomicalRepository {
  final AstronomicalLocalDataSource _dataSource;
  final LocationService _locationService;

  AstronomicalRepository({
    required AstronomicalLocalDataSource dataSource,
    required LocationService locationService,
  }) : _dataSource = dataSource,
       _locationService = locationService;

  // =================== الموقع ===================

  /// الحصول على إعدادات الموقع الحالية
  LocationSettings getLocationSettings() {
    return _dataSource.getLocationSettingsOrDefault();
  }

  /// حفظ إعدادات الموقع
  Future<void> saveLocationSettings(LocationSettings settings) async {
    await _dataSource.saveLocationSettings(settings);
  }

  /// تحديد الموقع تلقائياً
  Future<LocationResult> detectLocation() async {
    final result = await _locationService.getCurrentLocation();
    if (result.isSuccess && result.location != null) {
      // البحث عن أقرب مدينة لتحديد الاسم
      final nearestCity = _locationService.findNearestCity(
        result.location!.latitude,
        result.location!.longitude,
      );

      final locationWithName = result.location!.copyWith(
        locationName: nearestCity?.locationName ?? 'موقعك الحالي',
        country: nearestCity?.country,
      );

      await saveLocationSettings(locationWithName);
      return LocationResult.success(locationWithName);
    }
    return result;
  }

  /// اختيار مدينة من القائمة
  Future<void> selectCity(String cityKey) async {
    final city = LocationSettings.famousCities[cityKey];
    if (city != null) {
      await saveLocationSettings(city);
    }
  }

  // =================== المعايرة ===================

  /// الحصول على إعدادات المعايرة الحالية
  CalibrationSettings getCalibrationSettings() {
    return _dataSource.getCalibrationSettingsOrDefault();
  }

  /// حفظ إعدادات المعايرة
  Future<void> saveCalibrationSettings(CalibrationSettings settings) async {
    await _dataSource.saveCalibrationSettings(settings);
  }

  /// تعديل يوم الهجري
  Future<void> adjustHijriDay(int adjustment) async {
    final settings = getCalibrationSettings();
    final newSettings = settings.copyWith(hijriDayAdjustment: adjustment);
    await saveCalibrationSettings(newSettings);
  }

  /// تعديل وقت صلاة معينة
  Future<void> adjustPrayerTime(Prayer prayer, int minutes) async {
    final settings = getCalibrationSettings();
    CalibrationSettings newSettings;

    switch (prayer) {
      case Prayer.fajr:
        newSettings = settings.copyWith(fajrAdjustment: minutes);
        break;
      case Prayer.sunrise:
        newSettings = settings.copyWith(sunriseAdjustment: minutes);
        break;
      case Prayer.dhuhr:
        newSettings = settings.copyWith(dhuhrAdjustment: minutes);
        break;
      case Prayer.asr:
        newSettings = settings.copyWith(asrAdjustment: minutes);
        break;
      case Prayer.maghrib:
        newSettings = settings.copyWith(maghribAdjustment: minutes);
        break;
      case Prayer.isha:
        newSettings = settings.copyWith(ishaAdjustment: minutes);
        break;
    }

    await saveCalibrationSettings(newSettings);
  }

  /// تغيير طريقة الحساب
  Future<void> changeCalculationMethod(CalculationMethod method) async {
    final settings = getCalibrationSettings();
    final newSettings = settings.copyWith(calculationMethodName: method.name);
    await saveCalibrationSettings(newSettings);
  }

  // =================== الخدمة الفلكية ===================

  /// إنشاء خدمة فلكية بالإعدادات الحالية
  AstronomicalService createService() {
    return AstronomicalService(
      location: getLocationSettings(),
      calibration: getCalibrationSettings(),
    );
  }

  /// إعادة ضبط جميع الإعدادات
  Future<void> resetAllSettings() async {
    await _dataSource.resetAllSettings();
  }
}
