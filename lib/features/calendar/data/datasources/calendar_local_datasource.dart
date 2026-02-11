import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../models/islamic_event_model.dart';

/// مصدر البيانات المحلية للتقويم
abstract class CalendarLocalDataSource {
  /// الحصول على جميع الأحداث
  Future<List<IslamicEventModel>> getAllEvents();

  /// الحصول على أحداث شهر معين
  Future<List<IslamicEventModel>> getEventsForMonth(int hijriMonth);

  /// الحصول على أحداث يوم معين
  Future<List<IslamicEventModel>> getEventsForDay(int hijriMonth, int hijriDay);

  /// حفظ الأحداث في الكاش
  Future<void> cacheEvents(List<IslamicEventModel> events);

  /// البحث في الأحداث
  Future<List<IslamicEventModel>> searchEvents(String query);
}

class CalendarLocalDataSourceImpl implements CalendarLocalDataSource {
  final Box eventsBox;
  List<IslamicEventModel>? _cachedEvents;

  CalendarLocalDataSourceImpl({required this.eventsBox});

  @override
  Future<List<IslamicEventModel>> getAllEvents() async {
    try {
      // إذا كان لدينا كاش في الذاكرة
      if (_cachedEvents != null) {
        return _cachedEvents!;
      }

      // إذا كان الكاش فارغاً، نحمّل من ملفات الأصول أو الافتراضية
      await _loadEventsFromAssets();
      return _cachedEvents ?? [];
    } catch (e) {
      throw CacheException(message: 'فشل في تحميل الأحداث');
    }
  }

  @override
  Future<List<IslamicEventModel>> getEventsForMonth(int hijriMonth) async {
    try {
      final allEvents = await getAllEvents();
      return allEvents
          .where((event) => event.hijriMonth == hijriMonth)
          .toList();
    } catch (e) {
      throw CacheException(message: 'فشل في تحميل أحداث الشهر');
    }
  }

  @override
  Future<List<IslamicEventModel>> getEventsForDay(
    int hijriMonth,
    int hijriDay,
  ) async {
    try {
      final allEvents = await getAllEvents();
      return allEvents
          .where(
            (event) =>
                event.hijriMonth == hijriMonth && event.hijriDay == hijriDay,
          )
          .toList();
    } catch (e) {
      throw CacheException(message: 'فشل في تحميل أحداث اليوم');
    }
  }

  @override
  Future<void> cacheEvents(List<IslamicEventModel> events) async {
    try {
      _cachedEvents = events;
      // نحفظ كـ JSON في الصندوق
      await eventsBox.clear();
      for (final event in events) {
        await eventsBox.put(event.id, event.toJson());
      }
    } catch (e) {
      throw CacheException(message: 'فشل في حفظ الأحداث');
    }
  }

