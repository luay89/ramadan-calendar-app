import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/prayer_time_utils.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/prayer_times_entity.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../datasources/location_datasource.dart';
import '../models/prayer_times_model.dart';
import '../models/location_model.dart';
import 'package:hive/hive.dart';

/// تنفيذ مستودع مواقيت الصلاة
class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  final LocationDataSource locationDataSource;
  final Box<LocationModel> locationBox;

  PrayerTimesRepositoryImpl({
    required this.locationDataSource,
    required this.locationBox,
  });

  @override
  Future<Either<Failure, PrayerTimesEntity>> getPrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    try {
      final model = PrayerTimesModel.fromParams(
        date: date,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName ?? 'موقع مخصص',
      );

      return Right(model.toEntity());
    } catch (e) {
      return Left(UnexpectedFailure(message: 'فشل في حساب مواقيت الصلاة: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PrayerTimesEntity>>> getMonthPrayerTimes({
    required int year,
    required int month,
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    try {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final List<PrayerTimesEntity> monthTimes = [];

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final model = PrayerTimesModel.fromParams(
          date: date,
          latitude: latitude,
          longitude: longitude,
          locationName: locationName ?? 'موقع مخصص',
        );
        monthTimes.add(model.toEntity());
      }

      return Right(monthTimes);
    } catch (e) {
      return Left(UnexpectedFailure(message: 'فشل في حساب مواقيت الشهر: $e'));
    }
  }

  @override
  Future<Either<Failure, LocationEntity>> getCurrentLocation() async {
    try {
      final location = await locationDataSource.getCurrentLocation();
      return Right(location.toEntity());
    } on LocationException catch (e) {
      return Left(LocationFailure(message: e.message ?? 'فشل في تحديد الموقع'));
    } on PermissionException catch (e) {
      return Left(
        PermissionFailure(message: e.message ?? 'لم يتم منح صلاحية الموقع'),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, List<LocationEntity>>> searchLocation(
    String query,
  ) async {
    try {
      final locations = await locationDataSource.searchLocation(query);
      return Right(locations.map((l) => l.toEntity()).toList());
    } on LocationException catch (e) {
      return Left(LocationFailure(message: e.message ?? 'فشل في البحث'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveLocation(LocationEntity location) async {
    try {
      final model = LocationModel.fromEntity(location);
      await locationBox.put('saved_location', model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'فشل في حفظ الموقع'));
    }
  }

  @override
  Future<Either<Failure, LocationEntity?>> getSavedLocation() async {
    try {
      final model = locationBox.get('saved_location');
      return Right(model?.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'فشل في استرجاع الموقع المحفوظ'));
    }
  }

  @override
  Future<Either<Failure, Map<String, DateTime>>> getSuhoorAndIftarTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final prayerTimes = PrayerTimeUtils.getPrayerTimes(
        date: date,
        latitude: latitude,
        longitude: longitude,
      );

      return Right({
        'suhoor': PrayerTimeUtils.getSuhoorTime(prayerTimes),
        'iftar': PrayerTimeUtils.getIftarTime(prayerTimes),
      });
    } catch (e) {
      return Left(
        UnexpectedFailure(message: 'فشل في حساب أوقات السحور والإفطار'),
      );
    }
  }
}
