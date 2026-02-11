import 'package:adhan/adhan.dart';
import '../../../../core/utils/prayer_time_utils.dart';
import '../../domain/entities/prayer_times_entity.dart';

/// نموذج مواقيت الصلاة
class PrayerTimesModel {
  final PrayerTimes prayerTimes;
  final String locationName;

  PrayerTimesModel({required this.prayerTimes, required this.locationName});

  /// تحويل إلى Entity
  PrayerTimesEntity toEntity() {
    return PrayerTimesEntity(
      fajr: prayerTimes.fajr,
      sunrise: prayerTimes.sunrise,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
      midnight: PrayerTimeUtils.getMidnightTime(prayerTimes),
      lastThird: PrayerTimeUtils.getLastThirdOfNight(prayerTimes),
      date: DateTime(
        prayerTimes.fajr.year,
        prayerTimes.fajr.month,
        prayerTimes.fajr.day,
      ),
      locationName: locationName,
      latitude: prayerTimes.coordinates.latitude,
      longitude: prayerTimes.coordinates.longitude,
    );
  }

  /// إنشاء من معاملات
  factory PrayerTimesModel.fromParams({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String locationName,
  }) {
    final prayerTimes = PrayerTimeUtils.getPrayerTimes(
      date: date,
      latitude: latitude,
      longitude: longitude,
    );

    return PrayerTimesModel(
      prayerTimes: prayerTimes,
      locationName: locationName,
    );
  }
}
