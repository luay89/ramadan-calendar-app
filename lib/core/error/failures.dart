import 'package:equatable/equatable.dart';

/// أنواع الأخطاء في التطبيق
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// خطأ في الخادم
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'حدث خطأ في الخادم', super.code});
}

/// خطأ في الاتصال بالإنترنت
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'لا يوجد اتصال بالإنترنت', super.code});
}

/// خطأ في التخزين المحلي
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'حدث خطأ في التخزين المحلي', super.code});
}

/// خطأ في قاعدة البيانات
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'حدث خطأ في قاعدة البيانات',
    super.code,
  });
}

/// خطأ في الموقع الجغرافي
class LocationFailure extends Failure {
  const LocationFailure({super.message = 'لا يمكن تحديد الموقع', super.code});
}

/// خطأ في صلاحيات التطبيق
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'لم يتم منح الإذن المطلوب',
    super.code,
  });
}

/// خطأ في التحقق من البيانات
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'البيانات المدخلة غير صحيحة',
    super.code,
  });
}

/// خطأ غير متوقع
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message = 'حدث خطأ غير متوقع', super.code});
}

/// خطأ في التاريخ/الوقت
class DateTimeFailure extends Failure {
  const DateTimeFailure({
    super.message = 'خطأ في معالجة التاريخ/الوقت',
    super.code,
  });
}

/// خطأ في ملفات البيانات
class DataFileFailure extends Failure {
  const DataFileFailure({
    super.message = 'خطأ في قراءة ملفات البيانات',
    super.code,
  });
}