  @override
  Future<List<IslamicEventModel>> searchEvents(String query) async {
    try {
      final allEvents = await getAllEvents();
      final lowerQuery = query.toLowerCase();
      return allEvents.where((event) {
        return event.title.toLowerCase().contains(lowerQuery) ||
            event.description.toLowerCase().contains(lowerQuery) ||
            (event.imam?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      throw CacheException(message: 'فشل في البحث');
    }
  }

  /// تحميل الأحداث من ملفات الأصول
  Future<void> _loadEventsFromAssets() async {
    try {
      final jsonString = await rootBundle.loadString(AssetPaths.eventsData);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final eventsList = jsonData['events'] as List<dynamic>;

      final events =
          eventsList
              .map((e) => IslamicEventModel.fromJson(e as Map<String, dynamic>))
              .toList();

      _cachedEvents = events;
    } catch (e) {
      // إذا فشل تحميل الملف، نستخدم البيانات الافتراضية
      await _loadDefaultEvents();
    }
  }

  /// تحميل الأحداث الافتراضية
  Future<void> _loadDefaultEvents() async {
    final defaultEvents = _getDefaultIslamicEvents();
    _cachedEvents = defaultEvents;
  }

  /// الأحداث الإسلامية الافتراضية
  List<IslamicEventModel> _getDefaultIslamicEvents() {
    return [
      // محرّم
      IslamicEventModel(
        id: 'muharram_1',
        title: 'رأس السنة الهجرية',
        description: 'بداية العام الهجري الجديد',
        hijriMonth: 1,
        hijriDay: 1,
        typeIndex: 4, // religious
        importanceIndex: 0, // high
        isHoliday: true,
      ),
      IslamicEventModel(
        id: 'muharram_10',
        title: 'يوم عاشوراء',
        description: 'ذكرى استشهاد الإمام الحسين عليه السلام',
        hijriMonth: 1,
        hijriDay: 10,
        typeIndex: 1, // martyrdom
        importanceIndex: 0, // high
        isMourning: true,
        imam: 'الإمام الحسين (ع)',
        actions: ['الصيام', 'قراءة مقتل الحسين', 'المجالس الحسينية', 'التصدق'],
      ),
      // صفر
      IslamicEventModel(
        id: 'safar_20',
        title: 'الأربعين الحسيني',
        description: 'أربعينية الإمام الحسين عليه السلام',
        hijriMonth: 2,
        hijriDay: 20,
        typeIndex: 4, // religious
        importanceIndex: 0, // high
        isMourning: true,
        imam: 'الإمام الحسين (ع)',
        actions: ['الزيارة', 'المجالس الحسينية'],
      ),
      IslamicEventModel(
        id: 'safar_28',
        title: 'وفاة النبي محمد (ص)',
        description: 'ذكرى وفاة النبي الأعظم محمد صلى الله عليه وآله',
        hijriMonth: 2,
        hijriDay: 28,
        typeIndex: 2, // death
        importanceIndex: 0, // high
        isMourning: true,
      ),
      // ربيع الأول
      IslamicEventModel(
        id: 'rabi1_12',
        title: 'المولد النبوي الشريف',
        description: 'ذكرى ولادة النبي محمد صلى الله عليه وآله',
        hijriMonth: 3,
        hijriDay: 12,
        typeIndex: 0, // birth
        importanceIndex: 0, // high
        isHoliday: true,
        actions: ['الاحتفال', 'قراءة السيرة النبوية', 'التصدق'],
      ),
      IslamicEventModel(
        id: 'rabi1_17',
        title: 'ولادة الإمام الصادق (ع)',
        description: 'ذكرى ولادة الإمام جعفر الصادق عليه السلام',
        hijriMonth: 3,
        hijriDay: 17,
        typeIndex: 0, // birth
        importanceIndex: 0, // high
        imam: 'الإمام جعفر الصادق (ع)',
      ),
      // رجب
      IslamicEventModel(
        id: 'rajab_1',
        title: 'ولادة الإمام الباقر (ع)',
        description: 'ذكرى ولادة الإمام محمد الباقر عليه السلام',
        hijriMonth: 7,
        hijriDay: 1,
        typeIndex: 0, // birth
        importanceIndex: 0, // high
        imam: 'الإمام محمد الباقر (ع)',
      ),
      IslamicEventModel(
        id: 'rajab_13',
        title: 'ولادة الإمام علي (ع)',
        description:
            'ذكرى ولادة أمير المؤمنين الإمام علي عليه السلام في الكعبة',
        hijriMonth: 7,
        hijriDay: 13,
        typeIndex: 0, // birth
        importanceIndex: 0, // high
        isHoliday: true,
        imam: 'الإمام علي (ع)',
        actions: ['الصيام', 'زيارة الإمام علي', 'التصدق'],
      ),
      IslamicEventModel(
        id: 'rajab_27',
        title: 'المبعث النبوي',
        description: 'ذكرى بعثة النبي محمد صلى الله عليه وآله',
        hijriMonth: 7,
        hijriDay: 27,
        typeIndex: 4, // religious
        importanceIndex: 0, // high
        isHoliday: true,
        actions: ['الصيام', 'الصلاة', 'قراءة القرآن'],
      ),
      // شعبان
      IslamicEventModel(
        id: 'shaban_3',
        title: 'ولادة الإمام الحسين (ع)',
        description: 'ذكرى ولادة الإمام الحسين عليه السلام',
        hijriMonth: 8,
        hijriDay: 3,
        typeIndex: 0, // birth
        importanceIndex: 0, // high
        imam: 'الإمام الحسين (ع)',
      ),
      IslamicEventModel(
        id: 'shaban_15',
        title: 'ولادة الإمام المهدي (عج)',
        description: 'ذكرى ولادة الإمام محمد المهدي عجل الله فرجه',
        hijriMonth: 8,
        hijriDay: 15,
        typeIndex: 0, // birth
        importanceIndex: 0, // high
        isHoliday: true,
        imam: 'الإمام المهدي (عج)',
        actions: ['الصيام', 'دعاء الفرج', 'التصدق', 'صلاة ليلة النصف'],
      ),
      // رمضان
      IslamicEventModel(
        id: 'ramadan_1',
        title: 'بداية شهر رمضان',
        description: 'أول يوم من شهر رمضان المبارك',
        hijriMonth: 9,
        hijriDay: 1,
        typeIndex: 4, // religious
        importanceIndex: 0, // high
      ),
      IslamicEventModel(
        id: 'ramadan_19',
        title: 'ليلة القدر الأولى',
        description: 'إحدى ليالي القدر المحتملة',
        hijriMonth: 9,
        hijriDay: 19,
        typeIndex: 6, // special
        importanceIndex: 0, // high
        actions: ['إحياء الليل', 'قراءة القرآن', 'الدعاء', 'أعمال ليلة القدر'],
      ),
      IslamicEventModel(
        id: 'ramadan_21',
        title: 'شهادة الإمام علي (ع) / ليلة القدر',
        description: 'ذكرى استشهاد أمير المؤمنين وليلة القدر',
        hijriMonth: 9,
        hijriDay: 21,
        typeIndex: 1, // martyrdom
        importanceIndex: 0, // high
        isMourning: true,
        imam: 'الإمام علي (ع)',
        actions: ['إحياء الليل', 'قراءة القرآن', 'الدعاء', 'زيارة الإمام علي'],
      ),
      IslamicEventModel(
        id: 'ramadan_23',
        title: 'ليلة القدر الكبرى',
        description: 'أرجح ليالي القدر',
        hijriMonth: 9,
        hijriDay: 23,
        typeIndex: 6, // special
        importanceIndex: 0, // high
        actions: ['إحياء الليل', 'قراءة القرآن', 'الدعاء', 'أعمال ليلة القدر'],
      ),
      // شوال
      IslamicEventModel(
        id: 'shawwal_1',
        title: 'عيد الفطر',
        description: 'عيد الفطر المبارك',
        hijriMonth: 10,
        hijriDay: 1,
        typeIndex: 3, // eid
        importanceIndex: 0, // high
        isHoliday: true,
        actions: ['صلاة العيد', 'زكاة الفطرة', 'صلة الأرحام'],
      ),
      // ذو الحجة
      IslamicEventModel(
        id: 'dhulhijjah_9',
        title: 'يوم عرفة',
        description: 'يوم الوقوف بعرفة',
        hijriMonth: 12,
        hijriDay: 9,
        typeIndex: 4, // religious
        importanceIndex: 0, // high
        actions: ['الصيام', 'دعاء عرفة', 'الذكر'],
      ),
      IslamicEventModel(
        id: 'dhulhijjah_10',
        title: 'عيد الأضحى',
        description: 'عيد الأضحى المبارك',
        hijriMonth: 12,
        hijriDay: 10,
        typeIndex: 3, // eid
        importanceIndex: 0, // high
        isHoliday: true,
        actions: ['صلاة العيد', 'الأضحية', 'صلة الأرحام'],
      ),
      IslamicEventModel(
        id: 'dhulhijjah_18',
        title: 'عيد الغدير',
        description: 'ذكرى تنصيب الإمام علي عليه السلام',
        hijriMonth: 12,
        hijriDay: 18,
        typeIndex: 3, // eid
        importanceIndex: 0, // high
        isHoliday: true,
        imam: 'الإمام علي (ع)',
        actions: ['الصيام', 'صلاة يوم الغدير', 'زيارة الإمام علي', 'التصدق'],
      ),
    ];
  }
}
