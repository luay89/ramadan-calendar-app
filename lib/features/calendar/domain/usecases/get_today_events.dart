import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/islamic_event.dart';
import '../repositories/calendar_repository.dart';

/// حالة استخدام: الحصول على أحداث اليوم
class GetTodayEvents implements UseCase<List<IslamicEvent>, NoParams> {
  final CalendarRepository repository;

  GetTodayEvents(this.repository);

  @override
  Future<Either<Failure, List<IslamicEvent>>> call(NoParams params) async {
    return await repository.getTodayEvents();
  }
}
