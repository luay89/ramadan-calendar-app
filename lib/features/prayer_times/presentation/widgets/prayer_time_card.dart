import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/services/adhan_notification_service.dart';

/// ويدجت بطاقة وقت الصلاة
class PrayerTimeCard extends StatefulWidget {
  final String name;
  final DateTime time;
  final Color color;
  final bool isPassed;
  final bool showAdhanToggle;
  final PrayerName? prayerName;
  final VoidCallback? onAdhanToggled;

  const PrayerTimeCard({
    super.key,
    required this.name,
    required this.time,
    required this.color,
    this.isPassed = false,
    this.showAdhanToggle = false,
    this.prayerName,
    this.onAdhanToggled,
  });

  @override
  State<PrayerTimeCard> createState() => _PrayerTimeCardState();
}

class _PrayerTimeCardState extends State<PrayerTimeCard> {
  final AdhanNotificationService _notificationService =
      AdhanNotificationService();
  bool _isAdhanEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.showAdhanToggle && widget.prayerName != null) {
      _loadAdhanState();
    }
  }

  Future<void> _loadAdhanState() async {
    await _notificationService.initialize();
    if (mounted) {
      setState(() {
        _isAdhanEnabled = _notificationService.isAdhanEnabled(
          widget.prayerName!,
        );
      });
    }
  }

  Future<void> _toggleAdhan(bool value) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _notificationService.setAdhanEnabled(widget.prayerName!, value);

      if (value) {
        // جدولة الأذان
        await _notificationService.scheduleAdhan(
          prayer: widget.prayerName!,
          prayerTime: widget.time,
        );
      } else {
        // إلغاء الجدولة
        await _notificationService.cancelAdhan(widget.prayerName!);
      }

      if (mounted) {
        setState(() => _isAdhanEnabled = value);
        widget.onAdhanToggled?.call();

        // إظهار رسالة تأكيد
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'تم تفعيل الأذان لصلاة ${widget.name} ✅'
                  : 'تم إلغاء الأذان لصلاة ${widget.name}',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color:
          widget.isPassed
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : null,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: widget.isPassed ? 0.3 : 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIcon(),
            color: widget.isPassed ? Colors.grey : widget.color,
            size: 28,
          ),
        ),
        title: Text(
          widget.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: widget.isPassed ? Colors.grey : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle:
            widget.showAdhanToggle
                ? Row(
                  children: [
                    Icon(
                      _isAdhanEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      size: 14,
                      color: _isAdhanEnabled ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isAdhanEnabled ? 'الأذان مفعّل' : 'الأذان معطّل',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isAdhanEnabled ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                )
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showAdhanToggle && widget.prayerName != null) ...[
              _isLoading
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Switch(
                    value: _isAdhanEnabled,
                    onChanged: _toggleAdhan,
                    activeThumbColor: widget.color,
                  ),
              const SizedBox(width: 8),
            ],
            Text(
              AppDateUtils.formatTime(widget.time),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: widget.isPassed ? Colors.grey : widget.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.name) {
      case 'الفجر':
        return Icons.brightness_3;
      case 'الشروق':
        return Icons.wb_sunny;
      case 'الظهر':
        return Icons.wb_sunny_outlined;
      case 'العصر':
        return Icons.sunny_snowing;
      case 'المغرب':
        return Icons.wb_twilight;
      case 'العشاء':
        return Icons.nightlight;
      case 'منتصف الليل الشرعي':
        return Icons.dark_mode;
      case 'الثلث الأخير من الليل':
        return Icons.bedtime;
      default:
        return Icons.access_time;
    }
  }
}
