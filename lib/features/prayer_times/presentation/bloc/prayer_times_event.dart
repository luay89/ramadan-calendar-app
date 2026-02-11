part of 'prayer_times_bloc.dart';

/// أحداث مواقيت الصلاة
abstract class PrayerTimesEvent extends Equatable {
  const PrayerTimesEvent();

  @override
  List<Object?> get props => [];
}

/// تحميل مواقيت الصلاة
class LoadPrayerTimes extends PrayerTimesEvent {
  const LoadPrayerTimes();
}

/// تحميل مواقيت لموقع محدد
class LoadPrayerTimesForLocation extends PrayerTimesEvent {
  final LocationEntity location;
  final DateTime date;

  const LoadPrayerTimesForLocation({
    required this.location,
    required this.date,
  });

  @override
  List<Object> get props => [location, date];
}

/// تحديث العد التنازلي
class UpdateCountdown extends PrayerTimesEvent {
  const UpdateCountdown();
}

/// تغيير التاريخ
class ChangeDate extends PrayerTimesEvent {
  final DateTime date;

  const ChangeDate(this.date);

  @override
  List<Object> get props => [date];
}

/// البحث عن موقع
class SearchLocation extends PrayerTimesEvent {
  final String query;

  const SearchLocation(this.query);

  @override
  List<Object> get props => [query];
}

/// اختيار موقع
class SelectLocation extends PrayerTimesEvent {
  final LocationEntity location;

  const SelectLocation(this.location);

  @override
  List<Object> get props => [location];
}
