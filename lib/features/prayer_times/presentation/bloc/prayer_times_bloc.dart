import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/prayer_times_entity.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_prayer_times.dart';
import '../../domain/repositories/prayer_times_repository.dart';

part 'prayer_times_event.dart';
part 'prayer_times_state.dart';

/// Bloc مواقيت الصلاة
class PrayerTimesBloc extends Bloc<PrayerTimesEvent, PrayerTimesState> {
  final GetPrayerTimes getPrayerTimes;
  final GetCurrentLocation getCurrentLocation;
  final PrayerTimesRepository repository;

  Timer? _countdownTimer;

  PrayerTimesBloc({
    required this.getPrayerTimes,
    required this.getCurrentLocation,
    required this.repository,
  }) : super(PrayerTimesInitial()) {
    on<LoadPrayerTimes>(_onLoadPrayerTimes);
    on<LoadPrayerTimesForLocation>(_onLoadPrayerTimesForLocation);
    on<UpdateCountdown>(_onUpdateCountdown);
    on<ChangeDate>(_onChangeDate);
    on<SearchLocation>(_onSearchLocation);
    on<SelectLocation>(_onSelectLocation);
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }

  /// تحميل مواقيت الصلاة
  Future<void> _onLoadPrayerTimes(
    LoadPrayerTimes event,
    Emitter<PrayerTimesState> emit,
  ) async {
    emit(PrayerTimesLoading());

    // محاولة الحصول على الموقع المحفوظ أولاً
    final savedLocationResult = await repository.getSavedLocation();

    LocationEntity? location;
    savedLocationResult.fold(
      (failure) => null,
      (savedLocation) => location = savedLocation,
    );

    // إذا لم يكن هناك موقع محفوظ، نحاول الحصول على الموقع الحالي
    if (location == null) {
      final locationResult = await getCurrentLocation(const NoParams());

      locationResult.fold((failure) {
        // استخدام الموقع الافتراضي (بغداد)
        location = const LocationEntity(
          latitude: AppConstants.defaultLatitude,
          longitude: AppConstants.defaultLongitude,
          cityName: AppConstants.defaultCity,
        );
      }, (loc) => location = loc);
    }

    // الحصول على مواقيت الصلاة
    final result = await getPrayerTimes(
      PrayerTimesParams(
        date: DateTime.now(),
        latitude: location!.latitude,
        longitude: location!.longitude,
        locationName: location!.cityName,
      ),
    );

    result.fold((failure) => emit(PrayerTimesError(failure.message)), (
      prayerTimes,
    ) {
      _startCountdownTimer();
      emit(
        PrayerTimesLoaded(
          prayerTimes: prayerTimes,
          location: location!,
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

  /// البحث عن موقع
  Future<void> _onSearchLocation(
    SearchLocation event,
    Emitter<PrayerTimesState> emit,
  ) async {
    if (state is PrayerTimesLoaded) {
      final currentState = state as PrayerTimesLoaded;
      emit(currentState.copyWith(isSearching: true));

      final result = await repository.searchLocation(event.query);

      result.fold(
        (failure) =>
            emit(currentState.copyWith(isSearching: false, searchResults: [])),
        (locations) => emit(
          currentState.copyWith(isSearching: false, searchResults: locations),
        ),
      );
    }
  }

  /// اختيار موقع
  Future<void> _onSelectLocation(
    SelectLocation event,
    Emitter<PrayerTimesState> emit,
  ) async {
    // حفظ الموقع
    await repository.saveLocation(event.location);

    // إعادة تحميل المواقيت
    add(
      LoadPrayerTimesForLocation(
        location: event.location,
        date: DateTime.now(),
      ),
    );
  }
}
