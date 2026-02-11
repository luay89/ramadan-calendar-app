import 'package:hive/hive.dart';
import '../../domain/entities/location_entity.dart';

@HiveType(typeId: 1)
class LocationModel extends HiveObject {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final String? cityName;

  @HiveField(3)
  final String? countryName;

  @HiveField(4)
  final String? timezone;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.cityName,
    this.countryName,
    this.timezone,
  });

  /// تحويل إلى Entity
  LocationEntity toEntity() {
    return LocationEntity(
      latitude: latitude,
      longitude: longitude,
      cityName: cityName,
      countryName: countryName,
      timezone: timezone,
    );
  }

  /// إنشاء من Entity
  factory LocationModel.fromEntity(LocationEntity entity) {
    return LocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      cityName: entity.cityName,
      countryName: entity.countryName,
      timezone: entity.timezone,
    );
  }

  /// إنشاء من JSON
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      cityName: json['city_name'] as String?,
      countryName: json['country_name'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city_name': cityName,
      'country_name': countryName,
      'timezone': timezone,
    };
  }
}
