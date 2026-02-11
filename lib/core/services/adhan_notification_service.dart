import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'adhan_audio_service.dart';

/// أسماء الصلوات
enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

/// خدمة إشعارات الأذان المجدولة
class AdhanNotificationService {
  static final AdhanNotificationService _instance =
      AdhanNotificationService._internal();
  factory AdhanNotificationService() => _instance;
  AdhanNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  /// مفاتيح التفضيلات
  static const String _prefKeyFajr = 'adhan_enabled_fajr';
  static const String _prefKeyDhuhr = 'adhan_enabled_dhuhr';
  static const String _prefKeyAsr = 'adhan_enabled_asr';
  static const String _prefKeyMaghrib = 'adhan_enabled_maghrib';
  static const String _prefKeyIsha = 'adhan_enabled_isha';

  /// معرفات الإشعارات
  static const int _notificationIdFajr = 1001;
  static const int _notificationIdDhuhr = 1002;
  static const int _notificationIdAsr = 1003;
  static const int _notificationIdMaghrib = 1004;
  static const int _notificationIdIsha = 1005;

  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();

    // تهيئة المناطق الزمنية
    tz_data.initializeTimeZones();

    // إعدادات Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // إعدادات iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // طلب الصلاحيات على Android 13+
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

    _isInitialized = true;
  }

  /// طلب صلاحيات Android
  Future<void> _requestAndroidPermissions() async {
    final androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      // طلب صلاحية الإشعارات
      await androidPlugin.requestNotificationsPermission();
      // طلب صلاحية المنبهات الدقيقة
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  /// معالجة الضغط على الإشعار
  void _onNotificationTapped(NotificationResponse response) async {
    // تشغيل الأذان عند الضغط على الإشعار
    final adhanService = AdhanAudioService();
    await adhanService.playAdhan();
  }

  /// الحصول على مفتاح التفضيل للصلاة
  String _getPrefKey(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return _prefKeyFajr;
      case PrayerName.dhuhr:
        return _prefKeyDhuhr;
      case PrayerName.asr:
        return _prefKeyAsr;
      case PrayerName.maghrib:
        return _prefKeyMaghrib;
      case PrayerName.isha:
        return _prefKeyIsha;
    }
  }

  /// الحصول على معرف الإشعار للصلاة
  int _getNotificationId(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return _notificationIdFajr;
      case PrayerName.dhuhr:
        return _notificationIdDhuhr;
      case PrayerName.asr:
        return _notificationIdAsr;
      case PrayerName.maghrib:
        return _notificationIdMaghrib;
      case PrayerName.isha:
        return _notificationIdIsha;
    }
  }

  /// الحصول على اسم الصلاة بالعربية
  String _getPrayerNameArabic(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return 'الفجر';
      case PrayerName.dhuhr:
        return 'الظهر';
      case PrayerName.asr:
        return 'العصر';
      case PrayerName.maghrib:
        return 'المغرب';
      case PrayerName.isha:
        return 'العشاء';
    }
  }

  /// التحقق من تفعيل الأذان لصلاة معينة
  bool isAdhanEnabled(PrayerName prayer) {
    return _prefs.getBool(_getPrefKey(prayer)) ?? false;
  }

  /// تفعيل أو إلغاء الأذان لصلاة معينة
  Future<void> setAdhanEnabled(PrayerName prayer, bool enabled) async {
    await _prefs.setBool(_getPrefKey(prayer), enabled);
  }

  /// جدولة الأذان لصلاة معينة
  Future<void> scheduleAdhan({
    required PrayerName prayer,
    required DateTime prayerTime,
  }) async {
    if (!_isInitialized) await initialize();

    final notificationId = _getNotificationId(prayer);
    final prayerNameArabic = _getPrayerNameArabic(prayer);

    // إلغاء الإشعار السابق إن وجد
    await _notificationsPlugin.cancel(notificationId);

    // إذا كان الوقت قد مضى اليوم، نجدول لنفس الوقت غداً
    DateTime scheduledTime = prayerTime;
    if (prayerTime.isBefore(DateTime.now())) {
      scheduledTime = DateTime(
        prayerTime.year,
        prayerTime.month,
        prayerTime.day + 1,
        prayerTime.hour,
        prayerTime.minute,
        prayerTime.second,
      );
    }

    // إعدادات الإشعار
    final androidDetails = AndroidNotificationDetails(
      'adhan_channel',
      'أذان الصلاة',
      channelDescription: 'إشعارات الأذان عند دخول وقت الصلاة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('adhan'),
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: false,
      styleInformation: BigTextStyleInformation(
        'حان الآن موعد صلاة $prayerNameArabic\nحيّ على الصلاة 🕌',
        contentTitle: '🕌 أذان $prayerNameArabic',
        summaryText: 'وقت الصلاة',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'adhan.mp3',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // جدولة الإشعار
    await _notificationsPlugin.zonedSchedule(
      notificationId,
      '🕌 أذان $prayerNameArabic',
      'حان الآن موعد صلاة $prayerNameArabic - حيّ على الصلاة',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // يكرر يومياً
    );
  }

  /// إلغاء جدولة الأذان لصلاة معينة
  Future<void> cancelAdhan(PrayerName prayer) async {
    final notificationId = _getNotificationId(prayer);
    await _notificationsPlugin.cancel(notificationId);
  }

  /// جدولة جميع الصلوات المفعلة
  Future<void> scheduleAllEnabledAdhans({
    required DateTime fajrTime,
    required DateTime dhuhrTime,
    required DateTime asrTime,
    required DateTime maghribTime,
    required DateTime ishaTime,
  }) async {
    if (!_isInitialized) await initialize();

    final prayers = {
      PrayerName.fajr: fajrTime,
      PrayerName.dhuhr: dhuhrTime,
      PrayerName.asr: asrTime,
      PrayerName.maghrib: maghribTime,
      PrayerName.isha: ishaTime,
    };

    for (final entry in prayers.entries) {
      if (isAdhanEnabled(entry.key)) {
        await scheduleAdhan(prayer: entry.key, prayerTime: entry.value);
      } else {
        await cancelAdhan(entry.key);
      }
    }
  }

  /// إلغاء جميع الإشعارات
  Future<void> cancelAllAdhans() async {
    await _notificationsPlugin.cancelAll();
  }

  /// التحقق من وجود صلاحيات الإشعارات
  Future<bool> hasNotificationPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    return true;
  }
}
