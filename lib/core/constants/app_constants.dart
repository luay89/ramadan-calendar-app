/// ثوابت التطبيق الأساسية
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'تقويم المؤمن';
  static const String appNameEn = 'Mumin Calendar';
  static const String appVersion = '1.0.0';

  // Database
  static const String dbName = 'mumin_calendar_db';
  static const int dbVersion = 1;

  // Hive Boxes
  static const String settingsBox = 'settings_box';
  static const String duasBox = 'duas_box';
  static const String ziyaratBox = 'ziyarat_box';
  static const String eventsBox = 'events_box';
  static const String favoritesBox = 'favorites_box';
  static const String cacheBox = 'cache_box';

  // Prayer Times Settings
  static const double defaultLatitude = 33.3152; // Baghdad
  static const double defaultLongitude = 44.3661;
  static const String defaultTimezone = 'Asia/Baghdad';
  static const String defaultCity = 'بغداد';

  // Jafari Prayer Calculation Parameters
  static const double fajrAngle = 18.0; // زاوية الفجر للمذهب الجعفري (18 درجة)
  static const double ishaAngle = 14.0; // زاوية العشاء للمذهب الجعفري
  static const double maghribAngle = -2.0; // تعديل المغرب (دقائق)

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Cache Duration
  static const Duration cacheValidDuration = Duration(days: 7);

  // Notification IDs
  static const int fajrNotificationId = 1001;
  static const int sunriseNotificationId = 1002;
  static const int dhuhrNotificationId = 1003;
  static const int asrNotificationId = 1004;
  static const int maghribNotificationId = 1005;
  static const int ishaNotificationId = 1006;
  static const int suhoorNotificationId = 1007;
  static const int iftarNotificationId = 1008;
  static const int dailyDuaNotificationId = 2001;
  static const int eventNotificationId = 3001;
}

/// ثوابت الليالي الخاصة في المذهب الشيعي
class SpecialNights {
  SpecialNights._();

  // ليالي القدر
  static const List<int> laylatalQadrNights = [19, 21, 23];

  // الليالي البيض
  static const List<int> whitNights = [13, 14, 15];

  // ليالي الجمعة
  static const int fridayNight = 5; // الخميس ليلاً

  // ليالي مخصوصة في رجب
  static const List<int> rajabSpecialNights = [1, 13, 14, 15, 27];

  // ليالي مخصوصة في شعبان
  static const List<int> shabanSpecialNights = [1, 15];

  // ليالي مخصوصة في رمضان
  static const List<int> ramadanSpecialNights = [
    1,
    15,
    17,
    19,
    21,
    23,
    25,
    27,
    29,
  ];
}

/// ثوابت الأشهر الهجرية
class HijriMonths {
  HijriMonths._();

  static const List<String> arabicNames = [
    'محرّم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوّال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const int muharram = 1;
  static const int safar = 2;
  static const int rabiAlAwwal = 3;
  static const int rabiAlThani = 4;
  static const int jumadaAlUla = 5;
  static const int jumadaAlThani = 6;
  static const int rajab = 7;
  static const int shaban = 8;
  static const int ramadan = 9;
  static const int shawwal = 10;
  static const int dhuAlQidah = 11;
  static const int dhuAlHijjah = 12;
}

/// ثوابت أيام الأسبوع
class WeekDays {
  WeekDays._();

  static const List<String> arabicNames = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  static const int sunday = 0;
  static const int monday = 1;
  static const int tuesday = 2;
  static const int wednesday = 3;
  static const int thursday = 4;
  static const int friday = 5;
  static const int saturday = 6;
}
