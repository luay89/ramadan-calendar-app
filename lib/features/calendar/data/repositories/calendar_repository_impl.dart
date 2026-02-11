import 'package:dartz/dartz.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/calendar_day.dart';
import '../../domain/entities/islamic_event.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_local_datasource.dart';

/// تنفيذ مستودع التقويم
class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarLocalDataSource localDataSource;

  CalendarRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<IslamicEvent>>> getAllEvents() async {
    try {
      final events = await localDataSource.getAllEvents();
      return Right(events.map((e) => e.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message ?? 'خطأ في التخزين المحلي'));
    }
  }

  @override
  Future<Either<Failure, List<IslamicEvent>>> getEventsForMonth(
    int hijriYear,
    int hijriMonth,
  ) async {
    try {
      final events = await localDataSource.getEventsForMonth(hijriMonth);
      return Right(events.map((e) => e.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message ?? 'خطأ في التخزين المحلي'));
    }
  }

  @override
  Future<Either<Failure, List<IslamicEvent>>> getEventsForDay(
    int hijriYear,
    int hijriMonth,
    int hijriDay,
  ) async {
    try {
      final events = await localDataSource.getEventsForDay(
        hijriMonth,
        hijriDay,
      );
      return Right(events.map((e) => e.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message ?? 'خطأ في التخزين المحلي'));
    }
  }

  @override
  Future<Either<Failure, List<CalendarDay>>> getCalendarDays(
    int year,
    int month,
    bool isHijri,
  ) async {
    try {
      final events = await localDataSource.getAllEvents();
      final List<CalendarDay> days = [];

      if (isHijri) {
        // التقويم الهجري
        final hijri = HijriCalendar();
        final daysInMonth = hijri.getDaysInMonth(year, month);

        // الحصول على أول يوم في الشهر لمعرفة يوم الأسبوع
        hijri.hYear = year;
        hijri.hMonth = month;
        hijri.hDay = 1;
        final firstDayGregorian = AppDateUtils.hijriToGregorian(hijri);

        // حساب موقع اليوم الأول في الأسبوع (0 = الأحد)
        // Dart weekday: 1=Mon, 2=Tue, ..., 7=Sun
        // نريد: 0=الأحد, 1=الإثنين, ...
        final firstDayWeekday = firstDayGregorian.weekday % 7;

        // إضافة أيام فارغة في بداية الشهر
        for (int i = 0; i < firstDayWeekday; i++) {
          days.add(CalendarDay.empty());
        }

        for (int day = 1; day <= daysInMonth; day++) {
          hijri.hYear = year;
          hijri.hMonth = month;
          hijri.hDay = day;

          final gregorian = AppDateUtils.hijriToGregorian(hijri);
          final today = AppDateUtils.currentHijri;

          final dayEvents =
              events
                  .where((e) => e.hijriMonth == month && e.hijriDay == day)
                  .toList();

          days.add(
            CalendarDay(
              gregorianDate: gregorian,
              hijriDate:
                  HijriCalendar()
                    ..hYear = year
                    ..hMonth = month
                    ..hDay = day,
              isToday:
                  today.hYear == year &&
                  today.hMonth == month &&
                  today.hDay == day,
              hasEvent: dayEvents.isNotEmpty,
              isMourning: dayEvents.any((e) => e.isMourning),
              isHoliday: dayEvents.any((e) => e.isHoliday),
              isSpecialNight: _isSpecialNight(month, day),
              isFridayNight: gregorian.weekday == DateTime.thursday,
              isWhiteNight: AppDateUtils.isWhiteNight(hijri),
              isLaylatalQadr: AppDateUtils.isLaylatalQadrNight(hijri),
            ),
          );
        }
      } else {
        // التقويم الميلادي
        final daysInMonth = DateTime(year, month + 1, 0).day;

        // الحصول على أول يوم في الشهر
        final firstDayGregorian = DateTime(year, month, 1);

        // حساب موقع اليوم الأول في الأسبوع (0 = الأحد)
        final firstDayWeekday = firstDayGregorian.weekday % 7;

        // إضافة أيام فارغة في بداية الشهر
        for (int i = 0; i < firstDayWeekday; i++) {
          days.add(CalendarDay.empty());
        }

        for (int day = 1; day <= daysInMonth; day++) {
          final gregorian = DateTime(year, month, day);
          final hijri = AppDateUtils.gregorianToHijri(gregorian);
          final today = DateTime.now();

          final dayEvents =
              events
                  .where(
                    (e) =>
                        e.hijriMonth == hijri.hMonth &&
                        e.hijriDay == hijri.hDay,
                  )
                  .toList();

          days.add(
            CalendarDay(
              gregorianDate: gregorian,
              hijriDate: hijri,
              isToday:
                  today.year == year &&
                  today.month == month &&
                  today.day == day,
              hasEvent: dayEvents.isNotEmpty,
              isMourning: dayEvents.any((e) => e.isMourning),
              isHoliday: dayEvents.any((e) => e.isHoliday),
              isSpecialNight: _isSpecialNight(hijri.hMonth, hijri.hDay),
              isFridayNight: gregorian.weekday == DateTime.thursday,
              isWhiteNight: AppDateUtils.isWhiteNight(hijri),
              isLaylatalQadr: AppDateUtils.isLaylatalQadrNight(hijri),
            ),
          );
        }
      }

      return Right(days);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message ?? 'خطأ في التخزين المحلي'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, List<IslamicEvent>>> searchEvents(String query) async {
    try {
      final events = await localDataSource.searchEvents(query);
      return Right(events.map((e) => e.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message ?? 'خطأ في البحث'));
    }
  }

  @override
  Future<Either<Failure, List<IslamicEvent>>> getUpcomingEvents(
    int limit,
  ) async {
    try {
      final events = await localDataSource.getAllEvents();
      final today = AppDateUtils.currentHijri;

      // فرز الأحداث حسب القرب من التاريخ الحالي
      final sortedEvents =
          events.map((e) => e.toEntity()).toList()..sort((a, b) {
            final aDays = _getDaysUntilEvent(today, a);
            final bDays = _getDaysUntilEvent(today, b);
            return aDays.compareTo(bDays);
          });

      return Right(sortedEvents.take(limit).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message ?? 'خطأ في التخزين المحلي'));
    }
  }

  @override
  Future<Either<Failure, List<IslamicEvent>>> getTodayEvents() async {
    try {
      final today = AppDateUtils.currentHijri;
      final events = await localDataSource.getEventsForDay(
        today.hMonth,
        today.hDay,
      );
      return Right(events.map((e) => e.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message ?? 'خطأ في التخزين المحلي'));
    }
  }

  /// حساب عدد الأيام حتى الحدث
  int _getDaysUntilEvent(HijriCalendar today, IslamicEvent event) {
    if (event.hijriMonth > today.hMonth) {
      return (event.hijriMonth - today.hMonth) * 30 +
          (event.hijriDay - today.hDay);
    } else if (event.hijriMonth == today.hMonth) {
      if (event.hijriDay >= today.hDay) {
        return event.hijriDay - today.hDay;
      }
      return 354 - (today.hDay - event.hijriDay); // العام القادم
    }
    return (12 - today.hMonth + event.hijriMonth) * 30 +
        (event.hijriDay - today.hDay);
  }

  /// التحقق من الليالي الخاصة
  bool _isSpecialNight(int month, int day) {
    // ليالي رمضان الخاصة
    if (month == 9 && [19, 21, 23].contains(day)) return true;
    // ليلة النصف من شعبان
    if (month == 8 && day == 15) return true;
    // ليالي رجب
    if (month == 7 && [1, 13, 15, 27].contains(day)) return true;
    return false;
  }
}
