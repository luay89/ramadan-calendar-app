import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/error/exceptions.dart';
import '../models/location_model.dart';

/// مصدر بيانات الموقع
abstract class LocationDataSource {
  /// الحصول على الموقع الحالي
  Future<LocationModel> getCurrentLocation();

  /// البحث عن موقع بالاسم
  Future<List<LocationModel>> searchLocation(String query);

  /// التحقق من صلاحيات الموقع
  Future<bool> checkPermission();

  /// طلب صلاحيات الموقع
  Future<bool> requestPermission();
}

class LocationDataSourceImpl implements LocationDataSource {
  @override
  Future<LocationModel> getCurrentLocation() async {
    try {
      // التحقق من تفعيل خدمات الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException(message: 'خدمات الموقع غير مفعلة');
      }

      // التحقق من الصلاحيات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw PermissionException(message: 'تم رفض صلاحية الموقع');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw PermissionException(message: 'صلاحية الموقع مرفوضة بشكل دائم');
      }

      // الحصول على الموقع
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // الحصول على اسم المدينة
      String? cityName;
      String? countryName;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          cityName = placemarks.first.locality;
          countryName = placemarks.first.country;
        }
      } catch (_) {
        // إذا فشل الحصول على اسم المدينة، نستمر بدونه
      }

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: cityName,
        countryName: countryName,
      );
    } on LocationException {
      rethrow;
    } on PermissionException {
      rethrow;
    } catch (e) {
      throw LocationException(message: 'فشل في الحصول على الموقع: $e');
    }
  }

  @override
  Future<List<LocationModel>> searchLocation(String query) async {
    try {
      final locations = await locationFromAddress(query);

      final results = <LocationModel>[];
      for (final location in locations) {
        try {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          String? cityName;
          String? countryName;
          if (placemarks.isNotEmpty) {
            cityName = placemarks.first.locality;
            countryName = placemarks.first.country;
          }

          results.add(
            LocationModel(
              latitude: location.latitude,
              longitude: location.longitude,
              cityName: cityName ?? query,
              countryName: countryName,
            ),
          );
        } catch (_) {
          results.add(
            LocationModel(
              latitude: location.latitude,
              longitude: location.longitude,
              cityName: query,
            ),
          );
        }
      }

      return results;
    } catch (e) {
      throw LocationException(message: 'فشل في البحث عن الموقع: $e');
    }
  }

  @override
  Future<bool> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
