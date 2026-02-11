import 'package:geolocator/geolocator.dart' as geo;
import '../settings/location_settings.dart';

/// خدمة تحديد الموقع الجغرافي
///
/// توفر:
/// - تحديد الموقع التلقائي عبر GPS
/// - حساب المنطقة الزمنية من الإحداثيات
/// - التحقق من صلاحيات الموقع
class LocationService {
  /// الحصول على الموقع الحالي
  Future<LocationResult> getCurrentLocation() async {
    try {
      // التحقق من تفعيل خدمة الموقع
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error(
          'خدمة الموقع غير مفعلة',
          LocationErrorType.serviceDisabled,
        );
      }

      // التحقق من الصلاحيات
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          return LocationResult.error(
            'صلاحية الموقع مرفوضة',
            LocationErrorType.permissionDenied,
          );
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        return LocationResult.error(
          'صلاحية الموقع مرفوضة بشكل دائم. يرجى تفعيلها من الإعدادات',
          LocationErrorType.permissionDeniedForever,
        );
      }

      // الحصول على الموقع
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // حساب المنطقة الزمنية التقريبية
      final timezone = _calculateTimezone(position.longitude);

      final location = LocationSettings(
        latitude: position.latitude,
        longitude: position.longitude,
        timezone: timezone,
        elevation: position.altitude > 0 ? position.altitude : null,
        isAutoDetected: true,
        lastUpdated: DateTime.now(),
      );

      return LocationResult.success(location);
    } catch (e) {
      return LocationResult.error(
        'فشل في تحديد الموقع: ${e.toString()}',
        LocationErrorType.unknown,
      );
    }
  }

  /// حساب المنطقة الزمنية التقريبية من خط الطول
  double _calculateTimezone(double longitude) {
    // تقريب بسيط: كل 15 درجة = ساعة واحدة
    return (longitude / 15).roundToDouble();
  }

  /// الحصول على آخر موقع معروف
  Future<LocationSettings?> getLastKnownLocation() async {
    try {
      final position = await geo.Geolocator.getLastKnownPosition();
      if (position == null) return null;

      final timezone = _calculateTimezone(position.longitude);

      return LocationSettings(
        latitude: position.latitude,
        longitude: position.longitude,
        timezone: timezone,
        elevation: position.altitude > 0 ? position.altitude : null,
        isAutoDetected: true,
      );
    } catch (e) {
      return null;
    }
  }

  /// حساب المسافة بين موقعين بالكيلومتر
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return geo.Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// حساب اتجاه القبلة من موقع معين
  double calculateQiblaDirection(double latitude, double longitude) {
    // إحداثيات الكعبة المشرفة
    const kaabaLat = 21.4225;
    const kaabaLon = 39.8262;

    return geo.Geolocator.bearingBetween(
      latitude,
      longitude,
      kaabaLat,
      kaabaLon,
    );
  }

  /// المسافة إلى الكعبة المشرفة بالكيلومتر
  double distanceToKaaba(double latitude, double longitude) {
    const kaabaLat = 21.4225;
    const kaabaLon = 39.8262;

    return calculateDistance(latitude, longitude, kaabaLat, kaabaLon);
  }

  /// فتح إعدادات الموقع في النظام
  Future<bool> openLocationSettings() async {
    return await geo.Geolocator.openLocationSettings();
  }

  /// فتح إعدادات التطبيق
  Future<bool> openAppSettings() async {
    return await geo.Geolocator.openAppSettings();
  }

  /// البحث عن أقرب مدينة من القائمة المعروفة
  LocationSettings? findNearestCity(double latitude, double longitude) {
    LocationSettings? nearest;
    double minDistance = double.infinity;

    for (final city in LocationSettings.famousCities.values) {
      final distance = calculateDistance(
        latitude,
        longitude,
        city.latitude,
        city.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = city;
      }
    }

    return nearest;
  }
}

/// نتيجة تحديد الموقع
class LocationResult {
  final LocationSettings? location;
  final String? errorMessage;
  final LocationErrorType? errorType;
  final bool isSuccess;

  LocationResult._({
    this.location,
    this.errorMessage,
    this.errorType,
    required this.isSuccess,
  });

  factory LocationResult.success(LocationSettings location) {
    return LocationResult._(location: location, isSuccess: true);
  }

  factory LocationResult.error(String message, LocationErrorType type) {
    return LocationResult._(
      errorMessage: message,
      errorType: type,
      isSuccess: false,
    );
  }
}

/// أنواع أخطاء الموقع
enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}
