import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../astronomical.dart';

// =================== Events ===================

abstract class AstronomicalEvent extends Equatable {
  const AstronomicalEvent();

  @override
  List<Object?> get props => [];
}

class LoadAstronomicalSettings extends AstronomicalEvent {}

class DetectLocation extends AstronomicalEvent {}

class SelectCity extends AstronomicalEvent {
  final String cityKey;
  const SelectCity(this.cityKey);

  @override
  List<Object?> get props => [cityKey];
}

class UpdateLocation extends AstronomicalEvent {
  final LocationSettings location;
  const UpdateLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class UpdateCalibration extends AstronomicalEvent {
  final CalibrationSettings calibration;
  const UpdateCalibration(this.calibration);

  @override
  List<Object?> get props => [calibration];
}

class AdjustHijriDay extends AstronomicalEvent {
  final int adjustment;
  const AdjustHijriDay(this.adjustment);

  @override
  List<Object?> get props => [adjustment];
}

class AdjustPrayerTime extends AstronomicalEvent {
  final Prayer prayer;
  final int minutes;
  const AdjustPrayerTime(this.prayer, this.minutes);

  @override
  List<Object?> get props => [prayer, minutes];
}

class ChangeCalculationMethod extends AstronomicalEvent {
  final CalculationMethod method;
  const ChangeCalculationMethod(this.method);

  @override
  List<Object?> get props => [method];
}

class ResetSettings extends AstronomicalEvent {}

// =================== States ===================

abstract class AstronomicalState extends Equatable {
  const AstronomicalState();

  @override
  List<Object?> get props => [];
}

class AstronomicalInitial extends AstronomicalState {}

class AstronomicalLoading extends AstronomicalState {}

class AstronomicalLoaded extends AstronomicalState {
  final LocationSettings location;
  final CalibrationSettings calibration;
  final AstronomicalService service;

  const AstronomicalLoaded({
    required this.location,
    required this.calibration,
    required this.service,
  });

  @override
  List<Object?> get props => [location, calibration];

  AstronomicalLoaded copyWith({
    LocationSettings? location,
    CalibrationSettings? calibration,
    AstronomicalService? service,
  }) {
    return AstronomicalLoaded(
      location: location ?? this.location,
      calibration: calibration ?? this.calibration,
      service: service ?? this.service,
    );
  }
}

class AstronomicalError extends AstronomicalState {
  final String message;
  const AstronomicalError(this.message);

  @override
  List<Object?> get props => [message];
}

class LocationDetecting extends AstronomicalState {}

class LocationDetected extends AstronomicalState {
  final LocationSettings location;
  const LocationDetected(this.location);

  @override
  List<Object?> get props => [location];
}

class LocationError extends AstronomicalState {
  final String message;
  final LocationErrorType errorType;

  const LocationError(this.message, this.errorType);

  @override
  List<Object?> get props => [message, errorType];
}

// =================== BLoC ===================

class AstronomicalBloc extends Bloc<AstronomicalEvent, AstronomicalState> {
  final AstronomicalRepository _repository;

  AstronomicalBloc({required AstronomicalRepository repository})
    : _repository = repository,
      super(AstronomicalInitial()) {
    on<LoadAstronomicalSettings>(_onLoadSettings);
    on<DetectLocation>(_onDetectLocation);
    on<SelectCity>(_onSelectCity);
    on<UpdateLocation>(_onUpdateLocation);
    on<UpdateCalibration>(_onUpdateCalibration);
    on<AdjustHijriDay>(_onAdjustHijriDay);
    on<AdjustPrayerTime>(_onAdjustPrayerTime);
    on<ChangeCalculationMethod>(_onChangeCalculationMethod);
    on<ResetSettings>(_onResetSettings);
  }

  Future<void> _onLoadSettings(
    LoadAstronomicalSettings event,
    Emitter<AstronomicalState> emit,
  ) async {
    emit(AstronomicalLoading());
    try {
      final location = _repository.getLocationSettings();
      final calibration = _repository.getCalibrationSettings();
      final service = _repository.createService();

      emit(
        AstronomicalLoaded(
          location: location,
          calibration: calibration,
          service: service,
        ),
      );
    } catch (e) {
      emit(AstronomicalError('فشل في تحميل الإعدادات: $e'));
    }
  }

  Future<void> _onDetectLocation(
    DetectLocation event,
    Emitter<AstronomicalState> emit,
  ) async {
    final currentState = state;
    emit(LocationDetecting());

    final result = await _repository.detectLocation();

    if (result.isSuccess && result.location != null) {
      if (currentState is AstronomicalLoaded) {
        final service = AstronomicalService(
          location: result.location!,
          calibration: currentState.calibration,
        );
        emit(
          currentState.copyWith(location: result.location!, service: service),
        );
      } else {
        emit(LocationDetected(result.location!));
        add(LoadAstronomicalSettings());
      }
    } else {
      emit(
        LocationError(
          result.errorMessage ?? 'فشل في تحديد الموقع',
          result.errorType ?? LocationErrorType.unknown,
        ),
      );
      // إعادة الحالة السابقة
      if (currentState is AstronomicalLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onSelectCity(
    SelectCity event,
    Emitter<AstronomicalState> emit,
  ) async {
    await _repository.selectCity(event.cityKey);
    add(LoadAstronomicalSettings());
  }

  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<AstronomicalState> emit,
  ) async {
    await _repository.saveLocationSettings(event.location);

    if (state is AstronomicalLoaded) {
      final currentState = state as AstronomicalLoaded;
      final service = AstronomicalService(
        location: event.location,
        calibration: currentState.calibration,
      );
      emit(currentState.copyWith(location: event.location, service: service));
    }
  }

  Future<void> _onUpdateCalibration(
    UpdateCalibration event,
    Emitter<AstronomicalState> emit,
  ) async {
    await _repository.saveCalibrationSettings(event.calibration);

    if (state is AstronomicalLoaded) {
      final currentState = state as AstronomicalLoaded;
      final service = AstronomicalService(
        location: currentState.location,
        calibration: event.calibration,
      );
      emit(
        currentState.copyWith(calibration: event.calibration, service: service),
      );
    }
  }

  Future<void> _onAdjustHijriDay(
    AdjustHijriDay event,
    Emitter<AstronomicalState> emit,
  ) async {
    await _repository.adjustHijriDay(event.adjustment);
    add(LoadAstronomicalSettings());
  }

  Future<void> _onAdjustPrayerTime(
    AdjustPrayerTime event,
    Emitter<AstronomicalState> emit,
  ) async {
    await _repository.adjustPrayerTime(event.prayer, event.minutes);
    add(LoadAstronomicalSettings());
  }

  Future<void> _onChangeCalculationMethod(
    ChangeCalculationMethod event,
    Emitter<AstronomicalState> emit,
  ) async {
    await _repository.changeCalculationMethod(event.method);
    add(LoadAstronomicalSettings());
  }

  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<AstronomicalState> emit,
  ) async {
    await _repository.resetAllSettings();
    add(LoadAstronomicalSettings());
  }
}
