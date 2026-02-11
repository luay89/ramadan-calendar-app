/// مكتبة الحساب الفلكي للتطبيق الإسلامي
///
/// توفر حسابات دقيقة لـ:
/// - مواقيت الصلاة وفق المذهب الجعفري
/// - التقويم الهجري مع إمكانية المعايرة
/// - أوقات القمر (الاقتران، البدر، عمر الهلال)
/// - اتجاه القبلة والمسافة إلى الكعبة
library;

// الثوابت الفلكية
export 'constants/astronomical_constants.dart';

// المحركات الحسابية
export 'engine/astronomical_engine.dart';
export 'engine/prayer_times_engine.dart';
export 'engine/hijri_calendar_engine.dart';

// الإعدادات
export 'settings/location_settings.dart';
export 'settings/calibration_settings.dart';

// الخدمات
export 'services/location_service.dart';
export 'services/astronomical_service.dart';

// البيانات
export 'data/astronomical_repository.dart';

// إدارة الحالة
export 'bloc/astronomical_bloc.dart';
