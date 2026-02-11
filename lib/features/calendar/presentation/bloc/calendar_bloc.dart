import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/calendar_day.dart';
import '../../domain/entities/islamic_event.dart';
import '../../domain/usecases/get_calendar_days.dart';
import '../../domain/usecases/get_month_events.dart';
import '../../domain/usecases/get_today_events.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

/// Bloc التقويم
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final GetCalendarDays getCalendarDays;
  final GetMonthEvents getMonthEvents;
  final GetTodayEvents getTodayEvents;

  CalendarBloc({
    required this.getCalendarDays,
    required this.getMonthEvents,
    required this.getTodayEvents,
  }) : super(CalendarInitial()) {
    on<LoadCalendarDays>(_onLoadCalendarDays);
    on<SelectDay>(_onSelectDay);
    on<ChangeMonth>(_onChangeMonth);
    on<ToggleCalendarType>(_onToggleCalendarType);
    on<LoadTodayEvents>(_onLoadTodayEvents);
  }

  /// تحميل أيام التقويم
  Future<void> _onLoadCalendarDays(
    LoadCalendarDays event,
    Emitter<CalendarState> emit,
  ) async {
    emit(CalendarLoading());

    final daysResult = await getCalendarDays(
      CalendarDaysParams(
        year: event.year,
        month: event.month,
        isHijri: event.isHijri,
      ),
    );

    final eventsResult = await getMonthEvents(
      MonthParams(hijriYear: event.year, hijriMonth: event.month),
    );

    daysResult.fold((failure) => emit(CalendarError(failure.message)), (days) {
      eventsResult.fold(
        (failure) => emit(
          CalendarLoaded(
            days: days,
            events: [],
            currentMonth: event.month,
            currentYear: event.year,
            isHijri: event.isHijri,
          ),
        ),
        (events) => emit(
          CalendarLoaded(
            days: days,
            events: events,
            currentMonth: event.month,
            currentYear: event.year,
            isHijri: event.isHijri,
          ),
        ),
      );
    });
  }

  /// اختيار يوم معين
  Future<void> _onSelectDay(
    SelectDay event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;

      // تحديث الأيام مع تحديد اليوم المختار
      final updatedDays =
          currentState.days.map((day) {
            if (day.gregorianDate == event.day.gregorianDate) {
              return day.copyWith(isSelected: true);
            }
            return day.copyWith(isSelected: false);
          }).toList();

      // الحصول على أحداث اليوم المحدد
      final selectedDayEvents =
          currentState.events
              .where((e) => e.matchesDate(event.day.hijriDate))
              .toList();

      emit(
        CalendarLoaded(
          days: updatedDays,
          events: currentState.events,
          currentMonth: currentState.currentMonth,
          currentYear: currentState.currentYear,
          isHijri: currentState.isHijri,
          selectedDay: event.day,
          selectedDayEvents: selectedDayEvents,
        ),
      );
    }
  }

  /// تغيير الشهر
  Future<void> _onChangeMonth(
    ChangeMonth event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;

      int newMonth = currentState.currentMonth + event.delta;
      int newYear = currentState.currentYear;

      if (newMonth > 12) {
        newMonth = 1;
        newYear++;
      } else if (newMonth < 1) {
        newMonth = 12;
        newYear--;
      }

      add(
        LoadCalendarDays(
          year: newYear,
          month: newMonth,
          isHijri: currentState.isHijri,
        ),
      );
    }
  }

  /// تبديل نوع التقويم (هجري/ميلادي)
  Future<void> _onToggleCalendarType(
    ToggleCalendarType event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;
      final newIsHijri = !currentState.isHijri;

      if (newIsHijri) {
        final today = AppDateUtils.currentHijri;
        add(
          LoadCalendarDays(
            year: today.hYear,
            month: today.hMonth,
            isHijri: true,
          ),
        );
      } else {
        final today = DateTime.now();
        add(
          LoadCalendarDays(
            year: today.year,
            month: today.month,
            isHijri: false,
          ),
        );
      }
    }
  }

  /// تحميل أحداث اليوم
  Future<void> _onLoadTodayEvents(
    LoadTodayEvents event,
    Emitter<CalendarState> emit,
  ) async {
    final result = await getTodayEvents(const NoParams());

    result.fold(
      (failure) => null, // لا نغير الحالة عند الفشل
      (events) {
        if (state is CalendarLoaded) {
          final currentState = state as CalendarLoaded;
          emit(currentState.copyWith(todayEvents: events));
        }
      },
    );
  }
}
