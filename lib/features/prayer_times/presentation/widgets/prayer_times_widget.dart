import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/astronomical/astronomical.dart';
import '../../../../core/services/location_service.dart' as app_location;

/// ويدجت عرض مواقيت الصلاة المحسن
class PrayerTimesWidget extends StatefulWidget {
  final LocationSettings location;
  final CalibrationSettings calibration;
  final DateTime? date;

  const PrayerTimesWidget({
    super.key,
    required this.location,
    required this.calibration,
    this.date,
  });

  @override
  State<PrayerTimesWidget> createState() => _PrayerTimesWidgetState();
}

class _PrayerTimesWidgetState extends State<PrayerTimesWidget> {
  late AstronomicalService _service;
  late CalculatedPrayerTimes _times;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initService();
    _startTimer();
  }

  @override
  void didUpdateWidget(PrayerTimesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location ||
        oldWidget.calibration != widget.calibration ||
        oldWidget.date != widget.date) {
      _initService();
    }
  }

  void _initService() {
    _service = AstronomicalService(
      location: widget.location,
      calibration: widget.calibration,
    );
    _times = _service.getPrayerTimes(widget.date ?? DateTime.now());
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentPrayer = _times.currentPrayer(now);
    final nextPrayer = _times.nextPrayer(now);
    final nextTime = _times.nextPrayerTime(now);

    return Column(
      children: [
        // بطاقة الصلاة القادمة
        _buildNextPrayerCard(nextPrayer, nextTime),
        const SizedBox(height: 16),
        // قائمة المواقيت
        _buildPrayerTimesList(currentPrayer),
        const SizedBox(height: 16),
        // أوقات إضافية
        _buildExtraTimesCard(),
      ],
    );
  }

  Widget _buildNextPrayerCard(Prayer nextPrayer, DateTime? nextTime) {
    final remaining =
        nextTime != null ? nextTime.difference(DateTime.now()) : Duration.zero;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'الصلاة القادمة',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nextPrayer.arabicName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            if (nextTime != null)
              Text(
                _formatTime(nextTime),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            const SizedBox(height: 12),
            // العداد التنازلي
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatDuration(remaining),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList(Prayer currentPrayer) {
    final prayers = [
      (Prayer.fajr, 'الفجر', _times.fajr, Icons.nights_stay),
      (Prayer.sunrise, 'الشروق', _times.sunrise, Icons.wb_sunny_outlined),
      (Prayer.dhuhr, 'الظهر', _times.dhuhr, Icons.wb_sunny),
      (Prayer.asr, 'العصر', _times.asr, Icons.wb_twilight),
      (Prayer.maghrib, 'المغرب', _times.maghrib, Icons.nightlight_round),
      (Prayer.isha, 'العشاء', _times.isha, Icons.bedtime),
    ];

    return Card(
      child: Column(
        children:
            prayers.map((item) {
              final (prayer, name, time, icon) = item;
              final isCurrent = prayer == currentPrayer;
              final isPast = time != null && DateTime.now().isAfter(time);

              return _buildPrayerTimeRow(
                name: name,
                time: time,
                icon: icon,
                isCurrent: isCurrent,
                isPast: isPast && !isCurrent,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildPrayerTimeRow({
    required String name,
    required DateTime? time,
    required IconData icon,
    required bool isCurrent,
    required bool isPast,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            isCurrent
                ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.5)
                : null,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isCurrent
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            icon,
            color:
                isCurrent
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isPast ? Theme.of(context).disabledColor : null,
          ),
        ),
        trailing: Text(
          time != null ? _formatTime(time) : '--:--',
          style: TextStyle(
            fontSize: 18,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isPast ? Theme.of(context).disabledColor : null,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _buildExtraTimesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أوقات إضافية',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildExtraTimeItem(
                    'منتصف الليل',
                    _times.midnight,
                    Icons.dark_mode,
                  ),
                ),
                Expanded(
                  child: _buildExtraTimeItem(
                    'الثلث الأخير',
                    _times.lastThird,
                    Icons.bedtime_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraTimeItem(String label, DateTime? time, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          time != null ? _formatTime(time) : '--:--',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return '٠٠:٠٠:٠٠';
    }
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

/// صفحة مواقيت الصلاة الكاملة
class AdvancedPrayerTimesPage extends StatefulWidget {
  const AdvancedPrayerTimesPage({super.key});

  @override
  State<AdvancedPrayerTimesPage> createState() =>
      _AdvancedPrayerTimesPageState();
}

class _AdvancedPrayerTimesPageState extends State<AdvancedPrayerTimesPage> {
  LocationSettings? _location;
  final CalibrationSettings _calibration = CalibrationSettings.jafariDefault();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final location =
        await app_location.LocationService.instance.getCurrentLocation();
    if (mounted) {
      setState(() {
        _location = location;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _location == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('مواقيت الصلاة'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final service = AstronomicalService(
      location: _location!,
      calibration: _calibration,
    );
    final hijri = service.toHijri(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // الانتقال لصفحة الإعدادات
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // معلومات الموقع والتاريخ
            _buildHeaderCard(hijri),
            const SizedBox(height: 16),
            // ويدجت المواقيت
            PrayerTimesWidget(
              location: _location!,
              calibration: _calibration,
              date: _selectedDate,
            ),
            const SizedBox(height: 16),
            // اتجاه القبلة
            _buildQiblaCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(HijriDate hijri) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // التاريخ
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(
                        const Duration(days: 1),
                      );
                    });
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Column(
                      children: [
                        Text(
                          hijri.toArabicString(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(
                        const Duration(days: 1),
                      );
                    });
                  },
                ),
              ],
            ),
            const Divider(),
            // الموقع
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Text(
                  _location!.locationName ?? 'موقع غير محدد',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQiblaCard() {
    final service = LocationService();
    final qiblaDirection = service.calculateQiblaDirection(
      _location!.latitude,
      _location!.longitude,
    );
    final distanceToKaaba = service.distanceToKaaba(
      _location!.latitude,
      _location!.longitude,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Transform.rotate(
                angle: qiblaDirection * 3.14159 / 180,
                child: Icon(
                  Icons.navigation,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اتجاه القبلة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${qiblaDirection.toStringAsFixed(1)}° من الشمال'),
                  Text(
                    'المسافة: ${distanceToKaaba.toStringAsFixed(0)} كم',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }
}
