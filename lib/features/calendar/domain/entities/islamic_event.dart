import 'package:equatable/equatable.dart';
import 'package:hijri/hijri_calendar.dart';

/// كيان الحدث الإسلامي
class IslamicEvent extends Equatable {
  final String id;
  final String title;
  final String description;
  final int hijriMonth;
  final int hijriDay;
  final EventType type;
  final EventImportance importance;
  final List<String>? actions; // الأعمال المستحبة
  final bool isMourning; // هل هي مناسبة حزينة
  final bool isHoliday; // هل هي عطلة
  final String? imam; // الإمام المرتبط بالمناسبة

  const IslamicEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.hijriMonth,
    required this.hijriDay,
    required this.type,
    required this.importance,
    this.actions,
    this.isMourning = false,
    this.isHoliday = false,
    this.imam,
  });

  /// التحقق من تطابق الحدث مع تاريخ هجري معين
  bool matchesDate(HijriCalendar hijri) {
    return hijri.hMonth == hijriMonth && hijri.hDay == hijriDay;
  }

  /// الحصول على التاريخ الهجري للحدث في سنة معينة
  HijriCalendar getHijriDate(int year) {
    final hijri = HijriCalendar();
    hijri.hYear = year;
    hijri.hMonth = hijriMonth;
    hijri.hDay = hijriDay;
    return hijri;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    hijriMonth,
    hijriDay,
    type,
    importance,
    actions,
    isMourning,
    isHoliday,
    imam,
  ];
}

/// أنواع الأحداث
enum EventType {
  birth, // ولادة
  martyrdom, // شهادة
  death, // وفاة
  eid, // عيد
  religious, // ديني
  historical, // تاريخي
  special, // مناسبة خاصة
}

/// أهمية الحدث
enum EventImportance {
  high, // عالية (أعياد، شهادات الأئمة)
  medium, // متوسطة
  low, // منخفضة
}

/// امتداد للحصول على أسماء عربية
extension EventTypeExtension on EventType {
  String get arabicName {
    switch (this) {
      case EventType.birth:
        return 'ولادة';
      case EventType.martyrdom:
        return 'شهادة';
      case EventType.death:
        return 'وفاة';
      case EventType.eid:
        return 'عيد';
      case EventType.religious:
        return 'ديني';
      case EventType.historical:
        return 'تاريخي';
      case EventType.special:
        return 'مناسبة خاصة';
    }
  }
}

extension EventImportanceExtension on EventImportance {
  String get arabicName {
    switch (this) {
      case EventImportance.high:
        return 'عالية';
      case EventImportance.medium:
        return 'متوسطة';
      case EventImportance.low:
        return 'منخفضة';
    }
  }
}
