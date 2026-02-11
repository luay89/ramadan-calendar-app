import 'package:equatable/equatable.dart';

/// كيان يوم رمضان
class RamadanDay extends Equatable {
  final int dayNumber;
  final DateTime gregorianDate;
  final DateTime fajrTime;
  final DateTime maghribTime;
  final DateTime suhoorTime;
  final DateTime iftarTime;
  final bool isLaylatalQadr;
  final bool hasSpecialActions;
  final String? specialNote;

  const RamadanDay({
    required this.dayNumber,
    required this.gregorianDate,
    required this.fajrTime,
    required this.maghribTime,
    required this.suhoorTime,
    required this.iftarTime,
    this.isLaylatalQadr = false,
    this.hasSpecialActions = false,
    this.specialNote,
  });

  /// مدة الصيام
  Duration get fastingDuration => maghribTime.difference(fajrTime);

  /// تنسيق مدة الصيام
  String get fastingDurationFormatted {
    final hours = fastingDuration.inHours;
    final minutes = fastingDuration.inMinutes.remainder(60);
    return '$hours ساعة و $minutes دقيقة';
  }

  @override
  List<Object?> get props => [
    dayNumber,
    gregorianDate,
    fajrTime,
    maghribTime,
    suhoorTime,
    iftarTime,
    isLaylatalQadr,
    hasSpecialActions,
    specialNote,
  ];
}
