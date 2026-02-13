import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/services/adhan_audio_service.dart';
import '../../../../core/services/adhan_notification_service.dart';
import '../../../../core/services/gps_location_service.dart';
import '../../domain/entities/prayer_times_entity.dart';
import '../bloc/prayer_times_bloc.dart';
import '../widgets/prayer_time_card.dart';
import '../widgets/next_prayer_widget.dart';
import '../widgets/hijri_gregorian_calendar.dart';

/// صفحة مواقيت الصلاة
class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  final AdhanAudioService _adhanService = AdhanAudioService();
  final AdhanNotificationService _notificationService =
      AdhanNotificationService();
  bool _isPlayingAdhan = false;

  @override
  void initState() {
    super.initState();
    context.read<PrayerTimesBloc>().add(const LoadPrayerTimes());
    _initAdhanService();
  }

  Future<void> _initAdhanService() async {
    await _adhanService.initialize();
    await _notificationService.initialize();
    _adhanService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAdhan = state.playing;
        });
        // إيقاف عند انتهاء الأذان
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlayingAdhan = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _adhanService.stopAdhan();
    super.dispose();
  }

  /// جدولة الأذان للصلوات المفعلة
  Future<void> _scheduleEnabledAdhans(PrayerTimesEntity prayerTimes) async {
    await _notificationService.scheduleAllEnabledAdhans(
      fajrTime: prayerTimes.fajr,
      dhuhrTime: prayerTimes.dhuhr,
      asrTime: prayerTimes.asr,
      maghribTime: prayerTimes.maghrib,
      ishaTime: prayerTimes.isha,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        actions: [
          IconButton(
            onPressed: _toggleAdhan,
            icon: Icon(
              _isPlayingAdhan ? Icons.stop_circle : Icons.volume_up,
              color: _isPlayingAdhan ? AppColors.error : null,
            ),
            tooltip: _isPlayingAdhan ? 'إيقاف الأذان' : 'تشغيل الأذان',
          ),
          IconButton(
            onPressed: () => _refreshLocation(context),
            icon: const Icon(Icons.my_location),
            tooltip: 'تحديث الموقع',
          ),
          IconButton(
            onPressed: () => _showDatePicker(context),
            icon: const Icon(Icons.calendar_today),
            tooltip: 'تغيير التاريخ',
          ),
        ],
      ),
      body: BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
        builder: (context, state) {
          if (state is PrayerTimesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PrayerTimesError) {
            return _buildErrorWidget(context, state);
          }

          if (state is PrayerTimesLoaded) {
            // جدولة الأذان للصلوات المفعلة
            _scheduleEnabledAdhans(state.prayerTimes);

            return RefreshIndicator(
              onRefresh: () async {
                context.read<PrayerTimesBloc>().add(const LoadPrayerTimes());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // معلومات الموقع والتاريخ
                    _buildHeader(state),
                    const SizedBox(height: 16),

                    // الصلاة القادمة
                    NextPrayerWidget(
                      prayerName: state.nextPrayer.key,
                      prayerTime: state.nextPrayer.value,
                      remainingTime: state.timeUntilNextPrayer,
                    ),
                    const SizedBox(height: 24),

                    // قائمة المواقيت
                    _buildPrayerTimesList(state.prayerTimes),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(PrayerTimesLoaded state) {
    final hijriDate = AppDateUtils.gregorianToHijri(state.selectedDate);
    final dayName = AppDateUtils.getDayNameArabic(state.selectedDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // الموقع
            Row(
              children: [
                state.isRefreshingLocation
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.location.fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${state.location.latitude.toStringAsFixed(4)}°, ${state.location.longitude.toStringAsFixed(4)}°',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _refreshLocation(context),
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'تحديث الموقع',
                ),
              ],
            ),
            const Divider(height: 24),
            // التقويم المدمج
            Row(
              children: [
                const Icon(Icons.calendar_month, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم اليوم
                      Text(
                        dayName,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // التاريخ الهجري
                      Row(
                        children: [
                          const Icon(
                            Icons.brightness_2,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppDateUtils.formatHijriArabic(hijriDate),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'هـ',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // التاريخ الميلادي
                      Row(
                        children: [
                          const Icon(
                            Icons.wb_sunny_outlined,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppDateUtils.formatGregorianArabic(
                              state.selectedDate,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'م',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showDatePicker(context),
                  icon: const Icon(Icons.edit_calendar, size: 20),
                  tooltip: 'تغيير التاريخ',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList(PrayerTimesEntity prayerTimes) {
    // قائمة الصلوات مع إمكانية تفعيل الأذان (ماعدا الشروق)
    final prayers = [
      (
        'الفجر',
        prayerTimes.fajr,
        PrayerType.fajr,
        AppColors.fajrColor,
        PrayerName.fajr,
        true,
      ),
      (
        'الشروق',
        prayerTimes.sunrise,
        PrayerType.sunrise,
        AppColors.sunriseColor,
        null,
        false,
      ),
      (
        'الظهر',
        prayerTimes.dhuhr,
        PrayerType.dhuhr,
        AppColors.dhuhrColor,
        PrayerName.dhuhr,
        true,
      ),
      (
        'العصر',
        prayerTimes.asr,
        PrayerType.asr,
        AppColors.asrColor,
        PrayerName.asr,
        true,
      ),
      (
        'المغرب',
        prayerTimes.maghrib,
        PrayerType.maghrib,
        AppColors.maghribColor,
        PrayerName.maghrib,
        true,
      ),
      (
        'العشاء',
        prayerTimes.isha,
        PrayerType.isha,
        AppColors.ishaColor,
        PrayerName.isha,
        true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'مواقيت الصلاة',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _showAdhanSettingsInfo,
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('تفعيل الأذان'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...prayers.map(
          (prayer) => PrayerTimeCard(
            name: prayer.$1,
            time: prayer.$2,
            color: prayer.$4,
            isPassed: DateTime.now().isAfter(prayer.$2),
            showAdhanToggle: prayer.$6,
            prayerName: prayer.$5,
          ),
        ),

        // الأوقات الإضافية
        if (prayerTimes.midnight != null || prayerTimes.lastThird != null) ...[
          const SizedBox(height: 16),
          Text(
            'أوقات مستحبة',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (prayerTimes.midnight != null)
            PrayerTimeCard(
              name: 'منتصف الليل الشرعي',
              time: prayerTimes.midnight!,
              color: AppColors.ramadanBlue,
              isPassed: DateTime.now().isAfter(prayerTimes.midnight!),
            ),
          if (prayerTimes.lastThird != null)
            PrayerTimeCard(
              name: 'الثلث الأخير من الليل',
              time: prayerTimes.lastThird!,
              color: AppColors.ramadanPurple,
              isPassed: DateTime.now().isAfter(prayerTimes.lastThird!),
            ),
        ],
      ],
    );
  }

  /// تحديث الموقع من GPS
  void _refreshLocation(BuildContext context) {
    context.read<PrayerTimesBloc>().add(const RefreshLocation());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري تحديث الموقع...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// بناء واجهة الخطأ
  Widget _buildErrorWidget(BuildContext context, PrayerTimesError state) {
    IconData icon = Icons.error_outline;
    String buttonText = 'إعادة المحاولة';
    VoidCallback? secondaryAction;
    String? secondaryButtonText;

    // تخصيص الواجهة حسب نوع الخطأ
    if (state.errorType == GPSErrorType.serviceDisabled) {
      icon = Icons.location_disabled;
      secondaryButtonText = 'فتح الإعدادات';
      secondaryAction =
          () => GPSLocationService.instance.openLocationSettings();
    } else if (state.errorType == GPSErrorType.permissionDenied) {
      icon = Icons.location_off;
    } else if (state.errorType == GPSErrorType.permissionDeniedForever) {
      icon = Icons.location_off;
      secondaryButtonText = 'فتح إعدادات التطبيق';
      secondaryAction = () => GPSLocationService.instance.openAppSettings();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<PrayerTimesBloc>().add(const LoadPrayerTimes());
              },
              icon: const Icon(Icons.refresh),
              label: Text(buttonText),
            ),
            if (secondaryAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: secondaryAction,
                icon: const Icon(Icons.settings),
                label: Text(secondaryButtonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context) async {
    final state = context.read<PrayerTimesBloc>().state;
    if (state is! PrayerTimesLoaded) return;

    final date = await showHijriGregorianCalendarPicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      context.read<PrayerTimesBloc>().add(ChangeDate(date));
    }
  }

  Future<void> _toggleAdhan() async {
    if (_isPlayingAdhan) {
      await _adhanService.stopAdhan();
    } else {
      await _adhanService.playAdhan();
    }
  }

  void _showAdhanSettingsInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.green),
                SizedBox(width: 8),
                Text('تفعيل الأذان التلقائي'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'يمكنك تفعيل الأذان التلقائي لكل صلاة بشكل منفصل:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text('• استخدم الزر بجانب كل صلاة لتفعيل أو إلغاء الأذان'),
                SizedBox(height: 8),
                Text('• سيتم تشغيل الأذان تلقائياً عند دخول وقت الصلاة'),
                SizedBox(height: 8),
                Text('• يعمل الأذان حتى لو كان التطبيق مغلقاً'),
                SizedBox(height: 8),
                Text('• تأكد من السماح للتطبيق بإرسال الإشعارات'),
                SizedBox(height: 12),
                Text(
                  '💡 ملاحظة: قد تحتاج لتعطيل وضع توفير البطارية للتطبيق',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
    );
  }
}
