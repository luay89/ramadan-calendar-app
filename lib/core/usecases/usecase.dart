import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// واجهة UseCase الأساسية
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// معاملات فارغة للـ UseCases التي لا تحتاج معاملات
class NoParams {
  const NoParams();
}
