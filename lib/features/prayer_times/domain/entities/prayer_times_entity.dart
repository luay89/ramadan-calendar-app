import 'package:equatable/equatable.dart';

/// كيان مواقيت الصلاة
class PrayerTimesEntity extends Equatable {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime? midnight; // منتصف الليل الشرعي
  final DateTime? lastThird; // الثلث الأخير من الليل
  final DateTime date;
  final String locationName;
  final double latitude;
  final double longitude;

  const PrayerTimesEntity({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.midnight,
    this.lastThird,
    required this.date,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });

  /// الحصول على قائمة الصلوات الخمس
  Map<String, DateTime> get fivePrayers => {
    'الفجر': fajr,
    'الظهر': dhuhr,
    'العصر': asr,
    'المغرب': maghrib,
    'العشاء': isha,
  };

  /// الحصول على جميع الأوقات
  Map<String, DateTime> get allTimes => {
    'الفجر': fajr,
    'الشروق': sunrise,
    'الظهر': dhuhr,
    'العصر': asr,
    'المغرب': maghrib,
    'العشاء': isha,
    if (midnight != null) 'منتصف الليل': midnight!,
    if (lastThird != null) 'الثلث الأخير': lastThird!,
  };

  @override
  List<Object?> get props => [
    fajr,
    sunrise,
    dhuhr,
    asr,
    maghrib,
    isha,
    midnight,
    lastThird,
    date,
    locationName,
    latitude,
    longitude,
  ];
}

/// كيان الصلاة الفردية
class Prayer extends Equatable {
  final String name;
  final DateTime time;
  final PrayerType type;
  final bool isNext;
  final bool isPassed;

  const Prayer({
    required this.name,
    required this.time,
    required this.type,
    this.isNext = false,
    this.isPassed = false,
  });

  @override
  List<Object> get props => [name, time, type, isNext, isPassed];
}

/// أنواع الصلوات
enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
  midnight,
  lastThird,
}

extension PrayerTypeExtension on PrayerType {
  String get arabicName {
    switch (this) {
      case PrayerType.fajr:
        return 'الفجر';
      case PrayerType.sunrise:
        return 'الشروق';
      case PrayerType.dhuhr:
        return 'الظهر';
      case PrayerType.asr:
        return 'العصر';
      case PrayerType.maghrib:
        return 'المغرب';
      case PrayerType.isha:
        return 'العشاء';
      case PrayerType.midnight:
        return 'منتصف الليل';
      case PrayerType.lastThird:
        return 'الثلث الأخير';
    }
  }
}
