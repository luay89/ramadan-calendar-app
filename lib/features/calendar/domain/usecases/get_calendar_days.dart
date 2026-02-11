import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/calendar_day.dart';
import '../repositories/calendar_repository.dart';

/// حالة استخدام: الحصول على أيام التقويم
class GetCalendarDays
    implements UseCase<List<CalendarDay>, CalendarDaysParams> {
  final CalendarRepository repository;

  GetCalendarDays(this.repository);

  @override
  Future<Either<Failure, List<CalendarDay>>> call(
    CalendarDaysParams params,
  ) async {
    return await repository.getCalendarDays(
      params.year,
      params.month,
      params.isHijri,
    );
  }
}

/// معاملات أيام التقويم
class CalendarDaysParams extends Equatable {
  final int year;
  final int month;
  final bool isHijri;

  const CalendarDaysParams({
    required this.year,
    required this.month,
    this.isHijri = true,
  });

  @override
  List<Object> get props => [year, month, isHijri];
}
