/// مسارات الأصول (Assets)
class AssetPaths {
  AssetPaths._();

  // Base paths
  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _audio = 'assets/audio';
  static const String _data = 'assets/data';
  static const String _fonts = 'assets/fonts';

  // Images
  static const String logo = '$_images/logo.png';
  static const String splash = '$_images/splash.png';
  static const String kaaba = '$_images/kaaba.png';
  static const String mosque = '$_images/mosque.png';
  static const String quran = '$_images/quran.png';
  static const String ramadanBg = '$_images/ramadan_bg.png';
  static const String prayerBg = '$_images/prayer_bg.png';

  // Icons
  static const String prayerIcon = '$_icons/prayer.svg';
  static const String calendarIcon = '$_icons/calendar.svg';
  static const String duaIcon = '$_icons/dua.svg';
  static const String ziyaratIcon = '$_icons/ziyarat.svg';
  static const String settingsIcon = '$_icons/settings.svg';
  static const String locationIcon = '$_icons/location.svg';
  static const String notificationIcon = '$_icons/notification.svg';
  static const String moonIcon = '$_icons/moon.svg';
  static const String sunIcon = '$_icons/sun.svg';
  static const String starIcon = '$_icons/star.svg';

  // Audio
  static const String adhanAudio = '$_audio/adhan.mp3';
  static const String notificationSound = '$_audio/notification.mp3';
  static const String duaBackground = '$_audio/dua_background.mp3';

  // Data Files (JSON)
  static const String duasData = '$_data/duas.json';
  static const String ziyaratData = '$_data/ziyarat.json';
  static const String eventsData = '$_data/events.json';
  static const String tonightActionsData = '$_data/tonight_actions.json';
  static const String laylatalQadrData = '$_data/laylatal_qadr.json';
  static const String ramadanActionsData = '$_data/ramadan_actions.json';

  // Fonts
  static const String arabicFont = '$_fonts/Amiri-Regular.ttf';
  static const String arabicFontBold = '$_fonts/Amiri-Bold.ttf';
}
