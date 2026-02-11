part of 'calendar_bloc.dart';

/// حالات التقويم
abstract class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

/// الحالة الابتدائية
class CalendarInitial extends CalendarState {}

/// حالة التحميل
class CalendarLoading extends CalendarState {}

/// حالة التحميل الناجح
class CalendarLoaded extends CalendarState {
  final List<CalendarDay> days;
  final List<IslamicEvent> events;
  final int currentMonth;
  final int currentYear;
  final bool isHijri;
  final CalendarDay? selectedDay;
  final List<IslamicEvent>? selectedDayEvents;
  final List<IslamicEvent>? todayEvents;

  const CalendarLoaded({
    required this.days,
    required this.events,
    required this.currentMonth,
    required this.currentYear,
    required this.isHijri,
    this.selectedDay,
    this.selectedDayEvents,
    this.todayEvents,
  });

  CalendarLoaded copyWith({
    List<CalendarDay>? days,
    List<IslamicEvent>? events,
    int? currentMonth,
    int? currentYear,
    bool? isHijri,
    CalendarDay? selectedDay,
    List<IslamicEvent>? selectedDayEvents,
    List<IslamicEvent>? todayEvents,
  }) {
    return CalendarLoaded(
      days: days ?? this.days,
      events: events ?? this.events,
      currentMonth: currentMonth ?? this.currentMonth,
      currentYear: currentYear ?? this.currentYear,
      isHijri: isHijri ?? this.isHijri,
      selectedDay: selectedDay ?? this.selectedDay,
      selectedDayEvents: selectedDayEvents ?? this.selectedDayEvents,
      todayEvents: todayEvents ?? this.todayEvents,
    );
  }

  @override
  List<Object?> get props => [
    days,
    events,
    currentMonth,
    currentYear,
    isHijri,
    selectedDay,
    selectedDayEvents,
    todayEvents,
  ];
}

/// حالة الخطأ
class CalendarError extends CalendarState {
  final String message;

  const CalendarError(this.message);

  @override
  List<Object> get props => [message];
}
