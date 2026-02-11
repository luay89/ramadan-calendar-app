import 'package:flutter/material.dart';
import '../../../../core/astronomical/astronomical.dart';

/// صفحة إعدادات التقويم والمواقيت
class AstronomicalSettingsPage extends StatefulWidget {
  const AstronomicalSettingsPage({super.key});

  @override
  State<AstronomicalSettingsPage> createState() =>
      _AstronomicalSettingsPageState();
}

class _AstronomicalSettingsPageState extends State<AstronomicalSettingsPage> {
  late CalibrationSettings _calibration;
  late LocationSettings _location;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // تحميل الإعدادات (في التطبيق الفعلي من Hive)
    setState(() {
      _calibration = CalibrationSettings.jafariDefault();
      _location = LocationSettings.defaultLocation();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات المواقيت والتقويم'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // قسم الموقع
          _buildSectionHeader('الموقع الجغرافي', Icons.location_on),
          _buildLocationCard(),
          const SizedBox(height: 24),

          // قسم طريقة الحساب
          _buildSectionHeader('طريقة حساب المواقيت', Icons.calculate),
          _buildCalculationMethodCard(),
          const SizedBox(height: 24),

          // قسم التعديلات اليدوية
          _buildSectionHeader('تعديل المواقيت', Icons.tune),
          _buildPrayerAdjustmentsCard(),
          const SizedBox(height: 24),

          // قسم التقويم الهجري
          _buildSectionHeader('التقويم الهجري', Icons.calendar_month),
          _buildHijriCalendarCard(),
          const SizedBox(height: 24),

          // قسم الإعدادات المتقدمة
          _buildSectionHeader('إعدادات متقدمة', Icons.settings),
          _buildAdvancedSettingsCard(),
          const SizedBox(height: 32),

          // زر إعادة الضبط
          Center(
            child: OutlinedButton.icon(
              onPressed: _resetToDefaults,
              icon: const Icon(Icons.restore),
              label: const Text('إعادة الضبط للقيم الافتراضية'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الموقع الحالي
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.place)),
              title: Text(_location.locationName ?? 'موقع غير محدد'),
              subtitle: Text(_location.country ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _detectLocation,
                tooltip: 'تحديد الموقع تلقائياً',
              ),
            ),
            const Divider(),
            // الإحداثيات
            Row(
              children: [
                Expanded(
                  child: _buildCoordinateField(
                    'خط العرض',
                    _location.latitude.toStringAsFixed(4),
                    (value) {
                      final lat = double.tryParse(value);
                      if (lat != null && lat >= -90 && lat <= 90) {
                        setState(() {
                          _location = _location.copyWith(latitude: lat);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCoordinateField(
                    'خط الطول',
                    _location.longitude.toStringAsFixed(4),
                    (value) {
                      final lon = double.tryParse(value);
                      if (lon != null && lon >= -180 && lon <= 180) {
                        setState(() {
                          _location = _location.copyWith(longitude: lon);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // المنطقة الزمنية
            Row(
              children: [
                const Text('المنطقة الزمنية: '),
                const SizedBox(width: 8),
                DropdownButton<double>(
                  value: _location.timezone,
                  items:
                      List.generate(25, (i) => i - 12).map((offset) {
                        final sign = offset >= 0 ? '+' : '';
                        return DropdownMenuItem(
                          value: offset.toDouble(),
                          child: Text('UTC$sign$offset'),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _location = _location.copyWith(timezone: value);
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // اختيار من المدن
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showCitySelector,
                icon: const Icon(Icons.list),
                label: const Text('اختيار من قائمة المدن'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinateField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      controller: TextEditingController(text: value),
      onChanged: onChanged,
    );
  }

  Widget _buildCalculationMethodCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // طريقة الحساب
            const Text(
              'طريقة حساب الفجر والعشاء',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...CalculationMethodInfo.availableMethods.map((method) {
              return RadioListTile<CalculationMethod>(
                title: Text(method.arabicName),
                subtitle: Text(
                  'فجر: ${method.fajrAngle}° | عشاء: ${method.ishaAngle > 0 ? '${method.ishaAngle}°' : '${method.ishaMinutes} دقيقة'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: method.method,
                groupValue: _calibration.calculationMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _calibration.calculationMethod = value;
                    });
                  }
                },
                dense: true,
              );
            }),
            const Divider(),
            // طريقة حساب العصر
            const Text(
              'طريقة حساب العصر',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            RadioListTile<AsrCalculation>(
              title: const Text('الجمهور (المثل)'),
              subtitle: const Text('الشافعية والمالكية والحنابلة والجعفرية'),
              value: AsrCalculation.standard,
              groupValue: _calibration.asrCalculation,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _calibration.asrCalculation = value;
                  });
                }
              },
              dense: true,
            ),
            RadioListTile<AsrCalculation>(
              title: const Text('الحنفية (المثلين)'),
              value: AsrCalculation.hanafi,
              groupValue: _calibration.asrCalculation,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _calibration.asrCalculation = value;
                  });
                }
              },
              dense: true,
            ),
            const Divider(),
            // منتصف الليل
            const Text(
              'طريقة حساب منتصف الليل',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            RadioListTile<MidnightMethod>(
              title: const Text('الشرعي (مغرب - فجر)'),
              subtitle: const Text('منتصف الليل بين المغرب والفجر'),
              value: MidnightMethod.jafari,
              groupValue: _calibration.midnightMethod,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _calibration.midnightMethod = value;
                  });
                }
              },
              dense: true,
            ),
            RadioListTile<MidnightMethod>(
              title: const Text('الفلكي (غروب - شروق)'),
              subtitle: const Text('منتصف الليل بين الغروب والشروق'),
              value: MidnightMethod.standard,
              groupValue: _calibration.midnightMethod,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _calibration.midnightMethod = value;
                  });
                }
              },
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerAdjustmentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تعديل أوقات الصلاة (بالدقائق)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'استخدم هذه التعديلات لمعايرة المواقيت مع التقويم المحلي',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildAdjustmentSlider('الفجر', _calibration.fajrAdjustment, (
              value,
            ) {
              setState(() => _calibration.fajrAdjustment = value);
            }),
            _buildAdjustmentSlider('الشروق', _calibration.sunriseAdjustment, (
              value,
            ) {
              setState(() => _calibration.sunriseAdjustment = value);
            }),
            _buildAdjustmentSlider('الظهر', _calibration.dhuhrAdjustment, (
              value,
            ) {
              setState(() => _calibration.dhuhrAdjustment = value);
            }),
            _buildAdjustmentSlider('العصر', _calibration.asrAdjustment, (
              value,
            ) {
              setState(() => _calibration.asrAdjustment = value);
            }),
            _buildAdjustmentSlider('المغرب', _calibration.maghribAdjustment, (
              value,
            ) {
              setState(() => _calibration.maghribAdjustment = value);
            }),
            _buildAdjustmentSlider('العشاء', _calibration.ishaAdjustment, (
              value,
            ) {
              setState(() => _calibration.ishaAdjustment = value);
            }),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _calibration.resetAdjustments());
                },
                child: const Text('إعادة ضبط التعديلات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentSlider(
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: -30,
              max: 30,
              divisions: 60,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '${value >= 0 ? '+' : ''}$value د',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    value == 0
                        ? Colors.grey
                        : (value > 0 ? Colors.green : Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHijriCalendarCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تعديل التقويم الهجري',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'لتوافق التقويم مع الرؤية الشرعية في منطقتك',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: () {
                    setState(() {
                      _calibration.hijriDayAdjustment--;
                    });
                  },
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Text(
                      '${_calibration.hijriDayAdjustment >= 0 ? '+' : ''}${_calibration.hijriDayAdjustment}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Text('يوم'),
                  ],
                ),
                const SizedBox(width: 24),
                IconButton.filled(
                  onPressed: () {
                    setState(() {
                      _calibration.hijriDayAdjustment++;
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // معاينة التاريخ
            _buildDatePreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePreview() {
    final engine = HijriCalendarEngine(
      dayAdjustment: _calibration.hijriDayAdjustment,
    );
    final hijri = engine.gregorianToHijri(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 20),
          const SizedBox(width: 8),
          Text(
            'اليوم: ${hijri.toArabicString()}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قاعدة خطوط العرض العالية
            const Text(
              'قاعدة خطوط العرض العالية',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const Text(
              'للمناطق التي لا تغرب فيها الشمس أو لا يظهر الفجر',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            DropdownButton<HighLatitudeRule>(
              value: _calibration.highLatitudeRule,
              isExpanded: true,
              items:
                  HighLatitudeRule.values.map((rule) {
                    return DropdownMenuItem(
                      value: rule,
                      child: Text(_highLatitudeRuleName(rule)),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _calibration.highLatitudeRule = value;
                  });
                }
              },
            ),
            const Divider(height: 32),
            // تأخير المغرب
            Row(
              children: [
                const Text('تأخير المغرب: '),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _calibration.maghribDelay,
                  items:
                      List.generate(16, (i) => i).map((minutes) {
                        return DropdownMenuItem(
                          value: minutes,
                          child: Text('$minutes دقيقة'),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _calibration.maghribDelay = value;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'المذهب الجعفري: المغرب بعد زوال الحمرة المشرقية (4 دقائق)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _highLatitudeRuleName(HighLatitudeRule rule) {
    switch (rule) {
      case HighLatitudeRule.none:
        return 'بدون تعديل';
      case HighLatitudeRule.middleOfNight:
        return 'نسبة من منتصف الليل';
      case HighLatitudeRule.seventhOfNight:
        return 'سُبع الليل';
      case HighLatitudeRule.twilightAngle:
        return 'زاوية الشفق';
    }
  }

  void _detectLocation() async {
    final service = LocationService();
    final result = await service.getCurrentLocation();

    if (result.isSuccess && result.location != null) {
      setState(() {
        _location = result.location!;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديد الموقع بنجاح')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'فشل تحديد الموقع')),
        );
      }
    }
  }

  void _showCitySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'اختر مدينة',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: LocationSettings.famousCities.length,
                      itemBuilder: (context, index) {
                        final entry = LocationSettings.famousCities.entries
                            .elementAt(index);
                        final city = entry.value;
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.place)),
                          title: Text(city.locationName ?? entry.key),
                          subtitle: Text(city.country ?? ''),
                          trailing: Text(
                            'UTC${city.timezone >= 0 ? '+' : ''}${city.timezone.toInt()}',
                          ),
                          onTap: () {
                            setState(() {
                              _location = city;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('إعادة الضبط'),
            content: const Text(
              'هل تريد إعادة جميع الإعدادات للقيم الافتراضية؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _calibration.resetToDefaults();
                    _location = LocationSettings.defaultLocation();
                  });
                  Navigator.pop(context);
                },
                child: const Text('إعادة الضبط'),
              ),
            ],
          ),
    );
  }
}
