import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dua_entity.dart';

/// واجهة مستودع الأدعية
abstract class DuasRepository {
  /// الحصول على جميع الأدعية
  Future<Either<Failure, List<DuaEntity>>> getAllDuas();

  /// الحصول على الأدعية حسب التصنيف
  Future<Either<Failure, List<DuaEntity>>> getDuasByCategory(
    DuaCategory category,
  );

  /// الحصول على دعاء بالمعرف
  Future<Either<Failure, DuaEntity>> getDuaById(String id);

  /// البحث في الأدعية
  Future<Either<Failure, List<DuaEntity>>> searchDuas(String query);

  /// الحصول على المفضلة
  Future<Either<Failure, List<DuaEntity>>> getFavorites();

  /// إضافة/إزالة من المفضلة
  Future<Either<Failure, void>> toggleFavorite(String duaId);

  /// الحصول على أدعية اليوم
  Future<Either<Failure, List<DuaEntity>>> getTodayDuas();

  /// الحصول على أدعية الليلة
  Future<Either<Failure, List<DuaEntity>>> getTonightDuas();

  /// الحصول على الزيارات
  Future<Either<Failure, List<DuaEntity>>> getZiyarat();

  /// الحصول على أدعية يوم معين من الأسبوع
  Future<Either<Failure, List<DuaEntity>>> getDuasForWeekday(int weekday);
}
