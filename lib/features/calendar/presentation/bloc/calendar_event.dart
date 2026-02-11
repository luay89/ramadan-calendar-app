part of 'calendar_bloc.dart';

/// أحداث التقويم
abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

/// تحميل أيام التقويم
class LoadCalendarDays extends CalendarEvent {
  final int year;
  final int month;
  final bool isHijri;

  const LoadCalendarDays({
    required this.year,
    required this.month,
    this.isHijri = true,
  });

  @override
  List<Object> get props => [year, month, isHijri];
}

/// اختيار يوم
class SelectDay extends CalendarEvent {
  final CalendarDay day;

  const SelectDay(this.day);

  @override
  List<Object> get props => [day];
}

/// تغيير الشهر
class ChangeMonth extends CalendarEvent {
  final int delta; // +1 للشهر التالي، -1 للشهر السابق

  const ChangeMonth(this.delta);

  @override
  List<Object> get props => [delta];
}

/// تبديل نوع التقويم
class ToggleCalendarType extends CalendarEvent {
  const ToggleCalendarType();
}

/// تحميل أحداث اليوم
class LoadTodayEvents extends CalendarEvent {
  const LoadTodayEvents();
}
