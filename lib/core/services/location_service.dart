import 'package:shared_preferences/shared_preferences.dart';
import '../astronomical/settings/location_settings.dart';

/// خدمة إدارة الموقع
class LocationService {
  static LocationService? _instance;
  static LocationService get instance {
    _instance ??= LocationService._();
    return _instance!;
  }

  LocationService._();

  /// مفاتيح التخزين
  static const String _cityKey = 'selectedCity';
  static const String _latKey = 'latitude';
  static const String _lngKey = 'longitude';
  static const String _tzKey = 'timezone';
  static const String _autoLocationKey = 'autoLocation';

  /// خريطة المدن بالعربي إلى مفاتيح المدن
  static final Map<String, String> _arabicToKey = {
    'بغداد': 'baghdad',
    'كربلاء': 'karbala',
    'النجف': 'najaf',
    'البصرة': 'basra',
    'الموصل': 'mosul',
    'أربيل': 'erbil',
    'السليمانية': 'sulaymaniyah',
    'الكوفة': 'kufa',
    'سامراء': 'samarra',
    'الكاظمية': 'kadhimiya',
    'مكة المكرمة': 'mecca',
    'المدينة المنورة': 'medina',
    'القاهرة': 'cairo',
    'دمشق': 'damascus',
    'بيروت': 'beirut',
    'طهران': 'tehran',
    'قم': 'qom',
    'مشهد': 'mashhad',
    'الكويت': 'kuwait',
    'المنامة': 'bahrain',
    'الدوحة': 'doha',
    'دبي': 'dubai',
    'إسطنبول': 'istanbul',
    'لندن': 'london',
    'باريس': 'paris',
    'برلين': 'berlin',
    'نيويورك': 'new_york',
    'لوس أنجلوس': 'los_angeles',
    'سيدني': 'sydney',
  };

  /// مدن إضافية مع إحداثياتها
  static final Map<String, LocationSettings> _additionalCities = {
    'basra': LocationSettings(
      latitude: 30.5085,
      longitude: 47.7804,
      timezone: 3.0,
      locationName: 'البصرة',
      country: 'العراق',
      elevation: 5,
    ),
    'mosul': LocationSettings(
      latitude: 36.3350,
      longitude: 43.1189,
      timezone: 3.0,
      locationName: 'الموصل',
      country: 'العراق',
      elevation: 223,
    ),
    'erbil': LocationSettings(
      latitude: 36.1911,
      longitude: 44.0094,
      timezone: 3.0,
      locationName: 'أربيل',
      country: 'العراق',
      elevation: 414,
    ),
    'sulaymaniyah': LocationSettings(
      latitude: 35.5570,
      longitude: 45.4351,
      timezone: 3.0,
      locationName: 'السليمانية',
      country: 'العراق',
      elevation: 853,
    ),
    'kufa': LocationSettings(
      latitude: 32.0300,
      longitude: 44.4000,
      timezone: 3.0,
      locationName: 'الكوفة',
      country: 'العراق',
      elevation: 25,
    ),
    'samarra': LocationSettings(
      latitude: 34.1959,
      longitude: 43.8742,
      timezone: 3.0,
      locationName: 'سامراء',
      country: 'العراق',
      elevation: 75,
    ),
    'kadhimiya': LocationSettings(
      latitude: 33.3789,
      longitude: 44.3394,
      timezone: 3.0,
      locationName: 'الكاظمية',
      country: 'العراق',
      elevation: 34,
    ),
  };

  /// الحصول على إعدادات الموقع الحالية
  Future<LocationSettings> getCurrentLocation() async {
    final prefs = await SharedPreferences.getInstance();

    // نقرأ المدينة المحفوظة دائماً
    final cityName = prefs.getString(_cityKey) ?? 'بغداد';
    print('LocationService: تم تحميل المدينة: $cityName');
    final location = getLocationForCity(cityName);
    print(
      'LocationService: الإحداثيات - lat: ${location.latitude}, lng: ${location.longitude}',
    );
    return location;
  }

  /// الحصول على إعدادات الموقع لمدينة معينة
  LocationSettings getLocationForCity(String cityName) {
    final cityKey = _arabicToKey[cityName];

    if (cityKey != null) {
      // البحث في المدن الرئيسية
      if (LocationSettings.famousCities.containsKey(cityKey)) {
        return LocationSettings.famousCities[cityKey]!;
      }
      // البحث في المدن الإضافية
      if (_additionalCities.containsKey(cityKey)) {
        return _additionalCities[cityKey]!;
      }
    }

    // الافتراضي: بغداد
    return LocationSettings.famousCities['baghdad'] ??
        LocationSettings.defaultLocation();
  }

  /// حفظ الموقع المختار
  Future<void> saveSelectedCity(String cityName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, cityName);
    print('LocationService: تم حفظ المدينة: $cityName');

    final location = getLocationForCity(cityName);
    await prefs.setDouble(_latKey, location.latitude);
    await prefs.setDouble(_lngKey, location.longitude);
    await prefs.setDouble(_tzKey, location.timezone);
    print(
      'LocationService: تم حفظ الإحداثيات - lat: ${location.latitude}, lng: ${location.longitude}',
    );
  }

  /// الحصول على اسم المدينة المحفوظة
  Future<String> getSavedCityName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cityKey) ?? 'بغداد';
  }

  /// قائمة المدن المتاحة (بالعربي)
  List<String> getAvailableCities() {
    return _arabicToKey.keys.toList();
  }
}
