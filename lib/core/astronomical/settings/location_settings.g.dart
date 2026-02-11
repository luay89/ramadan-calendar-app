// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationSettingsAdapter extends TypeAdapter<LocationSettings> {
  @override
  final int typeId = 50;

  @override
  LocationSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationSettings(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      timezone: fields[2] as double,
      locationName: fields[3] as String?,
      country: fields[4] as String?,
      elevation: fields[5] as double?,
      isAutoDetected: fields[6] as bool,
      lastUpdated: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LocationSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.timezone)
      ..writeByte(3)
      ..write(obj.locationName)
      ..writeByte(4)
      ..write(obj.country)
      ..writeByte(5)
      ..write(obj.elevation)
      ..writeByte(6)
      ..write(obj.isAutoDetected)
      ..writeByte(7)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
