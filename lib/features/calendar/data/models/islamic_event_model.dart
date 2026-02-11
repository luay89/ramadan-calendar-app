// Hive model for Islamic events
import '../../domain/entities/islamic_event.dart';

// Note: Run `flutter pub run build_runner build` to generate the .g.dart file
// part 'islamic_event_model.g.dart';

// @HiveType(typeId: 0)
class IslamicEventModel {
  // @HiveField(0)
  final String id;

  // @HiveField(1)
  final String title;

  // @HiveField(2)
  final String description;

  // @HiveField(3)
  final int hijriMonth;

  // @HiveField(4)
  final int hijriDay;

  // @HiveField(5)
  final int typeIndex;

  // @HiveField(6)
  final int importanceIndex;

  // @HiveField(7)
  final List<String>? actions;

  // @HiveField(8)
  final bool isMourning;

  // @HiveField(9)
  final bool isHoliday;

  // @HiveField(10)
  final String? imam;

  IslamicEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.hijriMonth,
    required this.hijriDay,
    required this.typeIndex,
    required this.importanceIndex,
    this.actions,
    this.isMourning = false,
    this.isHoliday = false,
    this.imam,
  });

  /// تحويل من JSON
  factory IslamicEventModel.fromJson(Map<String, dynamic> json) {
    return IslamicEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      hijriMonth: json['hijri_month'] as int,
      hijriDay: json['hijri_day'] as int,
      typeIndex: json['type'] as int,
      importanceIndex: json['importance'] as int,
      actions: (json['actions'] as List<dynamic>?)?.cast<String>(),
      isMourning: json['is_mourning'] as bool? ?? false,
      isHoliday: json['is_holiday'] as bool? ?? false,
      imam: json['imam'] as String?,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'hijri_month': hijriMonth,
      'hijri_day': hijriDay,
      'type': typeIndex,
      'importance': importanceIndex,
      'actions': actions,
      'is_mourning': isMourning,
      'is_holiday': isHoliday,
      'imam': imam,
    };
  }

  /// تحويل إلى Entity
  IslamicEvent toEntity() {
    return IslamicEvent(
      id: id,
      title: title,
      description: description,
      hijriMonth: hijriMonth,
      hijriDay: hijriDay,
      type: EventType.values[typeIndex],
      importance: EventImportance.values[importanceIndex],
      actions: actions,
      isMourning: isMourning,
      isHoliday: isHoliday,
      imam: imam,
    );
  }

  /// تحويل من Entity
  factory IslamicEventModel.fromEntity(IslamicEvent entity) {
    return IslamicEventModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      hijriMonth: entity.hijriMonth,
      hijriDay: entity.hijriDay,
      typeIndex: entity.type.index,
      importanceIndex: entity.importance.index,
      actions: entity.actions,
      isMourning: entity.isMourning,
      isHoliday: entity.isHoliday,
      imam: entity.imam,
    );
  }
}
