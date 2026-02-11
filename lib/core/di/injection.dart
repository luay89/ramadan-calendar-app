import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../network/network_info.dart';
import '../services/ramadan_config_service.dart';

// Prayer Times Feature
import '../../features/prayer_times/data/datasources/location_datasource.dart';
import '../../features/prayer_times/data/repositories/prayer_times_repository_impl.dart';
import '../../features/prayer_times/data/models/location_model.dart';
import '../../features/prayer_times/data/models/location_model_adapter.dart';
import '../../features/prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../features/prayer_times/domain/usecases/get_prayer_times.dart';
import '../../features/prayer_times/domain/usecases/get_current_location.dart';
import '../../features/prayer_times/presentation/bloc/prayer_times_bloc.dart';

// Calendar Feature
import '../../features/calendar/data/datasources/calendar_local_datasource.dart';
import '../../features/calendar/data/repositories/calendar_repository_impl.dart';
import '../../features/calendar/domain/repositories/calendar_repository.dart';
import '../../features/calendar/domain/usecases/get_calendar_days.dart';
import '../../features/calendar/domain/usecases/get_month_events.dart';
import '../../features/calendar/domain/usecases/get_today_events.dart';
import '../../features/calendar/presentation/bloc/calendar_bloc.dart';

/// حاوية حقن التبعيات
final getIt = GetIt.instance;

/// تهيئة التبعيات
Future<void> initDependencies() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);

  getIt.registerLazySingleton(() => Connectivity());

  // Core
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<Connectivity>()),
  );

  // Hive Boxes
  await _initHive();

  // تهيئة خدمة إعدادات رمضان
  await RamadanConfigService.instance.loadSettings();

  // تسجيل التبعيات للميزات
  await _initPrayerTimesFeature();
  await _initCalendarFeature();
}

/// تهيئة Hive
Future<void> _initHive() async {
  await Hive.initFlutter();

  // تسجيل المحولات
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(LocationModelAdapter());
  }

  // فتح الصناديق
  await Hive.openBox('settings');
  await Hive.openBox('favorites');
  await Hive.openBox('completedActions');
  await Hive.openBox('cache');
  await Hive.openBox<LocationModel>('locations');
  await Hive.openBox('events'); // صندوق عادي للأحداث
}

/// تهيئة ميزة مواقيت الصلاة
Future<void> _initPrayerTimesFeature() async {
  // Data sources
  getIt.registerLazySingleton<LocationDataSource>(
    () => LocationDataSourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<PrayerTimesRepository>(
    () => PrayerTimesRepositoryImpl(
      locationDataSource: getIt<LocationDataSource>(),
      locationBox: Hive.box<LocationModel>('locations'),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(
    () => GetPrayerTimes(getIt<PrayerTimesRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetCurrentLocation(getIt<PrayerTimesRepository>()),
  );

  // Bloc
  getIt.registerFactory(
    () => PrayerTimesBloc(
      getPrayerTimes: getIt<GetPrayerTimes>(),
      getCurrentLocation: getIt<GetCurrentLocation>(),
      repository: getIt<PrayerTimesRepository>(),
    ),
  );
}

/// تهيئة ميزة التقويم
Future<void> _initCalendarFeature() async {
  // Data sources
  getIt.registerLazySingleton<CalendarLocalDataSource>(
    () => CalendarLocalDataSourceImpl(eventsBox: Hive.box('events')),
  );

  // Repositories
  getIt.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(
      localDataSource: getIt<CalendarLocalDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(
    () => GetCalendarDays(getIt<CalendarRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetMonthEvents(getIt<CalendarRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetTodayEvents(getIt<CalendarRepository>()),
  );

  // Bloc
  getIt.registerFactory(
    () => CalendarBloc(
      getCalendarDays: getIt<GetCalendarDays>(),
      getMonthEvents: getIt<GetMonthEvents>(),
      getTodayEvents: getIt<GetTodayEvents>(),
    ),
  );
}
