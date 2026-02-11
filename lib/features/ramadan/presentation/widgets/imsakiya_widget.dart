import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/services/ramadan_config_service.dart';
import '../../../prayer_times/presentation/bloc/prayer_times_bloc.dart';
import '../../../../core/utils/prayer_time_utils.dart';

/// ويدجت الإمساكية
class ImsakiyaWidget extends StatefulWidget {
  const ImsakiyaWidget({super.key});

  @override
  State<ImsakiyaWidget> createState() => _ImsakiyaWidgetState();
}

class _ImsakiyaWidgetState extends State<ImsakiyaWidget> {
  List<Map<String, dynamic>>? _ramadanDays;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRamadanTimes();
  }

  Future<void> _loadRamadanTimes() async {
    final state = context.read<PrayerTimesBloc>().state;
    if (state is PrayerTimesLoaded) {
      final location = state.location;
      final ramadanDays = <Map<String, dynamic>>[];

      // الحصول على السنة الهجرية الحالية
      final hijri = AppDateUtils.currentHijri;
      int hijriYear = hijri.hYear;

      // إذا انتهى رمضان هذا العام، نستخدم السنة القادمة
      if (hijri.hMonth > 9) {
        hijriYear++;
      }

      // حساب أوقات كل يوم من أيام رمضان
      for (int day = 1; day <= 30; day++) {
        // تحويل التاريخ الهجري إلى ميلادي
        final gregorianDate = _hijriToGregorian(hijriYear, 9, day);

        // حساب أوقات الصلاة لهذا اليوم
        final prayerTimes = PrayerTimeUtils.getPrayerTimes(
          date: gregorianDate,
          latitude: location.latitude,
          longitude: location.longitude,
        );

        ramadanDays.add({
          'day': day,
          'gregorianDate': gregorianDate,
          'fajr': prayerTimes.fajr,
          'maghrib': prayerTimes.maghrib,
          'suhoor': prayerTimes.fajr.subtract(const Duration(minutes: 10)),
        });
      }

      if (mounted) {
        setState(() {
          _ramadanDays = ramadanDays;
          _isLoading = false;
        });
      }
    }
  }

  DateTime _hijriToGregorian(int year, int month, int day) {
    // استخدام مكتبة hijri_calendar للتحويل
    try {
      final hijri =
          HijriCalendar()
            ..hYear = year
            ..hMonth = month
            ..hDay = day;
      return AppDateUtils.hijriToGregorian(hijri);
    } catch (e) {
      // في حالة الخطأ، نستخدم تاريخ بداية رمضان من الإعدادات
      return RamadanConfigService.instance.getRamadanDay(day);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrayerTimesBloc, PrayerTimesState>(
      listener: (context, state) {
        if (state is PrayerTimesLoaded && _ramadanDays == null) {
          _loadRamadanTimes();
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading || _ramadanDays == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ramadanDays!.length,
      itemBuilder: (context, index) {
        final dayData = _ramadanDays![index];
        final dayNumber = dayData['day'] as int;
        final fajr = dayData['fajr'] as DateTime;
        final maghrib = dayData['maghrib'] as DateTime;
        final isLaylatalQadr = [19, 21, 23, 25, 27].contains(dayNumber);
        final isWhiteNight = [13, 14, 15].contains(dayNumber);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color:
              isLaylatalQadr
                  ? AppColors.laylatalQadr.withValues(alpha: 0.1)
                  : isWhiteNight
                  ? Colors.white
                  : null,
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isLaylatalQadr ? AppColors.laylatalQadr : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$dayNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  'اليوم $dayNumber',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLaylatalQadr) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ramadanGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'ليلة القدر',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isWhiteNight) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ليلة بيضاء',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Row(
              children: [
                const Icon(
                  Icons.nightlight_round,
                  size: 14,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
                Text(_formatTime(fajr)),
                const SizedBox(width: 16),
                const Icon(Icons.wb_sunny, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(_formatTime(maghrib)),
              ],
            ),
            trailing: IconButton(
              onPressed: () {
                _showDayDetails(context, dayNumber, dayData);
              },
              icon: const Icon(Icons.info_outline),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showDayDetails(
    BuildContext context,
    int dayNumber,
    Map<String, dynamic> dayData,
  ) {
    final state = context.read<PrayerTimesBloc>().state;
    if (state is! PrayerTimesLoaded) return;

    final location = state.location;
    final gregorianDate = dayData['gregorianDate'] as DateTime;

    // حساب جميع أوقات الصلاة لهذا اليوم
    final prayerTimes = PrayerTimeUtils.getPrayerTimes(
      date: gregorianDate,
      latitude: location.latitude,
      longitude: location.longitude,
    );

    final suhoor = prayerTimes.fajr.subtract(const Duration(minutes: 10));
    final fajr = prayerTimes.fajr;
    final sunrise = prayerTimes.sunrise;
    final dhuhr = prayerTimes.dhuhr;
    final asr = prayerTimes.asr;
    final maghrib = prayerTimes.maghrib;
    final isha = prayerTimes.isha;

    // حساب مدة الصيام
    final fastingDuration = maghrib.difference(fajr);
    final hours = fastingDuration.inHours;
    final minutes = fastingDuration.inMinutes.remainder(60);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'اليوم $dayNumber من رمضان',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  'السحور',
                  _formatTime(suhoor),
                  Icons.nightlight_round,
                ),
                _buildDetailRow('الفجر', _formatTime(fajr), Icons.brightness_3),
                _buildDetailRow('الشروق', _formatTime(sunrise), Icons.wb_sunny),
                _buildDetailRow(
                  'الظهر',
                  _formatTime(dhuhr),
                  Icons.wb_sunny_outlined,
                ),
                _buildDetailRow('العصر', _formatTime(asr), Icons.sunny_snowing),
                _buildDetailRow(
                  'المغرب',
                  _formatTime(maghrib),
                  Icons.wb_twilight,
                ),
                _buildDetailRow('العشاء', _formatTime(isha), Icons.nightlight),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'مدة الصيام: $hours ساعة و $minutes دقيقة',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
