import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_calendar/core/astronomical/astronomical.dart';

void main() {
  group('إمساكية رمضان', () {
    test('حساب أوقات رمضان 1446 - يجب أن تتغير الأوقات يومياً', () {
      // إعدادات بغداد
      final location = LocationSettings(
        latitude: 33.3152,
        longitude: 44.3661,
        timezone: 3.0,
        locationName: 'بغداد',
      );

      final calibration = CalibrationSettings.jafariDefault();

      final service = AstronomicalService(
        location: location,
        calibration: calibration,
      );

      final imsakiya = service.getRamadanImsakiya(1446);

      expect(imsakiya.isNotEmpty, true);

      // التحقق من أن التواريخ الميلادية تتغير
      if (imsakiya.length >= 2) {
        expect(
          imsakiya[0].gregorianDate.day,
          isNot(equals(imsakiya[1].gregorianDate.day)),
        );
      }

      // التحقق من أن الأوقات تتغير (ولو قليلاً)
      if (imsakiya.length >= 10) {
        final day1Fajr = imsakiya[0].fajr;
        final day10Fajr = imsakiya[9].fajr;

        if (day1Fajr != null && day10Fajr != null) {
          // يجب أن يكون هناك فرق بين اليوم 1 واليوم 10
          final diff =
              (day1Fajr.hour * 60 + day1Fajr.minute) -
              (day10Fajr.hour * 60 + day10Fajr.minute);

          // يجب أن يكون الفرق أكثر من 0
          expect(
            diff.abs(),
            greaterThan(0),
            reason: 'يجب أن يتغير وقت الفجر خلال رمضان',
          );
        }
      }
    });

    test('التحويل من هجري إلى ميلادي', () {
      final location = LocationSettings(
        latitude: 33.3152,
        longitude: 44.3661,
        timezone: 3.0,
        locationName: 'بغداد',
      );

      final calibration = CalibrationSettings.jafariDefault();

      final service = AstronomicalService(
        location: location,
        calibration: calibration,
      );

      // تحويل 1 رمضان 1446
      final hijri1 = HijriDate(year: 1446, month: 9, day: 1);
      final gregorian1 = service.toGregorian(hijri1);

      // تحويل 2 رمضان 1446
      final hijri2 = HijriDate(year: 1446, month: 9, day: 2);
      final gregorian2 = service.toGregorian(hijri2);

      // يجب أن يكون الفرق يوم واحد
      final diff = gregorian2.difference(gregorian1).inDays;
      expect(diff, equals(1), reason: 'يجب أن يكون الفرق يوم واحد');

      // التحقق من أن التاريخ في مارس 2025 (التاريخ الصحيح لرمضان 1446)
      expect(gregorian1.year, equals(2025));
      expect(gregorian1.month, equals(3));
    });
  });
}
