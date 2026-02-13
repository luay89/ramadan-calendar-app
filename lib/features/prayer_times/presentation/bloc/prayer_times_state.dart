part of 'prayer_times_bloc.dart';

/// حالات مواقيت الصلاة
abstract class PrayerTimesState extends Equatable {
  const PrayerTimesState();

  @override
  List<Object?> get props => [];
}

/// الحالة الابتدائية
class PrayerTimesInitial extends PrayerTimesState {}

/// حالة التحميل
class PrayerTimesLoading extends PrayerTimesState {}

/// حالة التحميل الناجح
class PrayerTimesLoaded extends PrayerTimesState {
  final PrayerTimesEntity prayerTimes;
  final LocationEntity location;
  final DateTime selectedDate;
  final bool isRefreshingLocation;
  final DateTime lastUpdate; // لتحديث العد التنازلي

  PrayerTimesLoaded({
    required this.prayerTimes,
    required this.location,
    required this.selectedDate,
    this.isRefreshingLocation = false,
    DateTime? lastUpdate,
  }) : lastUpdate = lastUpdate ?? DateTime.now();

  /// الحصول على الصلاة القادمة
  MapEntry<String, DateTime> get nextPrayer {
    final now = DateTime.now();
    final times = prayerTimes.allTimes;

    for (final entry in times.entries) {
      if (entry.value.isAfter(now)) {
        return entry;
      }
    }

    // إذا انتهت جميع الصلوات، نرجع الفجر
    return MapEntry('الفجر', prayerTimes.fajr);
  }

  /// الوقت المتبقي للصلاة القادمة
  Duration get timeUntilNextPrayer {
    return nextPrayer.value.difference(DateTime.now());
  }

  PrayerTimesLoaded copyWith({
    PrayerTimesEntity? prayerTimes,
    LocationEntity? location,
    DateTime? selectedDate,
    bool? isRefreshingLocation,
    DateTime? lastUpdate,
  }) {
    return PrayerTimesLoaded(
      prayerTimes: prayerTimes ?? this.prayerTimes,
      location: location ?? this.location,
      selectedDate: selectedDate ?? this.selectedDate,
      isRefreshingLocation: isRefreshingLocation ?? this.isRefreshingLocation,
      lastUpdate: lastUpdate ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    prayerTimes,
    location,
    selectedDate,
    isRefreshingLocation,
    lastUpdate,
  ];
}

/// حالة الخطأ
class PrayerTimesError extends PrayerTimesState {
  final String message;
  final GPSErrorType? errorType;

  const PrayerTimesError(this.message, {this.errorType});

  @override
  List<Object?> get props => [message, errorType];
}
