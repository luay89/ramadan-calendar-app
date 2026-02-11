import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ramadan_day.dart';
import '../entities/laylatal_qadr_action.dart';

/// واجهة مستودع رمضان
abstract class RamadanRepository {
  /// الحصول على إمساكية رمضان
  Future<Either<Failure, List<RamadanDay>>> getRamadanCalendar({
    required int hijriYear,
    required double latitude,
    required double longitude,
    String? locationName,
  });

  /// الحصول على يوم رمضان الحالي
  Future<Either<Failure, RamadanDay?>> getCurrentRamadanDay({
    required double latitude,
    required double longitude,
  });

  /// الحصول على أعمال ليلة القدر
  Future<Either<Failure, List<LaylatalQadrAction>>> getLaylatalQadrActions(
    int nightNumber,
  );

  /// حفظ حالة إتمام العمل
  Future<Either<Failure, void>> saveActionCompletion(
    String actionId,
    bool isCompleted,
  );

  /// الحصول على حالات الإتمام المحفوظة
  Future<Either<Failure, Map<String, bool>>> getSavedCompletions();

  /// الحصول على الأعمال المشتركة لليالي القدر
  Future<Either<Failure, List<LaylatalQadrAction>>>
  getCommonLaylatalQadrActions();

  /// الحصول على أعمال ليلة 19
  Future<Either<Failure, List<LaylatalQadrAction>>> getNight19Actions();

  /// الحصول على أعمال ليلة 21
  Future<Either<Failure, List<LaylatalQadrAction>>> getNight21Actions();

  /// الحصول على أعمال ليلة 23
  Future<Either<Failure, List<LaylatalQadrAction>>> getNight23Actions();
}
