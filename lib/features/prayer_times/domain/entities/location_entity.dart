import 'package:equatable/equatable.dart';

/// كيان الموقع الجغرافي
class LocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final String? cityName;
  final String? countryName;
  final String? timezone;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    this.cityName,
    this.countryName,
    this.timezone,
  });

  /// اسم الموقع الكامل
  String get fullName {
    if (cityName != null && countryName != null) {
      return '$cityName، $countryName';
    }
    return cityName ?? countryName ?? 'موقع غير معروف';
  }

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    cityName,
    countryName,
    timezone,
  ];
}
