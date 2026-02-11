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
  final bool isSearching;
  final List<LocationEntity>? searchResults;

  const PrayerTimesLoaded({
    required this.prayerTimes,
    required this.location,
    required this.selectedDate,
    this.isSearching = false,
    this.searchResults,
  });

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
    bool? isSearching,
    List<LocationEntity>? searchResults,
  }) {
    return PrayerTimesLoaded(
      prayerTimes: prayerTimes ?? this.prayerTimes,
      location: location ?? this.location,
      selectedDate: selectedDate ?? this.selectedDate,
      isSearching: isSearching ?? this.isSearching,
      searchResults: searchResults ?? this.searchResults,
    );
  }

  @override
  List<Object?> get props => [
    prayerTimes,
    location,
    selectedDate,
    isSearching,
    searchResults,
    DateTime.now().second, // لتحديث العد التنازلي
  ];
}

/// حالة الخطأ
class PrayerTimesError extends PrayerTimesState {
  final String message;

  const PrayerTimesError(this.message);

  @override
  List<Object> get props => [message];
}
