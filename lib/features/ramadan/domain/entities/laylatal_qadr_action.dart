import 'package:equatable/equatable.dart';

/// كيان أعمال ليلة القدر
class LaylatalQadrAction extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? arabicText;
  final ActionType type;
  final int? repeatCount;
  final int order;
  final bool isCompleted;

  const LaylatalQadrAction({
    required this.id,
    required this.title,
    required this.description,
    this.arabicText,
    required this.type,
    this.repeatCount,
    required this.order,
    this.isCompleted = false,
  });

  LaylatalQadrAction copyWith({
    String? id,
    String? title,
    String? description,
    String? arabicText,
    ActionType? type,
    int? repeatCount,
    int? order,
    bool? isCompleted,
  }) {
    return LaylatalQadrAction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      arabicText: arabicText ?? this.arabicText,
      type: type ?? this.type,
      repeatCount: repeatCount ?? this.repeatCount,
      order: order ?? this.order,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    arabicText,
    type,
    repeatCount,
    order,
    isCompleted,
  ];
}

/// أنواع الأعمال
enum ActionType {
  ghusl, // غسل
  prayer, // صلاة
  dua, // دعاء
  quran, // قرآن
  dhikr, // ذكر
  ziyarat, // زيارة
  sadaqa, // صدقة
  other, // أخرى
}

extension ActionTypeExtension on ActionType {
  String get arabicName {
    switch (this) {
      case ActionType.ghusl:
        return 'غسل';
      case ActionType.prayer:
        return 'صلاة';
      case ActionType.dua:
        return 'دعاء';
      case ActionType.quran:
        return 'قرآن';
      case ActionType.dhikr:
        return 'ذكر';
      case ActionType.ziyarat:
        return 'زيارة';
      case ActionType.sadaqa:
        return 'صدقة';
      case ActionType.other:
        return 'أخرى';
    }
  }
}
