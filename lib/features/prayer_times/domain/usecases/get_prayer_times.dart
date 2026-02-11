import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/prayer_times_entity.dart';
import '../repositories/prayer_times_repository.dart';

/// حالة استخدام: الحصول على مواقيت الصلاة
class GetPrayerTimes implements UseCase<PrayerTimesEntity, PrayerTimesParams> {
  final PrayerTimesRepository repository;

  GetPrayerTimes(this.repository);

  @override
  Future<Either<Failure, PrayerTimesEntity>> call(
    PrayerTimesParams params,
  ) async {
    return await repository.getPrayerTimes(
      date: params.date,
      latitude: params.latitude,
      longitude: params.longitude,
      locationName: params.locationName,
    );
  }
}

/// معاملات مواقيت الصلاة
class PrayerTimesParams extends Equatable {
  final DateTime date;
  final double latitude;
  final double longitude;
  final String? locationName;

  const PrayerTimesParams({
    required this.date,
    required this.latitude,
    required this.longitude,
    this.locationName,
  });

  @override
  List<Object?> get props => [date, latitude, longitude, locationName];
}
