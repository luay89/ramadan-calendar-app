import 'package:equatable/equatable.dart';
import 'package:hijri/hijri_calendar.dart';

/// كيان اليوم في التقويم
class CalendarDay extends Equatable {
  final DateTime gregorianDate;
  final HijriCalendar hijriDate;
  final bool isToday;
  final bool isSelected;
  final bool hasEvent;
  final bool isMourning;
  final bool isHoliday;
  final bool isSpecialNight;
  final bool isFridayNight;
  final bool isWhiteNight;
  final bool isLaylatalQadr;
  final bool isEmpty; // يوم فارغ للتنسيق

  const CalendarDay({
    required this.gregorianDate,
    required this.hijriDate,
    this.isToday = false,
    this.isSelected = false,
    this.hasEvent = false,
    this.isMourning = false,
    this.isHoliday = false,
    this.isSpecialNight = false,
    this.isFridayNight = false,
    this.isWhiteNight = false,
    this.isLaylatalQadr = false,
    this.isEmpty = false,
  });

  /// إنشاء يوم فارغ (للتنسيق في بداية الشهر)
  factory CalendarDay.empty() {
    return CalendarDay(
      gregorianDate: DateTime(1970, 1, 1),
      hijriDate:
          HijriCalendar()
            ..hYear = 1
            ..hMonth = 1
            ..hDay = 1,
      isEmpty: true,
    );
  }

  CalendarDay copyWith({
    DateTime? gregorianDate,
    HijriCalendar? hijriDate,
    bool? isToday,
    bool? isSelected,
    bool? hasEvent,
    bool? isMourning,
    bool? isHoliday,
    bool? isSpecialNight,
    bool? isFridayNight,
    bool? isWhiteNight,
    bool? isLaylatalQadr,
    bool? isEmpty,
  }) {
    return CalendarDay(
      gregorianDate: gregorianDate ?? this.gregorianDate,
      hijriDate: hijriDate ?? this.hijriDate,
      isToday: isToday ?? this.isToday,
      isSelected: isSelected ?? this.isSelected,
      hasEvent: hasEvent ?? this.hasEvent,
      isMourning: isMourning ?? this.isMourning,
      isHoliday: isHoliday ?? this.isHoliday,
      isSpecialNight: isSpecialNight ?? this.isSpecialNight,
      isFridayNight: isFridayNight ?? this.isFridayNight,
      isWhiteNight: isWhiteNight ?? this.isWhiteNight,
      isLaylatalQadr: isLaylatalQadr ?? this.isLaylatalQadr,
      isEmpty: isEmpty ?? this.isEmpty,
    );
  }

  @override
  List<Object?> get props => [
    gregorianDate,
    hijriDate.hYear,
    hijriDate.hMonth,
    hijriDate.hDay,
    isToday,
    isSelected,
    hasEvent,
    isMourning,
    isHoliday,
    isSpecialNight,
    isFridayNight,
    isWhiteNight,
    isLaylatalQadr,
    isEmpty,
  ];
}
