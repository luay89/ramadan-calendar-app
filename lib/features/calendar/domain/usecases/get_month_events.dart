import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/islamic_event.dart';
import '../repositories/calendar_repository.dart';

/// حالة استخدام: الحصول على أحداث شهر معين
class GetMonthEvents implements UseCase<List<IslamicEvent>, MonthParams> {
  final CalendarRepository repository;

  GetMonthEvents(this.repository);

  @override
  Future<Either<Failure, List<IslamicEvent>>> call(MonthParams params) async {
    return await repository.getEventsForMonth(
      params.hijriYear,
      params.hijriMonth,
    );
  }
}

/// معاملات الشهر
class MonthParams extends Equatable {
  final int hijriYear;
  final int hijriMonth;

  const MonthParams({required this.hijriYear, required this.hijriMonth});

  @override
  List<Object> get props => [hijriYear, hijriMonth];
}
