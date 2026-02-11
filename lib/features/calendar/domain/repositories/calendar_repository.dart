import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/islamic_event.dart';
import '../entities/calendar_day.dart';

/// واجهة مستودع التقويم
abstract class CalendarRepository {
  /// الحصول على أحداث شهر معين
  Future<Either<Failure, List<IslamicEvent>>> getEventsForMonth(
    int hijriYear,
    int hijriMonth,
  );

  /// الحصول على أحداث يوم معين
  Future<Either<Failure, List<IslamicEvent>>> getEventsForDay(
    int hijriYear,
    int hijriMonth,
    int hijriDay,
  );

  /// الحصول على جميع الأحداث
  Future<Either<Failure, List<IslamicEvent>>> getAllEvents();

  /// الحصول على أيام التقويم لشهر معين
  Future<Either<Failure, List<CalendarDay>>> getCalendarDays(
    int year,
    int month,
    bool isHijri,
  );

  /// البحث عن أحداث
  Future<Either<Failure, List<IslamicEvent>>> searchEvents(String query);

  /// الحصول على الأحداث القادمة
  Future<Either<Failure, List<IslamicEvent>>> getUpcomingEvents(int limit);

  /// الحصول على أحداث اليوم
  Future<Either<Failure, List<IslamicEvent>>> getTodayEvents();
}
