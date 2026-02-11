import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/prayer_times_entity.dart';
import '../entities/location_entity.dart';

/// واجهة مستودع مواقيت الصلاة
abstract class PrayerTimesRepository {
  /// الحصول على مواقيت الصلاة لتاريخ وموقع معينين
  Future<Either<Failure, PrayerTimesEntity>> getPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    String? locationName,
  });

  /// الحصول على مواقيت الصلاة لشهر كامل
  Future<Either<Failure, List<PrayerTimesEntity>>> getMonthPrayerTimes({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
    String? locationName,
  });

  /// الحصول على الموقع الحالي
  Future<Either<Failure, LocationEntity>> getCurrentLocation();

  /// البحث عن موقع بالاسم
  Future<Either<Failure, List<LocationEntity>>> searchLocation(String query);

  /// حفظ الموقع المفضل
  Future<Either<Failure, void>> saveLocation(LocationEntity location);

  /// الحصول على الموقع المحفوظ
  Future<Either<Failure, LocationEntity?>> getSavedLocation();

  /// الحصول على وقت السحور والإفطار
  Future<Either<Failure, Map<String, DateTime>>> getSuhoorAndIftarTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
  });
}
