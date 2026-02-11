// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calibration_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalibrationSettingsAdapter extends TypeAdapter<CalibrationSettings> {
  @override
  final int typeId = 51;

  @override
  CalibrationSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalibrationSettings(
      hijriDayAdjustment: fields[0] as int,
      calculationMethodName: fields[1] as String,
      customFajrAngle: fields[2] as double?,
      customIshaAngle: fields[3] as double?,
      customMaghribAngle: fields[4] as double?,
      maghribDelay: fields[5] as int,
      ishaInterval: fields[6] as int?,
      asrCalculationName: fields[7] as String,
      midnightMethodName: fields[8] as String,
      highLatitudeRuleName: fields[9] as String,
      fajrAdjustment: fields[10] as int,
      sunriseAdjustment: fields[11] as int,
      dhuhrAdjustment: fields[12] as int,
      asrAdjustment: fields[13] as int,
      maghribAdjustment: fields[14] as int,
      ishaAdjustment: fields[15] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CalibrationSettings obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.hijriDayAdjustment)
      ..writeByte(1)
      ..write(obj.calculationMethodName)
      ..writeByte(2)
      ..write(obj.customFajrAngle)
      ..writeByte(3)
      ..write(obj.customIshaAngle)
      ..writeByte(4)
      ..write(obj.customMaghribAngle)
      ..writeByte(5)
      ..write(obj.maghribDelay)
      ..writeByte(6)
      ..write(obj.ishaInterval)
      ..writeByte(7)
      ..write(obj.asrCalculationName)
      ..writeByte(8)
      ..write(obj.midnightMethodName)
      ..writeByte(9)
      ..write(obj.highLatitudeRuleName)
      ..writeByte(10)
      ..write(obj.fajrAdjustment)
      ..writeByte(11)
      ..write(obj.sunriseAdjustment)
      ..writeByte(12)
      ..write(obj.dhuhrAdjustment)
      ..writeByte(13)
      ..write(obj.asrAdjustment)
      ..writeByte(14)
      ..write(obj.maghribAdjustment)
      ..writeByte(15)
      ..write(obj.ishaAdjustment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalibrationSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
