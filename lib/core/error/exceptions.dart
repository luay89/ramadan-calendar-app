/// الاستثناءات المخصصة للتطبيق
library;

/// استثناء الخادم
class ServerException implements Exception {
  final String? message;
  final int? statusCode;

  ServerException({this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// استثناء الشبكة
class NetworkException implements Exception {
  final String? message;

  NetworkException({this.message});

  @override
  String toString() => 'NetworkException: $message';
}

/// استثناء التخزين المؤقت
class CacheException implements Exception {
  final String? message;

  CacheException({this.message});

  @override
  String toString() => 'CacheException: $message';
}

/// استثناء قاعدة البيانات
class DatabaseException implements Exception {
  final String? message;

  DatabaseException({this.message});

  @override
  String toString() => 'DatabaseException: $message';
}

/// استثناء الموقع
class LocationException implements Exception {
  final String? message;

  LocationException({this.message});

  @override
  String toString() => 'LocationException: $message';
}

/// استثناء الصلاحيات
class PermissionException implements Exception {
  final String? message;

  PermissionException({this.message});

  @override
  String toString() => 'PermissionException: $message';
}

/// استثناء التحقق
class ValidationException implements Exception {
  final String? message;
  final Map<String, String>? errors;

  ValidationException({this.message, this.errors});

  @override
  String toString() => 'ValidationException: $message';
}

/// استثناء ملفات البيانات
class DataFileException implements Exception {
  final String? message;
  final String? filePath;

  DataFileException({this.message, this.filePath});

  @override
  String toString() => 'DataFileException: $message (File: $filePath)';
}
