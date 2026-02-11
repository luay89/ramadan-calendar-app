import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/astronomical/astronomical.dart';
import '../../../../core/services/location_service.dart' as app_location;

/// صفحة إمساكية رمضان المحسنة
class AdvancedImsakiyaPage extends StatefulWidget {
  const AdvancedImsakiyaPage({super.key});

  @override
  State<AdvancedImsakiyaPage> createState() => _AdvancedImsakiyaPageState();
}

class _AdvancedImsakiyaPageState extends State<AdvancedImsakiyaPage>
    with WidgetsBindingObserver {
  AstronomicalService? _service;
  List<ImsakiyaDay> _imsakiya = [];
  HijriDate? _todayHijri;
  int _currentRamadanYear = 0;
  Timer? _timer;
  bool _isLoading = true;
  String _currentCity = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServiceAsync();
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // إعادة تحميل الموقع عند العودة للتطبيق
      _checkAndReloadLocation();
    }
  }

  Future<void> _checkAndReloadLocation() async {
    final savedCity =
        await app_location.LocationService.instance.getSavedCityName();
    if (savedCity != _currentCity) {
      print('ImsakiyaPage: تغيرت المدينة من $_currentCity إلى $savedCity');
      _initServiceAsync();
    }
  }

  Future<void> _initServiceAsync() async {
    setState(() => _isLoading = true);

    // تحميل الموقع المحفوظ من الإعدادات
    final location =
        await app_location.LocationService.instance.getCurrentLocation();
    _currentCity =
        await app_location.LocationService.instance.getSavedCityName();
    print('ImsakiyaPage: تم تحميل الموقع: $_currentCity');

    final calibration = CalibrationSettings.jafariDefault();

    _service = AstronomicalService(
      location: location,
      calibration: calibration,
    );

    _todayHijri = _service!.todayHijri;

    // تحديد سنة رمضان
    if (_todayHijri!.month <= 9) {
      _currentRamadanYear = _todayHijri!.year;
    } else {
      _currentRamadanYear = _todayHijri!.year + 1;
    }

    _imsakiya = _service!.getRamadanImsakiya(_currentRamadanYear);
    if (mounted) setState(() => _isLoading = false);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _service == null || _todayHijri == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('إمساكية رمضان')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isRamadan = _todayHijri!.month == 9;
    final currentDay = isRamadan ? _todayHijri!.day : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إمساكية رمضان'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectRamadanYear,
          ),
        ],
      ),
      body: Column(
        children: [
          // رأس الصفحة
          _buildHeader(isRamadan, currentDay),

          // قائمة الأيام
          Expanded(
            child: ListView.builder(
              itemCount: _imsakiya.length,
              itemBuilder: (context, index) {
                final day = _imsakiya[index];
                final isToday = isRamadan && day.day == currentDay;
                return _buildDayCard(day, isToday);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isRamadan, int currentDay) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // عنوان السنة
          Text(
            'رمضان $_currentRamadanYear هـ',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // الموقع
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 16),
              const SizedBox(width: 4),
              Text(
                _service!.location.locationName ?? 'موقع غير محدد',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),

          if (isRamadan) ...[
            const SizedBox(height: 16),
            // عداد الصيام
            _buildFastingCountdown(currentDay),
          ],
        ],
      ),
    );
  }

  Widget _buildFastingCountdown(int currentDay) {
    if (currentDay <= 0 || currentDay > _imsakiya.length) {
      return const SizedBox.shrink();
    }

    final todayData = _imsakiya[currentDay - 1];
    final now = DateTime.now();

    // تحديد حالة الصيام
    final isFasting =
        todayData.imsak != null &&
        todayData.maghrib != null &&
        now.isAfter(todayData.imsak!) &&
        now.isBefore(todayData.maghrib!);

    final targetTime = isFasting ? todayData.maghrib : todayData.imsak;
    final remaining =
        targetTime != null ? targetTime.difference(now) : Duration.zero;

    return Card(
      color: isFasting ? Colors.orange.shade100 : Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFasting ? Icons.wb_sunny : Icons.nights_stay,
                  color: isFasting ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  isFasting ? 'وقت الإفطار' : 'وقت الإمساك',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isFasting
                            ? Colors.orange.shade800
                            : Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(remaining),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (todayData.fastingDuration != null) ...[
              const SizedBox(height: 4),
              Text(
                'مدة الصيام: ${_formatFastingDuration(todayData.fastingDuration!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(ImsakiyaDay day, bool isToday) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color:
          isToday
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
              : null,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              isToday
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  isToday
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              weekDayNames[_service!.dayOfWeek(day.hijriDate)],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'اليوم',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${day.gregorianDate.day}/${day.gregorianDate.month}/${day.gregorianDate.year}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              day.imsak != null ? _formatTime(day.imsak!) : '--:--',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              day.maghrib != null ? _formatTime(day.maghrib!) : '--:--',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTimeRow('الإمساك', day.imsak, Icons.no_food, Colors.blue),
                _buildTimeRow(
                  'الفجر',
                  day.fajr,
                  Icons.nights_stay,
                  Colors.indigo,
                ),
                _buildTimeRow(
                  'الشروق',
                  day.sunrise,
                  Icons.wb_sunny_outlined,
                  Colors.amber,
                ),
                _buildTimeRow(
                  'الظهر',
                  day.dhuhr,
                  Icons.wb_sunny,
                  Colors.yellow.shade800,
                ),
                _buildTimeRow(
                  'العصر',
                  day.asr,
                  Icons.wb_twilight,
                  Colors.orange,
                ),
                _buildTimeRow(
                  'المغرب',
                  day.maghrib,
                  Icons.nightlight_round,
                  Colors.deepOrange,
                ),
                _buildTimeRow('العشاء', day.isha, Icons.bedtime, Colors.purple),
                const Divider(),
                if (day.fastingDuration != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('مدة الصيام:'),
                      Text(
                        _formatFastingDuration(day.fastingDuration!),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                // التحقق من ليالي القدر
                if (_service!.isLailatAlQadrCandidate(day.hijriDate))
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ليلة القدر المحتملة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(
    String label,
    DateTime? time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(
            time != null ? _formatTime(time) : '--:--',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  void _selectRamadanYear() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('اختر سنة رمضان'),
            content: SizedBox(
              width: 200,
              height: 300,
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  final year = _todayHijri!.year - 2 + index;
                  return ListTile(
                    title: Text('رمضان $year هـ'),
                    selected: year == _currentRamadanYear,
                    onTap: () {
                      setState(() {
                        _currentRamadanYear = year;
                        _imsakiya = _service!.getRamadanImsakiya(year);
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
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
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatFastingDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '$hours ساعة و $minutes دقيقة';
  }
}
