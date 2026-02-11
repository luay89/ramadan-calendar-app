import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/ramadan_config_service.dart';

/// صفحة الإعدادات
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // إعدادات المظهر
  bool _isDarkMode = false;
  double _fontSize = 18.0;

  // إعدادات التنبيهات
  bool _prayerNotifications = true;
  bool _eventNotifications = true;
  bool _ramadanNotifications = true;
  int _notificationMinutesBefore = 10;

  // إعدادات الموقع
  bool _autoLocation = true;
  String _selectedCity = 'بغداد';

  // إعدادات حساب الوقت
  String _calculationMethod = 'jafari';
  String _asrMethod = 'standard';

  // تعديل التقويم الهجري
  int _hijriAdjustment = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await AppDateUtils.loadHijriAdjustment();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _fontSize = prefs.getDouble('fontSize') ?? 18.0;
      _prayerNotifications = prefs.getBool('prayerNotifications') ?? true;
      _eventNotifications = prefs.getBool('eventNotifications') ?? true;
      _ramadanNotifications = prefs.getBool('ramadanNotifications') ?? true;
      _notificationMinutesBefore =
          prefs.getInt('notificationMinutesBefore') ?? 10;
      _autoLocation = prefs.getBool('autoLocation') ?? true;
      _selectedCity = prefs.getString('selectedCity') ?? 'بغداد';
      _calculationMethod = prefs.getString('calculationMethod') ?? 'jafari';
      _asrMethod = prefs.getString('asrMethod') ?? 'standard';
      _hijriAdjustment = AppDateUtils.hijriAdjustmentDays;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setBool('prayerNotifications', _prayerNotifications);
    await prefs.setBool('eventNotifications', _eventNotifications);
    await prefs.setBool('ramadanNotifications', _ramadanNotifications);
    await prefs.setInt('notificationMinutesBefore', _notificationMinutesBefore);
    await prefs.setBool('autoLocation', _autoLocation);
    await prefs.setString('selectedCity', _selectedCity);
    await prefs.setString('calculationMethod', _calculationMethod);
    await prefs.setString('asrMethod', _asrMethod);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // إعدادات المظهر
          _buildSectionHeader('المظهر', Icons.palette),
          _buildSettingsCard([
            SwitchListTile(
              title: const Text('الوضع الداكن'),
              subtitle: const Text('تفعيل المظهر الداكن للتطبيق'),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() => _isDarkMode = value);
                _saveSettings();
              },
              secondary: Icon(
                _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: AppColors.primary,
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('حجم الخط'),
              subtitle: Text('${_fontSize.toInt()} نقطة'),
              leading: Icon(Icons.text_fields, color: AppColors.primary),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: _fontSize,
                  min: 14,
                  max: 28,
                  divisions: 7,
                  onChanged: (value) {
                    setState(() => _fontSize = value);
                  },
                  onChangeEnd: (value) => _saveSettings(),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // إعدادات التنبيهات
          _buildSectionHeader('التنبيهات', Icons.notifications),
          _buildSettingsCard([
            SwitchListTile(
              title: const Text('تنبيهات الصلاة'),
              subtitle: const Text('التنبيه عند دخول وقت الصلاة'),
              value: _prayerNotifications,
              onChanged: (value) {
                setState(() => _prayerNotifications = value);
                _saveSettings();
              },
              secondary: Icon(Icons.access_time, color: AppColors.primary),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('تنبيهات المناسبات'),
              subtitle: const Text('التنبيه بالمناسبات الإسلامية'),
              value: _eventNotifications,
              onChanged: (value) {
                setState(() => _eventNotifications = value);
                _saveSettings();
              },
              secondary: Icon(Icons.event, color: AppColors.primary),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('تنبيهات رمضان'),
              subtitle: const Text('التنبيه بأوقات الإمساك والإفطار'),
              value: _ramadanNotifications,
              onChanged: (value) {
                setState(() => _ramadanNotifications = value);
                _saveSettings();
              },
              secondary: Icon(Icons.nights_stay, color: AppColors.primary),
            ),
            const Divider(),
            ListTile(
              title: const Text('وقت التنبيه'),
              subtitle: Text('$_notificationMinutesBefore دقيقة قبل الموعد'),
              leading: Icon(Icons.timer, color: AppColors.primary),
              trailing: DropdownButton<int>(
                value: _notificationMinutesBefore,
                items:
                    [5, 10, 15, 20, 30]
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text('$m دقيقة'),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _notificationMinutesBefore = value);
                    _saveSettings();
                  }
                },
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // إعدادات الموقع
          _buildSectionHeader('الموقع', Icons.location_on),
          _buildSettingsCard([
            SwitchListTile(
              title: const Text('تحديد الموقع تلقائياً'),
              subtitle: const Text('استخدام GPS لتحديد موقعك'),
              value: _autoLocation,
              onChanged: (value) {
                setState(() => _autoLocation = value);
                _saveSettings();
              },
              secondary: Icon(Icons.gps_fixed, color: AppColors.primary),
            ),
            const Divider(),
            ListTile(
              title: const Text('المدينة'),
              subtitle: Text(_selectedCity),
              leading: Icon(Icons.location_city, color: AppColors.primary),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              enabled: !_autoLocation,
              onTap: _autoLocation ? null : () => _showCityPicker(),
            ),
          ]),

          const SizedBox(height: 20),

          // إعدادات حساب مواقيت الصلاة
          _buildSectionHeader('مواقيت الصلاة', Icons.mosque),
          _buildSettingsCard([
            ListTile(
              title: const Text('طريقة الحساب'),
              subtitle: Text(_getCalculationMethodName(_calculationMethod)),
              leading: Icon(Icons.calculate, color: AppColors.primary),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showCalculationMethodPicker(),
            ),
            const Divider(),
            ListTile(
              title: const Text('حساب العصر'),
              subtitle: Text(_getAsrMethodName(_asrMethod)),
              leading: Icon(Icons.wb_sunny, color: AppColors.primary),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showAsrMethodPicker(),
            ),
          ]),

          const SizedBox(height: 20),

          // تعديل التقويم الهجري
          _buildSectionHeader('التقويم الهجري', Icons.calendar_month),
          _buildSettingsCard([
            ListTile(
              title: const Text('تعديل التقويم الهجري'),
              subtitle: Text(_getHijriAdjustmentText()),
              leading: Icon(Icons.tune, color: AppColors.primary),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showHijriAdjustmentDialog(),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _decrementHijriDay(),
                    icon: const Icon(Icons.remove, size: 18),
                    label: const Text('تأخير يوم'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _incrementHijriDay(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('تقديم يوم'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (_hijriAdjustment != 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton(
                  onPressed: () => _resetHijriAdjustment(),
                  child: const Text('إعادة تعيين التقويم'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التاريخ الهجري الحالي:',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppDateUtils.formatHijriArabic(AppDateUtils.currentHijri),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يوم ${AppDateUtils.getDayNameArabic(DateTime.now())}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // إعدادات رمضان
          _buildSectionHeader('إعدادات رمضان', Icons.nights_stay),
          _buildSettingsCard([
            ListTile(
              title: const Text('تاريخ بداية رمضان'),
              subtitle: Text(RamadanConfigService.instance.getRamadanInfo()),
              leading: Icon(Icons.calendar_today, color: AppColors.primary),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showRamadanStartPicker(),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.ramadanGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.ramadanGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'معلومات رمضان',
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(
                            color: AppColors.ramadanGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• أول أيام رمضان: ${RamadanConfigService.instance.startDayName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '• التاريخ الميلادي: ${RamadanConfigService.instance.startDay}/${RamadanConfigService.instance.startMonth}/${RamadanConfigService.instance.startYear}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '• السنة الهجرية: ${RamadanConfigService.instance.hijriYear} هـ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // حول التطبيق
          _buildSectionHeader('حول التطبيق', Icons.info),
          _buildSettingsCard([
            ListTile(
              title: const Text('مشاركة التطبيق'),
              subtitle: const Text('شارك التطبيق مع أصدقائك'),
              leading: Icon(Icons.share, color: AppColors.primary),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Share.share('تطبيق تقويم رمضان - مواقيت الصلاة والأدعية والزيارات\n\nحمّل التطبيق الآن!');
              },
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  String _getCalculationMethodName(String method) {
    switch (method) {
      case 'jafari':
        return 'المذهب الجعفري (شيعة اثنا عشرية)';
      case 'muslim_world_league':
        return 'رابطة العالم الإسلامي';
      case 'egyptian':
        return 'الهيئة المصرية للمساحة';
      case 'karachi':
        return 'جامعة العلوم الإسلامية - كراتشي';
      case 'umm_al_qura':
        return 'أم القرى';
      default:
        return method;
    }
  }

  String _getAsrMethodName(String method) {
    switch (method) {
      case 'standard':
        return 'القياسي (المثل)';
      case 'hanafi':
        return 'الحنفي (المثلين)';
      default:
        return method;
    }
  }

  void _showLocationUpdatedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تغيير الموقع إلى: $_selectedCity'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'حسناً',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showCityPicker() {
    final cities = LocationService.instance.getAvailableCities();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('اختر المدينة'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: cities.length,
                itemBuilder:
                    (context, index) => ListTile(
                      title: Text(cities[index]),
                      leading: Radio<String>(
                        value: cities[index],
                        groupValue: _selectedCity,
                        onChanged: (value) async {
                          setState(() => _selectedCity = value!);
                          await LocationService.instance.saveSelectedCity(
                            value!,
                          );
                          _saveSettings();
                          Navigator.pop(context);
                          _showLocationUpdatedMessage();
                        },
                      ),
                      onTap: () async {
                        setState(() => _selectedCity = cities[index]);
                        await LocationService.instance.saveSelectedCity(
                          cities[index],
                        );
                        _saveSettings();
                        Navigator.pop(context);
                        _showLocationUpdatedMessage();
                      },
                    ),
              ),
            ),
          ),
    );
  }

  void _showCalculationMethodPicker() {
    final methods = {
      'jafari': 'المذهب الجعفري (شيعة اثنا عشرية)',
      'muslim_world_league': 'رابطة العالم الإسلامي',
      'egyptian': 'الهيئة المصرية للمساحة',
      'karachi': 'جامعة العلوم الإسلامية - كراتشي',
      'umm_al_qura': 'أم القرى',
    };

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('طريقة الحساب'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  methods.entries
                      .map(
                        (e) => RadioListTile<String>(
                          title: Text(e.value),
                          value: e.key,
                          groupValue: _calculationMethod,
                          onChanged: (value) {
                            setState(() => _calculationMethod = value!);
                            _saveSettings();
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }

  void _showAsrMethodPicker() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('حساب وقت العصر'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('القياسي (المثل)'),
                  subtitle: const Text('معظم المذاهب'),
                  value: 'standard',
                  groupValue: _asrMethod,
                  onChanged: (value) {
                    setState(() => _asrMethod = value!);
                    _saveSettings();
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('الحنفي (المثلين)'),
                  subtitle: const Text('المذهب الحنفي'),
                  value: 'hanafi',
                  groupValue: _asrMethod,
                  onChanged: (value) {
                    setState(() => _asrMethod = value!);
                    _saveSettings();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  // دوال تعديل التقويم الهجري
  String _getHijriAdjustmentText() {
    if (_hijriAdjustment == 0) {
      return 'بدون تعديل';
    } else if (_hijriAdjustment > 0) {
      return 'تقديم $_hijriAdjustment ${_hijriAdjustment == 1 ? "يوم" : "أيام"}';
    } else {
      return 'تأخير ${_hijriAdjustment.abs()} ${_hijriAdjustment.abs() == 1 ? "يوم" : "أيام"}';
    }
  }

  Future<void> _incrementHijriDay() async {
    await AppDateUtils.incrementHijriDay();
    setState(() {
      _hijriAdjustment = AppDateUtils.hijriAdjustmentDays;
    });
    _showHijriUpdateSnackbar();
  }

  Future<void> _decrementHijriDay() async {
    await AppDateUtils.decrementHijriDay();
    setState(() {
      _hijriAdjustment = AppDateUtils.hijriAdjustmentDays;
    });
    _showHijriUpdateSnackbar();
  }

  Future<void> _resetHijriAdjustment() async {
    await AppDateUtils.resetHijriAdjustment();
    setState(() {
      _hijriAdjustment = 0;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إعادة تعيين التقويم الهجري'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showHijriUpdateSnackbar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'التاريخ الهجري: ${AppDateUtils.formatHijriArabic(AppDateUtils.currentHijri)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showHijriAdjustmentDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('تعديل التقويم الهجري'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'يمكنك تعديل التقويم الهجري ليتوافق مع رؤية الهلال في منطقتك',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'التاريخ الحالي',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppDateUtils.formatHijriArabic(
                                AppDateUtils.currentHijri,
                              ),
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'يوم ${AppDateUtils.getDayNameArabic(DateTime.now())}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filled(
                            onPressed: () async {
                              await AppDateUtils.decrementHijriDay();
                              setDialogState(() {});
                              setState(() {
                                _hijriAdjustment =
                                    AppDateUtils.hijriAdjustmentDays;
                              });
                            },
                            icon: const Icon(Icons.remove),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${AppDateUtils.hijriAdjustmentDays > 0 ? '+' : ''}${AppDateUtils.hijriAdjustmentDays}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton.filled(
                            onPressed: () async {
                              await AppDateUtils.incrementHijriDay();
                              setDialogState(() {});
                              setState(() {
                                _hijriAdjustment =
                                    AppDateUtils.hijriAdjustmentDays;
                              });
                            },
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getHijriAdjustmentText(),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await AppDateUtils.resetHijriAdjustment();
                        setDialogState(() {});
                        setState(() {
                          _hijriAdjustment = 0;
                        });
                      },
                      child: const Text('إعادة تعيين'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('تم'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showRamadanStartPicker() {
    final config = RamadanConfigService.instance;
    DateTime selectedDate = config.ramadanStartDate;
    int hijriYear = config.hijriYear;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('تاريخ بداية رمضان'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'اختر التاريخ الميلادي لأول يوم من شهر رمضان',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // السنة الهجرية
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('رمضان '),
                            DropdownButton<int>(
                              value: hijriYear,
                              items:
                                  List.generate(10, (i) => 1445 + i)
                                      .map(
                                        (y) => DropdownMenuItem(
                                          value: y,
                                          child: Text('$y هـ'),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() => hijriYear = value);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // اختيار التاريخ
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'التاريخ المختار:',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_getDayName(selectedDate.weekday)} ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2030),
                                    locale: const Locale('ar'),
                                  );
                                  if (date != null) {
                                    setDialogState(() => selectedDate = date);
                                  }
                                },
                                icon: const Icon(Icons.calendar_today),
                                label: const Text('اختر التاريخ'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // معلومات إضافية
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lightbulb,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'أول أيام رمضان سيكون: ${_getDayName(selectedDate.weekday)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await config.resetToDefaults();
                        setState(() {});
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('إعادة تعيين'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await config.saveSettings(
                          year: selectedDate.year,
                          month: selectedDate.month,
                          day: selectedDate.day,
                          hijriYear: hijriYear,
                        );
                        setState(() {});
                        if (context.mounted) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم تحديث تاريخ بداية رمضان: ${config.getRamadanInfo()}',
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      child: const Text('حفظ'),
                    ),
                  ],
                ),
          ),
    );
  }

  String _getDayName(int weekday) {
    const days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[weekday - 1];
  }
}
