import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة الموقع المعتمدة على GPS فقط
/// لا تستخدم قائمة مدن ثابتة - تعتمد على الإحداثيات الفعلية
class GPSLocationService {
  static GPSLocationService? _instance;
  static GPSLocationService get instance {
    _instance ??= GPSLocationService._();
    return _instance!;
  }

  GPSLocationService._();

  /// مفاتيح التخزين
  static const String _latKey = 'gps_latitude';
  static const String _lngKey = 'gps_longitude';
  static const String _displayNameKey = 'gps_display_name';
  static const String _lastUpdateKey = 'gps_last_update';

  /// عتبة تغيير الموقع (0.01 درجة ≈ 1 كم)
  static const double _locationChangeThreshold = 0.01;

  /// Stream controller لتغيير الموقع
  final _locationChangeController = StreamController<GPSLocation>.broadcast();
  Stream<GPSLocation> get locationChanges => _locationChangeController.stream;

  /// الحصول على الموقع الحالي من GPS
  Future<GPSLocationResult> getCurrentLocation() async {
    try {
      // التحقق من تفعيل خدمات الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return GPSLocationResult.error(
          'خدمات الموقع غير مفعلة. يرجى تفعيلها من الإعدادات.',
          GPSErrorType.serviceDisabled,
        );
      }

      // التحقق من الصلاحيات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return GPSLocationResult.error(
            'تم رفض صلاحية الموقع. التطبيق يحتاج للموقع لحساب أوقات الصلاة.',
            GPSErrorType.permissionDenied,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return GPSLocationResult.error(
          'صلاحية الموقع مرفوضة بشكل دائم. يرجى تفعيلها من إعدادات التطبيق.',
          GPSErrorType.permissionDeniedForever,
        );
      }

      // الحصول على الموقع بدقة عالية
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // الحصول على اسم المنطقة للعرض فقط (Reverse Geocoding)
      String displayName = 'موقعك الحالي';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          displayName = _buildDisplayName(place);
        }
      } catch (_) {
        // إذا فشل الـ reverse geocoding، نستخدم اسم افتراضي
      }

      final location = GPSLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        displayName: displayName,
        timestamp: DateTime.now(),
      );

      // التحقق من تغيير الموقع
      final savedLocation = await getSavedLocation();
      if (savedLocation != null &&
          _hasLocationChanged(savedLocation, location)) {
        _locationChangeController.add(location);
      }

      // حفظ الموقع الجديد
      await saveLocation(location);

      return GPSLocationResult.success(location);
    } catch (e) {
      return GPSLocationResult.error(
        'فشل في تحديد الموقع: $e',
        GPSErrorType.unknown,
      );
    }
  }

  /// بناء اسم العرض من الـ placemark
  String _buildDisplayName(Placemark place) {
    final parts = <String>[];

    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    } else if (place.subAdministrativeArea != null &&
        place.subAdministrativeArea!.isNotEmpty) {
      parts.add(place.subAdministrativeArea!);
    } else if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }

    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }

    return parts.isNotEmpty ? parts.join('، ') : 'موقعك الحالي';
  }

  /// التحقق من تغيير الموقع (أكثر من 1 كم)
  bool _hasLocationChanged(GPSLocation oldLocation, GPSLocation newLocation) {
    final latDiff = (oldLocation.latitude - newLocation.latitude).abs();
    final lngDiff = (oldLocation.longitude - newLocation.longitude).abs();
    return latDiff > _locationChangeThreshold ||
        lngDiff > _locationChangeThreshold;
  }

  /// حفظ الموقع
  Future<void> saveLocation(GPSLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, location.latitude);
    await prefs.setDouble(_lngKey, location.longitude);
    await prefs.setString(_displayNameKey, location.displayName);
    await prefs.setInt(
      _lastUpdateKey,
      location.timestamp.millisecondsSinceEpoch,
    );
  }

  /// الحصول على الموقع المحفوظ
  Future<GPSLocation?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);

    if (lat == null || lng == null) {
      return null;
    }

    return GPSLocation(
      latitude: lat,
      longitude: lng,
      displayName: prefs.getString(_displayNameKey) ?? 'موقع محفوظ',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(_lastUpdateKey) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// الحصول على الموقع (المحفوظ أو الجديد)
  /// يستخدم المحفوظ فوراً ثم يحدث بالخلفية
  Future<GPSLocationResult> getLocationWithFallback() async {
    // محاولة استخدام الموقع المحفوظ أولاً
    final savedLocation = await getSavedLocation();

    if (savedLocation != null) {
      // تحديث الموقع بالخلفية بصمت
      _updateLocationInBackground();
      return GPSLocationResult.success(savedLocation);
    }

    // إذا لم يوجد موقع محفوظ، نطلب GPS
    return getCurrentLocation();
  }

  /// تحديث الموقع بالخلفية
  Future<void> _updateLocationInBackground() async {
    try {
      final result = await getCurrentLocation();
      if (result.isSuccess && result.location != null) {
        // الموقع تم تحديثه وحفظه في getCurrentLocation
      }
    } catch (_) {
      // تجاهل الأخطاء في التحديث الخلفي
    }
  }

  /// الحصول على المنطقة الزمنية من النظام
  String getSystemTimezone() {
    return DateTime.now().timeZoneName;
  }

  /// الحصول على فرق التوقيت بالساعات
  double getTimezoneOffset() {
    return DateTime.now().timeZoneOffset.inMinutes / 60.0;
  }

  /// التحقق من صلاحيات الموقع
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// طلب صلاحيات الموقع
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// فتح إعدادات الموقع
  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  /// فتح إعدادات التطبيق
  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  /// إغلاق الـ stream
  void dispose() {
    _locationChangeController.close();
  }
}

/// نتيجة طلب الموقع
class GPSLocationResult {
  final GPSLocation? location;
  final String? errorMessage;
  final GPSErrorType? errorType;
  final bool isSuccess;

  GPSLocationResult._({
    this.location,
    this.errorMessage,
    this.errorType,
    required this.isSuccess,
  });

  factory GPSLocationResult.success(GPSLocation location) {
    return GPSLocationResult._(location: location, isSuccess: true);
  }

  factory GPSLocationResult.error(String message, GPSErrorType type) {
    return GPSLocationResult._(
      errorMessage: message,
      errorType: type,
      isSuccess: false,
    );
  }
}

/// أنواع أخطاء GPS
enum GPSErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

/// موقع GPS
class GPSLocation {
  final double latitude;
  final double longitude;
  final String displayName;
  final DateTime timestamp;

  const GPSLocation({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'GPSLocation(lat: $latitude, lng: $longitude, name: $displayName)';
  }
}
