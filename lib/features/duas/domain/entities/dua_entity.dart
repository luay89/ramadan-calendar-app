import 'package:equatable/equatable.dart';

/// كيان الدعاء أو الزيارة
class DuaEntity extends Equatable {
  final String id;
  final String title;
  final String arabicText;
  final String? translation;
  final String? transliteration;
  final String? source;
  final DuaCategory category;
  final List<String>? occasions;
  final bool isFavorite;
  final int? verseCount;
  final String? audioUrl;

  const DuaEntity({
    required this.id,
    required this.title,
    required this.arabicText,
    this.translation,
    this.transliteration,
    this.source,
    required this.category,
    this.occasions,
    this.isFavorite = false,
    this.verseCount,
    this.audioUrl,
  });

  DuaEntity copyWith({
    String? id,
    String? title,
    String? arabicText,
    String? translation,
    String? transliteration,
    String? source,
    DuaCategory? category,
    List<String>? occasions,
    bool? isFavorite,
    int? verseCount,
    String? audioUrl,
  }) {
    return DuaEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      arabicText: arabicText ?? this.arabicText,
      translation: translation ?? this.translation,
      transliteration: transliteration ?? this.transliteration,
      source: source ?? this.source,
      category: category ?? this.category,
      occasions: occasions ?? this.occasions,
      isFavorite: isFavorite ?? this.isFavorite,
      verseCount: verseCount ?? this.verseCount,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    arabicText,
    translation,
    transliteration,
    source,
    category,
    occasions,
    isFavorite,
    verseCount,
    audioUrl,
  ];
}

/// تصنيفات الأدعية
enum DuaCategory {
  daily, // أدعية يومية
  weekly, // أدعية أسبوعية (أيام الأسبوع)
  ziyarat, // الزيارات
  specialNights, // الليالي الخاصة
  sahifaSajjadiya, // الصحيفة السجادية
  quran, // أدعية قرآنية
  afterPrayer, // أدعية بعد كل فريضة
}

extension DuaCategoryExtension on DuaCategory {
  String get arabicName {
    switch (this) {
      case DuaCategory.daily:
        return 'أدعية يومية';
      case DuaCategory.weekly:
        return 'أدعية أيام الأسبوع';
      case DuaCategory.ziyarat:
        return 'الزيارات';
      case DuaCategory.specialNights:
        return 'الليالي الخاصة';
      case DuaCategory.sahifaSajjadiya:
        return 'الصحيفة السجادية';
      case DuaCategory.quran:
        return 'أدعية قرآنية';
      case DuaCategory.afterPrayer:
        return 'أدعية بعد كل فريضة';
    }
  }

  String get icon {
    switch (this) {
      case DuaCategory.daily:
        return '☀️';
      case DuaCategory.weekly:
        return '📅';
      case DuaCategory.ziyarat:
        return '🕌';
      case DuaCategory.specialNights:
        return '⭐';
      case DuaCategory.sahifaSajjadiya:
        return '📖';
      case DuaCategory.quran:
        return '📕';
      case DuaCategory.afterPrayer:
        return '🤲';
    }
  }
}
