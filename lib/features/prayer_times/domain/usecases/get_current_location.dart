import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/location_entity.dart';
import '../repositories/prayer_times_repository.dart';

/// حالة استخدام: الحصول على الموقع الحالي
class GetCurrentLocation implements UseCase<LocationEntity, NoParams> {
  final PrayerTimesRepository repository;

  GetCurrentLocation(this.repository);

  @override
  Future<Either<Failure, LocationEntity>> call(NoParams params) async {
    return await repository.getCurrentLocation();
  }
}
