import 'package:equatable/equatable.dart';

/// كيان عمل الليلة
class TonightAction extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? arabicText;
  final ActionPriority priority;
  final ActionTimeFrame timeFrame;
  final bool isCompleted;
  final int? repeatCount;
  final String? relatedDuaId;

  const TonightAction({
    required this.id,
    required this.title,
    required this.description,
    this.arabicText,
    this.priority = ActionPriority.normal,
    this.timeFrame = ActionTimeFrame.anytime,
    this.isCompleted = false,
    this.repeatCount,
    this.relatedDuaId,
  });

  TonightAction copyWith({
    String? id,
    String? title,
    String? description,
    String? arabicText,
    ActionPriority? priority,
    ActionTimeFrame? timeFrame,
    bool? isCompleted,
    int? repeatCount,
    String? relatedDuaId,
  }) {
    return TonightAction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      arabicText: arabicText ?? this.arabicText,
      priority: priority ?? this.priority,
      timeFrame: timeFrame ?? this.timeFrame,
      isCompleted: isCompleted ?? this.isCompleted,
      repeatCount: repeatCount ?? this.repeatCount,
      relatedDuaId: relatedDuaId ?? this.relatedDuaId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    arabicText,
    priority,
    timeFrame,
    isCompleted,
    repeatCount,
    relatedDuaId,
  ];
}

/// أولوية العمل
enum ActionPriority {
  high, // مستحب مؤكد
  normal, // مستحب
  optional, // اختياري
}

extension ActionPriorityExtension on ActionPriority {
  String get arabicName {
    switch (this) {
      case ActionPriority.high:
        return 'مستحب مؤكد';
      case ActionPriority.normal:
        return 'مستحب';
      case ActionPriority.optional:
        return 'اختياري';
    }
  }
}

/// وقت تنفيذ العمل
enum ActionTimeFrame {
  afterMaghrib, // بعد المغرب
  beforeMidnight, // قبل منتصف الليل
  afterMidnight, // بعد منتصف الليل
  lastThird, // الثلث الأخير
  anytime, // أي وقت
}

extension ActionTimeFrameExtension on ActionTimeFrame {
  String get arabicName {
    switch (this) {
      case ActionTimeFrame.afterMaghrib:
        return 'بعد المغرب';
      case ActionTimeFrame.beforeMidnight:
        return 'قبل منتصف الليل';
      case ActionTimeFrame.afterMidnight:
        return 'بعد منتصف الليل';
      case ActionTimeFrame.lastThird:
        return 'الثلث الأخير من الليل';
      case ActionTimeFrame.anytime:
        return 'في أي وقت';
    }
  }
}
