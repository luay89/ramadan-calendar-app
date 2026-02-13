import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/gps_location_service.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/prayer_times_entity.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_prayer_times.dart';
import '../../domain/repositories/prayer_times_repository.dart';

part 'prayer_times_event.dart';
part 'prayer_times_state.dart';

/// Bloc مواقيت الصلاة - معتمد على GPS فقط
class PrayerTimesBloc extends Bloc<PrayerTimesEvent, PrayerTimesState> {
  final GetPrayerTimes getPrayerTimes;
  final GetCurrentLocation getCurrentLocation;
  final PrayerTimesRepository repository;
  final GPSLocationService _gpsService = GPSLocationService.instance;

  Timer? _countdownTimer;
  StreamSubscription? _locationChangeSubscription;

  PrayerTimesBloc({
    required this.getPrayerTimes,
    required this.getCurrentLocation,
    required this.repository,
  }) : super(PrayerTimesInitial()) {
    on<LoadPrayerTimes>(_onLoadPrayerTimes);
    on<LoadPrayerTimesForLocation>(_onLoadPrayerTimesForLocation);
    on<UpdateCountdown>(_onUpdateCountdown);
    on<ChangeDate>(_onChangeDate);
    on<RefreshLocation>(_onRefreshLocation);
    on<LocationChanged>(_onLocationChanged);

    // الاستماع لتغييرات الموقع
    _locationChangeSubscription = _gpsService.locationChanges.listen((
      newLocation,
    ) {
      add(LocationChanged(newLocation));
    });
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _locationChangeSubscription?.cancel();
    return super.close();
  }

  /// تحميل مواقيت الصلاة - معتمد على GPS فقط
  Future<void> _onLoadPrayerTimes(
    LoadPrayerTimes event,
    Emitter<PrayerTimesState> emit,
  ) async {
    emit(PrayerTimesLoading());

    // الحصول على الموقع من GPS (مع fallback للمحفوظ)
    final gpsResult = await _gpsService.getLocationWithFallback();

    if (!gpsResult.isSuccess || gpsResult.location == null) {
      emit(
        PrayerTimesError(
          gpsResult.errorMessage ?? 'فشل في تحديد الموقع',
          errorType: gpsResult.errorType,
        ),
      );
      return;
    }

    final gpsLocation = gpsResult.location!;
    final location = LocationEntity(
      latitude: gpsLocation.latitude,
      longitude: gpsLocation.longitude,
      cityName: gpsLocation.displayName,
    );

    // الحصول على مواقيت الصلاة بناءً على الإحداثيات فقط
    final result = await getPrayerTimes(
      PrayerTimesParams(
        date: DateTime.now(),
        latitude: location.latitude,
        longitude: location.longitude,
        locationName: location.cityName,
      ),
    );

    result.fold((failure) => emit(PrayerTimesError(failure.message)), (
      prayerTimes,
    ) {
      _startCountdownTimer();
      emit(
        PrayerTimesLoaded(
          prayerTimes: prayerTimes,
          location: location,
          selectedDate: DateTime.now(),
        ),
      );
    });
  }

  /// تحميل مواقيت الصلاة لموقع محدد
  Future<void> _onLoadPrayerTimesForLocation(
    LoadPrayerTimesForLocation event,
    Emitter<PrayerTimesState> emit,
  ) async {
    emit(PrayerTimesLoading());

    final result = await getPrayerTimes(
      PrayerTimesParams(
        date: event.date,
        latitude: event.location.latitude,
        longitude: event.location.longitude,
        locationName: event.location.cityName,
      ),
    );

    result.fold((failure) => emit(PrayerTimesError(failure.message)), (
      prayerTimes,
    ) {
      _startCountdownTimer();
      emit(
        PrayerTimesLoaded(
          prayerTimes: prayerTimes,
          location: event.location,
          selectedDate: event.date,
        ),
      );
    });
  }

  /// تحديث العد التنازلي
  void _onUpdateCountdown(
    UpdateCountdown event,
    Emitter<PrayerTimesState> emit,
  ) {
    if (state is PrayerTimesLoaded) {
      final currentState = state as PrayerTimesLoaded;
      emit(currentState.copyWith());
    }
  }

  /// بدء مؤقت العد التنازلي
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(const UpdateCountdown());
    });
  }

  /// تغيير التاريخ
  Future<void> _onChangeDate(
    ChangeDate event,
    Emitter<PrayerTimesState> emit,
  ) async {
    if (state is PrayerTimesLoaded) {
      final currentState = state as PrayerTimesLoaded;

      final result = await getPrayerTimes(
        PrayerTimesParams(
          date: event.date,
          latitude: currentState.location.latitude,
          longitude: currentState.location.longitude,
          locationName: currentState.location.cityName,
        ),
      );

      result.fold(
        (failure) => emit(PrayerTimesError(failure.message)),
        (prayerTimes) => emit(
          currentState.copyWith(
            prayerTimes: prayerTimes,
            selectedDate: event.date,
          ),
        ),
      );
    }
  }

  /// تحديث الموقع من GPS
  Future<void> _onRefreshLocation(
    RefreshLocation event,
    Emitter<PrayerTimesState> emit,
  ) async {
    if (state is PrayerTimesLoaded) {
      final currentState = state as PrayerTimesLoaded;
      emit(currentState.copyWith(isRefreshingLocation: true));

      final gpsResult = await _gpsService.getCurrentLocation();

      if (gpsResult.isSuccess && gpsResult.location != null) {
        final gpsLocation = gpsResult.location!;
        final newLocation = LocationEntity(
          latitude: gpsLocation.latitude,
          longitude: gpsLocation.longitude,
          cityName: gpsLocation.displayName,
        );

        // إعادة حساب المواقيت
        final result = await getPrayerTimes(
          PrayerTimesParams(
            date: currentState.selectedDate,
            latitude: newLocation.latitude,
            longitude: newLocation.longitude,
            locationName: newLocation.cityName,
          ),
        );

        result.fold(
          (failure) => emit(currentState.copyWith(isRefreshingLocation: false)),
          (prayerTimes) => emit(
            currentState.copyWith(
              prayerTimes: prayerTimes,
              location: newLocation,
              isRefreshingLocation: false,
            ),
          ),
        );
      } else {
        emit(currentState.copyWith(isRefreshingLocation: false));
      }
    }
  }

  /// معالجة تغيير الموقع التلقائي
  Future<void> _onLocationChanged(
    LocationChanged event,
    Emitter<PrayerTimesState> emit,
  ) async {
    if (state is PrayerTimesLoaded) {
      final currentState = state as PrayerTimesLoaded;
      final gpsLocation = event.newLocation;

      final newLocation = LocationEntity(
        latitude: gpsLocation.latitude,
        longitude: gpsLocation.longitude,
        cityName: gpsLocation.displayName,
      );

      // إعادة حساب المواقيت مع الموقع الجديد
      final result = await getPrayerTimes(
        PrayerTimesParams(
          date: currentState.selectedDate,
          latitude: newLocation.latitude,
          longitude: newLocation.longitude,
          locationName: newLocation.cityName,
        ),
      );

      result.fold(
        (failure) => null,
        (prayerTimes) => emit(
          currentState.copyWith(
            prayerTimes: prayerTimes,
            location: newLocation,
          ),
        ),
      );
    }
  }
}
